extends SceneTree

const World = preload("res://scripts/world.gd")
const Controller = preload("res://scripts/controller.gd")

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
		print("FAIL ", message)


func empty_action() -> Dictionary:
	return {"move": 0, "jump": false, "dash": false}


func floor_world(extra: Array = []) -> Variant:
	var solids: Array = [{"x": -200, "y": 60, "w": 500, "h": 8}]
	solids.append_array(extra)
	return World.new(solids)


func test_scene_and_determinism() -> void:
	var world = floor_world([{"x": 90, "y": 0, "w": 3, "h": 60}])
	var first = Controller.new(0, 48)
	var second = Controller.new(0, 48)
	for frame_tick in 40:
		var action := {
			"move": [-1, 0, 1][(frame_tick * 7) % 3],
			"jump": frame_tick in [3, 18, 31],
			"dash": frame_tick in [8, 27],
		}
		first.step(action, world)
		second.step(action.duplicate(true), world)
	check(first.canonical_state() == second.canonical_state(), "identical fixed-tick runs are deterministic")
	check(first.tick == 40, "tick accounting remains exact")


func test_swept_solids() -> void:
	var wall_world = World.new([{"x": 20, "y": -100, "w": 1, "h": 300}])
	var dasher = Controller.new(0, 0)
	dasher.step({"move": 1, "jump": false, "dash": true}, wall_world)
	check(dasher.x == 12, "fourteen-subpixel dash stops flush against a one-subpixel wall")
	check(not wall_world.collides_solid(dasher.body_rect(), dasher.tick), "horizontal sweep never leaves overlap")

	var floor = World.new([{"x": -40, "y": 25, "w": 100, "h": 1}])
	var faller = Controller.new(0, 2)
	faller.vy = 12
	faller.step(empty_action(), floor)
	check(faller.y == 13 and faller.on_ground, "high-speed fall lands flush on a thin floor")

	var corner = World.new([
		{"x": 20, "y": 20, "w": 2, "h": 40},
		{"x": 20, "y": 20, "w": 40, "h": 2},
	])
	var diagonal = Controller.new(5, 5)
	diagonal.vy = 10
	diagonal.step({"move": 1, "jump": false, "dash": false}, corner)
	check(not corner.collides_solid(diagonal.body_rect(), diagonal.tick), "diagonal corner resolution never embeds the body")


func test_one_way_platforms() -> void:
	var world = World.new([], [{"x": -20, "y": 20, "w": 60, "h": 2}])
	var rising = Controller.new(0, 24)
	rising.vy = -11
	rising.step(empty_action(), world)
	check(rising.y < 20, "one-way platform allows upward passage")

	var falling = Controller.new(0, 0)
	falling.vy = 12
	falling.step(empty_action(), world)
	check(falling.y == 8 and falling.on_ground, "downward sweep lands exactly on one-way top")

	var lateral = Controller.new(-12, 8)
	lateral.vy = 0
	lateral.step({"move": 1, "jump": false, "dash": true}, world)
	check(lateral.x == 2, "one-way platform never blocks horizontal dash")


func test_coyote_boundaries() -> void:
	var world = World.new([{"x": -20, "y": 20, "w": 28, "h": 4}])
	var third_tick = Controller.new(0, 8)
	third_tick.step({"move": 1, "jump": false, "dash": false}, world)
	third_tick.step({"move": 1, "jump": false, "dash": false}, world)
	third_tick.step(empty_action(), world)
	third_tick.step(empty_action(), world)
	third_tick.step({"move": 0, "jump": true, "dash": false}, world)
	check(third_tick.vy == Controller.JUMP_SPEED, "jump is accepted on final coyote tick")

	var expired = Controller.new(0, 8)
	for frame_tick in 5:
		expired.step({"move": 1 if frame_tick < 2 else 0, "jump": false, "dash": false}, world)
	expired.step({"move": 0, "jump": true, "dash": false}, world)
	check(expired.vy != Controller.JUMP_SPEED, "jump is rejected after coyote window expires")


func test_jump_buffer_and_dash() -> void:
	var world = floor_world()
	var buffered = Controller.new(0, 40)
	buffered.vy = 8
	buffered.step({"move": 0, "jump": true, "dash": false}, world)
	check(buffered.vy == Controller.JUMP_SPEED and not buffered.on_ground, "buffered jump fires on landing boundary")

	var dasher = Controller.new(0, 20)
	dasher.step({"move": -1, "jump": false, "dash": true}, world)
	var first_delta: int = dasher.x
	dasher.step({"move": 1, "jump": false, "dash": false}, world)
	check(first_delta == -14 and dasher.x == -28, "dash keeps its initial direction for exactly two ticks")
	check(dasher.dash_left == 0 and not dasher.dash_available, "air dash remains unavailable before landing")
	for unused in 20:
		dasher.step(empty_action(), world)
		if dasher.on_ground:
			break
	check(dasher.dash_available, "landing resets dash availability")


func test_moving_platforms() -> void:
	var horizontal = World.new([], [], [
		{"x": 0, "y": 30, "w": 30, "h": 4, "dx": 3, "dy": 0, "period": 3},
	])
	var rider = Controller.new(6, 18)
	rider.on_ground = true
	rider.support_platform = 0
	rider.step(empty_action(), horizontal)
	check(rider.x == 9 and rider.y == 18 and rider.support_platform == 0, "rider receives complete horizontal platform carry")

	var elevator = World.new([], [], [
		{"x": 0, "y": 40, "w": 30, "h": 4, "dx": 0, "dy": -3, "period": 3},
	])
	var lifted = Controller.new(5, 28)
	lifted.on_ground = true
	lifted.support_platform = 0
	lifted.step(empty_action(), elevator)
	check(lifted.y == 25 and lifted.support_platform == 0, "rider receives complete vertical platform carry")

	var crusher = World.new([{"x": -10, "y": 0, "w": 60, "h": 4}], [], [
		{"x": 0, "y": 19, "w": 30, "h": 4, "dx": 0, "dy": -4, "period": 4},
	])
	var trapped = Controller.new(5, 7)
	trapped.on_ground = true
	trapped.support_platform = 0
	trapped.step(empty_action(), crusher)
	check(trapped.crushed, "upward platform marks a player crushed when ceiling prevents carry")


func _initialize() -> void:
	test_scene_and_determinism()
	test_swept_solids()
	test_one_way_platforms()
	test_coyote_boundaries()
	test_jump_buffer_and_dash()
	test_moving_platforms()
	if failures.is_empty():
		print("KINETIC_VAULT_TESTS_PASSED")
		quit(0)
	else:
		print("KINETIC_VAULT_TESTS_FAILED count=", failures.size())
		for failure in failures:
			print(" - ", failure)
		quit(1)
