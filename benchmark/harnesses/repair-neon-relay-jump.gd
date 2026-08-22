extends SceneTree

const EVENT_PREFIX := "GAMEPHANES_EVENT "
var game: Node
var elapsed := 0.0
var start_x := 0.0
var jumped := false
var shard_count := 0


func _initialize() -> void:
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	start_x = game.player_x
	emit_event("game_ready", {"player_x": start_x})
	Input.action_press("move_right")


func _process(delta: float) -> bool:
	elapsed += delta
	if not jumped and game.player_x > 170:
		jumped = true
		Input.action_press("jump")
	if jumped and game.velocity_y < 0:
		emit_event("player_jumped", {"velocity_y": game.velocity_y})
		Input.action_release("jump")
	if game.score > shard_count:
		shard_count = game.score
		emit_event("shard_collected", {"score": shard_count})
	if game.finished:
		Input.action_release("move_right")
		emit_event("relay_finished", {"shards": game.score, "distance": game.player_x - start_x})
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
	Input.action_release("jump")
	emit_event("playtest_complete", {"success": success})
	quit(0 if success else 1)
