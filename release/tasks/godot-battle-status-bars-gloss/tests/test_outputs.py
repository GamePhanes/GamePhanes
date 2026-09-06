import json, os, re, subprocess
from pathlib import Path
import yaml

ROOT = Path(os.environ.get("TASK_OUTPUT_ROOT", "/app"))
RUBRIC = Path(os.environ.get("RUBRIC_PATH", str(ROOT / "rubric.yaml")))

def read(path):
    p = ROOT / str(path)
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""

def test_rubric():
    spec = yaml.safe_load(RUBRIC.read_text(encoding="utf-8")) or {}
    checks = spec.get("checks", [])
    assert checks, "rubric has no checks"
    failures = []
    for c in checks:
        kind, path = c.get("type"), c.get("path", "")
        p = ROOT / path
        ok = p.is_file() if kind == "file_exists" else False
        text = read(path)
        if kind == "file_contains": ok = bool(c.get("expected")) and str(c["expected"]) in text
        if kind == "file_regex": ok = bool(re.search(str(c.get("pattern", c.get("expected", ""))), text, re.M))
        if kind == "godot_probe":
            probe_path = ROOT / ".forge_verifier_probe.gd"
            try:
                probe_path.write_text(str(c.get("probe_script", "")) + "\n", encoding="utf-8")
                proc = subprocess.run(f"godot --headless --path . --script {probe_path.name}", shell=True, cwd=ROOT, capture_output=True, text=True, timeout=120)
                output = (proc.stdout or "") + (proc.stderr or "")
                expected = str(c.get("expected", ""))
                ok = proc.returncode == 0 and (expected in output if expected else True)
            finally:
                probe_path.unlink(missing_ok=True)
        if kind == "command":
            proc = subprocess.run(str(c.get("command", "")), shell=True, cwd=ROOT, capture_output=True, text=True, timeout=120)
            output = (proc.stdout or "") + (proc.stderr or "")
            expected = str(c.get("expected", ""))
            ok = proc.returncode == 0 and (expected in output if expected and expected != "exit_code=0" else True)
        if kind in ("json_field", "yaml_field"):
            try:
                value = json.loads(text) if kind == "json_field" else yaml.safe_load(text)
                for part in str(c.get("field", "")).split("."): value = value[part]
                ok = value == c.get("expected")
            except Exception: ok = False
        if not ok: failures.append(c.get("id", "check"))
    assert not failures, "failed checks: " + ", ".join(failures)
