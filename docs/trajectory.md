# Coding Agent Trajectory Contract / Coding Agent 轨迹契约

GamePhanes records the coding loop, not a gameplay policy loop. A trajectory connects an Agent's engineering actions to the runtime evidence produced by the modified project:

GamePhanes 记录的是 Coding Agent 的工程循环，而不是游戏操作策略循环。轨迹把 Agent 的工程动作和修改后工程产生的运行时证据连接起来：

```text
edit -> build/run -> runtime feedback -> diagnose -> repair
修改 -> 构建/运行 -> 运行时反馈 -> 诊断 -> 修复
```

## Schema / Schema

The public schema is versioned and JSON-serializable. Each step has one actor, one action, an observation, a result, and a numeric reward. Rewards describe engineering progress, such as assertion score or successful build, not player performance.

公开 Schema 有版本号，并且可以直接序列化为 JSON。每一步包含一个参与者、一个动作、一次观测、一个结果和数值 reward。Reward 描述工程进展，例如断言得分或构建成功，而不是玩家表现。

```json
{
  "schema_version": 1,
  "trajectory_type": "coding_agent",
  "episode_id": "ep_001",
  "task_id": "platformer_basic_001",
  "agent": "agent_x",
  "environment": { "engine": "godot", "version": "4.x" },
  "status": "failed",
  "steps": [
    {
      "step": 0,
      "actor": "agent",
      "action": { "type": "apply_patch", "input": { "files": ["scripts/player.gd"] } },
      "observation": { "source": "task" },
      "result": { "status": "ok" },
      "reward": 0,
      "cost": { "duration_ms": 1200, "tool_calls": 1 }
    },
    {
      "step": 1,
      "actor": "evaluator",
      "action": { "type": "run_playtest", "input": { "task_id": "platformer_basic_001" } },
      "observation": { "events": [{ "type": "ready" }] },
      "result": { "total_score": 0.4 },
      "reward": 0.4
    }
  ]
}
```

## Public API / 公开 API

```js
import { CodingAgentAdapter, TrajectoryRecorder } from "../src/trajectory/recorder.js";

const recorder = new TrajectoryRecorder({
  taskId: "platformer_basic_001",
  agent: "agent_x",
  environment: { engine: "godot", version: "4.x" },
});
const agent = new CodingAgentAdapter({ recorder });

agent.recordToolCall({
  tool: "read_file",
  input: { path: "scripts/player.gd" },
  output: { content: "..." },
});
agent.recordPatch({
  files: ["scripts/player.gd"],
  patch: "@@ ...",
});
agent.recordFeedback({ report });
agent.finish({ status: "passed", finalScore: 1 });
recorder.write("./trajectory.json");
```

Supported Agent actions are `read_file`, `write_file`, `apply_patch`, `run_godot`, `run_playtest`, `inspect_scene`, `take_screenshot`, and `repair`. Player controls such as `press_key`, `move_player`, or `attack` are intentionally rejected as Agent actions.

支持的 Agent 动作包括 `read_file`、`write_file`、`apply_patch`、`run_godot`、`run_playtest`、`inspect_scene`、`take_screenshot` 和 `repair`。`press_key`、`move_player`、`attack` 等玩家控制动作会被有意拒绝，不能作为 Coding Agent 动作记录。

## Evaluator Probe / 评测器探针

`gamephanes run task.json --trajectory trajectory.json` can save a public `evaluator_probe` trace. This trace captures the environment's feedback and logs, but contains no Agent tool calls. It is useful for checking the environment contract and must not be counted as a coding-agent rollout.

`gamephanes run task.json --trajectory trajectory.json` 可以保存公开的 `evaluator_probe` 轨迹。它记录环境反馈和日志，但不包含 Agent 工具调用，适合检查环境契约，不能计入 Coding Agent rollout。

## Data Boundary / 数据边界

The recorder stores caller-supplied outputs and logs. Production integrations should redact credentials, personal data, and customer source before exporting a trajectory. Private task variants, hidden evaluator details, full customer rollouts, and derived failure labels remain outside the public repository.

记录器会保存调用方传入的输出和日志。生产接入在导出轨迹前必须脱敏凭证、个人信息和客户源代码。私有任务变体、隐藏评测细节、完整客户 Rollout 和派生失败标签仍不进入公开仓库。
