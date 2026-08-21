# GamePhanes Architecture / GamePhanes 架构

## Design Principles / 设计原则

1. **Execution before appearance / 先验证运行，再讨论表现**：Build、启动和功能行为优先于视觉质量评分。
2. **Deterministic before subjective / 先确定性，再主观判断**：能用状态断言验证的需求不交给 LLM Judge。
3. **Evidence before claims / 证据胜过结论**：Agent 必须通过日志、事件、截图或状态证明功能工作。
4. **One agent, structured tools first / 单 Agent，结构化工具优先**：首版保持单一控制循环，按需增加工具，而不是预设大量角色。
5. **Godot-first, engine-neutral contracts / Godot 优先、契约保持引擎中立**：执行器聚焦 Godot，task、event 和 report contract 尽量不绑定引擎内部格式。

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

## Planned Agent Loop / 计划中的 Agent 闭环

The next layer will use the existing runner as an oracle.

下一层 Agent 将把现有 runner 作为行为验证器：

```text
GameSpec -> Task Graph -> Patch -> Validate -> Playtest -> Diagnose
                              ^                         |
                              +-------- Repair --------+
```

Each repair iteration will retain / 每轮修复都会保留：

- changed artifacts / 发生变化的工程产物；
- build and runtime logs / 构建与运行时日志；
- assertion failures / 断言失败信息；
- screenshots and state snapshots / 截图与状态快照；
- token, time and tool-call costs / Token、时间和工具调用成本。

This record becomes both Agent context and benchmark evidence.

这些记录既是 Agent 上下文，也是 benchmark 评测证据。

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
