# Game Terminal-Bench

> **SWE-bench for interactive software.**
>
> A Harbor-compatible benchmark for coding agents that build, debug, and repair games and other interactive applications through terminal workspaces and executable runtime feedback.

[简体中文](README.zh-CN.md)

[Homepage](https://gamephanes.github.io/) · [Benchmark](https://gamephanes.github.io/bench.html) · [Task Registry](https://gamephanes.github.io/registry/) · [Issues](https://github.com/GamePhanes/GamePhanes/issues) · [Discussions](https://github.com/GamePhanes/GamePhanes/discussions)

## What Is Game Terminal-Bench?

Terminal benchmarks usually stop at files, commands, and exit codes. Interactive software adds a second truth: the project must import, launch, accept controlled input, change runtime state, and produce the intended behavior. Game Terminal-Bench evaluates coding agents on that complete loop.

```text
instruction -> inspect -> edit -> run -> observe -> diagnose -> repair -> verify
```

The benchmark target is a coding agent, not a player bot. Harness inputs are evaluator-controlled probes used to obtain evidence about the submitted code. The agent is judged on engineering work: code changes, debugging, runtime behavior, and regression resistance.

This is an independent dataset built on the Harbor task contract. It is compatible with Harbor execution, but it is not Terminal-Bench 2.0, TB-Science, or a leaderboard subset of either dataset.

## Current Task

The first complete Harbor task is [`repair-neon-relay-jump`](benchmark/harbor-tasks/repair-neon-relay-jump/). It asks an agent to repair a broken phase jump in a Godot platformer while preserving shard collection and relay completion.

| Task | Category | Acceptance boundary |
|---|---|---|
| `repair-neon-relay-jump` | bug-fix · movement · runtime | Project launches, jump produces upward velocity, three shards remain collectible, and the relay can still be completed. |

The public site contains six playable reference projects. The planned production slate is 20 tasks across gameplay, engine/runtime, UI/interaction, content/systems, and delivery/quality. Planned tasks are not measured scores until they have a versioned package and a reproducible evaluation run.

## Harbor Task Format

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

### File Responsibilities

- `task.toml`: Harbor schema version, task name, description, artifacts, metadata, timeouts, and resource limits. Keep it declarative and reproducible.
- `instruction.md`: the user-facing task. State the starting condition, target behavior, constraints, and acceptance criteria. Do not include the solution or hints that reveal the exact patch.
- `environment/Dockerfile`: pin the engine, OS packages, project dependencies, and runtime entrypoint. A clean build must produce the same environment.
- `environment/project/`: the broken or incomplete starter project. It must be runnable enough for an agent to inspect and reproduce the problem.
- `tests/`: benchmark-owned verification. Tests must exercise the project from outside the candidate code and check both the requested change and important preserved behavior.
- `solution/solve.sh`: an executable oracle used by maintainers to prove the task is solvable. It is not copied into the agent workspace during evaluation.

The task package must not depend on a contributor's local absolute path, private package registry, undisclosed asset, network download at evaluation time, or an interactive GUI step.

## Minimal `task.toml`

Use Harbor's current schema and keep metadata explicit:

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

## How To Run

### Validate the repository

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

## How To Submit A Task

1. Fork this repository and create a branch for one task.
2. Add one directory under `benchmark/harbor-tasks/<task-name>/` using the format above.
3. Make `tests/test.sh` and `solution/solve.sh` executable.
4. Run `npm test`, the task verifier, a clean Docker build, and the oracle solution from a clean checkout.
5. Open a pull request. Link the issue or task proposal and explain the runtime behavior being evaluated.

### Pull Request Checklist

- [ ] `task.toml` uses a supported Harbor schema and a unique task name.
- [ ] `instruction.md` describes outcomes, constraints, and acceptance criteria without exposing the solution.
- [ ] The starter project contains a real bug, missing feature, or regression that an agent can investigate from the workspace.
- [ ] `tests/` is independent from the candidate implementation and checks required behavior plus meaningful regression boundaries.
- [ ] The task is deterministic or documents every controlled source of randomness.
- [ ] Docker build and runtime test work without network access after dependencies are prepared.
- [ ] `solution/solve.sh` solves the task from the starter state and exits non-zero on failure.
- [ ] No secrets, private assets, copyrighted game content, or machine-specific paths are included.
- [ ] The PR states estimated expert time, difficulty, category, and known limitations.

## Task Quality Bar

A strong task has a narrow user-visible objective, a believable engineering failure, enough surface area for inspection and repair, deterministic evidence, and a regression boundary. It should reward understanding the project rather than string-matching a known patch.

Reviewers will reject tasks that can be passed by deleting the gameplay loop, replacing the project with a stub, weakening the verifier, relying on screenshots alone, or hard-coding the probe sequence.

## Public And Private Layers

| Public | Private or service layer |
|---|---|
| Harbor task schema and examples | Sealed task variants |
| Starter projects and public demos | Hidden evaluators and anti-shortcut checks |
| Reference tests and scoring principles | Production rollout traces and failure labels |
| Local runner and reproducible reports | Customer-specific environments and private data |

The public repository is the inspectable trust layer. Private evaluation content and collected agent trajectories are not published as benchmark answers.

## Showcase

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
