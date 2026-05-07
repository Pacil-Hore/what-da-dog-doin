@tool
extends Node2D

@export_enum("Tangled", "Loosened", "Untangled") var visual_state := 0:
	set(value):
		visual_state = value
		queue_redraw()
@export var accent_color := Color(0.95, 0.28, 0.32):
	set(value):
		accent_color = value
		queue_redraw()


func _draw() -> void:
	match visual_state:
		0:
			_draw_tangle(accent_color)
		1:
			_draw_partly_untangled(accent_color)
		2:
			_draw_untangled(accent_color)

	draw_circle(Vector2.ZERO, 26.0, Color(0.04, 0.05, 0.06))
	draw_circle(Vector2.ZERO, 21.0, accent_color)


func _draw_tangle(color: Color) -> void:
	for index in range(7):
		var angle: float = float(index) * TAU / 7.0
		var center: Vector2 = Vector2(cos(angle), sin(angle)) * 25.0
		draw_arc(center, 28.0 + index % 3 * 4.0, angle, angle + PI * 1.55, 32, Color(0.03, 0.035, 0.04), 9.0)
		draw_arc(center, 28.0 + index % 3 * 4.0, angle, angle + PI * 1.55, 32, color, 5.0)


func _draw_partly_untangled(color: Color) -> void:
	draw_arc(Vector2(-18.0, 0.0), 42.0, -PI * 0.85, PI * 0.7, 48, Color(0.03, 0.035, 0.04), 9.0)
	draw_arc(Vector2(22.0, 0.0), 38.0, PI * 0.2, PI * 1.55, 48, Color(0.03, 0.035, 0.04), 9.0)
	draw_line(Vector2(-58.0, 34.0), Vector2(58.0, -34.0), Color(0.03, 0.035, 0.04), 9.0)
	draw_arc(Vector2(-18.0, 0.0), 42.0, -PI * 0.85, PI * 0.7, 48, color, 5.0)
	draw_arc(Vector2(22.0, 0.0), 38.0, PI * 0.2, PI * 1.55, 48, color, 5.0)
	draw_line(Vector2(-58.0, 34.0), Vector2(58.0, -34.0), color, 5.0)


func _draw_untangled(color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-58.0, 22.0),
		Vector2(-32.0, -20.0),
		Vector2(0.0, 20.0),
		Vector2(32.0, -20.0),
		Vector2(58.0, 22.0),
	])
	draw_polyline(points, Color(0.03, 0.035, 0.04), 10.0)
	draw_polyline(points, color, 6.0)
