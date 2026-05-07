extends Node2D

signal game_won
signal game_lost

func _ready():
	print("Placeholder Game Started: ", name)
	# Win after 2 seconds by default
	await get_tree().create_timer(2.0).timeout
	emit_signal("game_won")
