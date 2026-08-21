# GamePhanes

> An open-source game coding agent environment that builds, plays, tests, and repairs Godot games.
>
> 一个开源的 Godot 游戏编码智能体环境，帮助 Agent 构建、试玩、测试并修复游戏。

[Project homepage / 项目主页](https://gamephanes.github.io/) · [Showcase / 游戏展示](#five-game-showcase--五款游戏展示) · [Architecture / 架构](docs/architecture.md)

![Neon Relay running in GamePhanes](docs/assets/neon-relay.png)

## What is GamePhanes? / 项目简介

GamePhanes is designed around a verifiable engineering loop rather than one-shot code generation.

GamePhanes 不把“生成代码”当作终点，而是围绕可验证的工程闭环设计：

```text
Understand -> Plan -> Build -> Run -> Play -> Observe -> Repair -> Evaluate
理解需求   -> 规划 -> 构建 -> 运行 -> 试玩 -> 观测 -> 修复 -> 评测
```

The current `v0.1` foundation provides / 当前 `v0.1` 基础版本提供：

- Godot environment discovery / Godot 环境探测；
- JSON benchmark task validation / JSON benchmark 任务校验；
- Temporary project copies with Playtest harness injection / 临时工程副本与 Playtest harness 注入；
- Godot headless import and runtime execution / Godot headless 导入和运行；
- Structured runtime events over NDJSON logs / 基于 NDJSON 日志的结构化运行时事件；
- Deterministic assertions and scoring without an LLM judge / 不依赖 LLM Judge 的确定性断言与评分报告；
- Five polished 2D/3D showcase slices with external Playtests / 五款带独立 Playtest 的精致 2D/3D 游戏切片。

## Five-game Showcase / 五款游戏展示

These are runnable Godot reference projects, not static mockups. Together they exercise movement, combat, physics state, resource strategy, wave simulation, 3D rendering, external input, and deterministic evaluation.

它们是真正可运行的 Godot 参考工程，不是静态概念图。五款游戏共同覆盖移动、战斗、物理状态、资源策略、波次模拟、3D 渲染、外部输入和确定性评测。

| Game / 游戏 | Runtime capture / 实机画面 | Verified loop / 已验证闭环 |
|---|---|---|
| [Neon Relay](examples/neon-relay) | ![Neon Relay](docs/assets/neon-relay.png) | Run, jump, collect three shards, finish / 奔跑、跳跃、收集三枚碎片、抵达终点 |
| [Last Signal](examples/last-signal) | ![Last Signal](docs/assets/last-signal.png) | Reposition, pulse, clear four threats / 移动、脉冲攻击、清除四个威胁 |
| [Gravity Lab](examples/gravity-lab) | ![Gravity Lab](docs/assets/gravity-lab.png) | Flip gravity, stabilize core, unlock exit / 反转重力、稳定核心、解锁出口 |
| [Tiny Bastion](examples/tiny-bastion) | ![Tiny Bastion](docs/assets/tiny-bastion.png) | Build towers, start wave, defend keep / 建塔、开启波次、守住城堡 |
| [Rift Arena](examples/rift-arena) | ![Rift Arena](docs/assets/rift-arena.png) | Move in 3D, strike warden, stabilize rift / 3D 移动、攻击守卫、稳定裂隙 |

All five currently pass `22/22` deterministic assertions with zero protocol errors.

五款游戏目前全部通过 `22/22` 项确定性断言，协议错误为零。

```powershell
npm run showcase:validate
$env:GAMEPHANES_GODOT = "C:\path\to\godot.exe"
npm run showcase:run
```

## Quick Start / 快速开始

Requirements / 环境要求：

- Node.js 22 or newer / Node.js 22 或更高版本；
- Godot 4.x, preferably the console build for complete logs / Godot 4.x，推荐控制台版本以保留完整日志。

```powershell
npm test
node ./bin/gamephanes.js validate ./benchmark/tasks/platformer-basic.json
node ./bin/gamephanes.js doctor --godot C:\path\to\godot.exe
node ./bin/gamephanes.js run ./benchmark/tasks/platformer-basic.json `
  --godot C:\path\to\godot.exe `
  --report ./reports/platformer-basic.json
```

Or set the environment variable / 也可以设置环境变量：

```powershell
$env:GAMEPHANES_GODOT = "C:\path\to\godot.exe"
npm run demo
```

The example verifies game startup, movement, jumping, coin collection, and Playtest completion.

示例评测会验证游戏启动、玩家移动、玩家跳跃、金币收集和 Playtest 完成状态。

## Task Format / 任务格式

Each task declares a candidate project, requirements, external harness, and rule assertions.

每个任务明确声明候选工程、需求、外部测试 harness 和规则断言。

```json
{
  "schema_version": 1,
  "id": "platformer_basic_001",
  "project": { "path": "../../examples/platformer-basic" },
  "requirements": [
    { "id": "player_jump", "description": "The player can jump." }
  ],
  "evaluation": {
    "harness": "../harnesses/platformer-basic.gd",
    "timeout_seconds": 15,
    "assertions": [
      {
        "id": "player_jumped",
        "event": "player_jumped",
        "field": "velocity_y",
        "operator": "<",
        "value": 0
      }
    ]
  }
}
```

Supported operators / 当前支持的断言操作符：`exists`、`==`、`!=`、`>`、`>=`、`<`、`<=`、`includes`。

## Asset Engineering / 资产工程

GamePhanes treats assets as versioned, inspectable engineering artifacts rather than untracked downloads.

GamePhanes 将资产视为有版本、可检查的工程产物，而不是临时下载的文件：

```powershell
node ./bin/gamephanes.js assets validate ./assets/manifest.json
node ./bin/gamephanes.js assets list ./assets/manifest.json
```

Each manifest entry records an asset ID, type, source, license, files, and runtime metadata. The showcase uses reproducible procedural visuals and versioned runtime captures, so it does not depend on external downloads.

每个 Manifest 条目记录资产 ID、类型、来源、许可证、文件和运行时元数据。Showcase 使用可复现的程序化视觉与有版本的实机截图，因此不依赖外部下载。

The asset pipeline is intentionally layered:

资产流水线分为四层：

1. Procedural fallback / 程序化兜底：确保 Benchmark 在没有外部资产时仍可运行；
2. Curated packs / 固定资产包：使用明确许可、可版本化和可再分发的素材；
3. Generated variants / 生成式变体：为角色、纹理、音频和 3D 内容提供可替换来源；
4. Agent adaptation / Agent 适配：完成格式转换、SpriteSheet、碰撞体、Pivot、动画和 Godot 导入验证。

See [`assets/manifest.json`](assets/manifest.json) for the current contract / 当前契约见 [`assets/manifest.json`](assets/manifest.json)。

## Why External Harnesses? / 为什么使用外部 Harness？

Test logic does not live inside candidate game code. GamePhanes:

测试逻辑不放在候选游戏代码中。GamePhanes 会：

1. Copy the candidate Godot project into a temporary directory / 将候选 Godot 工程复制到临时目录；
2. Inject a benchmark-owned harness / 把 benchmark 管理的 harness 注入临时副本；
3. Run the Godot import check / 运行 Godot 导入检查；
4. Load the main scene, perform inputs, and emit state events / 加载主场景、执行输入并输出状态事件；
5. Remove the copy and create a structured report / 删除临时副本并生成结构化报告。

This keeps ground-truth tests separate from Agent artifacts and leaves the original project untouched.

这样可以让 ground-truth 测试与 Agent 产物保持清晰边界，也不会修改原始工程。

## Repository Layout / 仓库结构

```text
gamephanes/
├── benchmark/
│   ├── harnesses/       # Independent Playtest drivers / 独立 Playtest 驱动
│   └── tasks/           # Reproducible task specs / 可复现任务规范
├── examples/            # Example Godot projects / 示例 Godot 工程
├── src/
│   ├── core/            # Task contract / 任务契约
│   ├── evaluation/      # Event protocol and scoring / 事件协议与评分
│   ├── godot/           # Engine discovery and execution / 引擎探测与执行
│   └── runtime/         # Process lifecycle / 子进程生命周期
├── test/
└── docs/                # GitHub Pages homepage / GitHub Pages 主页
```

## Current Boundary / 当前边界

The local runner isolates project files and execution time; it is not an OS-level security sandbox. Godot still inherits the current user's permissions and network access. Run untrusted Agent projects inside a container or a permission-isolated worker.

当前 runner 提供的是临时工程副本和执行时间限制，并非操作系统级安全沙箱。Godot 子进程仍继承当前用户权限和网络访问能力。运行不受信任的 Agent 工程时，应使用容器或权限隔离的 worker。

GamePhanes is currently evaluation-first. It does not yet include a specific LLM, automatic coding loop, Artifact Graph, screenshot understanding, or asset generation.

GamePhanes 当前以 evaluation-first 为边界，尚未接入具体大模型、自动编码循环、Artifact Graph、截图理解或资产生成。

## Roadmap / 路线图

- `M0 - Environment`：Task contract, Godot runner, event protocol, rule evaluator / 任务契约、Godot runner、事件协议、规则评测；
- `M1 - Coding Agent`：Controlled file tools and repair loop / 受控文件工具、Godot 项目检查、实现与修复循环；
- `M2 - Playtest`：Input DSL, screenshots, Node state, time-series assertions / 键鼠动作 DSL、截图、Node 状态和时间序列断言；
- `M3 - GamePhanes-Bench`：Five showcase slices available; expand toward 10 core tasks and baselines / 已提供五款展示切片，继续扩展到 10 个核心任务和 baseline；
- `M4 - Project State`：Scene/Script/Resource Artifact Graph and long-task ablations / Scene/Script/Resource Artifact Graph 与长任务消融；
- `M5 - Assets and 3D`：Asset retrieval, adaptation, animation, and Godot 3D / 资产检索、适配、动画和 Godot 3D。

## License / 许可证

MIT
