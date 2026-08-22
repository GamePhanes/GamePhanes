# GamePhanes Benchmark Quality Bar / Benchmark 质量门槛

The Registry is not the benchmark. A polished task card can describe a weak task, so GamePhanes separates presentation quality from evaluation quality.

Registry 页面不是 Benchmark 本身。一个漂亮的任务卡片也可能对应一个很弱的任务，因此 GamePhanes 将展示质量与评测质量分开。

## Task Classes / 任务类别

### `reference_environment`

An open, working project used to prove the runtime contract. Its harness and assertions are public. It is not a coding challenge and must not be used as evidence of Agent repair ability.

用于证明运行时契约的公开、正常工程。Harness 和断言公开；它不是 Coding Challenge，不能用来证明 Agent 的修复能力。

### `coding_challenge`

A reproducible starter project with a deliberate defect, missing feature, or regression. The Agent must make a code or project change and pass evaluator-owned checks. `public_development` is allowed for local authoring; production benchmark tasks use `sealed` evaluation.

带有明确缺陷、缺失功能或回归问题的可复现 Starter 工程。Agent 必须修改代码或工程，并通过评测器拥有的检查。`public_development` 只用于本地开发；生产 Benchmark 任务使用 `sealed` 评测。

## Release Gate / 发布门禁

Every production challenge must have all of the following before publication:

每个生产任务在发布前必须具备：

1. A pinned starter revision and deterministic reset / 固定的 Starter 版本与确定性重置；
2. An instruction that states the user-visible outcome without prescribing the patch / 只描述用户可见结果，不指定 Patch 方案的 Instruction；
3. At least one real diagnosis step and one meaningful code or project edit / 至少一个真实诊断步骤和一次有意义的代码或工程修改；
4. Independent build, runtime, behavior, and regression checks / 独立的构建、运行时、行为和回归检查；
5. A private evaluator, private fixtures, or anti-shortcut checks / 私有评测器、私有 Fixture 或反捷径检查；
6. A clean-run report plus at least one failed and one successful author trajectory / 一份干净运行报告，以及至少一条失败和一条成功的作者轨迹；
7. Human review for ambiguity, accidental shortcuts, determinism, and difficulty / 人工审查歧义、意外捷径、确定性与难度。

## What We Publish / 我们公开什么

Public pages expose the task ID, version, taxonomy, difficulty, high-level instruction, project evidence, and usage contract. They do not expose sealed starter contents, hidden fixtures, evaluator source, expected patch text, or benchmark answer artifacts.

公开页面展示任务 ID、版本、分类、难度、高层 Instruction、工程证据和使用契约；不公开 sealed Starter 内容、隐藏 Fixture、评测器源码、预期 Patch 文本或 Benchmark 答案产物。

The current seven showcase entries are `reference_environment` tasks. The first repair task is a public development specimen so the authoring loop can be inspected; it is not counted as a sealed benchmark score.

当前七个 Showcase 条目都是 `reference_environment`。第一个修复任务是公开开发样本，用于检查出题流程；它不计入 sealed Benchmark 得分。
