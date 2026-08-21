extends Node2D

const EVENT_PREFIX := "GAMEPHANES_EVENT "
const VIEWPORT_SIZE := Vector2(960, 540)
const ARENA := Rect2(42, 92, 876, 382)
const PLAYER_START := Vector2(480, 364)

enum Phase { INTRO, COMBAT, UPGRADE, BOSS, VICTORY }

const ENEMY_LIBRARY := {
	"skimmer": {"hp": 2, "speed": 28.0, "radius": 14.0, "color": Color("ff557a"), "accent": Color("ffb0c0")},
	"warden": {"hp": 4, "speed": 17.0, "radius": 20.0, "color": Color("9d6bff"), "accent": Color("d8c8ff")},
	"oracle": {"hp": 7, "speed": 11.0, "radius": 25.0, "color": Color("ffb84d"), "accent": Color("fff0b0")},
}

const UPGRADE_LIBRARY := [
	{"id": "overclock", "title": "OVERCLOCK", "detail": "+25% fire rate", "color": Color("55f5d1")},
	{"id": "phase_armor", "title": "PHASE ARMOR", "detail": "+2 max hull", "color": Color("8ca8ff")},
	{"id": "magnet_core", "title": "MAGNET CORE", "detail": "+20% shard pull", "color": Color("ffcc66")},
]

var phase := Phase.INTRO
var player_position := PLAYER_START
var player_velocity := Vector2.ZERO
var player_hp := 6
var max_hp := 6
var energy := 100.0
var scrap := 0
var shards := 0
var score := 0
var elapsed := 0.0
var phase_time := 0.0
var fire_cooldown := 0.0
var dash_cooldown := 0.0
var damage_flash := 0.0
var shake := 0.0
var enemies: Array = []
var enemies_defeated := 0
var boss_health := 0
var boss_max_health := 0
var victory := false
var upgrade_selected := false
var selected_upgrade := ""
var particles: Array = []
var projectiles: Array = []
var floating_text: Array = []
var starfield: Array = []
var title_label: Label
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	seed(1337)
	for index in range(72):
		starfield.append({"position": Vector2(randf_range(0, 960), randf_range(0, 540)), "size": randf_range(0.5, 2.2), "speed": randf_range(4, 18), "alpha": randf_range(0.18, 0.72)})
	title_label = make_label(Vector2(34, 18), 24, Color("f2f5ff"))
	title_label.text = "STARFALL PROTOCOL"
	status_label = make_label(Vector2(668, 24), 14, Color("62efd1"))
	spawn_encounter()
	emit_event("game_ready", {"phase": "combat", "enemies": enemies.size(), "max_hp": max_hp})
	phase = Phase.COMBAT
	queue_redraw()


