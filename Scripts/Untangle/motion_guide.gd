@tool
extends Node2D

@export var min_radius := 48.0:
	set(value):
		min_radius = value
		queue_redraw()
@export var max_radius := 260.0:
	set(value):
		max_radius = value
		queue_redraw()
@export var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func set_progress(value: float) -> void:
	progress = value


func _draw() -> void:
	var target_radius: float = (min_radius + max_radius) * 0.5
	draw_circle(Vector2.ZERO, max_radius, Color(0.06, 0.08, 0.1, 0.22))
	draw_circle(Vector2.ZERO, min_radius, Color(0.12, 0.15, 0.17, 0.5))
	draw_arc(Vector2.ZERO, target_radius, 0.0, TAU, 128, Color(0.86, 0.92, 0.95, 0.28), 4.0)
	draw_arc(Vector2.ZERO, min_radius, 0.0, TAU, 128, Color(0.86, 0.92, 0.95, 0.14), 2.0)
	draw_arc(Vector2.ZERO, max_radius, 0.0, TAU, 128, Color(0.86, 0.92, 0.95, 0.14), 2.0)

	for index in range(24):
		var angle: float = float(index) * TAU / 24.0
		var direction := Vector2(cos(angle), sin(angle))
		var tick_length: float = 16.0 if index % 4 == 0 else 8.0
		var tick_color: Color = Color(0.86, 0.92, 0.95, 0.35) if index % 4 == 0 else Color(0.86, 0.92, 0.95, 0.18)
		draw_line(direction * (target_radius - tick_length), direction * (target_radius + tick_length), tick_color, 2.0)

	for index in range(3):
		var angle: float = -PI * 0.5 + float(index) * TAU / 3.0
		_draw_arrow(angle, target_radius, Color(0.36, 0.84, 1.0, 0.32))

	if progress <= 0.0:
		return

	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + TAU * progress
	draw_arc(Vector2.ZERO, target_radius, start_angle, end_angle, 128, Color(0.36, 0.84, 1.0, 0.95), 10.0)
	var head_position := Vector2(cos(end_angle), sin(end_angle)) * target_radius
	draw_circle(head_position, 8.0, Color(0.8, 0.96, 1.0, 1.0))
	draw_circle(head_position, 4.0, Color(0.12, 0.25, 0.3, 1.0))


func _draw_arrow(angle: float, radius: float, color: Color) -> void:
	var direction := Vector2(cos(angle), sin(angle))
	var tangent := Vector2(-direction.y, direction.x)
	var center := direction * radius
	var points := PackedVector2Array([
		center + tangent * 16.0,
		center - tangent * 10.0 + direction * 9.0,
		center - tangent * 10.0 - direction * 9.0,
	])
	draw_colored_polygon(points, color)
