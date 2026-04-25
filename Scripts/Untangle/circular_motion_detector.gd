extends Node

signal rotation_completed(total_rotations: int)
signal progress_changed(progress: float)

@export var min_radius := 48.0
@export var max_radius := 260.0
@export var min_angle_delta := 0.01
@export var direction_change_grace := 0.45
@export var radius_exit_grace := 0.12

var is_enabled := true
var completed_rotations := 0
var accumulated_angle := 0.0
var previous_angle := 0.0
var has_previous_sample := false
var rotation_direction := 0.0
var reverse_angle := 0.0
var radius_exit_time := 0.0


func reset() -> void:
	completed_rotations = 0
	accumulated_angle = 0.0
	previous_angle = 0.0
	has_previous_sample = false
	rotation_direction = 0.0
	reverse_angle = 0.0
	radius_exit_time = 0.0
	progress_changed.emit(0.0)


func set_motion_enabled(value: bool) -> void:
	is_enabled = value
	if not is_enabled:
		has_previous_sample = false


func sample(pointer_position: Vector2, center_position: Vector2, delta: float) -> void:
	if not is_enabled:
		return

	var offset := pointer_position - center_position
	var radius := offset.length()
	if radius < min_radius or radius > max_radius:
		radius_exit_time += delta
		if radius_exit_time >= radius_exit_grace:
			has_previous_sample = false
		return
	radius_exit_time = 0.0

	var angle := offset.angle()
	if not has_previous_sample:
		previous_angle = angle
		has_previous_sample = true
		return

	var angle_delta := wrapf(angle - previous_angle, -PI, PI)
	previous_angle = angle

	if absf(angle_delta) < min_angle_delta:
		return

	var delta_direction := signf(angle_delta)
	if rotation_direction == 0.0:
		rotation_direction = delta_direction
	elif delta_direction != rotation_direction:
		reverse_angle += absf(angle_delta)
		if reverse_angle >= direction_change_grace:
			accumulated_angle = 0.0
			rotation_direction = delta_direction
			reverse_angle = 0.0
			progress_changed.emit(0.0)
		return
	else:
		reverse_angle = 0.0

	accumulated_angle += angle_delta
	progress_changed.emit(get_rotation_progress())

	if absf(accumulated_angle) >= TAU:
		completed_rotations += 1
		accumulated_angle = fmod(absf(accumulated_angle), TAU) * rotation_direction
		rotation_completed.emit(completed_rotations)
		progress_changed.emit(get_rotation_progress())


func get_rotation_progress() -> float:
	return clampf(absf(accumulated_angle) / TAU, 0.0, 1.0)
