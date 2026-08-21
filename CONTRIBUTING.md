# Contributing to GameBuddy

GameBuddy is currently building its execution and evaluation foundation. Contributions are most useful when they improve reproducibility, observable game behavior, or benchmark integrity.

## Local Setup

Requirements:

- Node.js 22 or newer;
- Godot 4.x for end-to-end playtests.

```powershell
npm test
npm run validate
npm run site
```

Set `GAMEBUDDY_GODOT` or pass `--godot PATH` before running the demo benchmark.

## Pull Requests

Keep changes focused and include evidence appropriate to the change:

- unit tests for contracts, parsers, and evaluators;
- a deterministic harness assertion for gameplay behavior;
- desktop and mobile checks for homepage changes;
- raw failure logs when fixing Godot runtime behavior.

New benchmark tasks should keep candidate projects separate from benchmark-owned harnesses and must not rely solely on an LLM judge.

## Reporting Issues

Include the operating system, Node version, Godot version, command used, and the smallest relevant log excerpt. Never include tokens or account credentials.
