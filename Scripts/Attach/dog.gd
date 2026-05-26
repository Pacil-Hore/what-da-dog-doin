extends CharacterBody2D

# === Field boundaries ===
@export var field_min_x: float = 50.0
@export var field_max_x: float = 1100.0
@export var field_min_y: float = -450.0
@export var field_max_y: float = 50.0

# === Movement settings ===
@export var speed: float = 200.0
@export var target_reach_threshold: float = 20.0
@export var rest_time_at_target: float = 0.3
@export var min_target_distance: float = 100.0

# === Rotation settings ===
@export var rotation_speed: float = 5.0  # tinggi = belok cepat, rendah = belok lambat
@export var sprite_default_facing: float = 0.0  # angle default sprite (0 = kanan)

# === Debug visualization ===
@export var show_debug_visuals: bool = true

# === State ===
var target_position: Vector2
var is_resting: bool = false
var rest_timer: float = 0.0

func _ready():
	_pick_new_target()

func _physics_process(delta):
	if is_resting:
		rest_timer -= delta
		velocity = Vector2.ZERO
		if rest_timer <= 0:
			is_resting = false
			_pick_new_target()
	else:
		# Gerak menuju target
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Rotate body smoothly ke arah target
		_smooth_rotate_to_direction(direction, delta)
		
		if global_position.distance_to(target_position) < target_reach_threshold:
			is_resting = true
			rest_timer = rest_time_at_target
	
	if show_debug_visuals:
		queue_redraw()

func _smooth_rotate_to_direction(dir: Vector2, delta: float):
	if dir.length() < 0.1:
		return  # gak gerak, gak perlu rotate
	
	# Angle target = arah gerak
	# Adjust dengan default facing sprite (kalau sprite default-nya bukan kanan)
	var target_angle = dir.angle() - sprite_default_facing
	
	# Smooth rotate pakai lerp_angle
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

func _pick_new_target():
	var attempts = 0
	var new_target: Vector2
	
	while attempts < 10:
		new_target = Vector2(
			randf_range(field_min_x, field_max_x),
			randf_range(field_min_y, field_max_y)
		)
		if global_position.distance_to(new_target) >= min_target_distance:
			break
		attempts += 1
	
	target_position = new_target

# === Debug visualization ===
func _draw():
	if not show_debug_visuals:
		return
	
	var field_color = Color(1, 1, 0, 0.5)
	var corners_global = [
		Vector2(field_min_x, field_min_y),
		Vector2(field_max_x, field_min_y),
		Vector2(field_max_x, field_max_y),
		Vector2(field_min_x, field_max_y),
	]
	var corners_local = []
	for corner in corners_global:
		corners_local.append(to_local(corner))
	
	for i in range(4):
		draw_line(corners_local[i], corners_local[(i + 1) % 4], field_color, 2.0)
	
	var target_local = to_local(target_position)
	draw_circle(target_local, 15, Color(1, 0, 0, 0.7))
	draw_arc(target_local, 15, 0, TAU, 32, Color.RED, 2.0)
	draw_line(Vector2.ZERO, target_local, Color(1, 0, 0, 0.4), 1.5)
