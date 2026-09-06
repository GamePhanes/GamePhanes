extends Node

const World = preload("res://scripts/world.gd")
const Controller = preload("res://scripts/controller.gd")


func _ready() -> void:
	var world = World.new([
		{"x": -40, "y": 40, "w": 160, "h": 8},
		{"x": 72, "y": 8, "w": 8, "h": 32},
	])
	var player = Controller.new(0, 28)
	for frame_tick in 12:
		player.step({"move": 1, "jump": frame_tick == 2, "dash": frame_tick == 7}, world)
	print("KINETIC_VAULT_READY ", player.state_hash())
	get_tree().quit()