func make_label(at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


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


func spawn_encounter() -> void:
	enemies.clear()
	var formation := [Vector2(170, 170), Vector2(320, 142), Vector2(480, 128), Vector2(640, 142), Vector2(790, 170), Vector2(240, 285)]
	for index in formation.size():
		var kind := "skimmer" if index % 3 != 2 else "warden"
		var profile: Dictionary = ENEMY_LIBRARY[kind]
		enemies.append({"kind": kind, "position": formation[index], "hp": profile.hp, "max_hp": profile.hp, "cooldown": 0.3 + index * 0.12, "phase": index * 0.8, "hit": 0.0})


func spawn_boss() -> void:
	phase = Phase.BOSS
	phase_time = 0.0
	boss_max_health = 18
	boss_health = boss_max_health
	enemies.clear()
	enemies.append({"kind": "oracle", "position": Vector2(480, 180), "hp": boss_health, "max_hp": boss_health, "cooldown": 0.8, "phase": 0.0, "hit": 0.0})
	emit_event("boss_spawned", {"health": boss_health})
	add_floating_text(Vector2(390, 122), "THE ORACLE AWAKENS", Color("ffcf73"))


func _physics_process(delta: float) -> void:
	elapsed += delta
	phase_time += delta
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	damage_flash = maxf(0.0, damage_flash - delta * 3.5)
	shake = maxf(0.0, shake - delta * 4.0)
	update_stars(delta)
	update_particles(delta)
	update_projectiles(delta)
	update_floating_text(delta)
	if phase == Phase.INTRO:
		if phase_time > 1.0:
			phase = Phase.COMBAT
	elif phase == Phase.COMBAT:
		update_player(delta)
		update_enemies(delta)
		if action_just_pressed("fire"):
			fire_weapon()
		if enemies.is_empty():
			enter_upgrade()
	elif phase == Phase.UPGRADE:
		update_player(delta)
		if action_just_pressed("interact") or action_just_pressed("fire"):
			select_upgrade()
	elif phase == Phase.BOSS:
		update_player(delta)
		update_enemies(delta)
		if action_just_pressed("fire"):
			fire_weapon()
		if boss_health <= 0:
			finish_victory()
	web_just_pressed.clear()
	update_hud()
	queue_redraw()


func update_player(delta: float) -> void:
	var direction := Vector2.ZERO
	if action_pressed("move_left"): direction.x -= 1.0
	if action_pressed("move_right"): direction.x += 1.0
	if action_pressed("move_up"): direction.y -= 1.0
	if action_pressed("move_down"): direction.y += 1.0
	if direction.length() > 1.0: direction = direction.normalized()
	var speed := 218.0 if phase != Phase.BOSS else 232.0
	player_velocity = player_velocity.lerp(direction * speed, minf(1.0, delta * 10.0))
	if action_just_pressed("dash") and dash_cooldown <= 0.0 and direction.length() > 0:
		player_position += direction * 72.0
		dash_cooldown = 1.2
		shake = 0.22
		burst_particles(player_position, Color("55f5d1"), 12)
	player_position += player_velocity * delta
	player_position.x = clampf(player_position.x, ARENA.position.x + 24, ARENA.end.x - 24)
	player_position.y = clampf(player_position.y, ARENA.position.y + 24, ARENA.end.y - 24)
	energy = move_toward(energy, 100.0, delta * 4.0)


func update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy.hp <= 0: continue
		var profile: Dictionary = ENEMY_LIBRARY[enemy.kind]
		enemy.phase += delta
		enemy.hit = maxf(0.0, enemy.hit - delta * 5.0)
		var to_player: Vector2 = player_position - enemy.position
		var distance := to_player.length()
		if distance > (102.0 if phase == Phase.COMBAT else 170.0):
			enemy.position += to_player.normalized() * profile.speed * delta
		else:
			enemy.position += Vector2(cos(enemy.phase * 1.9), sin(enemy.phase * 2.3)) * 4.0 * delta
		enemy.cooldown -= delta
		if enemy.cooldown <= 0.0 and distance < 330.0:
			enemy.cooldown = 1.4 if phase == Phase.COMBAT else 0.85
			projectiles.append({"position": enemy.position, "velocity": to_player.normalized() * 92.0, "life": 3.0, "enemy": true})
		if distance < profile.radius + 13.0 and damage_flash <= 0.0:
			player_hp = maxi(0, player_hp - 1)
			damage_flash = 1.0
			shake = 0.35
			add_floating_text(player_position + Vector2(-18, -28), "-1 HULL", Color("ff667d"))


func fire_weapon() -> void:
	if fire_cooldown > 0.0 or enemies.is_empty(): return
	fire_cooldown = 0.24 if selected_upgrade != "overclock" else 0.17
	var target = nearest_enemy()
	if target == null: return
	var damage := 1
	var direction: Vector2 = (target.position - player_position).normalized()
	projectiles.append({"position": player_position, "velocity": direction * 530.0, "life": 0.8, "enemy": false, "damage": damage})
	burst_particles(player_position + direction * 18.0, Color("ffe18a"), 4)


func nearest_enemy():
	var nearest = null
	var distance := INF
	for enemy in enemies:
		if enemy.hp <= 0: continue
		var candidate_distance := player_position.distance_squared_to(enemy.position)
		if candidate_distance < distance:
			nearest = enemy
			distance = candidate_distance
	return nearest


func update_projectiles(delta: float) -> void:
	for projectile in projectiles.duplicate():
		projectile.position += projectile.velocity * delta
		projectile.life -= delta
		if not projectile.enemy:
			for enemy in enemies:
				if enemy.hp > 0 and projectile.position.distance_to(enemy.position) < 24.0:
					enemy.hp -= projectile.damage
					enemy.hit = 1.0
					score += 10
					burst_particles(enemy.position, Color("fff0b0"), 7)
					if enemy.hp <= 0:
						enemies_defeated += 1
						emit_event("enemy_defeated", {"count": enemies_defeated, "kind": enemy.kind})
					projectile.life = 0.0
					break
		else:
			if projectile.position.distance_to(player_position) < 16.0 and damage_flash <= 0.0:
				player_hp = maxi(0, player_hp - 1)
				damage_flash = 1.0
				projectile.life = 0.0
		if projectile.life <= 0.0 or not ARENA.grow(20).has_point(projectile.position):
			projectiles.erase(projectile)
	# Remove defeated actors so the encounter can advance once the last target falls.
	for enemy in enemies.duplicate():
		if enemy.hp <= 0:
			enemies.erase(enemy)
	if phase == Phase.BOSS:
		boss_health = 0 if enemies.is_empty() else maxf(0, enemies[0].hp)


func enter_upgrade() -> void:
	if phase != Phase.COMBAT: return
	phase = Phase.UPGRADE
	phase_time = 0.0
	scrap += 40
	emit_event("encounter_cleared", {"defeated": enemies_defeated, "scrap": scrap})
	add_floating_text(Vector2(350, 128), "CHOOSE A PROTOCOL [E]", Color("55f5d1"))


func select_upgrade() -> void:
	if upgrade_selected: return
	upgrade_selected = true
	selected_upgrade = UPGRADE_LIBRARY[0].id
	if selected_upgrade == "phase_armor":
		max_hp += 2
		player_hp = max_hp
	emit_event("upgrade_selected", {"upgrade": selected_upgrade, "scrap": scrap})
	add_floating_text(Vector2(386, 128), "OVERCLOCK INSTALLED", Color("55f5d1"))
	spawn_boss()


func finish_victory() -> void:
	if phase == Phase.VICTORY: return
	phase = Phase.VICTORY
	victory = true
	phase_time = 0.0
	boss_health = 0
	score += 500
	emit_event("boss_defeated", {"score": score, "scrap": scrap})
	emit_event("starfall_complete", {"boss_health": boss_health, "score": score})
	emit_event("playtest_complete", {"success": true, "score": score})
	burst_particles(Vector2(480, 180), Color("ffe18a"), 36)
	add_floating_text(Vector2(364, 126), "STARFALL STABILIZED", Color("ffe18a"))


func update_hud() -> void:
	if phase == Phase.UPGRADE:
		status_label.text = "PROTOCOL SELECT  //  PRESS E"
	elif phase == Phase.BOSS:
		status_label.text = "ORACLE  %02d / %02d    SCORE %04d" % [boss_health, boss_max_health, score]
	elif phase == Phase.VICTORY:
		status_label.text = "MISSION COMPLETE  //  SCORE %04d" % score
	else:
		status_label.text = "HULL %d / %d    ENERGY %03d    SCRAP %03d" % [player_hp, max_hp, int(energy), scrap]


func burst_particles(at: Vector2, color: Color, count: int) -> void:
	for index in count:
		particles.append({"position": at, "velocity": Vector2.from_angle(randf() * TAU) * randf_range(35, 150), "life": randf_range(0.3, 0.8), "max_life": 0.8, "color": color})


func add_floating_text(at: Vector2, text: String, color: Color) -> void:
	floating_text.append({"position": at, "text": text, "color": color, "life": 2.2})


func update_particles(delta: float) -> void:
	for particle in particles.duplicate():
		particle.position += particle.velocity * delta
		particle.velocity *= 0.92
		particle.life -= delta
		if particle.life <= 0: particles.erase(particle)


func update_floating_text(delta: float) -> void:
	for item in floating_text.duplicate():
		item.position.y -= delta * 12.0
		item.life -= delta
		if item.life <= 0: floating_text.erase(item)


func update_stars(delta: float) -> void:
	for star in starfield:
		star.position.x -= star.speed * delta
		if star.position.x < -4: star.position.x = 964


func emit_event(type: String, fields := {}) -> void:
	var payload := {"type": type, "time": elapsed}
	for key in fields: payload[key] = fields[key]
	print(EVENT_PREFIX + JSON.stringify(payload))


func _draw() -> void:
	var offset := Vector2(randf_range(-shake, shake) * 8.0, randf_range(-shake, shake) * 8.0)
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("070b19"))
	for star in starfield:
		var alpha: float = star.alpha * (0.65 + sin(elapsed * 2.0 + star.position.x) * 0.25)
		draw_circle(star.position, star.size, Color(0.58, 0.75, 1.0, alpha))
	draw_rect(ARENA, Color("0b1428"), true)
	for x in range(50, 920, 38):
		draw_line(Vector2(x, 92), Vector2(x, 474), Color(0.16, 0.35, 0.48, 0.11), 1.0)
	for y in range(102, 474, 38):
		draw_line(Vector2(42, y), Vector2(918, y), Color(0.16, 0.35, 0.48, 0.11), 1.0)
	draw_rect(ARENA, Color("385e74"), false, 2.0)
	draw_circle(Vector2(480, 260), 126 + sin(elapsed * 1.5) * 5.0, Color(0.22, 0.86, 0.75, 0.04), false, 2)
	draw_arc(Vector2(480, 260), 126, elapsed * 0.4, elapsed * 0.4 + PI * 1.3, 48, Color(0.32, 0.94, 0.78, 0.28), 2)
	for projectile in projectiles:
		var color := Color("ffcf73") if not projectile.enemy else Color("ff5275")
		draw_circle(projectile.position + offset, 5.0, Color(color, 0.16))
		draw_line(projectile.position - projectile.velocity.normalized() * 14.0 + offset, projectile.position + offset, color, 3.0)
	for enemy in enemies:
		if enemy.hp <= 0: continue
		draw_enemy(enemy, offset)
	draw_player(offset)
	for particle in particles:
		var alpha: float = clampf(particle.life / particle.max_life, 0.0, 1.0)
		draw_circle(particle.position + offset, 2.0 + alpha * 3.0, Color(particle.color, alpha))
	for item in floating_text:
		draw_string(ThemeDB.fallback_font, item.position + offset, item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(item.color, clampf(item.life, 0.0, 1.0)))
	if phase == Phase.UPGRADE: draw_upgrade_overlay()
	if phase == Phase.VICTORY: draw_victory_overlay()
	draw_hud_bars()


