@tool
extends Node2D
class_name PickTheRopeBackground

@export var size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	_draw_sky()
	_draw_backdrop()
	_draw_storefront(Rect2(Vector2(-6.0, 128.0), Vector2(366.0, 230.0)), Color(0.73, 0.56, 0.47), Color(0.41, 0.31, 0.26), Color(0.86, 0.68, 0.3))
	_draw_storefront(Rect2(Vector2(374.0, 142.0), Vector2(314.0, 216.0)), Color(0.72, 0.8, 0.82), Color(0.34, 0.42, 0.44), Color(0.46, 0.76, 0.74))
	_draw_shoulder()
	_draw_road()
	_draw_center_glow()
	_draw_street_details()
	_draw_utility_pole()


func _draw_sky() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 130.0)), Color(0.78, 0.86, 0.93), true)
	draw_rect(Rect2(Vector2(0.0, 130.0), Vector2(size.x, 44.0)), Color(0.86, 0.88, 0.87), true)

	for cloud_center in [Vector2(136.0, 62.0), Vector2(414.0, 48.0), Vector2(716.0, 66.0)]:
		draw_circle(cloud_center, 26.0, Color(1.0, 1.0, 1.0, 0.16))
		draw_circle(cloud_center + Vector2(24.0, 6.0), 22.0, Color(1.0, 1.0, 1.0, 0.14))
		draw_circle(cloud_center + Vector2(-22.0, 8.0), 20.0, Color(1.0, 1.0, 1.0, 0.12))


func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2(0.0, 168.0), Vector2(size.x, 36.0)), Color(0.88, 0.88, 0.85), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 206.0),
		Vector2(96.0, 164.0),
		Vector2(224.0, 206.0),
	]), Color(0.82, 0.82, 0.79))
	draw_colored_polygon(PackedVector2Array([
		Vector2(220.0, 206.0),
		Vector2(350.0, 150.0),
		Vector2(520.0, 206.0),
	]), Color(0.86, 0.86, 0.82))
	draw_colored_polygon(PackedVector2Array([
		Vector2(488.0, 206.0),
		Vector2(646.0, 154.0),
		Vector2(844.0, 206.0),
	]), Color(0.84, 0.84, 0.8))
	draw_colored_polygon(PackedVector2Array([
		Vector2(780.0, 206.0),
		Vector2(930.0, 160.0),
		Vector2(1152.0, 206.0),
	]), Color(0.8, 0.8, 0.78))


func _draw_storefront(rect: Rect2, facade_color: Color, trim_color: Color, accent_color: Color) -> void:
	var upper_rect: Rect2 = rect
	var lower_rect: Rect2 = Rect2(Vector2(rect.position.x, rect.position.y + rect.size.y - 48.0), Vector2(rect.size.x, 66.0))

	draw_rect(upper_rect, facade_color, true)
	draw_rect(upper_rect, trim_color, false, 5.0)
	draw_rect(lower_rect, facade_color.darkened(0.14), true)
	draw_rect(Rect2(rect.position + Vector2(0.0, 30.0), Vector2(rect.size.x, 12.0)), trim_color.lightened(0.1), true)

	var sign_rect: Rect2 = Rect2(rect.position + Vector2(44.0, 16.0), Vector2(rect.size.x - 96.0, 32.0))
	draw_rect(sign_rect, trim_color, true)
	draw_rect(sign_rect.grow(-4.0), Color(0.95, 0.91, 0.84), true)
	draw_rect(Rect2(sign_rect.position + Vector2(12.0, 12.0), Vector2(sign_rect.size.x - 24.0, 5.0)), accent_color, true)
	_draw_paw_icon(sign_rect.position + sign_rect.size * 0.5 + Vector2(0.0, 3.0), accent_color)

	var awning_rect: Rect2 = Rect2(rect.position + Vector2(22.0, 74.0), Vector2(rect.size.x - 44.0, 32.0))
	_draw_awning(awning_rect, accent_color, Color(0.96, 0.93, 0.88))

	var window_width: float = (rect.size.x - 86.0) * 0.5
	_draw_window(Rect2(rect.position + Vector2(42.0, 122.0), Vector2(window_width, 112.0)), trim_color, Color(0.72, 0.86, 0.94))
	_draw_window(Rect2(rect.position + Vector2(44.0 + window_width, 122.0), Vector2(window_width, 112.0)), trim_color, Color(0.72, 0.86, 0.94))


