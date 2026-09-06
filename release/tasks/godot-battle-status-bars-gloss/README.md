# Godot Battle Status Bars Gloss

This is the public GameForgeBench sample task. It is a complete, deterministic Godot 4.6.1 repair contract, not a tutorial or a design prompt.

## Task

The starter scene contains a compact battle HUD with 62x6 HP and MP bars. Replace the flat fill controls with the supplied glossy textures while preserving the existing layout and status-ratio behavior. Only `Main.tscn` and `scripts/status_bars.gd` are agent-editable.

The expected behavior is:

- HP and MP use separate native `TextureRect` nodes and canonical texture paths.
- The track nodes remain `ColorRect` controls at their original positions.
- A 50/200 HP and 90/120 MP update produces 25% and 75% widths independently.
- Repeating the same update does not drift the layout.
- Negative values clamp to zero, values above max clamp to max, and a non-positive max is treated as one.
- A second scene instance restores full-width bars and both texture bindings.
- The textures are 124x12 and expose a measurable bright upper highlight, dark lower shadow, and distinct HP/MP chroma.

## Run

```bash
godot --headless --path . --editor --quit
```

The starter is intentionally incomplete. To run the probe against the included reference solution, assemble a clean workspace and overlay only the two allowed solution files:

```bash
reference_dir=$(mktemp -d /tmp/gameforgebench-status-reference.XXXXXX)
mkdir -p "$reference_dir/assets/ui/battle" "$reference_dir/scripts"
cp Main.tscn project.godot "$reference_dir/"
cp assets/ui/battle/*.svg "$reference_dir/assets/ui/battle/"
cp scripts/status_bars.gd "$reference_dir/scripts/"
cp solution/Main.tscn solution/project.godot "$reference_dir/"
cp solution/scripts/status_bars.gd "$reference_dir/scripts/"
godot --headless --path "$reference_dir" --script "$PWD/tests/status_bars_probe.gd"
```

The reference solution prints:

```text
GAMEFORGEBENCH_GODOT_GLOSS_VISUAL_OK
GAMEFORGEBENCH_GODOT_STATUS_RUNTIME_OK
```

The hermetic verifier can be built and run from this directory:

```bash
reference_dir=$(mktemp -d /tmp/gameforgebench-status-reference.XXXXXX)
mkdir -p "$reference_dir/assets/ui/battle" "$reference_dir/scripts"
cp Main.tscn project.godot "$reference_dir/"
cp assets/ui/battle/*.svg "$reference_dir/assets/ui/battle/"
cp scripts/status_bars.gd "$reference_dir/scripts/"
cp solution/Main.tscn solution/project.godot "$reference_dir/"
cp solution/scripts/status_bars.gd "$reference_dir/scripts/"
docker build -f environment/Dockerfile -t gameforgebench-godot-status .
results_dir=$(mktemp -d /tmp/gameforgebench-status-results.XXXXXX)
docker run --rm -v "$reference_dir:/workspace/desktop" -v "$results_dir:/logs" gameforgebench-godot-status
cat "$results_dir/verifier/result.json"
```

## Bundle Map

| Path | Role |
| --- | --- |
| `instruction.md` | Agent-facing task request and source-intent anchor |
| `Main.tscn`, `scripts/status_bars.gd` | Starter workspace |
| `assets/` | Supplied non-private texture fixtures |
| `tests/status_bars_probe.gd` | Native runtime and texture observations |
| `tests/test.sh` | Container verifier and layered reward output |
| `rubric.yaml` | Five checks and the real-behavior contract |
| `solution/` | Reference implementation; never exposed to the agent |
| `environment/` | Reproducible Godot image definition |
| `provenance/` | Redacted source binding and eligibility record |

The `data/seed_digest.md` file is retained as a read-only provenance input. It is not an agent deliverable and is not needed to understand the public task.

## Verification Scope

The task has five checks: Godot import/parse, glossy scene binding, protected-workspace integrity, native status-bar runtime behavior, and native texture visual properties. The hidden sequence exercises full state, partial independent updates, repeated updates, invalid boundaries, and lifecycle reload. This is the smallest sample in the repository that demonstrates why a game-engine benchmark needs runtime contracts in addition to file-level checks.
