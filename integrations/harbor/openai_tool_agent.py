"""Dependency-free OpenAI-compatible coding agent for Harbor.

The model loop runs in the Harbor host process. Shell commands still execute in
the isolated task environment, so no model SDK or agent package is installed in
the task container at runtime.
"""

from __future__ import annotations

import asyncio
import json
import os
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

from harbor.agents.base import BaseAgent
from harbor.environments.base import BaseEnvironment
from harbor.models.agent.context import AgentContext

from integrations.harbor.response_policy import classify_response


class OpenAICompatibleToolAgent(BaseAgent):
    """Run an OpenAI-compatible tool loop against a Harbor environment."""

    SUPPORTS_WINDOWS = False

    @staticmethod
    def name() -> str:
        return "openai-compatible-tool-agent"

    def version(self) -> str:
        return "0.1.0"

    async def setup(self, environment: BaseEnvironment) -> None:
        return

    def _setting(self, name: str, default: str | None = None) -> str:
        value = self._get_env(name)
        if value is None:
            if default is None:
                raise ValueError(f"{name} is required")
            return default
        return value

    def _request(self, messages: list[dict[str, Any]]) -> dict[str, Any]:
        base_url = self._setting("OPENAI_BASE_URL").rstrip("/")
        api_key = self._setting("OPENAI_API_KEY")
        model = self.model_name or self._setting("OPENAI_MODEL")
        if "/" in model:
            model = model.split("/", 1)[1]

        payload = {
            "model": model,
            "messages": messages,
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "run_terminal",
                        "description": "Run a shell command in the isolated task workspace.",
                        "parameters": {
                            "type": "object",
                            "properties": {"command": {"type": "string"}},
                            "required": ["command"],
                        },
                    },
                }
            ],
            "tool_choice": "auto",
            "temperature": float(self._setting("OPENAI_TEMPERATURE", "1")),
            "max_tokens": int(self._setting("OPENAI_MAX_TOKENS", "4096")),
        }
        request = urllib.request.Request(
            f"{base_url}/chat/completions",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(
                request,
                timeout=float(self._setting("OPENAI_TIMEOUT_SEC", "180")),
            ) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            body = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"model API returned HTTP {error.code}: {body[:2000]}") from error

    @staticmethod
    def _assistant_message(message: dict[str, Any]) -> dict[str, Any]:
        stored: dict[str, Any] = {
            "role": "assistant",
            "content": message.get("content") or "",
        }
        if message.get("tool_calls"):
            stored["tool_calls"] = message["tool_calls"]
        return stored

    @staticmethod
    def _limited(value: str | None, limit: int = 30_000) -> str:
        text = value or ""
        if len(text) <= limit:
            return text
        return f"{text[:limit]}\n...[truncated {len(text) - limit} characters]"

    async def run(
        self,
        instruction: str,
        environment: BaseEnvironment,
        context: AgentContext,
    ) -> None:
        messages: list[dict[str, Any]] = [
            {
                "role": "system",
                "content": (
                    "You are an autonomous coding agent in a Harbor task. Work only in /app. "
                    "Use run_terminal to inspect, edit, and test the project. Do not merely explain "
                    "a solution: make the changes and verify them before finishing. Keep internal "
                    "planning concise and call run_terminal early in each response."
                ),
            },
            {"role": "user", "content": instruction},
        ]
        trajectory: list[dict[str, Any]] = []
        totals = {"prompt_tokens": 0, "completion_tokens": 0, "cached_tokens": 0}
        max_turns = int(self._setting("OPENAI_MAX_TURNS", "30"))
        max_truncations = int(self._setting("OPENAI_MAX_TRUNCATIONS", "6"))
        command_timeout = int(self._setting("AGENT_COMMAND_TIMEOUT_SEC", "180"))
        truncations = 0

        self.logs_dir.mkdir(parents=True, exist_ok=True)
        trajectory_path = Path(self.logs_dir) / "openai-tool-agent.json"

        for turn in range(max_turns):
            response = await asyncio.to_thread(self._request, messages)
            choices = response.get("choices") or []
            if not choices:
                raise RuntimeError("model API returned no choices")

            message = choices[0].get("message") or {}
            usage = response.get("usage") or {}
            totals["prompt_tokens"] += int(usage.get("prompt_tokens") or 0)
            totals["completion_tokens"] += int(usage.get("completion_tokens") or 0)
            prompt_details = usage.get("prompt_tokens_details") or {}
            totals["cached_tokens"] += int(
                prompt_details.get("cached_tokens")
                or prompt_details.get("cached_read_tokens")
                or 0
            )

            assistant = self._assistant_message(message)
            messages.append(assistant)
            turn_record: dict[str, Any] = {
                "turn": turn,
                "finish_reason": choices[0].get("finish_reason"),
                "assistant": assistant,
                "usage": usage,
                "tool_results": [],
            }
            trajectory.append(turn_record)

            tool_calls = message.get("tool_calls") or []
            action = classify_response(choices[0].get("finish_reason"), bool(tool_calls))
            if action == "continue":
                truncations += 1
                trajectory_path.write_text(
                    json.dumps(trajectory, indent=2, ensure_ascii=False),
                    encoding="utf-8",
                )
                if truncations > max_truncations:
                    raise RuntimeError(
                        "model repeatedly exhausted its response token limit without a tool call "
                        f"(OPENAI_MAX_TRUNCATIONS={max_truncations})"
                    )
                messages.append(
                    {
                        "role": "user",
                        "content": (
                            "Your previous response reached its token limit before taking an action. "
                            "Continue from your current analysis and call run_terminal immediately "
                            "to edit or test the solution."
                        ),
                    }
                )
                continue

            if action == "complete":
                trajectory_path.write_text(
                    json.dumps(trajectory, indent=2, ensure_ascii=False),
                    encoding="utf-8",
                )
                context.n_input_tokens = totals["prompt_tokens"]
                context.n_output_tokens = totals["completion_tokens"]
                context.n_cache_tokens = totals["cached_tokens"]
                context.metadata = {
                    "turns": turn + 1,
                    "finish_reason": choices[0].get("finish_reason"),
                    "truncations": truncations,
                    "trajectory": trajectory_path.name,
                }
                return

            for call in tool_calls:
                function = call.get("function") or {}
                call_id = call.get("id") or f"tool-{turn}"
                if function.get("name") != "run_terminal":
                    result = {"error": f"unsupported tool: {function.get('name')}"}
                else:
                    try:
                        arguments = json.loads(function.get("arguments") or "{}")
                        command = arguments["command"]
                        if not isinstance(command, str) or not command.strip():
                            raise ValueError("command must be a non-empty string")
                        execution = await environment.exec(
                            command=command,
                            cwd="/app",
                            timeout_sec=command_timeout,
                        )
                        result = {
                            "exit_code": execution.return_code,
                            "stdout": self._limited(execution.stdout),
                            "stderr": self._limited(execution.stderr),
                        }
                    except Exception as error:
                        result = {"error": f"{type(error).__name__}: {error}"}

                turn_record["tool_results"].append({"id": call_id, "result": result})
                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": call_id,
                        "content": json.dumps(result, ensure_ascii=False),
                    }
                )

            trajectory_path.write_text(
                json.dumps(trajectory, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )

        raise RuntimeError(f"agent exceeded OPENAI_MAX_TURNS={max_turns}")