func _draw_awning(rect: Rect2, base_color: Color, stripe_color: Color) -> void:
	draw_rect(rect, base_color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 4.0), Vector2(rect.size.x, 4.0)), base_color.darkened(0.16), true)

	var stripe_width: float = rect.size.x / 6.0
	for stripe_index in range(6):
		if stripe_index % 2 == 0:
			draw_rect(
				Rect2(
					rect.position + Vector2(float(stripe_index) * stripe_width, 0.0),
					Vector2(stripe_width, rect.size.y - 4.0)
				),
				stripe_color,
				true
			)


func _draw_window(rect: Rect2, frame_color: Color, glass_color: Color) -> void:
	draw_rect(rect, frame_color, true)
	draw_rect(rect.grow(-6.0), glass_color, true)
	draw_line(rect.position + Vector2(rect.size.x * 0.5, 8.0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 8.0), frame_color.darkened(0.14), 4.0)
	draw_line(rect.position + Vector2(8.0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 8.0, rect.size.y * 0.5), frame_color.darkened(0.14), 4.0)
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(12.0, 10.0),
		rect.position + Vector2(rect.size.x * 0.44, 10.0),
		rect.position + Vector2(rect.size.x * 0.26, rect.size.y - 14.0),
		rect.position + Vector2(12.0, rect.size.y - 14.0),
	]), Color(1.0, 1.0, 1.0, 0.16))


func _draw_shoulder() -> void:
	draw_rect(Rect2(Vector2(0.0, 358.0), Vector2(size.x, 176.0)), Color(0.76, 0.71, 0.67), true)
	draw_rect(Rect2(Vector2(0.0, 358.0), Vector2(size.x, 16.0)), Color(0.9, 0.86, 0.82), true)
	draw_rect(Rect2(Vector2(0.0, 518.0), Vector2(size.x, 16.0)), Color(0.63, 0.6, 0.58), true)

	for seam_x in [110.0, 248.0, 414.0, 594.0, 760.0, 942.0]:
		draw_line(Vector2(seam_x, 374.0), Vector2(seam_x, 518.0), Color(0.63, 0.59, 0.56, 0.32), 2.0)

	for seam_y in [410.0, 464.0]:
		draw_line(Vector2(0.0, seam_y), Vector2(size.x, seam_y), Color(0.67, 0.63, 0.6, 0.22), 2.0)


func _draw_road() -> void:
	draw_rect(Rect2(Vector2(0.0, 534.0), Vector2(size.x, size.y - 534.0)), Color(0.24, 0.26, 0.3), true)
	draw_rect(Rect2(Vector2(0.0, 534.0), Vector2(size.x, 8.0)), Color(0.88, 0.84, 0.78), true)

	for stripe_index in range(7):
		var stripe_x: float = 80.0 + float(stripe_index) * 156.0
		draw_rect(Rect2(Vector2(stripe_x, 596.0), Vector2(84.0, 10.0)), Color(0.92, 0.9, 0.78, 0.75), true)


func _draw_center_glow() -> void:
	pass


func _draw_street_details() -> void:
	_draw_planter(Rect2(Vector2(54.0, 492.0), Vector2(96.0, 46.0)), Color(0.39, 0.32, 0.27), Color(0.47, 0.69, 0.44))
	_draw_planter(Rect2(Vector2(382.0, 494.0), Vector2(98.0, 44.0)), Color(0.39, 0.32, 0.27), Color(0.51, 0.72, 0.48))
	_draw_storm_drain(Rect2(Vector2(868.0, 486.0), Vector2(62.0, 26.0)))
	_draw_fire_hydrant(Vector2(1030.0, 522.0), Color(0.84, 0.29, 0.24))


func _draw_planter(rect: Rect2, box_color: Color, leaf_color: Color) -> void:
	draw_rect(rect, box_color, true)
	draw_rect(rect, box_color.darkened(0.22), false, 3.0)

	var center: Vector2 = rect.position + rect.size * 0.5
	for leaf_offset in [Vector2(-24.0, -12.0), Vector2(0.0, -22.0), Vector2(24.0, -10.0)]:
		draw_circle(center + leaf_offset, 18.0, leaf_color)
		draw_circle(center + leaf_offset + Vector2(8.0, -12.0), 12.0, leaf_color.lightened(0.08))


