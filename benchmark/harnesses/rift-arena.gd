extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var toggle_time := 0.25
var attack_down := false
var reported_hits := 0


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	emit_event("game_ready", {"enemy_health": game.enemy_health})
	Input.action_press("move_forward")


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 0.55: Input.action_release("move_forward")
	if elapsed >= toggle_time:
		attack_down = not attack_down
		if attack_down: Input.action_press("attack")
		else: Input.action_release("attack")
		toggle_time += 0.22
	if game.hits > reported_hits:
		reported_hits = game.hits
		emit_event("warden_hit", {"hits": game.hits, "health": game.enemy_health})
	if game.victory:
		emit_event("rift_stabilized", {"stability": game.rift_stability, "hits": game.hits})
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
	Input.action_release("move_forward")
	Input.action_release("attack")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
