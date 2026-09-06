class_name RollbackSession
extends RefCounted

const Simulation = preload("res://scripts/simulation.gd")

var simulation = Simulation.new()
var input_frames: Dictionary = {}
var seen_packet_ids: Dictionary = {}
var snapshots: Dictionary = {}
var snapshot_ticks: Array[int] = []
var max_history := 8


func _init(history_limit := 8) -> void:
	max_history = maxi(2, history_limit)


func _frame(tick: int) -> Dictionary:
	if not input_frames.has(tick):
		input_frames[tick] = {}
	return input_frames[tick]


func _oldest_retained_tick() -> int:
	if snapshot_ticks.is_empty():
		return simulation.tick
	return snapshot_ticks[0]


func submit(packet: Dictionary) -> bool:
	var packet_id := String(packet.get("id", ""))
	var packet_tick := int(packet.get("tick", -1))
	var player_id := String(packet.get("player", ""))
	var sequence := int(packet.get("seq", -1))
	if packet_id.is_empty() or packet_tick < 0 or not simulation.players.has(player_id):
		return false
	if seen_packet_ids.has(packet_id):
		return true

	seen_packet_ids[packet_id] = true
	var frame := _frame(packet_tick)
	var existing: Dictionary = frame.get(player_id, {})
	if not existing.is_empty() and sequence <= simulation.tick:
		return true
	frame[player_id] = {
		"seq": sequence,
		"action": packet.get("action", {}).duplicate(true),
	}

	if packet_tick < _oldest_retained_tick():
		return false
	if packet_tick < simulation.tick:
		_rollback_from(packet_tick)
	return true


func _actions_for_tick(frame_tick: int) -> Dictionary:
	var actions := {}
	var frame: Dictionary = input_frames.get(frame_tick, {})
	for player_id in frame:
		actions[player_id] = frame[player_id].action.duplicate(true)
	return actions


func _capture_snapshot() -> void:
	var frame_tick: int = int(simulation.tick)
	snapshots[frame_tick] = simulation.capture()
	if not snapshot_ticks.has(frame_tick):
		snapshot_ticks.append(frame_tick)
		snapshot_ticks.sort()
	while snapshot_ticks.size() > max_history:
		var expired: int = snapshot_ticks.pop_front()
		snapshots.erase(expired)


func advance() -> void:
	_capture_snapshot()
	simulation.step(_actions_for_tick(simulation.tick))


func _discard_snapshots_from(frame_tick: int) -> void:
	for saved_tick in snapshot_ticks.duplicate():
		if saved_tick >= frame_tick:
			snapshots.erase(saved_tick)
			snapshot_ticks.erase(saved_tick)


func _rollback_from(frame_tick: int) -> void:
	if not snapshots.has(frame_tick):
		return
	var target_tick: int = int(simulation.tick)
	simulation.restore(snapshots[frame_tick])
	_discard_snapshots_from(frame_tick + 1)
	while simulation.tick < target_tick - 1:
		_capture_snapshot()
		simulation.step(_actions_for_tick(simulation.tick))


func debug_snapshot_hash(frame_tick: int) -> String:
	if not snapshots.has(frame_tick):
		return ""
	return JSON.stringify(snapshots[frame_tick]).sha256_text()


func debug_input_hash() -> String:
	return JSON.stringify(input_frames).sha256_text()
