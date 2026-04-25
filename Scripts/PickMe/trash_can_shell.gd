@tool
extends Node2D

@export var has_clue := false:
	set(value):
		has_clue = value
		queue_redraw()
@export var can_size := Vector2(128.0, 150.0):
	set(value):
		can_size = value
		queue_redraw()


func _draw() -> void:
	var half_width := can_size.x * 0.5
	var top_y := -can_size.y * 0.5
	var bottom_y := can_size.y * 0.5

	var body := PackedVector2Array([
		Vector2(-half_width + 18.0, top_y + 8.0),
		Vector2(half_width - 18.0, top_y + 8.0),
		Vector2(half_width - 8.0, bottom_y - 14.0),
		Vector2(-half_width + 8.0, bottom_y - 14.0),
	])
	draw_colored_polygon(body, Color(0.38, 0.41, 0.44))
	draw_polyline(_closed_points(body), Color(0.1, 0.12, 0.14), 3.0)

	var top_cap := Rect2(Vector2(-half_width + 23.0, top_y - 5.0), Vector2(can_size.x - 46.0, 20.0))
	draw_rect(top_cap, Color(0.5, 0.53, 0.55), true)
	draw_rect(top_cap, Color(0.1, 0.12, 0.14), false, 3.0)

	var open_rim := Rect2(Vector2(-half_width, bottom_y - 28.0), Vector2(can_size.x, 28.0))
	draw_rect(open_rim, Color(0.55, 0.58, 0.6), true)
	draw_rect(open_rim, Color(0.1, 0.12, 0.14), false, 3.0)

	var shadow := PackedVector2Array([
		Vector2(-half_width + 18.0, top_y + 16.0),
		Vector2(-half_width + 38.0, top_y + 16.0),
		Vector2(-half_width + 50.0, bottom_y - 24.0),
		Vector2(-half_width + 18.0, bottom_y - 24.0),
	])
	draw_colored_polygon(shadow, Color(0.23, 0.26, 0.29, 0.55))

	if has_clue:
		_draw_clue_marker(Vector2(0.0, 8.0))


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	return closed


func _draw_clue_marker(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -18.0),
		center + Vector2(18.0, 0.0),
		center + Vector2(0.0, 18.0),
		center + Vector2(-18.0, 0.0),
	])
	draw_colored_polygon(points, Color(1.0, 0.78, 0.18))
	draw_polyline(_closed_points(points), Color(0.22, 0.18, 0.08), 3.0)
	draw_circle(center + Vector2(0.0, -6.0), 3.0, Color(0.22, 0.18, 0.08))
	draw_circle(center + Vector2(0.0, 8.0), 3.0, Color(0.22, 0.18, 0.08))
