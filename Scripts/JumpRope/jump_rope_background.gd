@tool
extends Node2D

@export var size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.92, 0.84), true)
	draw_rect(Rect2(Vector2(0.0, size.y * 0.62), Vector2(size.x, size.y * 0.38)), Color(0.72, 0.81, 0.57), true)
	draw_circle(Vector2(152.0, 118.0), 56.0, Color(0.98, 0.86, 0.48, 0.95))
	draw_circle(Vector2(152.0, 118.0), 80.0, Color(0.98, 0.86, 0.48, 0.18))

	for index in range(7):
		var cloud_center: Vector2 = Vector2(120.0 + float(index) * 156.0, 84.0 + float(index % 2) * 26.0)
		draw_circle(cloud_center, 24.0, Color(1.0, 1.0, 1.0, 0.55))
		draw_circle(cloud_center + Vector2(28.0, 8.0), 20.0, Color(1.0, 1.0, 1.0, 0.55))
		draw_circle(cloud_center + Vector2(-28.0, 10.0), 18.0, Color(1.0, 1.0, 1.0, 0.55))

	var stage_rect: Rect2 = Rect2(Vector2(182.0, 300.0), Vector2(788.0, 234.0))
	draw_rect(stage_rect, Color(0.93, 0.88, 0.72), true)
	draw_rect(stage_rect, Color(0.58, 0.43, 0.24, 0.65), false, 6.0)

	for index in range(6):
		var y: float = 334.0 + float(index) * 34.0
		draw_line(Vector2(214.0, y), Vector2(938.0, y), Color(0.73, 0.63, 0.46, 0.24), 2.0)

	draw_arc(Vector2(576.0, 474.0), 118.0, PI, TAU, 48, Color(1.0, 1.0, 1.0, 0.35), 4.0)
	draw_line(Vector2(458.0, 474.0), Vector2(694.0, 474.0), Color(1.0, 1.0, 1.0, 0.2), 2.0)
