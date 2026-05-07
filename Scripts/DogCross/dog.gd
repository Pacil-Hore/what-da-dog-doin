extends CharacterBody2D

@export var move_action: String = "ui_right"
@export var step_distance: float = 162.0
@export var hop_duration: float = 0.15

var is_moving: bool = false
var current_platform: Node = null

func _input(event):
	if is_moving:
		return
	if event.is_action_pressed(move_action):
		try_hop_forward()

func try_hop_forward():
	# Hitung target position (maju = ke atas)
	var target_pos = global_position
	target_pos.y -= step_distance
	hop_to(target_pos)

func hop_to(target: Vector2):
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, hop_duration)
	tween.tween_callback(_on_hop_finished)

func _on_hop_finished():
	is_moving = false
