extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var fire_down := false
var next_fire := 0.3
var reported_defeated := 0
var upgraded := false
var boss_started := false


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	emit_event("harness_ready", {"target": "starfall_protocol"})


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed < 0.4:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
	if game.phase == game.Phase.COMBAT or game.phase == game.Phase.BOSS:
		if elapsed >= next_fire:
			fire_down = not fire_down
			if fire_down: Input.action_press("fire")
			else: Input.action_release("fire")
			next_fire += 0.16
	if game.enemies_defeated > reported_defeated:
		reported_defeated = game.enemies_defeated
		emit_event("enemy_progress", {"defeated": reported_defeated})
	if game.phase == game.Phase.UPGRADE and not upgraded:
		Input.action_press("interact")
		upgraded = true
	if game.phase == game.Phase.BOSS and not boss_started:
		Input.action_release("interact")
		boss_started = true
		emit_event("boss_phase_verified", {"health": game.boss_health})
	if game.victory:
		emit_event("starfall_complete", {"score": game.score, "boss_health": game.boss_health})
		finish(true)
		return true
	if elapsed > 15:
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
	Input.action_release("interact")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
