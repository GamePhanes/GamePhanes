# GamePhanes Architecture / GamePhanes 架构

## Design Principles / 设计原则

1. **Execution before appearance / 先验证运行，再讨论表现**：Build、启动和功能行为优先于视觉质量评分。
2. **Deterministic before subjective / 先确定性，再主观判断**：能用状态断言验证的需求不交给 LLM Judge。
3. **Evidence before claims / 证据胜过结论**：Agent 必须通过日志、事件、截图或状态证明功能工作。
4. **One agent, structured tools first / 单 Agent，结构化工具优先**：首版保持单一控制循环，按需增加工具，而不是预设大量角色。
5. **Godot-first, engine-neutral contracts / Godot 优先、契约保持引擎中立**：执行器聚焦 Godot，task、event 和 report contract 尽量不绑定引擎内部格式。

## Golden Demo Contract / 黄金 Demo 契约

`Starfall Protocol / 星坠协议` is the quality reference for generated games. It is deliberately small enough to run in one benchmark task, but wide enough to expose the systems an Agent must coordinate:

`Starfall Protocol / 星坠协议` 是生成游戏的质量参考。它足够小，可以放进一个 Benchmark 任务；又足够完整，能够暴露 Agent 必须协同的系统：

- **State machine / 状态机**: intro, combat, upgrade, boss, victory are explicit phases.
- **Data-driven content / 数据驱动内容**: enemy and upgrade libraries define balance-facing content separately from the loop.
- **Feedback pass / 反馈层**: projectiles, particles, hit flashes, floating text, HUD bars, and screen shake make state legible.
- **Asset contract / 资产契约**: procedural visuals and runtime captures are recorded in `assets/manifest.json`.
- **Playtest evidence / Playtest 证据**: the external harness drives inputs and checks six events without reading private benchmark code.
- **Repair loop / 修复闭环**: every failed assertion points to a named event and field, so an Agent can patch the smallest responsible system.

The target is not to imitate a commercial game's code or art. The target is to reproduce the underlying engineering properties: a readable loop, authored feedback, inspectable state, and evidence that survives a clean rerun.

目标不是模仿商业游戏的代码或美术，而是复现底层工程能力：清晰的玩法循环、经过设计的反馈、可检查的状态，以及在干净环境中重复通过的证据。

## Current Runtime Flow / 当前运行流程

```text
Task JSON
   |
   +-- candidate project / 候选工程
   +-- benchmark harness / benchmark harness
   +-- assertions / 断言
   |
   v
Temporary project copy / 临时工程副本
   |
   +-- Godot headless import check / Godot headless 导入检查
   +-- external harness injection / 外部 harness 注入
   +-- interaction and state events / 交互与状态事件
   |
   v
Rule evaluator -> JSON report / 规则评测器 -> JSON 报告
```

## Evaluation Surfaces / 评测分层

GamePhanes separates an inspectable public contract from evaluation material that must remain private to preserve benchmark integrity.

GamePhanes 将可检查的公开契约与必须保密的评测材料分开，以维持 Benchmark 的有效性：

```text
Public contract / 公开契约
  Task schema + local runner + example projects + reference harnesses
  任务格式 + 本地 Runner + 示例工程 + 参考 Harness
                         |
                         v
Production evaluation / 生产评测
  Private task variants + hidden harnesses + isolated workers
  私有任务变体 + 隐藏 Harness + 隔离 Worker
                         |
                         v
Rollout dataset / Rollout 数据集
  Actions + patches + runtime evidence + scores + failure labels + costs
  动作 + Patch + 运行证据 + 评分 + 失败标签 + 成本
```

Public tasks make the interface auditable and help agent developers integrate. Hidden variants measure generalization and prevent agents from optimizing against published answers. Both surfaces use versioned task, environment, and evaluator identifiers so scores remain comparable.

公开任务让接口可审计，也便于 Agent 开发者接入；隐藏变体用于衡量泛化能力，并防止 Agent 针对公开答案优化。两类评测都使用版本化的任务、环境和评测器标识，使分数保持可比较。

## Asset Layer / 资产层

Assets enter the system through a versioned manifest before an Agent can place them in a scene.

资产必须先通过版本化 Manifest 进入系统，Agent 才能把它们放入场景：

```text
AssetSpec -> Manifest -> Resolve -> Normalize -> Import -> Validate
资产需求 -> Manifest -> 解析 -> 标准化 -> 导入 -> 验证
```

The manifest keeps source and license metadata next to the asset identity. Procedural assets may have no files; curated, generated, adapted, and user assets must declare their files and remain inside the manifest directory.

Manifest 将来源与许可证元数据和资产身份放在一起。程序化资产可以没有文件；固定、生成、适配和用户资产必须声明文件，且文件路径不能逃出 Manifest 所在目录。

## Event Protocol / 事件协议

