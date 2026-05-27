extends CharacterBody2D

@export var move_action: String = "ui_right"
@export var step_distance: float = 162.0
@export var hop_duration: float = 0.15

var is_moving: bool = false
var current_platform = null
var is_on_safe_area: bool = false
var is_alive: bool = true

signal fell_in_water

func _input(event):
	if not is_alive or is_moving:
		return
	if event.is_action_pressed(move_action):
		try_hop_forward()

func try_hop_forward():
	var target_pos = global_position
	target_pos.y -= step_distance
	
	# Lepas dari platform sekarang
	if current_platform:
		current_platform.remove_occupant(self)
		current_platform = null
	
	hop_to(target_pos)
	
func hop_to(target: Vector2):
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, hop_duration)
	tween.tween_callback(_on_hop_finished)

func _on_hop_finished():
	is_moving = false
	# Tunggu 1 frame biar Area2D sempat detect
	await get_tree().process_frame
	# Cek apakah mendarat di tempat aman
	if current_platform == null and not is_on_safe_area:
		fall_in_water()

func fall_in_water():
	if not is_alive:
		return  # udah mati, jangan double trigger
	is_alive = false
	fell_in_water.emit()
	
	# Animasi jatuh
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 0.5)
