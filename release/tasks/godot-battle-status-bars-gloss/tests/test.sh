#!/bin/sh
set -u

MODE="${1:-run}"
if [ "$MODE" = "verify" ]; then
    WORKSPACE="${3:?verify requires a workspace path}"
    RESULT_PATH="${4:?verify requires a result path}"
else
    WORKSPACE="${TASK_OUTPUT_ROOT:-/workspace/desktop}"
    RESULT_PATH="${RESULT_PATH:-/logs/verifier/result.json}"
fi

RESULT_DIR=$(dirname "$RESULT_PATH")
mkdir -p "$RESULT_DIR"
PARSE_LOG="$RESULT_DIR/godot-import.log"
RUNTIME_LOG="$RESULT_DIR/godot-runtime.log"
PROBE="$WORKSPACE/.gameforgebench_status_probe.gd"

project_ok=false
scene_ok=false
protected_ok=false
runtime_ok=false
visual_ok=false

cleanup() {
    rm -f "$PROBE"
}
trap cleanup EXIT INT TERM

if [ -f "$WORKSPACE/project.godot" ] && [ -f "$WORKSPACE/Main.tscn" ] && [ -f "$WORKSPACE/scripts/status_bars.gd" ]; then
    if timeout 120 godot --headless --path "$WORKSPACE" --editor --quit >"$PARSE_LOG" 2>&1; then
        if ! grep -Eq 'SCRIPT ERROR|Parse Error|Failed to load script|Cannot open file' "$PARSE_LOG"; then
            project_ok=true
            printf '%s\n' GODOT_PROJECT_PARSE_OK >>"$PARSE_LOG"
        fi
    fi
fi

if [ "$(grep -Fc '[node name="HpFill" type="TextureRect" parent="HpBar"]' "$WORKSPACE/Main.tscn" 2>/dev/null || true)" -eq 1 ] &&
   [ "$(grep -Fc '[node name="MpFill" type="TextureRect" parent="MpBar"]' "$WORKSPACE/Main.tscn" 2>/dev/null || true)" -eq 1 ] &&
   grep -Fq 'res://assets/ui/battle/battle_status_fill_hp.svg' "$WORKSPACE/Main.tscn" &&
   grep -Fq 'res://assets/ui/battle/battle_status_fill_mp.svg' "$WORKSPACE/Main.tscn"; then
    scene_ok=true
fi

if cmp -s /grader/baseline/project.godot "$WORKSPACE/project.godot" &&
   cmp -s /grader/baseline/assets/ui/battle/battle_status_fill_hp.svg "$WORKSPACE/assets/ui/battle/battle_status_fill_hp.svg" &&
   cmp -s /grader/baseline/assets/ui/battle/battle_status_fill_mp.svg "$WORKSPACE/assets/ui/battle/battle_status_fill_mp.svg"; then
    protected_ok=true
fi

CURRENT_FILES=$(mktemp /tmp/gameforgebench-godot-files.XXXXXX)
(
    cd "$WORKSPACE" || exit 1
    find . -type f \
        ! -path './.godot/*' \
        ! -name '*.import' \
        ! -name '*.uid' \
        ! -name 'trajectory.jsonl' \
        ! -name 'agent_response.json' \
        ! -name '.gameforgebench_status_probe.gd' \
        -print | sed 's#^./##' | LC_ALL=C sort
) >"$CURRENT_FILES"
if ! cmp -s /grader/baseline/files.txt "$CURRENT_FILES"; then
    protected_ok=false
fi
rm -f "$CURRENT_FILES"

if [ "$project_ok" = true ] && [ "$scene_ok" = true ]; then
    cp /grader/tests/status_bars_probe.gd "$PROBE"
    if timeout 120 godot --headless --path "$WORKSPACE" --script "$PROBE" >"$RUNTIME_LOG" 2>&1; then
        if grep -Fq GAMEFORGEBENCH_GODOT_STATUS_RUNTIME_OK "$RUNTIME_LOG"; then
            runtime_ok=true
        fi
        if grep -Fq GAMEFORGEBENCH_GODOT_GLOSS_VISUAL_OK "$RUNTIME_LOG"; then
            visual_ok=true
        fi
    fi
fi

PASSED=0
[ "$project_ok" = true ] && PASSED=$((PASSED + 1))
[ "$scene_ok" = true ] && PASSED=$((PASSED + 1))
[ "$protected_ok" = true ] && PASSED=$((PASSED + 1))
[ "$runtime_ok" = true ] && PASSED=$((PASSED + 1))
[ "$visual_ok" = true ] && PASSED=$((PASSED + 1))

if [ "$PASSED" -eq 5 ]; then
    REWARD=1
    SCORE=1.0
else
    REWARD=0
    case "$PASSED" in
        0) SCORE=0.0 ;;
        1) SCORE=0.2 ;;
        2) SCORE=0.4 ;;
        3) SCORE=0.6 ;;
        *) SCORE=0.8 ;;
    esac
fi

cat >"$RESULT_PATH" <<EOF
{"status":"evaluated","reward":$REWARD,"score":$SCORE,"passed":$PASSED,"total":5,"checks":[{"id":"godot_project_parse","passed":$project_ok,"detail":"Godot 4.6.1 import and parse","type":"command","path":"project.godot"},{"id":"glossy_scene_binding","passed":$scene_ok,"detail":"TextureRect nodes and canonical texture bindings","type":"file_contains","path":"Main.tscn"},{"id":"protected_workspace","passed":$protected_ok,"detail":"image-owned project/assets/provenance digest and allowed file set","type":"integrity_probe","path":"Main.tscn"},{"id":"godot_status_runtime","passed":$runtime_ok,"detail":"native layout, ratio, clamp, idempotence and lifecycle sequence","type":"godot_probe","path":"Main.tscn"},{"id":"godot_gloss_visual","passed":$visual_ok,"detail":"native texture dimensions, pixel highlight/shadow and chroma","type":"godot_probe","path":"Main.tscn"}]}
EOF
printf '%s\n' "$REWARD" >"$RESULT_DIR/reward.txt"
exit 0
