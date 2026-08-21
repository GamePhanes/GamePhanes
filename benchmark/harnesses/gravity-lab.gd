extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var reported_flip := false
var reported_core := false


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	emit_event("game_ready", {"orb_y": game.orb_y})
	Input.action_press("toggle_gravity")
	Input.action_press("move_right")


func _process(delta: float) -> bool:
	elapsed += delta
	if not reported_flip and game.gravity_inverted:
		reported_flip = true
		Input.action_release("toggle_gravity")
		emit_event("gravity_flipped", {"inverted": true, "changes": game.polarity_changes})
	if not reported_core and game.orb_stabilized:
		reported_core = true
		emit_event("core_stabilized", {"orb_y": game.orb_y, "exit_open": game.exit_open})
	if game.completed:
		Input.action_release("move_right")
		emit_event("chamber_completed", {"player_x": game.player_x})
		finish(true)
		return true
	if elapsed > 8:
		finish(false)
		return true
	return false


func emit_event(type: String, fields := {}) -> void:
	var payload := {"type": type, "time": elapsed}
	for key in fields: payload[key] = fields[key]
	print(EVENT_PREFIX + JSON.stringify(payload))


func finish(success: bool) -> void:
	Input.action_release("move_right")
	Input.action_release("toggle_gravity")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
