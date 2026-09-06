extends Node2D

const GROUND_Y := 310.0
const PLAYER_SIZE := Vector2(28.0, 36.0)
const MOVE_SPEED := 140.0
const JUMP_SPEED := 310.0
const GRAVITY := 850.0
const COIN_X := 210.0

var player_x := 70.0
var player_y := GROUND_Y
var velocity_y := 0.0
var score := 0
var coin_visible := true
var score_label: Label


func _ready() -> void:
	score_label = Label.new()
	score_label.position = Vector2(20, 18)
	score_label.add_theme_font_size_override("font_size", 22)
	add_child(score_label)
	update_score_label()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	player_x = clampf(player_x + direction * MOVE_SPEED * delta, 14.0, 626.0)

	if Input.is_action_just_pressed("jump") and is_on_ground():
		velocity_y = -JUMP_SPEED

	velocity_y += GRAVITY * delta
	player_y += velocity_y * delta
	if player_y >= GROUND_Y:
		player_y = GROUND_Y
		velocity_y = 0.0

	if coin_visible and absf(player_x - COIN_X) < 18.0:
		coin_visible = false
		score += 1
		update_score_label()

	queue_redraw()


func is_on_ground() -> bool:
	return is_equal_approx(player_y, GROUND_Y)


func update_score_label() -> void:
	score_label.text = "COINS  %d" % score


func _draw() -> void:
	# A small procedural arena keeps the example asset-free and reproducible.
	for x in range(0, 641, 40):
		draw_line(Vector2(x, 92), Vector2(x, GROUND_Y + 18), Color("151c26"), 1.0)
	for y in range(110, 311, 40):
		draw_line(Vector2(0, y), Vector2(640, y), Color("151c26"), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(20, 76), "VERIFICATION ARENA / 001", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("64748b"))
	draw_rect(Rect2(0, GROUND_Y + 18, 640, 32), Color("273142"))
	draw_rect(Rect2(300, 256, 112, 12), Color("324052"))
	draw_rect(Rect2(472, 212, 90, 12), Color("324052"))
	draw_rect(Rect2(Vector2(player_x - 17, GROUND_Y + 12), Vector2(34, 6)), Color(0, 0, 0, 0.28))
	draw_rect(
		Rect2(Vector2(player_x, player_y) - PLAYER_SIZE / 2.0, PLAYER_SIZE),
		Color("54d2a0"),
	)
	draw_rect(Rect2(player_x + 5, player_y - 6, 4, 4), Color("091016"))
	if coin_visible:
		draw_circle(Vector2(COIN_X, GROUND_Y - 20), 12.0, Color("ffd166"))
		draw_circle(Vector2(COIN_X, GROUND_Y - 20), 6.0, Color("8d6a1d"))
	draw_string(ThemeDB.fallback_font, Vector2(20, 350), "A/D or arrows to move | Space to jump", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b6c2d2"))
