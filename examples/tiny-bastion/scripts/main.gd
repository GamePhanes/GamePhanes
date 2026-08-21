extends Node2D

const TOWER_SLOTS := [Vector2(320, 214), Vector2(484, 354), Vector2(650, 214)]

var towers_built := 0
var wave_started := false
var enemies_defeated := 0
var base_health := 5
var victory := false
var elapsed := 0.0
var wave_time := 0.0
var enemy_progress := [0.0, -0.18, -0.36, -0.54, -0.72]
var gold := 90
var pulse := 0.0
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	var title := Label.new()
	title.position = Vector2(34, 24)
	title.text = "TINY BASTION"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("fff5d6"))
	add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(700, 30)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("f6d66d"))
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


func action_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) or web_just_pressed.get(String(action), false)


func _physics_process(delta: float) -> void:
	elapsed += delta
	if action_just_pressed("build_tower") and towers_built < TOWER_SLOTS.size() and gold >= 30:
		towers_built += 1
		gold -= 30
		pulse = 1.0
		update_status()
	if action_just_pressed("start_wave") and towers_built > 0:
		wave_started = true
	if wave_started and not victory:
		wave_time += delta
		for index in enemy_progress.size():
			if enemy_progress[index] < 1.0:
				enemy_progress[index] += delta * (0.17 + towers_built * 0.035)
				if enemy_progress[index] >= 0.72:
					enemy_progress[index] = 1.0
					enemies_defeated += 1
					gold += 8
					update_status()
		if enemies_defeated == enemy_progress.size():
			victory = true
	pulse = maxf(0, pulse - delta * 2)
	web_just_pressed.clear()
	queue_redraw()


func update_status() -> void:
	status_label.text = "GOLD  %02d    WAVE  1 / 1" % gold


func path_position(progress: float) -> Vector2:
	var p := clampf(progress, 0, 1)
	if p < 0.33:
		return Vector2(20 + p / 0.33 * 300, 300)
	if p < 0.66:
		return Vector2(320 + (p - 0.33) / 0.33 * 330, 300 + sin((p - 0.33) / 0.33 * PI) * 92)
	return Vector2(650 + (p - 0.66) / 0.34 * 250, 300)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("14251a"))
	# Layered grass, river stones, and path establish a miniature tabletop feel.
	for index in range(55):
		var pos := Vector2(float((index * 79) % 940 + 10), float((index * 53) % 430 + 82))
		draw_line(pos, pos + Vector2(-2, -7 - index % 5), Color("2c5133"), 2)
	draw_polyline(PackedVector2Array([Vector2(0,300),Vector2(300,300),Vector2(470,390),Vector2(650,300),Vector2(900,300)]), Color("6d6045"), 54, true)
	draw_polyline(PackedVector2Array([Vector2(0,300),Vector2(300,300),Vector2(470,390),Vector2(650,300),Vector2(900,300)]), Color("b7a574"), 3, true)
	for index in range(towers_built):
		var tower: Vector2 = TOWER_SLOTS[index]
		draw_circle(tower + Vector2(0, 12), 24, Color(0,0,0,0.22))
		draw_rect(Rect2(tower + Vector2(-17,-16), Vector2(34,42)), Color("c8c0a5"), true)
		draw_rect(Rect2(tower + Vector2(-22,-24), Vector2(44,14)), Color("557ca8"), true)
		draw_circle(tower + Vector2(0,-17), 5, Color("ffe67b"))
		if wave_started and not victory:
			var beam_target := path_position(clampf(wave_time * 0.22 - index * 0.12, 0, 0.72))
			draw_line(tower + Vector2(0,-17), beam_target, Color(1,0.88,0.38,0.38), 2)
	for index in enemy_progress.size():
		if enemy_progress[index] >= 0 and enemy_progress[index] < 1:
			var enemy := path_position(enemy_progress[index])
			draw_circle(enemy, 13, Color("7b3155"))
			draw_circle(enemy + Vector2(-4,-3), 2, Color("ffe8a6"))
			draw_circle(enemy + Vector2(4,-3), 2, Color("ffe8a6"))
	# Bastion keep.
	draw_rect(Rect2(866, 239, 66, 112), Color("d9d0b4"), true)
	draw_rect(Rect2(858, 228, 82, 22), Color("6d88ae"), true)
	for x in [866.0, 889.0, 912.0]: draw_rect(Rect2(x, 215, 15, 20), Color("d9d0b4"), true)
	draw_rect(Rect2(890, 310, 18, 41), Color("594c3c"), true)
	for index in TOWER_SLOTS.size():
		if index >= towers_built:
			draw_circle(TOWER_SLOTS[index], 23, Color(0.9,0.82,0.4,0.06))
			draw_arc(TOWER_SLOTS[index], 23, 0, TAU, 32, Color("6b825d"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(34, 505), "B  BUILD TOWER     SPACE  CALL THE WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9aac8e"))
	if victory:
		draw_rect(Rect2(344, 92, 272, 64), Color(0.07,0.13,0.08,0.92), true)
		draw_rect(Rect2(344, 92, 272, 64), Color("f2d46d"), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(395, 132), "DAWN DEFENDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff4c4"))
