class_name ChronoSimulation
extends RefCounted

var tick := 0
var players := {
	"p1": {"x": 0, "hp": 100, "energy": 0, "cooldown": 0},
	"p2": {"x": 10, "hp": 100, "energy": 0, "cooldown": 0},
}
var projectiles: Array[Dictionary] = []
var pickups := {
	"left_core": {"x": 3, "claimed_by": ""},
	"right_core": {"x": 7, "claimed_by": ""},
}
var score := {"p1": 0, "p2": 0}
var rng_state := 0x13579B
var next_entity_id := 1


func _next_random() -> int:
	rng_state = int((rng_state * 1103515245 + 12345) & 0x7fffffff)
	return rng_state


func _input_for(frame_inputs: Dictionary, player_id: String) -> Dictionary:
	return frame_inputs.get(player_id, {"move": 0, "fire": false})


func step(frame_inputs: Dictionary) -> void:
	var player_ids := players.keys()
	player_ids.sort()
	for player_id in player_ids:
		var player: Dictionary = players[player_id]
		var action := _input_for(frame_inputs, player_id)
		player.x = clampi(int(player.x) + clampi(int(action.get("move", 0)), -1, 1), 0, 10)
		if int(player.cooldown) > 0:
			player.cooldown = int(player.cooldown) - 1
		if bool(action.get("fire", false)) and int(player.cooldown) == 0:
			projectiles.append({
				"id": next_entity_id,
				"owner": player_id,
				"x": int(player.x),
				"direction": 1 if player_id == "p1" else -1,
				"damage": 8 + (_next_random() % 5),
			})
			next_entity_id += 1
			player.cooldown = 3

	for projectile in projectiles:
		projectile.x = int(projectile.x) + int(projectile.direction) * 2

	var survivors: Array[Dictionary] = []
	for projectile in projectiles:
		var target_id := "p2" if projectile.owner == "p1" else "p1"
		var target: Dictionary = players[target_id]
		var passed_target := (
			int(projectile.direction) > 0 and int(projectile.x) >= int(target.x)
		) or (
			int(projectile.direction) < 0 and int(projectile.x) <= int(target.x)
		)
		if passed_target:
			target.hp = maxi(0, int(target.hp) - int(projectile.damage))
			score[projectile.owner] = int(score[projectile.owner]) + int(projectile.damage)
		elif int(projectile.x) >= -2 and int(projectile.x) <= 12:
			survivors.append(projectile)
	projectiles = survivors

	for pickup_id in pickups:
		var pickup: Dictionary = pickups[pickup_id]
		if String(pickup.claimed_by).is_empty():
			for player_id in player_ids:
				var player: Dictionary = players[player_id]
				if int(player.x) == int(pickup.x):
					pickup.claimed_by = player_id
					player.energy = int(player.energy) + 1
					score[player_id] = int(score[player_id]) + 20
					break

	tick += 1


func capture() -> Dictionary:
	# Rollback snapshots must not share nested state with the live simulation.
	return {
		"tick": tick,
		"players": players.duplicate(),
		"projectiles": projectiles.duplicate(),
		"pickups": pickups.duplicate(),
		"score": score.duplicate(),
	}


func restore(snapshot: Dictionary) -> void:
	tick = int(snapshot.tick)
	players = snapshot.players.duplicate()
	projectiles.assign(snapshot.projectiles.duplicate())
	pickups = snapshot.pickups.duplicate()
	score = snapshot.score.duplicate()


func canonical_state() -> Dictionary:
	var ordered_projectiles := projectiles.duplicate(true)
	ordered_projectiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.id) < int(b.id))
	return {
		"tick": tick,
		"players": players.duplicate(true),
		"projectiles": ordered_projectiles,
		"pickups": pickups.duplicate(true),
		"score": score.duplicate(true),
		"rng_state": rng_state,
		"next_entity_id": next_entity_id,
	}


func state_hash() -> String:
	return JSON.stringify(canonical_state()).sha256_text()
