extends Node2D

var player_x := 112.0
var orb_y := 396.0
var gravity_inverted := false
var polarity_changes := 0
var orb_stabilized := false
var exit_open := false
var completed := false
var elapsed := 0.0
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	var title := Label.new()
	title.position = Vector2(34, 24)
	title.text = "GRAVITY LAB / CHAMBER 04"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("e5f7ff"))
	add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(742, 30)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("73e7ff"))
	add_child(status_label)
	update_status()


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


func _physics_process(delta: float) -> void:
	elapsed += delta
	var direction := 0.0
	if action_pressed("move_left"):
		direction -= 1.0
	if action_pressed("move_right"):
		direction += 1.0
	player_x = clampf(player_x + direction * 170.0 * delta, 62.0, 900.0)
	if action_just_pressed("toggle_gravity"):
		gravity_inverted = not gravity_inverted
		polarity_changes += 1
		update_status()
	var target_y := 172.0 if gravity_inverted else 396.0
	orb_y = move_toward(orb_y, target_y, delta * 150.0)
	if gravity_inverted and orb_y <= 176.0:
		orb_stabilized = true
		exit_open = true
		update_status()
	if exit_open and player_x > 820.0:
		completed = true
	web_just_pressed.clear()
	queue_redraw()


func update_status() -> void:
	status_label.text = "POLARITY  %s" % ("INVERTED" if gravity_inverted else "NORMAL")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("071119"))
	for x in range(42, 920, 74):
		draw_line(Vector2(x, 92), Vector2(x, 462), Color(0.2, 0.47, 0.58, 0.13), 1)
	for y in range(100, 470, 58):
		draw_line(Vector2(34, y), Vector2(926, y), Color(0.2, 0.47, 0.58, 0.13), 1)
	# Magnetic rails and chamber windows.
	draw_rect(Rect2(34, 96, 892, 366), Color("0d202a"), false, 3)
	draw_rect(Rect2(70, 126, 278, 286), Color("09161e"), true)
	draw_rect(Rect2(372, 126, 278, 286), Color("09161e"), true)
	draw_rect(Rect2(674, 126, 210, 286), Color("09161e"), true)
	for y in [148.0, 390.0]:
		draw_line(Vector2(70, y), Vector2(884, y), Color("2bb6d3"), 3)
		for x in range(84, 884, 38):
			draw_circle(Vector2(x, y), 3, Color("a7efff"))
	var beam_alpha := 0.22 + sin(elapsed * 6) * 0.08
	draw_rect(Rect2(470, 148, 80, 244), Color(0.25, 0.8, 1.0, beam_alpha), true)
	draw_circle(Vector2(510, orb_y), 34, Color(0.2, 0.85, 1.0, 0.12))
	draw_circle(Vector2(510, orb_y), 18, Color("9cecff"))
	draw_circle(Vector2(504, orb_y - 6), 6, Color("eefcff"))
	var p := Vector2(player_x, 410)
	draw_rect(Rect2(p + Vector2(-15,-34), Vector2(30,34)), Color("eaf7fa"), true)
	draw_rect(Rect2(p + Vector2(-11,-27), Vector2(22,9)), Color("2fc8e8"), true)
	draw_line(p + Vector2(-9,0), p + Vector2(-13,13), Color("dcecf0"), 6)
	draw_line(p + Vector2(9,0), p + Vector2(13,13), Color("dcecf0"), 6)
	var door_color := Color("67e6ff") if exit_open else Color("d85050")
	draw_rect(Rect2(830, 246, 54, 166), Color(door_color, 0.08), true)
	draw_rect(Rect2(830, 246, 54, 166), door_color, false, 3)
	if not exit_open:
		for y in range(260, 405, 18): draw_line(Vector2(832,y), Vector2(882,y), door_color, 2)
	draw_string(ThemeDB.fallback_font, Vector2(34, 505), "A / D  WALK     SPACE  FLIP POLARITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("78909a"))
	draw_string(ThemeDB.fallback_font, Vector2(446, 116), "CORE LIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("6daebe"))
	if completed:
		draw_string(ThemeDB.fallback_font, Vector2(720, 108), "TEST PASSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("75ecba"))
