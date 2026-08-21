# GameBuddy Architecture

## Design Principles

1. **Execution before appearance**: 编译、启动和功能行为优先于视觉质量评分。
2. **Deterministic before subjective**: 能用状态断言验证的需求不交给 LLM Judge。
3. **Evidence before claims**: Agent 必须通过日志、事件、截图或状态证明功能工作。
4. **One agent, structured tools first**: 首版保持单一控制循环，按需要增加工具，而不是预设大量角色。
5. **Godot-first, engine-neutral contracts**: 执行器聚焦 Godot，task、event 和 report contract 尽量不绑定引擎内部格式。

## Current Runtime Flow

```text
Task JSON
   |
   +-- candidate project
   +-- benchmark harness
   +-- assertions
   |
   v
Temporary project copy
   |
   +-- Godot headless import check
   +-- external harness injection
   +-- interaction and state events
   |
   v
Rule evaluator -> JSON report
```

## Event Protocol

Godot harnesses write one JSON object per line with the `GAMEBUDDY_EVENT ` prefix:

```text
GAMEBUDDY_EVENT {"type":"player_jumped","velocity_y":-310.0}
```

Engine logs may appear before, after, or between events. The parser only consumes prefixed lines and reports malformed protocol messages separately.

## Planned Agent Loop

The next layer will use the existing runner as an oracle:

```text
GameSpec -> Task Graph -> Patch -> Validate -> Playtest -> Diagnose
                              ^                         |
                              +-------- Repair --------+
```

Each repair iteration will retain:

- changed artifacts;
- build and runtime logs;
- assertion failures;
- screenshots and state snapshots;
- token, time and tool-call costs.

This record becomes both Agent context and benchmark evidence.

## Benchmark Integrity

Candidate projects and benchmark-owned harnesses must remain separate. A production runner should additionally:

- mount the candidate project read-only;
- copy only declared artifacts into an isolated worker;
- disable outbound network access;
- enforce CPU, memory, process and disk quotas;
- sign task definitions and harness versions;
- store raw logs and evaluator versions with every report.

The local runner intentionally does not claim these container-level guarantees yet.
