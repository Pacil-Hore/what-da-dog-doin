extends CharacterBody2D
class_name PlayerMouse

@export var enabled := true
@export var cursor_radius := 6.0
@export var cursor_color := Color(1.0, 1.0, 1.0, 1.0)
@export var cursor_outline_color := Color(0.08, 0.09, 0.12, 1.0)

var movement_bounds := Rect2()
var has_movement_bounds := false


func _ready() -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not enabled:
		return

	var target_position := get_global_mouse_position()
	if has_movement_bounds:
		target_position = _clamp_to_bounds(target_position)

	var motion := target_position - global_position
	if motion.length_squared() == 0.0:
		return

	velocity = motion / delta
	move_and_slide()

	if has_movement_bounds:
		global_position = _clamp_to_bounds(global_position)


func _draw() -> void:
	draw_circle(Vector2.ZERO, cursor_radius + 2.0, cursor_outline_color)
	draw_circle(Vector2.ZERO, cursor_radius, cursor_color)


func _clamp_to_bounds(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(point.y, movement_bounds.position.y, movement_bounds.end.y)
	)
