# Hosted Evaluation Service Guide / 在线评测服务接入指引

This document describes the service boundary around a GamePhanes Harbor task. It is an integration guide, not a claim that the public repository already provides a hosted worker or a submission API.

本文说明 GamePhanes Harbor 任务与在线服务之间的边界。它是接入指引，不代表公开仓库已经提供托管 Worker 或在线提交 API。

## 1. Local readiness / 本地就绪标准

Run these checks from a clean checkout:

```powershell
npm install
npm test
npm run validate
npm run showcase:validate
```

The full Harbor check additionally requires Linux, Docker, the pinned Harbor version, and the engine used by the task. For `repair-neon-relay-jump`, the public container entry point is:

```bash
docker build -t game-terminal-bench-repair-neon-relay-jump \
  benchmark/harbor-tasks/repair-neon-relay-jump/environment
docker run --rm --network none \
  -v "$PWD/benchmark/harbor-tasks/repair-neon-relay-jump/tests:/tests:ro" \
  game-terminal-bench-repair-neon-relay-jump bash /tests/test.sh
```

Do not mark a task as fully verified from `npm test` or static schema checks alone. Record the Harbor version, Docker version, engine version, verifier exit code, Oracle result, and NOP baseline in a sanitized summary.

不要只凭 `npm test` 或静态 Schema 校验就宣布任务已经完整验证。应在脱敏摘要中记录 Harbor、Docker、引擎版本、Verifier 退出码、Oracle 结果和 NOP 基线。

## 2. Hosted worker responsibilities / 在线 Worker 职责

The hosted service should create one isolated worker per run:

```text
select task -> provision clean workspace -> expose terminal tools
     -> record commands and patches -> run hidden verifier
     -> publish score/report -> retain private rollout under policy
```

每次运行都应创建独立 Worker：

```text
选择任务 -> 创建干净工作区 -> 暴露 Terminal 工具
     -> 记录命令与 Patch -> 执行隐藏 Verifier
     -> 返回分数/报告 -> 按策略保存私有 Rollout
```

The worker must enforce all of the following:

- Mount only the candidate workspace at `/app`.
- Keep hidden tests, reference solutions, task mutations, and evaluator weights outside `/app` and outside the agent-visible filesystem.
- Disable outbound network access during evaluation unless a task explicitly declares a controlled dependency mirror.
- Enforce CPU, memory, process, disk, wall-clock, and output-size limits.
- Reset the workspace between trials and use immutable task/environment/evaluator versions.
- Store raw logs, tool calls, patches, report, and cost metadata with credentials and personal data redacted.
- Reject archives with path traversal, symlinks, unexpected artifacts, or undeclared executable entry points.

Worker 必须落实：

- 只把候选工作区挂载为 `/app`。
- 隐藏测试、参考解法、任务变体和评测权重不能出现在 `/app` 或 Agent 可见文件系统中。
- 评测阶段禁止出站网络，除非任务声明使用受控依赖镜像。
- 限制 CPU、内存、进程、磁盘、总时长和日志大小。
- 每个 Trial 重置工作区，并固定任务、环境和评测器版本。
- 保存原始日志、工具调用、Patch、报告和成本元数据，同时脱敏密钥及个人信息。
- 拒绝路径穿越、符号链接、未声明产物和未声明可执行入口。

## 3. Recommended service contract / 推荐服务契约

The service can expose a thin run API. The exact route is deployment-specific, but the payload should remain versioned:

```json
{
  "benchmark": "game-terminal-bench",
  "benchmark_version": "0.1.0",
  "task": "game-terminal-bench/repair-neon-relay-jump",
  "agent": { "name": "example-agent", "model": "kimi-k3" },
  "trials": 1,
  "options": { "network": "none", "timeout_sec": 900 }
}
```

Return a `run_id` immediately, then expose status and a final report:

```json
{
  "run_id": "run_01...",
  "status": "passed",
  "task": "game-terminal-bench/repair-neon-relay-jump",
  "reward": 1.0,
  "trials": [{ "reward": 1.0, "verifier_exit_code": 0 }],
  "versions": {
    "task": "0.1.0",
    "environment": "sha256:...",
    "evaluator": "gamephanes-hidden-v1"
  }
}
```

The service should not return hidden assertions, reference patches, private test files, or the full private rollout to the agent. A public result can contain the score and high-level failure category; maintainers can access detailed evidence through an authenticated review surface.

在线服务不应把隐藏断言、参考 Patch、私有测试文件或完整私有 Rollout 返回给 Agent。公开结果可以返回分数和高层失败类别；详细证据应通过受认证的审核入口提供给维护者。

## 4. OpenAI-compatible coding agents / OpenAI 兼容 Coding Agent

An agent adapter should point the model client at the service's OpenAI-compatible endpoint and supply an explicit terminal tool. The model loop owns the conversation; the worker owns command execution and evaluation.