func draw_player(offset: Vector2) -> void:
	var p := player_position + offset
	var glow := Color(0.32, 0.95, 0.82, 0.12 if damage_flash <= 0 else 0.28)
	draw_circle(p, 28.0 + sin(elapsed * 5.0) * 2.0, glow)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -22), p + Vector2(17, 18), p + Vector2(0, 10), p + Vector2(-17, 18)]), Color("e8f5ff"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -14), p + Vector2(8, 10), p + Vector2(0, 4), p + Vector2(-8, 10)]), Color("55f5d1"))
	draw_line(p + Vector2(-11, 18), p + Vector2(-15, 28), Color("ffcf73"), 4)
	draw_line(p + Vector2(11, 18), p + Vector2(15, 28), Color("ffcf73"), 4)


func draw_enemy(enemy: Dictionary, offset: Vector2) -> void:
	var profile: Dictionary = ENEMY_LIBRARY[enemy.kind]
	var p: Vector2 = enemy.position + offset
	var radius: float = profile.radius
	draw_circle(p, radius + 9.0, Color(profile.color, 0.08 if enemy.hit <= 0 else 0.22))
	if enemy.kind == "oracle":
		draw_arc(p, radius + 8, elapsed, elapsed + PI * 1.6, 36, Color("ffcf73"), 3)
		draw_circle(p, radius, profile.color)
		draw_circle(p, radius * 0.42, profile.accent)
		draw_line(p + Vector2(-radius, 0), p + Vector2(radius, 0), Color("fff1bd"), 2)
	else:
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -radius), p + Vector2(radius, radius * 0.65), p + Vector2(0, radius), p + Vector2(-radius, radius * 0.65)]), profile.color)
		draw_circle(p, radius * 0.3, profile.accent)
	var bar_width := radius * 2.5
	draw_rect(Rect2(p.x - bar_width / 2, p.y - radius - 11, bar_width, 3), Color(0.03, 0.06, 0.12, 0.9), true)
	draw_rect(Rect2(p.x - bar_width / 2, p.y - radius - 11, bar_width * float(enemy.hp) / float(enemy.max_hp), 3), profile.accent, true)


