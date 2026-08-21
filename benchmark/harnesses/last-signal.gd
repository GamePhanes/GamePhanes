extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var toggle_time := 0.15
var fire_down := false
var reported_kills := 0


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	emit_event("game_ready", {"threats": game.enemies.size()})
	Input.action_press("move_right")


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed >= toggle_time:
		fire_down = not fire_down
		if fire_down: Input.action_press("fire")
		else: Input.action_release("fire")
		toggle_time += 0.16
	if game.enemies_defeated > reported_kills:
		reported_kills = game.enemies_defeated
		emit_event("threat_cleared", {"count": reported_kills, "shots": game.shots_fired})
	if game.victory:
		emit_event("signal_secured", {"defeated": game.enemies_defeated, "charge": game.signal_charge})
		finish(true)
		return true
	if elapsed > 5:
		finish(false)
		return true
	return false


func emit_event(type: String, fields := {}) -> void:
	var payload := {"type": type, "time": elapsed}
	for key in fields: payload[key] = fields[key]
	print(EVENT_PREFIX + JSON.stringify(payload))


func finish(success: bool) -> void:
	Input.action_release("move_right")
	Input.action_release("fire")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
