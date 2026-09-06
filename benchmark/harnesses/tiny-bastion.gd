extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var stage := 0
var reported_defeated := 0


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	emit_event("game_ready", {"gold": game.gold})
	Input.action_press("build_tower")


func _process(delta: float) -> bool:
	elapsed += delta
	if stage == 0 and game.towers_built == 1:
		Input.action_release("build_tower")
		stage = 1
	if stage == 1 and elapsed > 0.25:
		Input.action_press("build_tower")
		stage = 2
	if stage == 2 and game.towers_built == 2:
		Input.action_release("build_tower")
		emit_event("towers_built", {"count": game.towers_built, "gold": game.gold})
		Input.action_press("start_wave")
		stage = 3
	if stage == 3 and game.wave_started:
		Input.action_release("start_wave")
		emit_event("wave_started", {"towers": game.towers_built})
		stage = 4
	if game.enemies_defeated > reported_defeated:
		reported_defeated = game.enemies_defeated
		emit_event("enemy_defeated", {"count": reported_defeated})
	if game.victory:
		emit_event("bastion_defended", {"base_health": game.base_health, "defeated": game.enemies_defeated})
		finish(true)
		return true
	if elapsed > 9:
		finish(false)
		return true
	return false


func emit_event(type: String, fields := {}) -> void:
	var payload := {"type": type, "time": elapsed}
	for key in fields: payload[key] = fields[key]
	print(EVENT_PREFIX + JSON.stringify(payload))


func finish(success: bool) -> void:
	Input.action_release("build_tower")
	Input.action_release("start_wave")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
