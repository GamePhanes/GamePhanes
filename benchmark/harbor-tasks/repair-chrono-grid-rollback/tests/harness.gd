extends SceneTree

const Session = preload("res://scripts/rollback_session.gd")

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
		print("FAIL ", message)


func packet(id: String, frame_tick: int, player: String, sequence: int, move: int, fire: bool) -> Dictionary:
	return {
		"id": id,
		"tick": frame_tick,
		"player": player,
		"seq": sequence,
		"action": {"move": move, "fire": fire},
	}


func action_for(seed: int, frame_tick: int, player_index: int) -> Dictionary:
	var mixed := seed + frame_tick * 17 + player_index * 31
	return {
		"move": [-1, 0, 1][abs(mixed) % 3],
		"fire": (frame_tick == 0 and player_index == 0) or abs(mixed * 7 + frame_tick) % 4 == 0,
	}


func make_packets(seed: int, count: int) -> Array[Dictionary]:
	var packets: Array[Dictionary] = []
	for frame_tick in count:
		for player_index in 2:
			var player_id := "p%d" % (player_index + 1)
			var action := action_for(seed, frame_tick, player_index)
			packets.append(packet(
				"%d-%d-%s" % [seed, frame_tick, player_id],
				frame_tick,
				player_id,
				1,
				int(action.move),
				bool(action.fire),
			))
	return packets


func run_on_time(packets: Array[Dictionary], count: int, history := 8) -> Variant:
	var session = Session.new(history)
	for frame_tick in count:
		for value in packets:
			if int(value.tick) == frame_tick:
				session.submit(value)
		session.advance()
	return session


func test_normal_execution() -> void:
	var packets := make_packets(11, 12)
	var session = run_on_time(packets, 12)
	check(session.simulation.tick == 12, "normal run advances every frame")
	check(session.simulation.next_entity_id > 1, "normal run creates projectiles")
	check(session.snapshot_ticks.size() <= session.max_history, "snapshot history is bounded")
	check(session.simulation.players.p1.hp >= 0 and session.simulation.players.p2.hp >= 0, "combat state remains valid")


func test_late_packets_match_on_time(seed: int, delayed_tick: int, delayed_player: String) -> void:
	var count := 14
	var packets := make_packets(seed, count)
	var baseline = run_on_time(packets, count, 16)
	var delayed = Session.new(16)
	var held: Dictionary
	for frame_tick in count:
		for value in packets:
			if int(value.tick) != frame_tick:
				continue
			if frame_tick == delayed_tick and String(value.player) == delayed_player:
				held = value
			else:
				delayed.submit(value)
		delayed.advance()
		if frame_tick == delayed_tick + 5:
			check(delayed.submit(held), "late packet inside history is accepted")
	check(
		delayed.simulation.canonical_state() == baseline.simulation.canonical_state(),
		"late packet replay matches on-time state for seed %d" % seed,
	)


func test_correction_replay() -> void:
	var count := 13
	var packets := make_packets(29, count)
	var corrected: Array[Dictionary] = []
	for value in packets:
		if int(value.tick) == 3 and String(value.player) == "p1":
			corrected.append(packet("correct-final", 3, "p1", 2, -1, true))
		else:
			corrected.append(value)
	var baseline = run_on_time(corrected, count, 16)
	var late = Session.new(16)
	for frame_tick in count:
		for value in packets:
			if int(value.tick) == frame_tick:
				late.submit(value)
		late.advance()
		if frame_tick == 9:
			check(late.submit(packet("correct-final", 3, "p1", 2, -1, true)), "newer correction is accepted")
	check(late.simulation.canonical_state() == baseline.simulation.canonical_state(), "corrected past input replays deterministically")


func test_idempotency_and_rejection() -> void:
	var session = Session.new(4)
	var first := packet("duplicate", 0, "p1", 1, 1, true)
	check(session.submit(first), "first packet is accepted")
	check(session.submit(first), "duplicate packet is idempotently accepted")
	for frame_tick in 10:
		if frame_tick > 0:
			session.submit(packet("future-%d" % frame_tick, frame_tick, "p2", 1, -1, frame_tick % 3 == 0))
		session.advance()
	var before_state: String = session.simulation.state_hash()
	var before_inputs: String = session.debug_input_hash()
	var before_seen: int = session.seen_packet_ids.size()
	check(not session.submit(packet("too-old", 0, "p2", 5, 1, true)), "input older than retained history is rejected")
	check(session.simulation.state_hash() == before_state, "rejected old input does not mutate simulation")
	check(session.debug_input_hash() == before_inputs, "rejected old input does not mutate input buffer")
	check(session.seen_packet_ids.size() == before_seen, "rejected old input does not mutate dedupe state")


func test_snapshot_immutability() -> void:
	var session = Session.new(10)
	for frame_tick in 4:
		session.submit(packet("immutable-%d" % frame_tick, frame_tick, "p1", 1, 1, frame_tick % 2 == 0))
		session.advance()
	var saved_hash := session.debug_snapshot_hash(1)
	for frame_tick in range(4, 8):
		session.submit(packet("mutate-%d" % frame_tick, frame_tick, "p2", 1, -1, true))
		session.advance()
	check(not saved_hash.is_empty(), "historical snapshot exists")
	check(session.debug_snapshot_hash(1) == saved_hash, "historical snapshot remains immutable")


func _initialize() -> void:
	test_normal_execution()
	test_late_packets_match_on_time(7, 2, "p2")
	test_late_packets_match_on_time(43, 5, "p1")
	test_correction_replay()
	test_idempotency_and_rejection()
	test_snapshot_immutability()
	if failures.is_empty():
		print("CHRONO_GRID_TESTS_PASSED")
		quit(0)
	else:
		print("CHRONO_GRID_TESTS_FAILED count=", failures.size())
		for failure in failures:
			print(" - ", failure)
		quit(1)
