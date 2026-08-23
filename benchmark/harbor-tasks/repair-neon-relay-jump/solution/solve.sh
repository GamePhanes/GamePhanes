#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

project = Path("/app/scripts/main.gd")
source = project.read_text(encoding="utf-8")
broken = (
    'if action_just_pressed("jump") and is_on_ground():\n'
    '\t\tvelocity_y = 0.0\n'
    '\tvelocity_y += GRAVITY * delta'
)
fixed = (
    'if action_just_pressed("jump") and is_on_ground():\n'
    '\t\tvelocity_y = -JUMP_SPEED\n'
    '\tvelocity_y += GRAVITY * delta'
)

if broken not in source:
    raise SystemExit("expected broken jump implementation was not found")
project.write_text(source.replace(broken, fixed, 1), encoding="utf-8")
PY
