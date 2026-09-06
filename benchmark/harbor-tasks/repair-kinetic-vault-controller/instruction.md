The Godot project in `/app` contains Kinetic Vault, a deterministic fixed-tick
platformer simulation used by gameplay code, replays, and server-side validation.

The current character controller looks plausible at low speed, but production
replays expose tunneling, incorrect one-way collisions, dropped buffered jumps,
off-by-one coyote jumps, dash direction changes, and moving-platform desync.

Repair the controller so that it obeys the public contract in
`scripts/controller.gd` and `scripts/world.gd`:

- All coordinates and velocities remain integer subpixels and identical runs
  produce identical canonical states.
- Solid rectangles use half-open bounds. Horizontal and vertical movement must
  sweep the complete displacement, so running, falling, dashing, and platform
  carry cannot tunnel through thin solids.
- One-way platforms never block horizontal or upward movement. They only catch
  a downward-moving player whose previous bottom is at or above the platform
  top, and the player must land exactly on that top surface.
- Ground contact, three-tick coyote time, three-tick jump buffering, landing,
  and dash reset must remain correct at their boundary ticks.
- A dash lasts exactly two simulation ticks, keeps the direction chosen when it
  starts, suppresses gravity during those ticks, and cannot be reused until the
  player lands on valid support.
- A player standing on a moving platform is carried by that platform's complete
  displacement before self movement. Carry still collides with the rest of the
  world. If a platform pushes the player into a solid with no valid placement,
  `crushed` becomes true.
- Existing public methods and the canonical state fields used by `main.gd` must
  remain available. Do not special-case the demo level or demonstrated inputs.

Work only in `/app`. Run the project and add your own focused scenarios before
finishing.
