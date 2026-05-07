@tool
extends Node2D
class_name PickTheRopeBackground

@export var size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	_draw_wall()
	_draw_floor()
	_draw_center_glow()
	_draw_rack_and_pole()
	_draw_poster(Rect2(Vector2(102.0, 146.0), Vector2(166.0, 112.0)), Color(0.84, 0.9, 0.8), Color(0.43, 0.63, 0.47))
	_draw_poster(Rect2(Vector2(884.0, 146.0), Vector2(166.0, 112.0)), Color(0.94, 0.88, 0.78), Color(0.82, 0.57, 0.24))
	_draw_storage_unit(Rect2(Vector2(54.0, 416.0), Vector2(236.0, 116.0)), Color(0.75, 0.68, 0.59), Color(0.86, 0.8, 0.72))
	_draw_storage_unit(Rect2(Vector2(862.0, 416.0), Vector2(236.0, 116.0)), Color(0.75, 0.68, 0.59), Color(0.86, 0.8, 0.72))
	_draw_bowl(Vector2(110.0, 560.0), Color(0.64, 0.79, 0.87))
	_draw_bowl(Vector2(1038.0, 560.0), Color(0.87, 0.73, 0.48))


func _draw_wall() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.95, 0.93, 0.88), true)
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(size.x, 92.0)), Color(0.89, 0.85, 0.78), true)
	draw_rect(Rect2(Vector2(126.0, 108.0), Vector2(900.0, 280.0)), Color(0.98, 0.97, 0.94), true)
	draw_rect(Rect2(Vector2(126.0, 108.0), Vector2(900.0, 280.0)), Color(0.84, 0.79, 0.71), false, 4.0)
	draw_rect(Rect2(Vector2(0.0, 388.0), Vector2(size.x, 26.0)), Color(0.86, 0.82, 0.74), true)

	for stripe_x in [166.0, 266.0, 886.0, 986.0]:
		draw_rect(Rect2(Vector2(stripe_x, 108.0), Vector2(2.0, 280.0)), Color(0.9, 0.88, 0.82), true)


func _draw_floor() -> void:
	var floor_top: float = size.y * 0.66
	draw_rect(Rect2(Vector2(0.0, floor_top), Vector2(size.x, size.y - floor_top)), Color(0.8, 0.74, 0.66), true)
	draw_rect(Rect2(Vector2(0.0, floor_top), Vector2(size.x, 14.0)), Color(0.72, 0.66, 0.59), true)

	for tile_index in range(11):
		var tile_x: float = float(tile_index) * 112.0
		draw_line(Vector2(tile_x, floor_top), Vector2(tile_x, size.y), Color(0.68, 0.62, 0.55, 0.24), 2.0)

	for row_index in range(4):
		var tile_y: float = floor_top + 28.0 + float(row_index) * 42.0
		draw_line(Vector2(0.0, tile_y), Vector2(size.x, tile_y), Color(0.69, 0.63, 0.56, 0.22), 2.0)

	draw_circle(Vector2(498.0, 566.0), 48.0, Color(0.42, 0.35, 0.29, 0.06))
	draw_circle(Vector2(654.0, 566.0), 48.0, Color(0.42, 0.35, 0.29, 0.06))
	draw_rect(Rect2(Vector2(498.0, 518.0), Vector2(156.0, 96.0)), Color(0.42, 0.35, 0.29, 0.06), true)


func _draw_center_glow() -> void:
	draw_circle(Vector2(576.0, 290.0), 194.0, Color(1.0, 1.0, 1.0, 0.28))
	draw_circle(Vector2(576.0, 290.0), 140.0, Color(1.0, 1.0, 1.0, 0.18))
	draw_circle(Vector2(576.0, 290.0), 96.0, Color(0.77, 0.69, 0.6, 0.06))


