extends Node

const Session = preload("res://scripts/rollback_session.gd")


func packet(id: String, tick: int, player: String, move: int, fire: bool) -> Dictionary:
	return {
		"id": id,
		"tick": tick,
		"player": player,
		"seq": 1,
		"action": {"move": move, "fire": fire},
	}


func _ready() -> void:
	var session = Session.new()
	for frame_tick in 6:
		session.submit(packet("p1-%d" % frame_tick, frame_tick, "p1", 1, frame_tick % 3 == 0))
		session.submit(packet("p2-%d" % frame_tick, frame_tick, "p2", -1, frame_tick % 4 == 0))
		session.advance()
	print("CHRONO_GRID_READY ", session.simulation.state_hash())
	get_tree().quit()
