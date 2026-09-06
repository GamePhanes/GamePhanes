#!/usr/bin/env python3
import json
import sys
from pathlib import Path


PREFIX = "GAMEPHANES_EVENT "


def load_events(log_path: Path):
    events = []
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith(PREFIX):
            events.append(json.loads(line[len(PREFIX):]))
    return events


def require(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def main() -> int:
    log_path = Path(sys.argv[1])
    process_status = int(sys.argv[2])
    events = load_events(log_path)
    by_type = {event["type"]: event for event in events}

    require(process_status == 0, f"Godot process exited with status {process_status}")
    require("game_ready" in by_type, "missing game_ready event")
    require(by_type.get("player_moved", {}).get("delta_x", 0) > 35, "runner did not move far enough")
    require(by_type.get("player_jumped", {}).get("velocity_y", 0) < 0, "jump did not produce upward velocity")
    require(by_type.get("relay_finished", {}).get("shards") == 3, "relay did not finish with three shards")
    require(by_type.get("relay_finished", {}).get("distance", 0) > 700, "runner did not reach the relay")
    require(by_type.get("playtest_complete", {}).get("success") is True, "playtest did not report success")

    print("repair-neon-relay-jump: all runtime assertions passed")
    Path("/logs/verifier/reward.txt").write_text("1\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, json.JSONDecodeError) as error:
        print(f"repair-neon-relay-jump: verification failed: {error}")
        Path("/logs/verifier/reward.txt").write_text("0\n", encoding="utf-8")
        raise SystemExit(1)
