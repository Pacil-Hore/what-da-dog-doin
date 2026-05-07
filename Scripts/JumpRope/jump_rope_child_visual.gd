@tool
extends Node2D

@export var mirror_character: bool = false:
	set(value):
		mirror_character = value
		queue_redraw()
@export var shirt_color: Color = Color(0.96, 0.47, 0.34):
	set(value):
		shirt_color = value
		queue_redraw()
@export var shorts_color: Color = Color(0.26, 0.33, 0.48):
	set(value):
		shorts_color = value
		queue_redraw()
@export var skin_color: Color = Color(0.95, 0.83, 0.68):
	set(value):
		skin_color = value
		queue_redraw()
@export var shoe_color: Color = Color(0.17, 0.19, 0.22):
	set(value):
		shoe_color = value
		queue_redraw()
@export var rope_handle_color: Color = Color(0.58, 0.3, 0.18):
	set(value):
		rope_handle_color = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var facing: float = -1.0 if mirror_character else 1.0
	var head_center: Vector2 = Vector2(0.0, -90.0)
	var body_top_left: Vector2 = Vector2(-28.0, -64.0)
	var body_size: Vector2 = Vector2(56.0, 68.0)
	var left_foot: Vector2 = Vector2(-18.0, 74.0)
	var right_foot: Vector2 = Vector2(18.0, 74.0)
	var handle_position: Vector2 = Vector2(40.0 * facing, -34.0)
	var front_shoulder: Vector2 = Vector2(14.0 * facing, -50.0)
	var back_shoulder: Vector2 = Vector2(-10.0 * facing, -48.0)
	var hip_left: Vector2 = Vector2(-10.0, 2.0)
	var hip_right: Vector2 = Vector2(10.0, 2.0)

	draw_circle(Vector2(0.0, 78.0), 24.0, Color(0.0, 0.0, 0.0, 0.16))
	draw_line(hip_left, left_foot, Color(0.13, 0.14, 0.16), 10.0)
	draw_line(hip_right, right_foot, Color(0.13, 0.14, 0.16), 10.0)
	draw_line(hip_left, left_foot, skin_color.darkened(0.2), 6.0)
	draw_line(hip_right, right_foot, skin_color.darkened(0.2), 6.0)
	draw_line(left_foot + Vector2(-8.0, 2.0), left_foot + Vector2(10.0, 2.0), shoe_color, 6.0)
	draw_line(right_foot + Vector2(-8.0, 2.0), right_foot + Vector2(10.0, 2.0), shoe_color, 6.0)

	draw_rect(Rect2(body_top_left, body_size), shirt_color, true)
	draw_rect(Rect2(Vector2(-24.0, -6.0), Vector2(48.0, 30.0)), shorts_color, true)
	draw_rect(Rect2(body_top_left, body_size), Color(0.14, 0.15, 0.17, 0.45), false, 3.0)
	draw_line(Vector2(0.0, -64.0), Vector2(0.0, 4.0), Color(1.0, 1.0, 1.0, 0.18), 2.0)

	draw_line(back_shoulder, Vector2(-34.0 * facing, -12.0), Color(0.14, 0.15, 0.17), 10.0)
	draw_line(back_shoulder, Vector2(-34.0 * facing, -12.0), skin_color, 6.0)
	draw_line(front_shoulder, handle_position, Color(0.14, 0.15, 0.17), 10.0)
	draw_line(front_shoulder, handle_position, skin_color, 6.0)
	draw_rect(Rect2(handle_position - Vector2(4.0, 12.0), Vector2(8.0, 24.0)), rope_handle_color, true)
	draw_rect(Rect2(handle_position - Vector2(4.0, 12.0), Vector2(8.0, 24.0)), Color(0.18, 0.12, 0.08, 0.75), false, 2.0)

	draw_circle(head_center, 26.0, skin_color)
	draw_circle(head_center + Vector2(-9.0 * facing, -3.0), 3.0, Color(0.21, 0.14, 0.12))
	draw_circle(head_center + Vector2(9.0 * facing, -3.0), 3.0, Color(0.21, 0.14, 0.12))
	draw_arc(head_center + Vector2(0.0, 7.0), 9.0, 0.1, PI - 0.1, 16, Color(0.62, 0.24, 0.18), 2.0)

	var hair: PackedVector2Array = PackedVector2Array([
		head_center + Vector2(-28.0, -3.0),
		head_center + Vector2(-15.0, -26.0),
		head_center + Vector2(0.0, -32.0),
		head_center + Vector2(16.0, -24.0),
		head_center + Vector2(28.0, -4.0),
		head_center + Vector2(18.0, -20.0),
		head_center + Vector2(0.0, -16.0),
		head_center + Vector2(-18.0, -18.0),
	])
	draw_colored_polygon(hair, Color(0.29, 0.18, 0.12))