func draw_hud_bars() -> void:
	draw_rect(Rect2(42, 488, 220, 7), Color("182a3b"), true)
	draw_rect(Rect2(42, 488, 220.0 * float(player_hp) / float(max_hp), 7), Color("ff6078"), true)
	draw_rect(Rect2(280, 488, 180, 7), Color("182a3b"), true)
	draw_rect(Rect2(280, 488, 180.0 * energy / 100.0, 7), Color("55f5d1"), true)
	draw_string(ThemeDB.fallback_font, Vector2(42, 520), "WASD MOVE   SHIFT DASH   SPACE FIRE   E SELECT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("71849d"))
	draw_string(ThemeDB.fallback_font, Vector2(718, 520), "SECTOR 01 // STARFALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("4e637c"))


func draw_upgrade_overlay() -> void:
	draw_rect(Rect2(244, 150, 472, 246), Color(0.02, 0.05, 0.11, 0.96), true)
	draw_rect(Rect2(244, 150, 472, 246), Color("55f5d1"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(290, 188), "SALVAGE PROTOCOL", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f2f5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(290, 211), "One upgrade. One chance before the Oracle.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("8ba1ba"))
	for index in UPGRADE_LIBRARY.size():
		var card := Rect2(268 + index * 138, 240, 120, 102)
		var upgrade: Dictionary = UPGRADE_LIBRARY[index]
		draw_rect(card, Color("132238"), true)
		draw_rect(card, upgrade.color, false, 2)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 28), str(upgrade.title), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, upgrade.color)
		draw_string(ThemeDB.fallback_font, card.position + Vector2(10, 58), str(upgrade.detail), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("d5deed"))
	if upgrade_selected:
		draw_string(ThemeDB.fallback_font, Vector2(386, 378), "LOADING BOSS ARENA...", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("55f5d1"))


func draw_victory_overlay() -> void:
	draw_rect(Rect2(282, 176, 396, 170), Color(0.02, 0.04, 0.09, 0.94), true)
	draw_rect(Rect2(282, 176, 396, 170), Color("ffcf73"), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(344, 232), "STARFALL STABILIZED", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("ffe6a8"))
	draw_string(ThemeDB.fallback_font, Vector2(382, 263), "ORACLE DEFEATED", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("55f5d1"))
	draw_string(ThemeDB.fallback_font, Vector2(380, 306), "SCORE  %04d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2f5ff"))
