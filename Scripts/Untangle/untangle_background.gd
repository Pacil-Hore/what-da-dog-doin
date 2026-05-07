@tool
extends Node2D

@export var size := Vector2(1152.0, 645.0):
	set(value):
		size = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.105, 0.13, 0.145), true)

	for index in range(18):
		var x: float = float(index) * 72.0
		draw_line(Vector2(x, 0.0), Vector2(x - 220.0, size.y), Color(0.35, 0.48, 0.52, 0.05), 2.0)

	for index in range(10):
		var y: float = float(index) * 72.0
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.35, 0.48, 0.52, 0.035), 1.0)

	draw_circle(size * 0.5, 330.0, Color(0.11, 0.21, 0.24, 0.32))
	draw_circle(size * 0.5, 210.0, Color(0.13, 0.28, 0.32, 0.18))
