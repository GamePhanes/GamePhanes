#!/usr/bin/env bash
set -euo pipefail

cat > /app/scripts/controller.gd <<'EOF'
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


func _move_x(amount: int, world, world_tick: int, excluded_platform := -1) -> bool:
	var direction := signi(amount)
	for unused in absi(amount):
		var candidate := body_rect(x + direction, y)
		if world.collides_solid(candidate, world_tick, excluded_platform):
			vx = 0
			return true
		x += direction
	return false


func _blocks_downward_step(before: Dictionary, after: Dictionary, world) -> bool:
	var old_bottom := int(before.y) + int(before.h)
	var new_bottom := int(after.y) + int(after.h)
	for platform in world.one_way_platforms:
		var top := int(platform.y)
		var horizontal_overlap := int(after.x) < int(platform.x) + int(platform.w) \
			and int(after.x) + int(after.w) > int(platform.x)
		if horizontal_overlap and old_bottom <= top and new_bottom > top:
			return true
	return false


func _move_y(amount: int, world, world_tick: int, excluded_platform := -1) -> bool:
	var direction := signi(amount)
	for unused in absi(amount):
		var before := body_rect()
		var candidate := body_rect(x, y + direction)
		var blocked: bool = world.collides_solid(candidate, world_tick, excluded_platform)
		if direction > 0 and _blocks_downward_step(before, candidate, world):
			blocked = true
		if blocked:
			vy = 0
			return true
		y += direction
	return false


func _consume_buffered_jump() -> bool:
	if jump_buffer_left <= 0 or (not on_ground and coyote_left <= 0):
		return false
	vy = JUMP_SPEED
	on_ground = false
	support_platform = -1
	coyote_left = 0
	jump_buffer_left = 0
	return true


func _apply_platform_carry(world, next_world_tick: int) -> void:
	if support_platform < 0 or world.support_platform(body_rect(), tick) != support_platform:
		return
	var carried_by := support_platform
	var motion: Dictionary = world.platform_motion(carried_by, tick)
	_move_x(int(motion.x), world, next_world_tick, carried_by)
	_move_y(int(motion.y), world, next_world_tick, carried_by)
	if world.collides_solid(body_rect(), next_world_tick):
		crushed = true


func step(action: Dictionary, world) -> void:
	if crushed:
		tick += 1
		return

	var next_world_tick := tick + 1
	_apply_platform_carry(world, next_world_tick)
	if crushed:
		tick = next_world_tick
		return

	var grounded_at_start: bool = world.has_support(body_rect(), next_world_tick)
	on_ground = grounded_at_start
	support_platform = world.support_platform(body_rect(), next_world_tick) if on_ground else -1
	if grounded_at_start:
		coyote_left = COYOTE_TICKS

	var move_input := clampi(int(action.get("move", 0)), -1, 1)
	if move_input != 0:
		facing = move_input
	if bool(action.get("jump", false)):
		jump_buffer_left = JUMP_BUFFER_TICKS
	var jumped := _consume_buffered_jump()

	if bool(action.get("dash", false)) and dash_available:
		dash_left = DASH_TICKS
		dash_available = false
		dash_direction = facing

	if dash_left > 0:
		vx = DASH_SPEED * dash_direction
		vy = 0
		dash_left -= 1
	else:
		vx = RUN_SPEED * move_input
		if not jumped:
			vy = mini(MAX_FALL, vy + GRAVITY)

	_move_x(vx, world, next_world_tick)
	_move_y(vy, world, next_world_tick)
	var grounded_at_end: bool = world.has_support(body_rect(), next_world_tick) and vy >= 0
	if grounded_at_end:
		vy = 0
		on_ground = true
		support_platform = world.support_platform(body_rect(), next_world_tick)
		if not grounded_at_start:
			dash_available = true
			coyote_left = COYOTE_TICKS
		if not jumped:
			jumped = _consume_buffered_jump()
	else:
		on_ground = false
		support_platform = -1

	if not jumped and not grounded_at_start and not grounded_at_end:
		coyote_left = maxi(0, coyote_left - 1)
	if not jumped and jump_buffer_left > 0:
		jump_buffer_left -= 1
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
EOF
