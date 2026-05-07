extends CharacterBody2D
class_name PlayerMouse

@export var enabled := true
@export var collision_radius := 5.0
@export var max_speed := 1500.0 # Limit speed to prevent tunneling through walls
@export var visual_path: NodePath = ^"Sprite2D"
@export var visual_rotation_offset := PI / 2.0

var movement_bounds := Rect2()
var has_movement_bounds := false

@onready var visual: Node2D = get_node_or_null(visual_path)

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if not enabled:
		return

	var target_position := get_global_mouse_position()
	if has_movement_bounds:
		target_position = _clamp_to_bounds(target_position)

	var diff := target_position - global_position
	if visual != null and diff.length_squared() > 1.0:
		visual.rotation = diff.angle() + visual_rotation_offset
	
	# Proportional movement: speed depends on distance to mouse
	# This feels more natural and less like "teleporting"
	var speed_factor = 30.0 
	var desired_velocity = diff * speed_factor
	
	# Limit velocity to prevent tunneling
	velocity = desired_velocity.limit_length(max_speed)
	
	move_and_slide()

	# Secondary clamp to ensure physics didn't push us out of bounds
	if has_movement_bounds:
		global_position = _clamp_to_bounds(global_position)


func _clamp_to_bounds(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(point.y, movement_bounds.position.y, movement_bounds.end.y)
	)
