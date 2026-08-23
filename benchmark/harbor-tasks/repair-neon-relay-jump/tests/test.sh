#!/usr/bin/env bash
set -euo pipefail

mkdir -p /logs/verifier
set +e
timeout --signal=TERM 30s "${GODOT_BIN:-godot}" --headless --path /app --script /tests/harness.gd > /logs/verifier/godot.log 2>&1
status=$?
set -e

python3 /tests/verify_runtime.py /logs/verifier/godot.log "$status"
