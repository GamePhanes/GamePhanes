"""Response-state policy for OpenAI-compatible Harbor agents."""

from __future__ import annotations

from typing import Literal


ResponseAction = Literal["tools", "continue", "complete"]


def classify_response(finish_reason: str | None, has_tool_calls: bool) -> ResponseAction:
    """Decide whether a model response should execute, continue, or finish."""
    if has_tool_calls:
        return "tools"
    if finish_reason == "length":
        return "continue"
    if finish_reason == "stop":
        return "complete"
    raise RuntimeError(
        "model response ended without tool calls or a normal stop "
        f"(finish_reason={finish_reason!r})"
    )
