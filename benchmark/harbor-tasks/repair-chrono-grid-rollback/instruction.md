The Godot project in `/app` contains Chrono Grid, a deterministic lockstep arena with late-input rollback.

Ordinary on-time play appears to work, but delayed or corrected input can leave the replayed world different from an equivalent on-time run. Players have reported divergent projectile damage, reused entity IDs, stale branch inputs, and one missing simulation step after reconciliation.

Repair the rollback implementation so that:

- An input received late produces the same canonical state as receiving that input on time.
- A higher-sequence correction replaces the earlier action for the same player and tick, then replays deterministically.
- Duplicate packet IDs are idempotent.
- Snapshots are immutable and restore every authoritative value needed for future simulation.
- Inputs older than retained rollback history are rejected without mutating session state.
- Snapshot history remains bounded during long sessions.
- Existing movement, projectile, pickup, score, and cooldown behavior remains intact.

Do not hard-code the demonstrated packet sequence or final state. The repaired implementation must work for other valid players, actions, packet orders, correction ticks, and rollback windows.

Work only in `/app`. Verify both normal execution and rollback reconciliation before finishing.
