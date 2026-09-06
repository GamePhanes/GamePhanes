# Contributing to GamePhanes / 参与 GamePhanes 贡献

GamePhanes is building its execution and evaluation foundation. Contributions are most useful when they improve reproducibility, observable game behavior, or benchmark integrity.

GamePhanes 正在建设执行与评测基础设施。能够提升可复现性、游戏行为可观测性或 benchmark 完整性的贡献最有价值。

## Local Setup / 本地设置

Requirements / 环境要求：

- Node.js 22 or newer / Node.js 22 或更高版本；
- Godot 4.x for end-to-end playtests / Godot 4.x，用于端到端 Playtest。

```powershell
npm test
npm run validate
npm run site
```

Set `GAMEPHANES_GODOT` or pass `--godot PATH` before running the demo benchmark.

运行 demo benchmark 前，请设置 `GAMEPHANES_GODOT` 或传入 `--godot PATH`。

## Pull Requests / Pull Request

Keep changes focused and include appropriate evidence / 保持改动聚焦，并提供与改动匹配的证据：

- unit tests for contracts, parsers, and evaluators / 为契约、解析器和评测器补充单元测试；
- a deterministic harness assertion for gameplay behavior / 为游戏行为提供确定性 harness 断言；
- desktop and mobile checks for homepage changes / 主页改动同时检查桌面和移动端；
- raw failure logs when fixing Godot runtime behavior / 修复 Godot 运行时行为时附上原始失败日志。

New benchmark tasks should keep candidate projects separate from benchmark-owned harnesses and must not rely solely on an LLM judge.

新增 benchmark 任务时，应保持候选工程与 benchmark harness 分离，不能只依赖 LLM Judge。

## Reporting Issues / 提交问题

Include the operating system, Node version, Godot version, command used, and the smallest relevant log excerpt.

请提供操作系统、Node 版本、Godot 版本、执行命令和最小相关日志片段。

Never include tokens, passwords, SSH private keys, or other credentials.

不要提交 Token、密码、SSH 私钥或其他凭据。
