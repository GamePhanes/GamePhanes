# GamePhanes Open-Core Boundary / GamePhanes 开源边界

GamePhanes uses an open-core model: the integration and trust layer is public, while benchmark secrecy and production data remain private.

GamePhanes 采用 Open Core 模式：接入与可信执行层公开，评测保密性和生产数据保持私有。

## Public Now / 当前开源

The current public repository includes:

- CLI, SDK, local runner, and engine discovery / CLI、SDK、本地 Runner 与引擎探测；
- task, report, and event contracts / Task、Report 与 Event 契约；
- Godot execution, reset, input, logging, and state-evidence interfaces / Godot 执行、重置、输入、日志与状态证据接口；
- reference harnesses and deterministic assertion primitives / 参考 Harness 与确定性断言原语；
- original or redistributable example projects and public demo tasks / 原创或可再分发的示例工程与公开 Demo 任务；
- deterministic scoring reports and reproducible validation commands / 确定性评分报告与可复现验证命令。

Public tasks exist for integration, debugging, research, and independent verification. Their harnesses are intentionally visible and must not be treated as hidden evaluation.

公开任务用于接入、调试、研究和独立复现。其 Harness 有意公开，不能被当作隐藏评测。

## Public When Introduced / 推出时保持开源

The following interfaces are not all implemented in `v0.1`, but will remain public when introduced:

以下接口并未全部在 `v0.1` 中实现，但推出时仍将保持开源：

- rollout schemas and sanitized rollout examples / Rollout Schema 与脱敏 Rollout 示例；
- agent adapters and submission interfaces / Agent Adapter 与提交接口；
- benchmark versioning, baseline methodology, and score aggregation rules / Benchmark 版本规则、Baseline 方法与分数聚合规则；
- generic worker manifests and reproducibility tooling that contain no private tasks / 不包含私有任务的通用 Worker Manifest 与复现工具。

## Private / 闭源

The production layer may include:

- private task pools, task variants, and customer-owned projects / 私有任务池、任务变体与客户项目；
- hidden harnesses, test cases, seeds, evaluator weights, and reference solutions / 隐藏 Harness、测试用例、随机种子、评测权重与参考解；
- task generation, mutation, calibration, contamination, and anti-overfitting systems / 任务生成、变异、难度校准、污染检测与抗过拟合系统；
- successful, failed, and repaired rollouts with tool calls, patches, evidence, costs, and failure labels / 包含工具调用、Patch、证据、成本和失败标签的成功、失败与修复 Rollout；
- hosted workers, isolation, scheduling, access control, and customer reporting / 托管 Worker、隔离、调度、访问控制与客户报告。

Private benchmark material and production rollouts must never be committed to the public repository, public CI artifacts, or public container layers.

私有评测材料与生产 Rollout 不得进入公开仓库、公开 CI Artifact 或公开容器层。

## Trust Contract / 可信原则

GamePhanes keeps evaluation understandable without publishing the exam answers:

1. Task, evidence, report, and version contracts are public / 任务、证据、报告与版本契约公开；
2. Scoring dimensions and aggregation principles are public / 评分维度与聚合原则公开；
3. Hidden task content and evaluator implementations remain private / 隐藏任务内容与评测实现私有；
4. Every production score identifies task, environment, and evaluator versions / 每个生产评分都标识任务、环境与评测器版本；
5. Public demos are reproducible examples, not claims about private benchmark performance / 公开 Demo 是可复现实例，不代表私有 Benchmark 成绩。

## Product Surfaces / 产品形态

- **GamePhanes Eval**: hidden evaluation, regression suites, and private leaderboards / 隐藏评测、回归测试集与私有排行榜；
- **GamePhanes Environments**: executable Godot tasks and customer-specific environments / 可执行 Godot 任务与客户定制环境；
- **GamePhanes Rollouts**: versioned success, failure, and repair trajectories for post-training / 用于后训练的版本化成功、失败与修复轨迹。

The public `v0.1` release currently implements the local deterministic evaluation foundation. Hosted hidden evaluation and production rollout datasets are product direction, not capabilities claimed by this release.

公开 `v0.1` 当前实现的是本地确定性评测基础。托管隐藏评测和生产 Rollout 数据集属于产品方向，不是本版本已经交付的能力。
