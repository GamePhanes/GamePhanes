# Game Terminal-Bench

> **SWE-bench for interactive software.**
>
> A Harbor-compatible benchmark for coding agents that build, debug, and repair games and other interactive applications through terminal workspaces and executable runtime feedback.
>
> **面向交互软件的 SWE-bench。** Game Terminal-Bench 将 Coding Agent 放进真实工程，通过 Terminal 修改代码、运行环境、观察游戏反馈，并用独立测试评估最终产物。

[Homepage / 项目主页](https://gamephanes.github.io/) · [Bench / Benchmark 页面](https://gamephanes.github.io/bench.html) · [Task Registry / 任务库](https://gamephanes.github.io/registry/) · [Issues](https://github.com/GamePhanes/GamePhanes/issues) · [Discussions](https://github.com/GamePhanes/GamePhanes/discussions)

## What Is Game Terminal-Bench? / 项目是什么

Terminal benchmarks usually stop at files, commands, and exit codes. Interactive software adds a second truth: the project must import, launch, accept controlled input, change runtime state, and produce the intended behavior. Game Terminal-Bench evaluates coding agents on that complete loop.

传统 Terminal Benchmark 通常在文件、命令和退出码处结束。交互软件还有第二层真相：工程必须成功导入、启动、接受受控输入、改变运行时状态并产生预期行为。Game Terminal-Bench 评估的正是这个完整闭环。

```text
instruction -> inspect -> edit -> run -> observe -> diagnose -> repair -> verify
任务说明     -> 检查   -> 修改 -> 运行 -> 观察   -> 诊断   -> 修复   -> 验证
```

The benchmark target is a coding agent, not a player bot. Harness inputs are evaluator-controlled probes used to obtain evidence about the submitted code. The agent is judged on engineering work: code changes, debugging, runtime behavior, and regression resistance.

评测对象是 Coding Agent，不是玩家 Bot。Harness 的输入由评测器控制，只用于获得提交代码的运行证据。Agent 被评估的是工程能力：代码修改、调试、运行时行为和对回归的控制。

This is an independent dataset built on the Harbor task contract. It is compatible with Harbor execution, but it is not Terminal-Bench 2.0, TB-Science, or a leaderboard subset of either dataset.

本项目是基于 Harbor 任务契约构建的独立数据集。它兼容 Harbor 的执行方式，但不是 Terminal-Bench 2.0、TB-Science 的子集，也不属于它们的 leaderboard。

## Current Task / 当前任务

The first complete Harbor task is [`repair-neon-relay-jump`](benchmark/harbor-tasks/repair-neon-relay-jump/). It asks an agent to repair a broken phase jump in a Godot platformer while preserving shard collection and relay completion.

首个完整 Harbor 任务是 [`repair-neon-relay-jump`](benchmark/harbor-tasks/repair-neon-relay-jump/)，要求 Agent 修复 Godot 平台游戏中失效的相位跳跃，同时保留碎片收集和中继完成行为。

| Task | Category | Acceptance boundary |
|---|---|---|
| `repair-neon-relay-jump` | bug-fix · movement · runtime | Project launches, jump produces upward velocity, three shards remain collectible, and the relay can still be completed. |

The public site contains six playable reference projects. The planned production slate is 20 tasks across gameplay, engine/runtime, UI/interaction, content/systems, and delivery/quality. Planned tasks are not measured scores until they have a versioned package and a reproducible evaluation run.

## Harbor Task Format / Harbor 任务格式

Every contributed task must be a self-contained Harbor task directory:

```text
task-name/
├── task.toml
├── instruction.md
├── environment/
│   ├── Dockerfile
│   └── project/          # starter project copied into the task container
├── tests/
│   ├── test.sh
│   └── ...                # verifier, harness, probes, fixtures
└── solution/
    └── solve.sh           # maintainer/oracle solution, never shown to the agent
```

### File responsibilities / 文件职责

- `task.toml`: Harbor schema version, task name, description, artifacts, metadata, timeouts, and resource limits. Keep it declarative and reproducible.
- `instruction.md`: the user-facing task. State the starting condition, target behavior, constraints, and acceptance criteria. Do not include the solution or hints that reveal the exact patch.
- `environment/Dockerfile`: pin the engine, OS packages, project dependencies, and runtime entrypoint. A clean build must produce the same environment.
- `environment/project/`: the broken or incomplete starter project. It must be runnable enough for an agent to inspect and reproduce the problem.
- `tests/`: benchmark-owned verification. Tests must exercise the project from outside the candidate code and must check both the requested change and important preserved behavior.
- `solution/solve.sh`: an executable oracle used by maintainers to prove the task is solvable. It is not copied into the agent workspace during evaluation.

The task package must not depend on a contributor's local absolute path, private package registry, undisclosed asset, network download at evaluation time, or an interactive GUI step.

任务包不得依赖贡献者本机绝对路径、私有包仓库、未声明资产、评测时网络下载或必须手动操作 GUI 的步骤。

## Minimal `task.toml` / 最小配置

Use Harbor's current schema and keep metadata explicit. This is the shape used by the reference task:

```toml
schema_version = "1.1"

artifacts = [
  "/app/project.godot",
  "/app/main.tscn",
  "/app/scripts/",
]

[task]
name = "game-terminal-bench/<task-name>"
description = "A concise, outcome-focused task description."
authors = [{ name = "Your Name", email = "you@example.com" }]

[metadata]
author_name = "Your Name"
difficulty = "medium"
category = "Software"
subcategory = "Game Development"
tags = ["godot", "bug-fix", "runtime-evaluation"]

[verifier]
timeout_sec = 120.0

[agent]
timeout_sec = 900.0

[environment]
build_timeout_sec = 600.0
cpus = 1
memory_mb = 2048
storage_mb = 10240
```

## How To Run / 如何运行

### Validate the repository task / 校验任务包

```powershell
npm install
npm test
```

For the Harbor package, inspect the package locally and run it with the Harbor version pinned by your evaluation setup. A Docker-capable machine is required for the full container run:

```powershell
docker build -t game-terminal-bench-repair-neon-relay-jump ./benchmark/harbor-tasks/repair-neon-relay-jump/environment
docker run --rm `
  -v "${PWD}/benchmark/harbor-tasks/repair-neon-relay-jump/tests:/tests:ro" `
  game-terminal-bench-repair-neon-relay-jump bash /tests/test.sh
```

The exact Harbor CLI invocation belongs to the runner version used by the benchmark service; the task directory itself is the portable unit. Do not report a task as verified from static checks alone: a maintainer must record the Harbor/container result.

Harbor 包的完整运行需要支持 Docker 的机器；具体 Harbor CLI 命令应跟随评测服务锁定的 Harbor 版本。任务目录本身是可移植单元。仅通过静态检查不能宣布任务已验证，维护者必须记录 Harbor/容器运行结果。

## How To Submit A Task / 如何提交任务

1. Fork this repository and create a branch for one task.
2. Add one directory under `benchmark/harbor-tasks/<task-name>/` using the format above.
3. Make `tests/test.sh` and `solution/solve.sh` executable.
4. Run `npm test`, the task verifier, a clean Docker build, and the oracle solution from a clean checkout.
5. Open a pull request. Link the issue or task proposal and explain the runtime behavior being evaluated.

提交流程：Fork 仓库，为一个任务创建分支；将任务放入 `benchmark/harbor-tasks/<task-name>/`；确保 `tests/test.sh` 和 `solution/solve.sh` 可执行；在干净环境中运行 `npm test`、Verifier、Docker 构建和 Oracle 解法；最后提交 Pull Request，并说明任务评估的运行时行为。

### Pull request checklist / PR 检查清单

- [ ] `task.toml` uses a supported Harbor schema and a unique task name.
- [ ] `instruction.md` describes outcomes, constraints, and acceptance criteria without exposing the solution.
- [ ] The starter project contains a real bug, missing feature, or regression that an agent can investigate from the workspace.
- [ ] `tests/` is independent from the candidate implementation and checks required behavior plus meaningful regression boundaries.
- [ ] The task is deterministic or documents every controlled source of randomness.
- [ ] Docker build and runtime test work without network access after dependencies are prepared.
- [ ] `solution/solve.sh` solves the task from the starter state and exits non-zero on failure.
- [ ] No secrets, private assets, copyrighted game content, or machine-specific paths are included.
- [ ] The PR states estimated expert time, difficulty, category, and known limitations.

## Task Quality Bar / 任务质量门槛

A strong task has a narrow user-visible objective, a believable engineering failure, enough surface area for inspection and repair, deterministic evidence, and a regression boundary. It should reward understanding the project rather than string-matching a known patch.

高质量任务应有明确的用户可见目标、可信的工程故障、足够的检查与修复空间、确定性证据和回归边界。任务应奖励理解工程，而不是匹配某个已知 Patch。

Reviewers will reject tasks that can be passed by deleting the gameplay loop, replacing the project with a stub, weakening the verifier, relying on screenshots alone, or hard-coding the probe sequence.

评审会拒绝以下任务：删除玩法循环即可通过、把工程替换成空壳、削弱 Verifier、只依赖截图，或把受控探针序列硬编码进候选工程即可通过。

## Public And Private Layers / 开源与闭源边界

| Public / 开源 | Private or service layer / 闭源或服务层 |
|---|---|
| Harbor task schema and examples / Harbor 任务格式与示例 | Sealed task variants / 封闭任务变体 |
| Starter projects and public demos / Starter 工程与公开 Demo | Hidden evaluators and anti-shortcut checks / 隐藏评测与反捷径检查 |
| Reference tests and scoring principles / 参考测试与评分原则 | Production rollout traces and failure labels / 生产 Rollout 轨迹与失败标签 |
| Local runner and reproducible reports / 本地 Runner 与可复现报告 | Customer-specific environments and private data / 客户定制环境与私有数据 |

The public repository is the inspectable trust layer. Private evaluation content and collected agent trajectories are not published as benchmark answers.

## Showcase / 游戏 Demo

Play the six reference environments on the [GamePhanes homepage](https://gamephanes.github.io/#showcase): Starfall Protocol, Neon Relay, Last Signal, Gravity Lab, Tiny Bastion, and Rift Arena. They are executable feedback surfaces, not player-policy benchmarks.

## Contributors

### Project Leadership

- Chenyi Zi

### Senior Reviewers

- xxxx

### Task Authors

- xxxx

## License

MIT
