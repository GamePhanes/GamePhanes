# Game Terminal-Bench

> **面向交互软件 Coding Agent 的 Terminal-Bench。**
>
> 一个兼容 Harbor 的 Benchmark，评估 Coding Agent 如何通过 Terminal 工作区和可执行的运行时反馈，构建、调试和修复游戏及其他交互应用。

[English](README.md)

[项目主页](https://gamephanes.github.io/) · [Benchmark 页面](https://gamephanes.github.io/bench.html) · [任务库](https://gamephanes.github.io/registry/) · [Issues](https://github.com/GamePhanes/GamePhanes/issues) · [Discussions](https://github.com/GamePhanes/GamePhanes/discussions)

## 项目是什么

传统 Terminal Benchmark 通常评估文件、命令和退出码。交互软件还有第二层真相：工程必须成功导入、启动、接受受控输入、改变运行时状态并产生预期行为。Game Terminal-Bench 评估的正是这个完整闭环。

```text
任务说明 -> 检查 -> 修改 -> 运行 -> 观察 -> 诊断 -> 修复 -> 验证
```

评测对象是 Coding Agent，不是玩家 Bot。Harness 的输入由评测器控制，只用于获得提交代码的运行证据。Agent 被评估的是工程能力：代码修改、调试、运行时行为和对回归的控制。

本项目是基于 Harbor 任务契约构建的独立数据集。它兼容 Harbor 的执行方式，但不是 Terminal-Bench 2.0、TB-Science 的子集，也不属于它们的 leaderboard。

## 已校准任务

| 任务 | 定位 | 运行时验收边界 | Kimi K3 |
|---|---|---|---|
| [`repair-neon-relay-jump`](benchmark/harbor-tasks/repair-neon-relay-jump/) | Smoke Test | 启动工程、修复相位跳跃，并保留碎片收集与中继完成行为。 | `1.0` |
| [`repair-chrono-grid-rollback`](benchmark/harbor-tasks/repair-chrono-grid-rollback/) | 较难校准题 | 修复确定性回滚、延迟修正、不可变快照、RNG 状态与有界历史。 | `1.0` |
| [`repair-kinetic-vault-controller`](benchmark/harbor-tasks/repair-kinetic-vault-controller/) | 有区分度的难题 | 修复连续碰撞、单向平台、coyote/buffer 边界、dash 状态、移动平台承载与挤压。 | `0.0`（通过 16/18 项断言） |

三道题都已具备完整 Harbor 任务包。其 Harbor 0.22.0 校准运行均无异常，Oracle 为 `1.0`、NOP 为 `0.0`。表中的 Kimi K3 成绩来自真实单次 Trial，不是预估值；版本化记录见 [`benchmark/results`](benchmark/results/)。

Kinetic Vault 的 K3 Trial 实际修改了代码，完成 30 个模型 Turn，并以 `finish_reason=stop` 正常结束，随后在两项隐藏边界断言上失败。它不是安装、网关、超时或截断导致的无效失败。

公开网站包含六个可试玩的参考工程。计划中的生产级任务集共 20 题，分为玩法与手感、引擎与运行时、UI 与交互、内容与系统、交付与质量五类。任务在完成版本化封装和可复现评测前，不会被报告为实测分数。

## Harbor 任务格式

每个贡献任务都必须是一个自包含的 Harbor 任务目录：

```text
task-name/
├── task.toml
├── instruction.md
├── environment/
│   ├── Dockerfile
│   └── project/          # 复制进任务容器的 Starter 工程
├── tests/
│   ├── test.sh
│   └── ...                # verifier、harness、探针和 fixtures
└── solution/
    └── solve.sh           # 维护者/Oracle 解法，不提供给 Agent
```

### 文件职责

- `task.toml`：Harbor Schema 版本、任务名称、描述、产物、元数据、超时和资源限制。保持声明式和可复现。
- `instruction.md`：给 Agent 的用户任务。描述起始状态、目标行为、约束和验收标准。不能写出解法，也不能提供暴露具体 Patch 的提示。
- `environment/Dockerfile`：固定引擎、操作系统依赖、工程依赖和运行入口。干净构建必须生成一致的环境。
- `environment/project/`：有真实 Bug 或缺失行为的 Starter 工程。Agent 应能在其中检查并复现问题。
- `tests/`：由 Benchmark 管理的独立验证。测试必须从候选代码外部驱动工程，同时检查目标行为和重要的保留行为。
- `solution/solve.sh`：维护者用来证明任务可解的可执行 Oracle。评测时不会复制到 Agent 工作区。

任务包不得依赖贡献者本机绝对路径、私有包仓库、未声明资产、评测时网络下载或必须手动操作 GUI 的步骤。

## 最小 `task.toml`

使用当前 Harbor Schema，并明确写出任务元数据：

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

## 如何运行

### 校验仓库

```powershell
npm install
npm test
```

Harbor 任务包的完整运行需要支持 Docker 的机器，并使用评测环境锁定的 Harbor 版本：

```powershell
docker build -t game-terminal-bench-repair-neon-relay-jump ./benchmark/harbor-tasks/repair-neon-relay-jump/environment
docker run --rm `
  -v "${PWD}/benchmark/harbor-tasks/repair-neon-relay-jump/tests:/tests:ro" `
  game-terminal-bench-repair-neon-relay-jump bash /tests/test.sh
```

具体 Harbor CLI 命令应跟随评测服务使用的 Harbor 版本；任务目录本身是可移植单元。仅通过静态检查不能宣布任务已验证，维护者必须记录 Harbor/容器运行结果。

本地校验与在线评测服务之间的边界、Worker 要求和 Agent 接入方式见[在线评测服务接入指引](docs/hosted-service.md)。

## 如何提交任务

1. Fork 本仓库，并为一个任务创建独立分支。
2. 按照上面的格式，在 `benchmark/harbor-tasks/<task-name>/` 下新增一个任务目录。
3. 确保 `tests/test.sh` 和 `solution/solve.sh` 具有可执行权限。
4. 在干净 Checkout 中运行 `npm test`、任务 Verifier、Docker 构建和 Oracle 解法。
5. 提交 Pull Request，关联 Issue 或任务提案，并说明任务评估的运行时行为。

### Pull Request 检查清单

- [ ] `task.toml` 使用受支持的 Harbor Schema，任务名称唯一。
- [ ] `instruction.md` 描述目标、约束和验收标准，但不泄露解法。
- [ ] Starter 工程包含 Agent 可以从工作区调查的真实 Bug、缺失功能或回归。
- [ ] `tests/` 独立于候选实现，同时检查目标行为和有意义的回归边界。
- [ ] 任务是确定性的，或明确记录所有受控随机来源。
- [ ] 依赖准备完成后，Docker 构建和运行时测试不依赖网络。
- [ ] `solution/solve.sh` 能从 Starter 状态解决任务，失败时返回非零退出码。
- [ ] 不包含密钥、私有资产、受版权保护的游戏内容或机器特定路径。
- [ ] PR 写明预计专家耗时、难度、类别和已知限制。

## 任务质量门槛

高质量任务应有明确的用户可见目标、可信的工程故障、足够的检查与修复空间、确定性证据和回归边界。任务应奖励理解工程，而不是匹配某个已知 Patch。

评审会拒绝以下任务：删除玩法循环即可通过、把工程替换成空壳、削弱 Verifier、只依赖截图，或把受控探针序列硬编码进候选工程即可通过。

## 开源与闭源边界

| 开源内容 | 闭源或服务层内容 |
|---|---|
| Harbor 任务格式与示例 | 封闭任务变体 |
| Starter 工程与公开 Demo | 隐藏评测与反捷径检查 |
| 参考测试与评分原则 | 生产 Rollout 轨迹与失败标签 |
| 本地 Runner 与可复现报告 | 客户定制环境与私有数据 |

公开仓库是可检查的信任基础层。私有评测内容和收集到的 Agent 轨迹不会作为 Benchmark 答案发布。

## 游戏 Demo

可在 [GamePhanes 项目主页](https://gamephanes.github.io/#showcase)试玩六个参考环境：Starfall Protocol、Neon Relay、Last Signal、Gravity Lab、Tiny Bastion 和 Rift Arena。它们是可执行的运行时反馈面，不是玩家策略 Benchmark。

## Contributors

### Project Leadership

- Chenyi Zi

### Senior Reviewers

- xxxx

### Task Authors

- xxxx

## 许可证

MIT

## Citation / 引用

如果你在研究、评测或 Agent 训练中使用 Game Terminal-Bench，请引用本仓库：

```bibtex
@software{game_terminal_bench_2026,
  author  = {Zi, Chenyi},
  title   = {Game Terminal-Bench},
  year    = {2026},
  url     = {https://github.com/GamePhanes/GamePhanes},
  license = {MIT}
}
```

GitHub 也会通过 **Cite this repository** 展示结构化引用元数据。

## GitHub Stars 随时间变化

<a href="https://www.star-history.com/?repos=GamePhanes%2FGamePhanes&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=GamePhanes/GamePhanes&type=date&theme=dark&legend=top-left&sealed_token=XlH0QS9JLCQB7yLakuOBheWskMb9mz5EWIosGu4IqmTavLemai-_WbLeRUiOFFLFESM2LA0P8Is-OMurRns1vkDLQPBThbbGCSs0C40YWGgU6aSEFR4m3fmfmIxnbWlQPyfY_Xl1RXMXFJ_4L6ZeFmgyTBieN-okDlNx68oFQ-sjV0Hw4ygSk8gvrfdh" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=GamePhanes/GamePhanes&type=date&legend=top-left&sealed_token=XlH0QS9JLCQB7yLakuOBheWskMb9mz5EWIosGu4IqmTavLemai-_WbLeRUiOFFLFESM2LA0P8Is-OMurRns1vkDLQPBThbbGCSs0C40YWGgU6aSEFR4m3fmfmIxnbWlQPyfY_Xl1RXMXFJ_4L6ZeFmgyTBieN-okDlNx68oFQ-sjV0Hw4ygSk8gvrfdh" />
   <img alt="GitHub Stars 随时间变化" src="https://api.star-history.com/chart?repos=GamePhanes/GamePhanes&type=date&legend=top-left&sealed_token=XlH0QS9JLCQB7yLakuOBheWskMb9mz5EWIosGu4IqmTavLemai-_WbLeRUiOFFLFESM2LA0P8Is-OMurRns1vkDLQPBThbbGCSs0C40YWGgU6aSEFR4m3fmfmIxnbWlQPyfY_Xl1RXMXFJ_4L6ZeFmgyTBieN-okDlNx68oFQ-sjV0Hw4ygSk8gvrfdh" />
 </picture>
</a>