Godot harnesses write one JSON object per line with the `GAMEPHANES_EVENT ` prefix.

Godot harness 每行输出一个 JSON 对象，并使用 `GAMEPHANES_EVENT ` 作为前缀：

```text
GAMEPHANES_EVENT {"type":"player_jumped","velocity_y":-310.0}
```

Engine logs may appear before, after, or between events. The parser only consumes prefixed lines and reports malformed protocol messages separately.

引擎日志可以出现在事件之前、之后或中间。解析器只消费带此前缀的行，并单独报告格式错误的协议消息。

## Agent Integration and Rollouts / Agent 接入与 Rollout

Coding agents use the runner as a runtime feedback oracle. The agent writes or repairs the project; the evaluator probes the resulting game and returns structured evidence. GamePhanes remains agent-agnostic and records the interaction needed for evaluation and post-training.

Coding Agent 将 Runner 作为运行时反馈验证器：Agent 编写或修复工程，评测器探测运行结果并返回结构化证据。GamePhanes 不绑定具体 Agent，并记录评测与后训练所需的交互：

```text
Task -> Inspect -> Edit -> Build/Run -> Runtime feedback -> Diagnose
  ^                                                    |
  +---------------------- Repair ----------------------+
```

The harness inputs are not gameplay actions generated by the coding agent. They are controlled probes that make the candidate implementation reveal behavior. A coding-agent rollout therefore differs from a gameplay RL trajectory:

Harness 输入不是 Coding Agent 生成的游戏操作，而是让候选实现暴露行为的受控探针。因此，Coding Agent rollout 与 gameplay RL trajectory 不同：

- **Coding-agent rollout / Coding Agent 轨迹**: tool calls, file patches, build results, runtime observations, failed assertions, diagnosis, and repair attempts.
- **Gameplay trajectory / 游戏操作轨迹**: player actions, game states, policy decisions, and rewards while controlling a character.

GamePhanes targets the first type. Game state is valuable because it is feedback for code generation, not because the agent must learn a better player policy.

GamePhanes 的目标是第一类。游戏状态之所以有价值，是因为它是代码生成的反馈，而不是因为 Agent 要学会更好的玩家策略。

Each iteration will retain / 每轮都会保留：

- changed artifacts / 发生变化的工程产物；
- build and runtime logs / 构建与运行时日志；
- assertion failures / 断言失败信息；
- screenshots and state snapshots / 截图与状态快照；
- token, time and tool-call costs / Token、时间和工具调用成本。

This versioned record can become Agent context, benchmark evidence, supervised repair data, or a post-training/RL trajectory for coding-agent repair. It should not be described as a gameplay-control trajectory.

这些版本化记录既可以作为 Agent 上下文和 Benchmark 证据，也可以成为 Coding Agent 修复的监督数据或后训练/RL 轨迹，不应描述成游戏操作轨迹。

## Benchmark Integrity / Benchmark 完整性

Candidate projects and benchmark-owned harnesses must remain separate.

候选工程与 benchmark 管理的 harness 必须保持分离。生产级 runner 还应：

- mount the candidate project read-only / 以只读方式挂载候选工程；
- copy only declared artifacts into an isolated worker / 只复制声明过的产物到隔离 worker；
- disable outbound network access / 禁止出站网络访问；
- enforce CPU, memory, process, and disk quotas / 限制 CPU、内存、进程和磁盘配额；
- sign task definitions and harness versions / 对任务定义和 harness 版本签名；
- store raw logs and evaluator versions with every report / 在每份报告中保存原始日志和评测器版本。

The local runner intentionally does not claim these container-level guarantees yet.

当前本地 runner 有意不宣称具备上述容器级安全保证。

## Showcase Matrix / 展示矩阵

The first public suite deliberately varies genre and rendering mode while keeping the same task, harness, event, and report contracts.

首批公开展示有意覆盖不同游戏类型和渲染模式，同时复用同一套任务、Harness、事件和报告契约。

| Project / 工程 | Core system / 核心系统 | Evidence / 验证证据 |
|---|---|---|
| Neon Relay | 2D movement and collection / 2D 移动与收集 | jump velocity, shards, distance / 跳跃速度、碎片、距离 |
| Last Signal | targeting and combat / 索敌与战斗 | shots, defeated threats / 射击、消灭威胁 |
| Gravity Lab | stateful puzzle / 状态解谜 | polarity, core height, exit / 极性、核心高度、出口 |
| Tiny Bastion | resources and waves / 资源与波次 | towers, kills, base health / 防御塔、击杀、基地生命 |
| Rift Arena | procedural 3D combat / 程序化 3D 战斗 | hits, enemy health, stability / 命中、敌人生命、稳定度 |
| Starfall Protocol | golden 2D action vertical slice / 黄金 2D 动作切片 | encounter, upgrade, boss, victory / 敌群、升级、Boss、胜利 |