func _draw_storm_drain(rect: Rect2) -> void:
	draw_rect(rect, Color(0.56, 0.55, 0.53), true)
	draw_rect(rect, Color(0.39, 0.38, 0.36), false, 3.0)

	for slot_index in range(4):
		var slot_x: float = rect.position.x + 10.0 + float(slot_index) * 12.0
		draw_line(Vector2(slot_x, rect.position.y + 6.0), Vector2(slot_x, rect.position.y + rect.size.y - 6.0), Color(0.4, 0.39, 0.38), 2.0)

func _draw_fire_hydrant(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0.0, 18.0), 24.0, Color(0.15, 0.12, 0.11, 0.12))
	draw_rect(Rect2(center + Vector2(-16.0, -18.0), Vector2(32.0, 52.0)), color, true)
	draw_rect(Rect2(center + Vector2(-26.0, -2.0), Vector2(14.0, 18.0)), color, true)
	draw_rect(Rect2(center + Vector2(12.0, -2.0), Vector2(14.0, 18.0)), color, true)
	draw_circle(center + Vector2(0.0, -22.0), 16.0, color)
	draw_circle(center + Vector2(-19.0, 6.0), 8.0, color.lightened(0.06))
	draw_circle(center + Vector2(19.0, 6.0), 8.0, color.lightened(0.06))
	draw_rect(Rect2(center + Vector2(-20.0, 28.0), Vector2(40.0, 10.0)), color.darkened(0.18), true)


func _draw_utility_pole() -> void:
	var pole_shape: PackedVector2Array = PackedVector2Array([
		Vector2(904.0, 72.0),
		Vector2(928.0, 72.0),
		Vector2(946.0, 516.0),
		Vector2(886.0, 516.0),
	])

	draw_colored_polygon(pole_shape, Color(0.67, 0.68, 0.7))
	draw_polyline(PackedVector2Array([
		pole_shape[0],
		pole_shape[1],
		pole_shape[2],
		pole_shape[3],
		pole_shape[0],
	]), Color(0.35, 0.37, 0.4), 4.0)
	draw_line(Vector2(916.0, 76.0), Vector2(924.0, 510.0), Color(0.8, 0.82, 0.84), 5.0)
	draw_line(Vector2(900.0, 76.0), Vector2(892.0, 510.0), Color(0.55, 0.56, 0.6), 4.0)
	draw_rect(Rect2(Vector2(894.0, 516.0), Vector2(44.0, 18.0)), Color(0.42, 0.43, 0.46), true)

	var band_color: Color = Color(0.45, 0.47, 0.5)
	for ring_y in [182.0, 248.0, 314.0, 380.0]:
		draw_rect(Rect2(Vector2(888.0, ring_y - 20.0), Vector2(56.0, 8.0)), band_color, true)
		draw_rect(Rect2(Vector2(894.0, ring_y + 14.0), Vector2(44.0, 6.0)), band_color.darkened(0.08), true)
		draw_circle(Vector2(916.0, ring_y), 18.0, Color(0.24, 0.22, 0.21), false, 4.0)
		draw_circle(Vector2(916.0, ring_y), 18.0, Color(0.78, 0.8, 0.83), false, 2.0)
		draw_arc(Vector2(916.0, ring_y + 22.0), 10.0, 0.0, PI, 16, Color(0.5, 0.44, 0.37), 3.0)

	draw_rect(Rect2(Vector2(852.0, 116.0), Vector2(30.0, 40.0)), Color(0.9, 0.88, 0.82), true)
	draw_rect(Rect2(Vector2(852.0, 116.0), Vector2(30.0, 40.0)), Color(0.45, 0.43, 0.39), false, 3.0)
	draw_line(Vector2(882.0, 134.0), Vector2(900.0, 134.0), Color(0.56, 0.54, 0.5), 2.0)


func _draw_paw_icon(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0.0, 8.0), 14.0, color)
	draw_circle(center + Vector2(-14.0, -12.0), 6.0, color)
	draw_circle(center + Vector2(-4.0, -18.0), 6.0, color)
	draw_circle(center + Vector2(8.0, -18.0), 6.0, color)
	draw_circle(center + Vector2(18.0, -12.0), 6.0, color)
