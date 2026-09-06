# Source Eligibility

- source_id: `019fe14c-1a55-7c82-b2eb-dfe864697791`
- engine: `Godot`
- source_engine_version: `4.6.1`
- benchmark_engine_version: `4.4.1`
- eligible: `true`
- evidence_kind: `post-compaction edit inventory plus completed native Godot regressions, workspace diff inventory, and visual capture fingerprint`
- redaction_status: `private paths, account identifiers, and source artwork omitted`
- agent_facing_mcp_required: `false`

The source contains a direct request to make flat HP/MP fills glossy, a preserved
inventory of the exact Godot scene/script/manager/test edits, two completed
Godot 4.6.1 regression runs, a returned `git status` inventory containing the
expected changed files and new fill assets, and a visual-capture result with a
stable PNG fingerprint. This is executable game-engine work rather than a
prose-only design request.

The benchmark intentionally narrows the private project edit to a self-contained
Godot scene and supplied texture fixtures. It does not claim to reproduce the
private art source, unrelated dirty-worktree changes, or the source project's
MCP bridge.
