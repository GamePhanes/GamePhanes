extends Node2D

const GROUND_Y := 428.0
const MOVE_SPEED := 220.0
const JUMP_SPEED := 410.0
const GRAVITY := 1080.0
const SHARD_X := [248.0, 478.0, 708.0]

var player_x := 92.0
var player_y := GROUND_Y
var velocity_y := 0.0
var score := 0
var finished := false
var elapsed := 0.0
var collected := [false, false, false]
var trail: Array[Vector2] = []
var title_label: Label
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	title_label = make_label(Vector2(42, 28), 25, Color("f3f7ff"))
	title_label.text = "NEON RELAY"
	status_label = make_label(Vector2(744, 34), 16, Color("7af7d0"))
	update_status()
	queue_redraw()


func setup_web_input() -> void:
	if not OS.has_feature("web"):
		return
	var window = JavaScriptBridge.get_interface("window")
	web_message_callback = JavaScriptBridge.create_callback(_on_web_message)
	window.addEventListener("message", web_message_callback)
	window.parent.postMessage("gamephanes-ready", window.location.origin)


func _on_web_message(arguments: Array) -> void:
	var event = arguments[0]
	var window = JavaScriptBridge.get_interface("window")
	if str(event.origin) != str(window.location.origin):
		return
	var parts := str(event.data).split("|")
	if parts.size() != 3 or parts[0] != "gamephanes-input" or not InputMap.has_action(parts[1]):
		return
	web_actions[parts[1]] = parts[2] == "1"
	if parts[2] == "1":
		web_just_pressed[parts[1]] = true


func action_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action) or web_actions.get(String(action), false)


func action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) or web_just_pressed.get(String(action), false)


func make_label(at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _physics_process(delta: float) -> void:
	elapsed += delta
	var direction := 0.0
	if action_pressed("move_left"):
		direction -= 1.0
	if action_pressed("move_right"):
		direction += 1.0
	player_x = clampf(player_x + direction * MOVE_SPEED * delta, 42.0, 918.0)
	if action_just_pressed("jump") and is_on_ground():
		velocity_y = 0.0
	velocity_y += GRAVITY * delta
	player_y += velocity_y * delta
	if player_y >= GROUND_Y:
		player_y = GROUND_Y
		velocity_y = 0.0
	for index in SHARD_X.size():
		if not collected[index] and absf(player_x - SHARD_X[index]) < 26.0:
			collected[index] = true
			score += 1
			update_status()
	if score == SHARD_X.size() and player_x > 850.0:
		finished = true
	trail.push_front(Vector2(player_x, player_y))
	if trail.size() > 12:
		trail.pop_back()
	web_just_pressed.clear()
	queue_redraw()


func is_on_ground() -> bool:
	return is_equal_approx(player_y, GROUND_Y)


func update_status() -> void:
	status_label.text = "SHARDS  %d / 3" % score


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("080b20"))
	# Parallax city and an electric horizon give the arena depth without external art.
	for index in range(18):
		var width := 34.0 + float((index * 13) % 48)
		var height := 70.0 + float((index * 37) % 170)
		var x := float(index * 58 - 22)
		draw_rect(Rect2(x, GROUND_Y - height - 48, width, height), Color("11183a"))
		for window_y in range(int(GROUND_Y - height - 34), int(GROUND_Y - 60), 20):
			draw_rect(Rect2(x + 8, window_y, 4, 7), Color("3f4b86" if (window_y + index) % 3 else "ff4fa3"))
	for y in range(104, 410, 34):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.18, 0.26, 0.48, 0.12), 1.0)
	draw_line(Vector2(0, GROUND_Y + 26), Vector2(960, GROUND_Y + 26), Color("32f6c4"), 3.0)
	draw_rect(Rect2(0, GROUND_Y + 29, 960, 84), Color("101631"))
	for x in range(0, 961, 48):
		draw_line(Vector2(x, GROUND_Y + 30), Vector2(x - 46, 540), Color(0.2, 0.75, 0.72, 0.2), 1.0)
	for index in trail.size():
		var alpha := (1.0 - float(index) / 13.0) * 0.32
		draw_circle(trail[index] + Vector2(0, -20), 13.0 - index * 0.5, Color(0.25, 0.95, 0.78, alpha))
	for index in SHARD_X.size():
		if not collected[index]:
			var bob := sin(elapsed * 4.0 + index) * 7.0
			var center := Vector2(SHARD_X[index], GROUND_Y - 42 + bob)
			draw_circle(center, 20.0, Color(0.25, 0.9, 1.0, 0.1))
			draw_colored_polygon(PackedVector2Array([center + Vector2(0,-15),center + Vector2(10,0),center + Vector2(0,15),center + Vector2(-10,0)]), Color("5af5ff"))
	# Runner silhouette, visor, and energy sole.
	var p := Vector2(player_x, player_y)
	draw_circle(p + Vector2(0, -29), 13, Color("ececff"))
	draw_rect(Rect2(p + Vector2(-12, -18), Vector2(24, 31)), Color("755bff"), true)
	draw_rect(Rect2(p + Vector2(2, -33), Vector2(12, 5)), Color("55f7e0"), true)
	draw_line(p + Vector2(-8, 10), p + Vector2(-14, 24), Color("ececff"), 6)
	draw_line(p + Vector2(8, 10), p + Vector2(14, 24), Color("ececff"), 6)
	draw_line(p + Vector2(-18, 24), p + Vector2(18, 24), Color("ff4fa3"), 4)
	draw_rect(Rect2(850, 280, 64, 174), Color(0.3, 0.95, 0.8, 0.08), true)
	draw_line(Vector2(850, 280), Vector2(850, 454), Color("55f7d0"), 3)
	draw_line(Vector2(914, 280), Vector2(914, 454), Color("55f7d0"), 3)
	draw_string(ThemeDB.fallback_font, Vector2(42, 68), "SECTOR 07  //  RUN THE LIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7783ad"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 508), "A / D  MOVE     SPACE  PHASE JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8e99bd"))
	if finished:
		draw_rect(Rect2(292, 194, 376, 110), Color(0.02, 0.04, 0.1, 0.94), true)
		draw_rect(Rect2(292, 194, 376, 110), Color("55f7d0"), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(360, 245), "RELAY SYNCHRONIZED", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f5f7ff"))
