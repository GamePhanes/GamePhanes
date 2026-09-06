#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

simulation = Path("/app/scripts/simulation.gd")
source = simulation.read_text(encoding="utf-8")
source = source.replace('"players": players.duplicate(),', '"players": players.duplicate(true),')
source = source.replace('"projectiles": projectiles.duplicate(),', '"projectiles": projectiles.duplicate(true),')
source = source.replace('"pickups": pickups.duplicate(),', '"pickups": pickups.duplicate(true),')
source = source.replace('"score": score.duplicate(),\n\t}', '"score": score.duplicate(true),\n\t\t"rng_state": rng_state,\n\t\t"next_entity_id": next_entity_id,\n\t}')
source = source.replace('players = snapshot.players.duplicate()', 'players = snapshot.players.duplicate(true)')
source = source.replace('projectiles.assign(snapshot.projectiles.duplicate())', 'projectiles.assign(snapshot.projectiles.duplicate(true))')
source = source.replace('pickups = snapshot.pickups.duplicate()', 'pickups = snapshot.pickups.duplicate(true)')
source = source.replace('score = snapshot.score.duplicate()\n', 'score = snapshot.score.duplicate(true)\n\trng_state = int(snapshot.rng_state)\n\tnext_entity_id = int(snapshot.next_entity_id)\n')
simulation.write_text(source, encoding="utf-8")

session = Path("/app/scripts/rollback_session.gd")
source = session.read_text(encoding="utf-8")
source = source.replace(
    '\tseen_packet_ids[packet_id] = true\n\tvar frame := _frame(packet_tick)',
    '\tif packet_tick < _oldest_retained_tick():\n\t\treturn false\n\n\tvar frame := _frame(packet_tick)',
)
source = source.replace(
    'if not existing.is_empty() and sequence <= simulation.tick:',
    'if not existing.is_empty() and sequence <= int(existing.seq):',
)
source = source.replace(
    '\tframe[player_id] = {\n\t\t"seq": sequence,',
    '\tseen_packet_ids[packet_id] = true\n\tframe[player_id] = {\n\t\t"seq": sequence,',
)
source = source.replace(
    '\n\tif packet_tick < _oldest_retained_tick():\n\t\treturn false\n\tif packet_tick < simulation.tick:',
    '\n\tif packet_tick < simulation.tick:',
)
source = source.replace('_discard_snapshots_from(frame_tick + 1)', '_discard_snapshots_from(frame_tick)')
source = source.replace('while simulation.tick < target_tick - 1:', 'while simulation.tick < target_tick:')
session.write_text(source, encoding="utf-8")
PY
