extends Node3D

var player_position := Vector3(0, 0.65, 3.4)
var hits := 0
var enemy_health := 3
var rift_stability := 18.0
var victory := false
var elapsed := 0.0
var attack_flash := 0.0
var player_mesh: MeshInstance3D
var enemy_mesh: MeshInstance3D
var rift_ring: MeshInstance3D
var status_label: Label
var web_message_callback
var web_actions := {}
var web_just_pressed := {}


func _ready() -> void:
	setup_web_input()
	build_world()
	build_hud()


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


func material(color: Color, emission := Color(0, 0, 0, 1), energy := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = 0.35
	result.roughness = 0.42
	if energy > 0:
		result.emission_enabled = true
		result.emission = emission
		result.emission_energy_multiplier = energy
	return result


func mesh_instance(mesh: PrimitiveMesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = mat
	add_child(instance)
	return instance


func build_world() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("080417")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("49317a")
	environment.ambient_light_energy = 0.8
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-54, -28, 0)
	light.light_color = Color("e1d5ff")
	light.light_energy = 1.7
	light.shadow_enabled = true
	add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8.2, 10.8)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 6.2
	floor_mesh.bottom_radius = 6.5
	floor_mesh.height = 0.5
	mesh_instance(floor_mesh, Vector3(0, -0.25, 0), material(Color("17152c")))
	for index in range(12):
		var angle := TAU * index / 12.0
		var column := BoxMesh.new()
		column.size = Vector3(0.42, 1.2 + (index % 3) * 0.35, 0.42)
		mesh_instance(column, Vector3(cos(angle) * 5.45, column.size.y / 2.0, sin(angle) * 5.45), material(Color("403864")))
	var player_body := CapsuleMesh.new()
	player_body.radius = 0.38
	player_body.height = 1.3
	player_mesh = mesh_instance(player_body, player_position, material(Color("e8edf7"), Color("63f6df"), 1.1))
	var enemy_body := SphereMesh.new()
	enemy_body.radius = 0.68
	enemy_body.height = 1.36
	enemy_mesh = mesh_instance(enemy_body, Vector3(0, 0.72, -1.7), material(Color("701f68"), Color("ff40b4"), 2.0))
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.28
	rift_ring = mesh_instance(torus, Vector3(0, 1.3, -3.7), material(Color("6e3b9c"), Color("9f59ff"), 3.2))
	rift_ring.rotation_degrees.x = 90
	for index in range(4):
		var crystal := PrismMesh.new()
		crystal.size = Vector3(0.55, 1.5, 0.55)
		var angle := TAU * index / 4.0 + PI / 4.0
		mesh_instance(crystal, Vector3(cos(angle) * 3.7, 0.75, sin(angle) * 3.7), material(Color("344073"), Color("557dff"), 1.5))


func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.position = Vector2(34, 24)
	title.text = "RIFT ARENA"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("f4eeff"))
	layer.add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(704, 30)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("d49cff"))
	layer.add_child(status_label)
	var controls := Label.new()
	controls.position = Vector2(34, 498)
	controls.text = "WASD  STRAFE     SPACE  RIFT STRIKE"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("968aaa"))
	layer.add_child(controls)
	update_status()


func _physics_process(delta: float) -> void:
	elapsed += delta
	var movement := Vector3.ZERO
	if action_pressed("move_left"):
		movement.x -= 1.0
	if action_pressed("move_right"):
		movement.x += 1.0
	if action_pressed("move_forward"):
		movement.z -= 1.0
	if action_pressed("move_back"):
		movement.z += 1.0
	if movement.length() > 1:
		movement = movement.normalized()
	player_position += movement * 3.2 * delta
	player_position.x = clampf(player_position.x, -4.4, 4.4)
	player_position.z = clampf(player_position.z, -0.2, 4.4)
	player_mesh.position = player_position
	player_mesh.rotation.y = sin(elapsed * 2.0) * 0.08
	enemy_mesh.position.y = 0.72 + sin(elapsed * 3.0) * 0.12
	enemy_mesh.rotation.y += delta * 1.4
	rift_ring.rotation.z += delta * 0.65
	if action_just_pressed("attack") and enemy_health > 0:
		hits += 1
		enemy_health -= 1
		rift_stability += 27.0
		attack_flash = 1.0
		if enemy_health == 0:
			victory = true
			enemy_mesh.visible = false
		update_status()
	attack_flash = maxf(0, attack_flash - delta * 3.0)
	var scale_boost := 1.0 + attack_flash * 0.24
	player_mesh.scale = Vector3.ONE * scale_boost
	web_just_pressed.clear()


func update_status() -> void:
	status_label.text = "RIFT  %d%%    WARDEN  %d / 3" % [int(minf(rift_stability, 100)), enemy_health]
	if victory:
		status_label.text = "RIFT STABILIZED  //  CLEAR"
