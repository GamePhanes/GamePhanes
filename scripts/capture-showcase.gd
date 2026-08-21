extends SceneTree

var game: Node
var frame := 0
var output_path := ""
var project_name := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			output_path = args[index + 1]
	if output_path.is_empty():
		push_error("Missing --output argument")
		quit(1)
		return
	project_name = ProjectSettings.get_setting("application/config/name", "")
	game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(game)
	if project_name == "Neon Relay": Input.action_press("move_right")
	if project_name == "Gravity Lab": Input.action_press("toggle_gravity")
	if project_name == "Rift Arena": Input.action_press("move_forward")


func tap(action: String) -> void:
	Input.action_release(action)
	Input.action_press(action)


func capture_frame() -> int:
	if project_name == "Last Signal": return 45
	if project_name == "Rift Arena": return 41
	return 72


func _process(_delta: float) -> bool:
	frame += 1
	if project_name == "Neon Relay":
		if frame == 24: Input.action_press("jump")
		if frame == 28: Input.action_release("jump")
	if project_name == "Last Signal":
		if frame in [8, 26, 44, 62]: tap("fire")
		if frame in [10, 28, 46, 64]: Input.action_release("fire")
	if project_name == "Gravity Lab" and frame == 3: Input.action_release("toggle_gravity")
	if project_name == "Tiny Bastion":
		if frame == 4: tap("build_tower")
		if frame == 7: Input.action_release("build_tower")
		if frame == 12: tap("build_tower")
		if frame == 15: Input.action_release("build_tower")
		if frame == 20: tap("start_wave")
		if frame == 23: Input.action_release("start_wave")
	if project_name == "Rift Arena":
		if frame == 26: Input.action_release("move_forward")
		if frame in [18, 40, 62]: tap("attack")
		if frame in [20, 42, 64]: Input.action_release("attack")
	if frame == capture_frame():
		if InputMap.has_action("move_right"): Input.action_release("move_right")
		if InputMap.has_action("move_forward"): Input.action_release("move_forward")
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png(output_path)
		quit(0 if error == OK else 1)
		return true
	return false
