@tool
extends Node2D

@export var size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.92, 0.95, 0.89), true)
	draw_rect(Rect2(Vector2(0.0, size.y * 0.62), Vector2(size.x, size.y * 0.38)), Color(0.69, 0.82, 0.61), true)

	var road_rect := Rect2(Vector2(462.0, 0.0), Vector2(228.0, size.y))
	draw_rect(road_rect, Color(0.29, 0.33, 0.37), true)
	draw_rect(Rect2(Vector2(446.0, 0.0), Vector2(16.0, size.y)), Color(0.79, 0.76, 0.69), true)
	draw_rect(Rect2(Vector2(690.0, 0.0), Vector2(16.0, size.y)), Color(0.79, 0.76, 0.69), true)

	for index in range(6):
		var dash_y := 54.0 + float(index) * 102.0
		draw_rect(Rect2(Vector2(570.0, dash_y), Vector2(12.0, 52.0)), Color(0.94, 0.92, 0.82), true)

	_draw_parking_barrier()
	_draw_owner_and_dog()


func _draw_parking_barrier() -> void:
	var barrier_rect := Rect2(Vector2(768.0, 555.0), Vector2(278.0, 32.0))
	draw_rect(barrier_rect, Color(0.87, 0.84, 0.75), true)
	draw_rect(barrier_rect, Color(0.27, 0.26, 0.24), false, 4.0)

	for index in range(6):
		var stripe_rect := Rect2(
			Vector2(barrier_rect.position.x + 10.0 + float(index) * 44.0, barrier_rect.position.y + 4.0),
			Vector2(24.0, barrier_rect.size.y - 8.0)
		)
		var points := PackedVector2Array([
			stripe_rect.position,
			stripe_rect.position + Vector2(stripe_rect.size.x, 0.0),
			stripe_rect.position + stripe_rect.size,
			stripe_rect.position + Vector2(0.0, stripe_rect.size.y),
		])
		draw_colored_polygon(points, Color(0.92, 0.73, 0.29))


func _draw_owner_and_dog() -> void:
	var person_origin := Vector2(110.0, 502.0)
	draw_circle(person_origin + Vector2(0.0, -54.0), 14.0, Color(0.92, 0.78, 0.63))
	draw_line(person_origin + Vector2(0.0, -40.0), person_origin + Vector2(0.0, 14.0), Color(0.19, 0.23, 0.29), 6.0)
	draw_line(person_origin + Vector2(0.0, -18.0), person_origin + Vector2(-18.0, 10.0), Color(0.19, 0.23, 0.29), 5.0)
	draw_line(person_origin + Vector2(0.0, -18.0), person_origin + Vector2(20.0, -2.0), Color(0.19, 0.23, 0.29), 5.0)
	draw_line(person_origin + Vector2(0.0, 14.0), person_origin + Vector2(-14.0, 56.0), Color(0.19, 0.23, 0.29), 5.0)
	draw_line(person_origin + Vector2(0.0, 14.0), person_origin + Vector2(18.0, 54.0), Color(0.19, 0.23, 0.29), 5.0)
	draw_rect(Rect2(person_origin + Vector2(-16.0, -34.0), Vector2(32.0, 26.0)), Color(0.42, 0.63, 0.91), true)

	var dog_origin := Vector2(206.0, 534.0)
	draw_circle(dog_origin + Vector2(-18.0, -26.0), 19.0, Color(0.93, 0.88, 0.79))
	draw_circle(dog_origin + Vector2(16.0, -30.0), 22.0, Color(0.93, 0.88, 0.79))
	draw_circle(dog_origin + Vector2(26.0, -38.0), 7.0, Color(0.93, 0.88, 0.79))
	draw_circle(dog_origin + Vector2(32.0, -34.0), 2.5, Color(0.15, 0.12, 0.1))
	draw_rect(Rect2(dog_origin + Vector2(-36.0, -26.0), Vector2(52.0, 28.0)), Color(0.93, 0.88, 0.79), true)
	draw_line(dog_origin + Vector2(-26.0, 2.0), dog_origin + Vector2(-30.0, 28.0), Color(0.48, 0.37, 0.24), 4.0)
	draw_line(dog_origin + Vector2(-4.0, 2.0), dog_origin + Vector2(-8.0, 30.0), Color(0.48, 0.37, 0.24), 4.0)
	draw_line(dog_origin + Vector2(6.0, 2.0), dog_origin + Vector2(2.0, 30.0), Color(0.48, 0.37, 0.24), 4.0)
	draw_line(dog_origin + Vector2(24.0, 0.0), dog_origin + Vector2(20.0, 28.0), Color(0.48, 0.37, 0.24), 4.0)
	draw_line(dog_origin + Vector2(-30.0, -30.0), person_origin + Vector2(18.0, -2.0), Color(0.34, 0.31, 0.27), 3.0)
	draw_arc(dog_origin + Vector2(-34.0, -18.0), 18.0, -0.35, 1.15, 18, Color(0.48, 0.37, 0.24), 4.0)

	var bubble_center := Vector2(240.0, 446.0)
	_draw_thought_bubble(bubble_center)


func _draw_thought_bubble(center: Vector2) -> void:
	draw_circle(center, 34.0, Color(1.0, 1.0, 1.0, 0.96))
	draw_circle(center + Vector2(-30.0, 16.0), 12.0, Color(1.0, 1.0, 1.0, 0.96))
	draw_circle(center + Vector2(-48.0, 34.0), 7.0, Color(1.0, 1.0, 1.0, 0.96))
	draw_circle(center + Vector2(10.0, -4.0), 4.0, Color(0.39, 0.25, 0.16))
	draw_circle(center + Vector2(-8.0, 4.0), 4.0, Color(0.39, 0.25, 0.16))
	draw_circle(center + Vector2(0.0, 10.0), 4.5, Color(0.39, 0.25, 0.16))
