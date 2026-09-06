# GameForgeBench

> **Terminal-Bench for interactive game-engine development agents.**
>
> A Harbor-compatible benchmark for coding agents that build, debug, and repair games through terminal workspaces and executable runtime feedback.

[Homepage](https://gamephanes.github.io/) · [Benchmark](https://gamephanes.github.io/bench.html) · [Task Registry](https://gamephanes.github.io/registry/) · [Issues](https://github.com/GamePhanesStudio/GamePhanes/issues) · [Discussions](https://github.com/GamePhanesStudio/GamePhanes/discussions)

## What Is GameForgeBench?

Terminal benchmarks often stop at files, commands, and exit codes. Interactive software has a second truth: the project must import, launch, accept controlled input, change runtime state, and produce the intended behavior. GameForgeBench evaluates coding agents on that complete loop.

```text
instruction -> inspect -> edit -> run -> observe -> diagnose -> repair -> verify
```

The benchmark target is a coding agent, not a player bot. Evaluator-controlled probes provide runtime evidence; the agent is judged on engineering work, debugging, behavior, and regression resistance.

## Open Release

The release corpus contains **81 completed executable tasks** spanning Godot, Unity, Roblox, Minecraft, Unreal, Web, and generic engine projects. The tasks cover gameplay systems, engine/runtime work, UI and interaction, plugins, persistence, callbacks, build workflows, and delivery quality.

Each task is a self-contained contract with a starter project, a natural-language request, a reproducible environment, protected files, a reference solution, and executable acceptance checks. The public upload includes one representative task so the complete workflow can be inspected without downloading the full corpus.

## Featured Task

| Task | Role | Runtime acceptance boundary |
|---|---|---|
| [`godot-battle-status-bars-gloss`](release/tasks/godot-battle-status-bars-gloss/) | Reference task | Replace flat HP/MP fills with glossy native textures; preserve layout, bounded ratios, and lifecycle behavior. |

The task starts with a compact Godot battle HUD whose HP and MP fills disappear into the background. The requested change sounds visual, but the acceptance boundary is engineering-focused:

- native `TextureRect` nodes and canonical resource bindings;
- fixed 62x6 geometry with unchanged tracks;
- independent HP/MP ratio transitions;
- clamping for negative, over-max, and non-positive values;
- idempotent repeated updates;
- second-instance lifecycle reload;
- measurable texture highlight, shadow, and color contrast.

The directory contains the starter project, instruction, rubric, native probe, Docker verifier, redacted provenance record, and reference solution.

## Task Format

Every contributed task follows the same portable directory shape:

```text
task-name/
├── task.toml
├── instruction.md
├── environment/
│   ├── Dockerfile
│   └── project files
├── tests/
│   ├── test.sh
│   └── runtime probes and fixtures
└── solution/
    └── reference implementation
```

### File Responsibilities

- `task.toml`: task metadata, schema version, timeouts, and resource limits.
- `instruction.md`: starting condition, requested outcome, constraints, and acceptance criteria without revealing the patch.
- `environment/`: pinned engine, operating system packages, project dependencies, and clean runtime entrypoint.
- `tests/`: benchmark-owned verification executed outside the candidate implementation.
- `solution/`: maintainer reference implementation used to prove solvability; never shown to the agent.

Tasks must not depend on a contributor's local absolute path, private package registry, undisclosed asset, network download at evaluation time, or interactive GUI step.

## How To Run The Example

Requires Godot 4.6.1 for local inspection and Docker for the hermetic verifier.

```bash
cd release/tasks/godot-battle-status-bars-gloss
godot --headless --path . --editor --quit
```

The task README contains the reference-workspace command and the Docker invocation. The verifier observes the running Godot project and writes a machine-readable result with per-check diagnostics.

## Evaluation Model

GameForgeBench separates four layers of evidence:

1. **Artifact**: required files, schemas, bindings, and protected-workspace integrity.
2. **Engine**: import, parsing, scene loading, and native startup.
3. **Behavior**: ordered events, state transitions, boundaries, persistence, and lifecycle behavior.
4. **Diagnostics**: invariant-level results explaining the outcome.

This separation distinguishes a plausible file edit from a project that actually behaves correctly when the engine runs it.

## Task Quality Bar

A strong task has a narrow user-visible objective, a believable engineering problem, enough surface area for inspection and repair, deterministic evidence, and a meaningful regression boundary. It should reward understanding the project rather than string matching a known patch.

Reviewers reject tasks that can pass by deleting the gameplay loop, replacing the project with a stub, weakening the verifier, hard-coding the probe sequence, or relying on screenshots alone.

## How To Contribute

1. Fork the repository and create a branch for one task.
2. Add a directory under `release/tasks/<task-name>/` using the format above.
3. Make `tests/test.sh` executable and include a reference solution.
4. Run a clean Docker build, the verifier, and the reference solution from a clean checkout.
5. Open a pull request describing the runtime behavior and regression boundary.

## Public Scope

The public repository is the inspectable trust layer: task contracts, starter projects, verifier design, reference examples, and reproducible reports. Private evaluation variants, collected agent trajectories, and service credentials are not published as benchmark answers.

## Contributors

GamePhanesStudio maintains the benchmark, task format, runtime adapters, and evaluation tooling. Contributions are welcome through issues, discussions, and pull requests.

## License

MIT.

## Citation

```bibtex
@software{gameforgebench2026,
  author  = {GamePhanesStudio},
  title   = {GameForgeBench},
  year    = {2026},
  url     = {https://github.com/GamePhanesStudio/GamePhanes},
  license = {MIT}
}
```
