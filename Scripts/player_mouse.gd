extends CharacterBody2D
class_name PlayerMouse

@export var enabled := true
@export var collision_radius := 5.0
@export var max_speed := 800.0 # Limit speed to prevent tunneling through walls
@export var visual_path: NodePath = ^"Sprite2D"
@export var visual_rotation_offset := PI / 2.0

var movement_bounds := Rect2()
var has_movement_bounds := false
var dust_emitter: CPUParticles2D

@onready var visual: Node2D = get_node_or_null(visual_path)

func _ready() -> void:
	wall_min_slide_angle = 0.01
	safe_margin = 0.02
	# Add dust emitter programmatically

	dust_emitter = CPUParticles2D.new()
	dust_emitter.amount = 10
	dust_emitter.lifetime = 0.3
	dust_emitter.gravity = Vector2.ZERO
	dust_emitter.initial_velocity_min = 5.0
	dust_emitter.initial_velocity_max = 15.0
	dust_emitter.spread = 180.0
	dust_emitter.scale_amount_min = 1.0
	dust_emitter.scale_amount_max = 3.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.85, 0.8, 0.75, 0.4))
	gradient.set_color(1, Color(0.85, 0.8, 0.75, 0.0))
	dust_emitter.color_ramp = gradient
	
	dust_emitter.emitting = false
	dust_emitter.show_behind_parent = true
	add_child(dust_emitter)

func _physics_process(_delta: float) -> void:
	if not enabled:
		if dust_emitter != null:
			dust_emitter.emitting = false
		return

	var target_position := get_global_mouse_position()
	if has_movement_bounds:
		target_position = _clamp_to_bounds(target_position)

	var diff := target_position - global_position
	if visual != null and diff.length_squared() > 1.0:
		visual.rotation = diff.angle() + visual_rotation_offset
	
	# Proportional movement: speed depends on distance to mouse
	var speed_factor = 30.0 
	var desired_velocity = diff * speed_factor
	
	# Apply weight tension / drag if man is far behind and pulling away
	var speed_scale := 1.0
	var tension := 0.0
	var man = get_parent().get_node_or_null("ManSprite")
	if man:
		var dist = global_position.distance_to(man.global_position)
		if dist > 62.0:
			var pull_dir = (global_position - man.global_position).normalized()
			if desired_velocity.dot(pull_dir) > 0.0:
				tension = clampf((dist - 62.0) / 18.0, 0.0, 1.0)
				speed_scale = lerpf(1.0, 0.45, tension)
	
	# Micro-shake sprite under high tension
	if visual != null:
		if tension > 0.6:
			var jitter_amount = (tension - 0.6) * 5.0 # Up to 2.0 pixels
			visual.position = Vector2(randf_range(-jitter_amount, jitter_amount), randf_range(-jitter_amount, jitter_amount))
		else:
			visual.position = Vector2.ZERO
	
	# Limit velocity to prevent tunneling
	velocity = (desired_velocity * speed_scale).limit_length(max_speed)
	
	if is_on_wall():
		var normal := get_wall_normal()
		if velocity.dot(normal) < 0.0:
			velocity = velocity.slide(normal)
	
	move_and_slide()

	# Emit dust particles when moving
	if dust_emitter != null:
		dust_emitter.emitting = velocity.length() > 30.0

	# Secondary clamp to ensure physics didn't push us out of bounds
	# (Disabled: manually modifying global_position after move_and_slide() overrides the physics solver and causes sticking against wall/tilemap colliders)
	pass


func _clamp_to_bounds(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(point.y, movement_bounds.position.y, movement_bounds.end.y)
	)
