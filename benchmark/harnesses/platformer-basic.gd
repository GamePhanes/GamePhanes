extends SceneTree

const EVENT_PREFIX := "GAMEBUDDY_EVENT "

var game: Node
var start_x := 0.0
var elapsed := 0.0
var moved_reported := false
var jumped_reported := false


func _initialize() -> void:
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene_path.is_empty():
		fail("main scene is not configured")
		return

	var packed_scene := load(main_scene_path) as PackedScene
	if packed_scene == null:
		fail("main scene could not be loaded")
		return

	game = packed_scene.instantiate()
	root.add_child(game)
	start_x = float(game.get("player_x"))
	emit_event("game_ready", {"player_x": start_x})
	Input.action_press("move_right")


func _process(delta: float) -> bool:
	elapsed += delta
	if game == null:
		return false

	var player_x := float(game.get("player_x"))
	if not moved_reported and player_x - start_x > 35.0:
		moved_reported = true
		emit_event("player_moved", {"delta_x": player_x - start_x})
		Input.action_press("jump")

	var velocity_y := float(game.get("velocity_y"))
	if moved_reported and not jumped_reported and velocity_y < 0.0:
		jumped_reported = true
		emit_event("player_jumped", {"velocity_y": velocity_y})
		Input.action_release("jump")

	var score := int(game.get("score"))
	if score >= 1:
		Input.action_release("move_right")
		emit_event("coin_collected", {"score": score})
		emit_event("playtest_complete", {"success": moved_reported and jumped_reported})
		quit(0)
		return true

	if elapsed > 8.0:
		fail("playtest timed out before the coin was collected")
		return true

	return false


func emit_event(type: String, fields := {}) -> void:
	var payload := {"type": type, "time": elapsed}
	for key in fields:
		payload[key] = fields[key]
	print(EVENT_PREFIX + JSON.stringify(payload))


func fail(message: String) -> void:
	Input.action_release("move_right")
	Input.action_release("jump")
	emit_event("playtest_error", {"message": message})
	emit_event("playtest_complete", {"success": false})
	quit(1)
