extends Node2D

var player_position := Vector2(480, 300)
var enemies := [Vector2(230, 190), Vector2(742, 172), Vector2(725, 395), Vector2(258, 414)]
var enemies_defeated := 0
var shots_fired := 0
var signal_charge := 32.0
var victory := false
var elapsed := 0.0
var muzzle_flash := 0.0
var last_target := Vector2.ZERO
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	var title := Label.new()
	title.position = Vector2(34, 24)
	title.text = "LAST SIGNAL"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("fff0dc"))
	add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(730, 30)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("ffca72"))
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
	var movement := Vector2.ZERO
	if action_pressed("move_left"):
		movement.x -= 1.0
	if action_pressed("move_right"):
		movement.x += 1.0
	if action_pressed("move_up"):
		movement.y -= 1.0
	if action_pressed("move_down"):
		movement.y += 1.0
	movement = movement.normalized()
	player_position += movement * 155.0 * delta
	player_position.x = clampf(player_position.x, 70, 890)
	player_position.y = clampf(player_position.y, 115, 465)
	for index in enemies.size():
		var direction: Vector2 = (player_position - enemies[index]).normalized()
		enemies[index] += direction * (18.0 + index * 2.0) * delta
	if action_just_pressed("fire") and not enemies.is_empty():
		fire_pulse()
	muzzle_flash = maxf(0.0, muzzle_flash - delta * 4.0)
	if enemies.is_empty():
		victory = true
		signal_charge = minf(100.0, signal_charge + delta * 34.0)
	web_just_pressed.clear()
	queue_redraw()


func fire_pulse() -> void:
	var nearest_index := 0
	var nearest_distance := INF
	for index in enemies.size():
		var distance := player_position.distance_squared_to(enemies[index])
		if distance < nearest_distance:
			nearest_index = index
			nearest_distance = distance
	last_target = enemies[nearest_index]
	enemies.remove_at(nearest_index)
	shots_fired += 1
	enemies_defeated += 1
	signal_charge = minf(100.0, signal_charge + 17.0)
	muzzle_flash = 1.0
	update_status()


func update_status() -> void:
	status_label.text = "THREATS  %d    SIGNAL  %d%%" % [enemies.size(), int(signal_charge)]


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("101114"))
	# Radio-map terrain: contour rings, roads, and a central beacon.
	for radius in range(72, 450, 52):
		draw_arc(Vector2(480, 300), radius, 0, TAU, 80, Color(0.55, 0.39, 0.23, 0.17), 1)
	for index in range(34):
		var x := float((index * 83) % 930 + 15)
		var y := float((index * 47) % 410 + 100)
		draw_circle(Vector2(x, y), 2 + index % 3, Color("3b332b"))
	draw_line(Vector2(0, 444), Vector2(960, 202), Color("332b25"), 18)
	draw_line(Vector2(0, 444), Vector2(960, 202), Color("a06e3e"), 1)
	draw_circle(Vector2(480, 300), 102, Color(0.95, 0.52, 0.25, 0.04))
	draw_arc(Vector2(480, 300), 102, -elapsed, TAU - elapsed, 72, Color(1, 0.62, 0.28, 0.32), 2)
	for enemy in enemies:
		draw_circle(enemy, 20, Color(0.95, 0.22, 0.19, 0.10))
		draw_colored_polygon(PackedVector2Array([enemy+Vector2(0,-13),enemy+Vector2(12,8),enemy+Vector2(0,4),enemy+Vector2(-12,8)]), Color("df4a3f"))
		draw_circle(enemy, 4, Color("fff2d6"))
	var p := player_position
	draw_circle(p, 31 + sin(elapsed * 5) * 2, Color(1, 0.67, 0.31, 0.09))
	draw_circle(p, 18, Color("f0b45d"))
	draw_circle(p, 10, Color("2d3334"))
	draw_line(p + Vector2(0,-22), p + Vector2(0,-46), Color("ffd181"), 3)
	draw_circle(p + Vector2(0,-49), 4, Color("fff0b5"))
	if muzzle_flash > 0:
		draw_line(p, last_target, Color(1, 0.82, 0.4, muzzle_flash), 4)
		draw_circle(last_target, 26 * muzzle_flash, Color(1, 0.3, 0.18, muzzle_flash * 0.35))
	draw_rect(Rect2(34, 72, 210, 4), Color("4a3d30"))
	draw_rect(Rect2(34, 72, 210 * signal_charge / 100.0, 4), Color("ffbd62"))
	draw_string(ThemeDB.fallback_font, Vector2(34, 505), "WASD  REPOSITION     SPACE  EMIT PULSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("82776b"))
	if victory:
		draw_string(ThemeDB.fallback_font, Vector2(372, 102), "CHANNEL SECURED", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffe1a8"))
