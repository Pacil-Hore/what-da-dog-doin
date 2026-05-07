extends Node2D
class_name Rope

@export var entity_a: CharacterBody2D # player
@export var entity_b: CharacterBody2D # dog
@export var max_steps: int = 3
@export var step_size: float = 162.0

@onready var line: Line2D = $Line2D

func _process(_delta):
	if not entity_a or not entity_b:
		return
	
	# Update visual line antara 2 entity
	line.clear_points()
	line.add_point(line.to_local(entity_a.global_position))
	line.add_point(line.to_local(entity_b.global_position))
	
	# Cek jarak (cuma kalau dua-duanya gak lagi gerak)
	if not entity_a.is_moving and not entity_b.is_moving:
		_check_constraint()

func _check_constraint():
	var distance = entity_a.global_position.distance_to(entity_b.global_position)
	var max_distance = step_size * max_steps
	
	if distance > max_distance:
		print("Tali putus! Game over")
		# Nanti tambahin logic game over