func _draw_rack_and_pole() -> void:
	draw_rect(Rect2(Vector2(84.0, 92.0), Vector2(size.x - 168.0, 18.0)), Color(0.56, 0.47, 0.38), true)
	draw_rect(Rect2(Vector2(102.0, 110.0), Vector2(size.x - 204.0, 8.0)), Color(0.37, 0.31, 0.25), true)

	for post_x in [124.0, 382.0, 770.0, 1028.0]:
		draw_rect(Rect2(Vector2(post_x, 92.0), Vector2(14.0, 82.0)), Color(0.44, 0.37, 0.31), true)

	draw_rect(Rect2(Vector2(544.0, 90.0), Vector2(64.0, 290.0)), Color(0.66, 0.57, 0.48), true)
	draw_rect(Rect2(Vector2(544.0, 90.0), Vector2(64.0, 290.0)), Color(0.31, 0.26, 0.22), false, 5.0)
	draw_rect(Rect2(Vector2(568.0, 90.0), Vector2(10.0, 290.0)), Color(0.84, 0.78, 0.69), true)
	draw_rect(Rect2(Vector2(530.0, 114.0), Vector2(92.0, 18.0)), Color(0.49, 0.41, 0.34), true)
	draw_rect(Rect2(Vector2(548.0, 380.0), Vector2(56.0, 20.0)), Color(0.49, 0.41, 0.34), true)

	for ring_y in [126.0, 194.0, 262.0, 330.0]:
		draw_circle(Vector2(576.0, ring_y), 18.0, Color(0.24, 0.22, 0.21), false, 4.0)
		draw_circle(Vector2(576.0, ring_y), 18.0, Color(0.78, 0.8, 0.83), false, 2.0)
		draw_arc(Vector2(576.0, ring_y + 22.0), 10.0, 0.0, PI, 16, Color(0.54, 0.45, 0.37), 3.0)


func _draw_poster(rect: Rect2, fill_color: Color, accent_color: Color) -> void:
	draw_rect(rect, Color(0.4, 0.34, 0.29), true)
	draw_rect(rect.grow(-6.0), Color(0.98, 0.97, 0.94), true)
	draw_rect(rect.grow(-14.0), fill_color, true)
	draw_rect(Rect2(rect.position + Vector2(18.0, 18.0), Vector2(rect.size.x - 36.0, 12.0)), accent_color, true)
	draw_rect(Rect2(rect.position + Vector2(30.0, 78.0), Vector2(rect.size.x - 60.0, 8.0)), accent_color.darkened(0.1), true)
	_draw_paw_icon(rect.position + rect.size * 0.5 + Vector2(0.0, 6.0), accent_color.darkened(0.18))


func _draw_paw_icon(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0.0, 8.0), 14.0, color)
	draw_circle(center + Vector2(-14.0, -12.0), 6.0, color)
	draw_circle(center + Vector2(-4.0, -18.0), 6.0, color)
	draw_circle(center + Vector2(8.0, -18.0), 6.0, color)
	draw_circle(center + Vector2(18.0, -12.0), 6.0, color)


func _draw_storage_unit(rect: Rect2, body_color: Color, top_color: Color) -> void:
	draw_rect(rect, body_color, true)
	draw_rect(rect, Color(0.35, 0.3, 0.26), false, 4.0)
	draw_rect(Rect2(rect.position + Vector2(4.0, 8.0), Vector2(rect.size.x - 8.0, 20.0)), top_color, true)

	for divider_x in [rect.position.x + rect.size.x / 3.0, rect.position.x + rect.size.x * 2.0 / 3.0]:
		draw_line(Vector2(divider_x, rect.position.y + 28.0), Vector2(divider_x, rect.position.y + rect.size.y - 10.0), Color(0.58, 0.51, 0.44), 3.0)

	for shelf_y in [rect.position.y + 56.0, rect.position.y + 84.0]:
		draw_line(Vector2(rect.position.x + 12.0, shelf_y), Vector2(rect.position.x + rect.size.x - 12.0, shelf_y), Color(0.62, 0.55, 0.47), 2.0)

	draw_rect(Rect2(rect.position + Vector2(24.0, 38.0), Vector2(38.0, 12.0)), Color(0.86, 0.67, 0.43), true)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 62.0, 38.0), Vector2(38.0, 12.0)), Color(0.54, 0.72, 0.84), true)


func _draw_bowl(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0.0, 6.0), 18.0, Color(0.18, 0.14, 0.12, 0.12))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-24.0, 0.0),
		center + Vector2(-18.0, 12.0),
		center + Vector2(18.0, 12.0),
		center + Vector2(24.0, 0.0),
	]), color)
	draw_polyline(PackedVector2Array([
		center + Vector2(-24.0, 0.0),
		center + Vector2(-18.0, 12.0),
		center + Vector2(18.0, 12.0),
		center + Vector2(24.0, 0.0),
	]), Color(0.34, 0.31, 0.28), 3.0)
