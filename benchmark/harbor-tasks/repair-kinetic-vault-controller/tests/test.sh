#!/usr/bin/env bash
set -euo pipefail

mkdir -p /logs/verifier
printf '0\n' > /logs/verifier/reward.txt
set +e
timeout --signal=TERM 90s "${GODOT_BIN:-godot}" --headless --path /app --script /tests/harness.gd > /logs/verifier/godot.log 2>&1
status=$?
set -e

cat /logs/verifier/godot.log
if [[ $status -ne 0 ]]; then
  echo "repair-kinetic-vault-controller: Godot verifier exited with $status" >&2
  exit "$status"
fi
if grep -qE "SCRIPT ERROR|Failed to load script" /logs/verifier/godot.log; then
  echo "repair-kinetic-vault-controller: script compilation or runtime error" >&2
  exit 1
fi
grep -q "KINETIC_VAULT_TESTS_PASSED" /logs/verifier/godot.log
printf '1\n' > /logs/verifier/reward.txt
echo "repair-kinetic-vault-controller: all deterministic controller assertions passed"
