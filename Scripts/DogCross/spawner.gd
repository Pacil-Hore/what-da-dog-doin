# Spawner.gd
extends Node2D

@export var scene_to_spawn: PackedScene  # drag scene di Inspector
@export var spawn_interval := 2.0

func _ready() -> void:
	$Timer.wait_time = spawn_interval
	$Timer.start()

func _on_timer_timeout() -> void:
	if scene_to_spawn == null:
		return
	
	var instance = scene_to_spawn.instantiate()
	instance.position = global_position  # spawn di posisi spawner
	instance.z_index = -1 
	get_parent().add_child(instance)     # tambah ke scene tree
