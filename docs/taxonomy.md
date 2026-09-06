# GamePhanes Task Taxonomy / GamePhanes 任务分类

GamePhanes classifies every task on two independent axes. `domain/subdomain` describes where the engineering work happens. `task_type` describes what the Coding Agent must do. Keeping these axes separate makes benchmark slices comparable without confusing a combat task with a bug-fix task.

GamePhanes 使用两个独立维度标注每个任务。`domain/subdomain` 描述工程工作发生在哪个领域，`task_type` 描述 Coding Agent 要完成什么工作。两个维度分开后，可以比较不同 Benchmark 切片，而不会把“战斗系统”和“Bug 修复”混成同一层分类。

## Domain Mix / 领域分布

The numbers below are the target mix for the first 100-task benchmark, not the current number of published tasks.

以下数字是首个 100 题 Benchmark 的目标分布，不是当前已经发布的题量。

| Domain / 领域 | Target / 目标题量 | Subdomains / 子领域 |
|---|---:|---|
| Gameplay Systems / 玩法系统 | 28 | Movement 6, Combat 6, Physics 5, AI & Navigation 5, Progression & Economy 6 |
| Engine & Runtime / 引擎与运行时 | 22 | Scene Lifecycle 6, Engine APIs 5, State & Signals 4, Performance 4, Platform Compatibility 3 |
| UI & Interaction / UI 与交互 | 16 | Input & Controls 5, HUD & Menus 4, Camera & Feedback 4, Accessibility 3 |
| Content & Design / 内容与设计 | 14 | Level Design 4, Procedural Content 3, Asset Integration 3, Narrative & Dialogue 2, Audio Integration 2 |
| Architecture & Data / 架构与数据 | 12 | Scenes & Resources 4, Save & Load 3, Data-driven Systems 3, Modularity & Dependencies 2 |
| Delivery & Quality / 交付与质量 | 8 | Regression Safety 3, Tests & Instrumentation 3, Build & Packaging 2 |

The mix intentionally gives more weight to gameplay systems and engine/runtime integration. These tasks require the Agent to connect code changes to interactive consequences, which is the capability ordinary terminal benchmarks under-measure.

玩法系统和引擎/运行时集成被有意赋予更高权重。这些任务要求 Agent 把代码修改与交互结果连接起来，正是普通 Terminal Benchmark 较难覆盖的能力。

## Task Types / 任务类型

| Task type | Meaning / 含义 |
|---|---|
| `bug_fix` | Repair a localized functional defect / 修复局部功能缺陷 |
| `feature_implementation` | Add a specified mechanic or product feature / 增加指定机制或产品功能 |
| `runtime_debugging` | Diagnose behavior that compiles but fails at runtime / 诊断可编译但运行行为错误的问题 |
| `interaction_repair` | Fix input, UI, camera, feedback, or control flow / 修复输入、UI、镜头、反馈或操作流程 |
| `regression_repair` | Restore behavior without breaking existing assertions / 在不破坏已有断言的前提下恢复行为 |
| `design_completion` | Turn a design brief into a complete playable slice / 将设计需求落成完整可玩切片 |
| `performance_optimization` | Improve runtime performance under a measured budget / 在量化预算下优化运行性能 |
| `build_delivery` | Repair import, packaging, export, or deployment / 修复导入、打包、导出或部署 |
| `reference_environment` | Public environment used to prove the evaluation contract / 用于证明评测契约的公开参考环境 |

## Task Contract / 任务契约

```json
{
  "taxonomy": {
    "domain": "engine_runtime",
    "subdomain": "state_signals",
    "task_type": "bug_fix"
  }
}
```

The canonical keys and target mix live in `src/core/taxonomy.js`. Task validation rejects unknown domains, subdomains assigned to the wrong domain, and unsupported task types.

分类键和目标分布的唯一事实来源是 `src/core/taxonomy.js`。任务校验会拒绝未知领域、归属错误的子领域和不支持的任务类型。
