class_name KineticWorld
extends RefCounted

var solids: Array[Dictionary] = []
var one_way_platforms: Array[Dictionary] = []
var moving_platforms: Array[Dictionary] = []


func _init(static_solids: Array = [], one_ways: Array = [], movers: Array = []) -> void:
	for value in static_solids:
		solids.append(value.duplicate(true))
	for value in one_ways:
		one_way_platforms.append(value.duplicate(true))
	for value in movers:
		moving_platforms.append(value.duplicate(true))


func overlaps(a: Dictionary, b: Dictionary) -> bool:
	return int(a.x) < int(b.x) + int(b.w) and int(a.x) + int(a.w) > int(b.x) \
		and int(a.y) < int(b.y) + int(b.h) and int(a.y) + int(a.h) > int(b.y)


func _phase(frame_tick: int, period: int) -> int:
	var span := maxi(1, period)
	var value := posmod(frame_tick, span * 2)
	return value if value <= span else span * 2 - value


func platform_rect(index: int, frame_tick: int) -> Dictionary:
	var source: Dictionary = moving_platforms[index]
	var phase := _phase(frame_tick, int(source.get("period", 1)))
	return {
		"x": int(source.x) + int(source.get("dx", 0)) * phase,
		"y": int(source.y) + int(source.get("dy", 0)) * phase,
		"w": int(source.w),
		"h": int(source.h),
		"platform_id": index,
	}


func platform_motion(index: int, frame_tick: int) -> Dictionary:
	var before := platform_rect(index, frame_tick)
	var after := platform_rect(index, frame_tick + 1)
	return {"x": int(after.x) - int(before.x), "y": int(after.y) - int(before.y)}


func solid_rects(frame_tick: int, excluded_platform := -1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in solids:
		result.append(value)
	for index in moving_platforms.size():
		if index != excluded_platform:
			result.append(platform_rect(index, frame_tick))
	return result


func collides_solid(rect: Dictionary, frame_tick: int, excluded_platform := -1) -> bool:
	for obstacle in solid_rects(frame_tick, excluded_platform):
		if overlaps(rect, obstacle):
			return true
	return false


func support_platform(rect: Dictionary, frame_tick: int) -> int:
	var bottom := int(rect.y) + int(rect.h)
	for index in moving_platforms.size():
		var platform := platform_rect(index, frame_tick)
		if bottom == int(platform.y) and int(rect.x) < int(platform.x) + int(platform.w) \
				and int(rect.x) + int(rect.w) > int(platform.x):
			return index
	return -1


func has_support(rect: Dictionary, frame_tick: int) -> bool:
	var probe := rect.duplicate(true)
	probe.y = int(probe.y) + 1
	if collides_solid(probe, frame_tick):
		return true
	var bottom := int(rect.y) + int(rect.h)
	for platform in one_way_platforms:
		if bottom == int(platform.y) and int(rect.x) < int(platform.x) + int(platform.w) \
				and int(rect.x) + int(rect.w) > int(platform.x):
			return true
	return false
