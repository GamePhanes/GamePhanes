class_name KineticController
extends RefCounted

const WIDTH := 8
const HEIGHT := 12
const RUN_SPEED := 6
const GRAVITY := 2
const MAX_FALL := 12
const JUMP_SPEED := -11
const DASH_SPEED := 14
const DASH_TICKS := 2
const COYOTE_TICKS := 3
const JUMP_BUFFER_TICKS := 3

var x := 0
var y := 0
var vx := 0
var vy := 0
var tick := 0
var facing := 1
var on_ground := false
var support_platform := -1
var coyote_left := 0
var jump_buffer_left := 0
var dash_left := 0
var dash_direction := 1
var dash_available := true
var crushed := false


func _init(start_x := 0, start_y := 0) -> void:
	x = start_x
	y = start_y


func body_rect(at_x := x, at_y := y) -> Dictionary:
	return {"x": at_x, "y": at_y, "w": WIDTH, "h": HEIGHT}


# Move on one axis and return whether an obstacle stopped the displacement.
func _move_x(amount: int, world, world_tick: int, excluded_platform := -1) -> bool:
	if amount == 0:
		return false
	x += amount
	if world.collides_solid(body_rect(), world_tick, excluded_platform):
		x -= signi(amount)
		vx = 0
		return true
	return false


func _move_y(amount: int, world, world_tick: int, excluded_platform := -1) -> bool:
	if amount == 0:
		return false
	var before_bottom := y + HEIGHT
	y += amount
	var blocked: bool = world.collides_solid(body_rect(), world_tick, excluded_platform)
	for platform in world.one_way_platforms:
		if world.overlaps(body_rect(), platform) and before_bottom >= int(platform.y):
			blocked = true
	if blocked:
		y -= signi(amount)
		vy = 0
		return true
	return false


func _start_jump_if_possible() -> void:
	if jump_buffer_left > 0 and (on_ground or coyote_left > 0):
		vy = JUMP_SPEED
		on_ground = false
		support_platform = -1
		coyote_left = 0
		jump_buffer_left = 0


func step(action: Dictionary, world) -> void:
	if crushed:
		tick += 1
		return

	var next_world_tick := tick + 1
	if support_platform >= 0:
		var carry: Dictionary = world.platform_motion(support_platform, tick)
		_move_x(int(carry.x), world, next_world_tick, support_platform)
		_move_y(int(carry.y), world, next_world_tick, support_platform)

	var move_input := clampi(int(action.get("move", 0)), -1, 1)
	if move_input != 0:
		facing = move_input
	if bool(action.get("jump", false)):
		jump_buffer_left = JUMP_BUFFER_TICKS
	else:
		jump_buffer_left = maxi(0, jump_buffer_left - 1)
	if on_ground:
		coyote_left = COYOTE_TICKS
	else:
		coyote_left = maxi(0, coyote_left - 1)
	_start_jump_if_possible()

	if bool(action.get("dash", false)) and dash_available:
		dash_left = DASH_TICKS
		dash_available = false
		dash_direction = facing

	if dash_left > 0:
		vx = DASH_SPEED * move_input
		vy = 0
		dash_left -= 1
	else:
		vx = RUN_SPEED * move_input
		vy = mini(MAX_FALL, vy + GRAVITY)

	_move_x(vx, world, next_world_tick)
	var moving_down := vy >= 0
	var hit_y := _move_y(vy, world, next_world_tick)
	on_ground = moving_down and hit_y
	support_platform = world.support_platform(body_rect(), next_world_tick) if on_ground else -1
	if on_ground:
		dash_available = true

	if world.collides_solid(body_rect(), next_world_tick):
		crushed = true
	tick = next_world_tick


func canonical_state() -> Dictionary:
	return {
		"tick": tick,
		"x": x,
		"y": y,
		"vx": vx,
		"vy": vy,
		"facing": facing,
		"on_ground": on_ground,
		"support_platform": support_platform,
		"coyote_left": coyote_left,
		"jump_buffer_left": jump_buffer_left,
		"dash_left": dash_left,
		"dash_direction": dash_direction,
		"dash_available": dash_available,
		"crushed": crushed,
	}


func state_hash() -> String:
	return JSON.stringify(canonical_state()).sha256_text()