Agent Adapter 应将模型客户端指向服务的 OpenAI 兼容接口，并显式提供 Terminal 工具。模型循环负责对话，Worker 负责执行命令和评测。

```bash
export OPENAI_BASE_URL="https://your-gateway.example/v1"
export OPENAI_API_KEY="<read-from-secret-manager>"
export OPENAI_MODEL="kimi-k3"
```

For Harbor `0.22.x`, GamePhanes includes a dependency-free host-side adapter. It avoids installing an Agent SDK inside every disposable task container:

```bash
export PYTHONPATH="$PWD"
harbor run --config integrations/harbor/kimi-k3-job.json
```

```json
{
  "agents": [{
    "import_path": "integrations.harbor.openai_tool_agent:OpenAICompatibleToolAgent",
    "model_name": "openai/kimi-k3",
    "env": {
      "OPENAI_API_KEY": "${OPENAI_API_KEY}",
      "OPENAI_BASE_URL": "${OPENAI_BASE_URL}",
      "OPENAI_TEMPERATURE": "1"
    }
  }],
  "tasks": [{ "path": "benchmark/harbor-tasks/repair-neon-relay-jump" }]
}
```

Run Harbor from the repository root and keep that root on `PYTHONPATH`; Harbor changes directories while constructing trials. The model API is called by the Harbor host process; every `run_terminal` command still executes through Harbor inside the isolated task container. This removes runtime `uv` and Agent-package downloads without weakening workspace or verifier isolation.

对于 Harbor `0.22.x`，GamePhanes 提供了一个无第三方依赖的主机侧 Adapter。模型 API 由 Harbor 主机进程调用，每条 `run_terminal` 命令仍通过 Harbor 在隔离任务容器中执行，因此可以去掉每个临时容器里的 `uv` 和 Agent Package 下载，同时不削弱工作区与 Verifier 隔离。

The terminal tool contract should be narrow and auditable:

```json
{
  "type": "function",
  "function": {
    "name": "run_terminal",
    "description": "Run a command in the isolated task workspace",
    "parameters": {
      "type": "object",
      "properties": { "command": { "type": "string" } },
      "required": ["command"]
    }
  }
}
```

The current test gateway exposes `kimi-k3` and `kimi-k3-256k`. On that gateway, `kimi-k3` returned standard OpenAI-style `tool_calls` when the tool schema was supplied, and requires `temperature=1`; `temperature=0` was rejected. This is a gateway/model constraint, so the adapter should make sampling parameters configurable and record the effective request configuration. A smoke test is not a benchmark score: publish a K3 score only after a complete Harbor run with the task version and verifier result recorded.

当前测试网关提供 `kimi-k3` 和 `kimi-k3-256k`。在该网关上，提供工具 Schema 后 `kimi-k3` 能返回标准 OpenAI 风格的 `tool_calls`，并要求 `temperature=1`；设置 `temperature=0` 会被拒绝。这是当前网关/模型的约束，因此 Adapter 应让采样参数可配置，并记录实际请求配置。接口 Smoke Test 不等于 Benchmark 分数；只有完成 Harbor 全流程并记录任务版本和 Verifier 结果后，才能发布 K3 分数。

The first complete K3 Harbor trial scored `1.0` with 14 model turns and 13 terminal tool calls. Agent setup took less than one millisecond because the adapter installs no runtime packages. See the [sanitized K3 result](../benchmark/results/repair-neon-relay-jump/v0.1.0/kimi-k3.json).

首个完整 K3 Harbor Trial 得分为 `1.0`，包含 14 个模型 Turn 和 13 次 Terminal Tool Call。由于 Adapter 不安装运行时 Package，Agent setup 不到 1 毫秒。详见[脱敏 K3 结果](../benchmark/results/repair-neon-relay-jump/v0.1.0/kimi-k3.json)。

Never commit API keys, provider headers, customer source, or raw private trajectories. Read credentials from a secret manager and redact them before exporting artifacts.

不要把 API Key、Provider Header、客户源代码或未经脱敏的私有轨迹提交到仓库。密钥应从 Secret Manager 读取，导出 Artifact 前完成脱敏。

## 5. Run record / 运行记录

Each published result should include:

- benchmark and task version;
- agent and model identifier;
- Harbor, Docker, engine, and worker image versions;
- trial count and timeout configuration;
- reward for every trial, mean reward, and error count;
- verifier exit code and a short sanitized log excerpt;
- artifact and trajectory hashes.

每条公开结果应包含：Benchmark 与任务版本、Agent 与模型标识、Harbor/Docker/引擎/Worker 镜像版本、Trial 数量与超时配置、每次 Reward/平均 Reward/错误数、Verifier 退出码与简短脱敏日志，以及 Artifact 和轨迹 Hash。
