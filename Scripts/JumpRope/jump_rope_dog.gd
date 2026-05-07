@tool
extends Node2D
class_name JumpRopeDog

@export var fur_color: Color = Color(0.84, 0.56, 0.29):
	set(value):
		fur_color = value
		queue_redraw()
@export var patch_color: Color = Color(0.28, 0.18, 0.12):
	set(value):
		patch_color = value
		queue_redraw()
@export var collar_color: Color = Color(0.2, 0.62, 0.78):
	set(value):
		collar_color = value
		queue_redraw()
@export var jump_height: float = 92.0:
	set(value):
		jump_height = value
		queue_redraw()

var rest_position: Vector2 = Vector2.ZERO
var has_rest_position: bool = false
var jump_elapsed: float = 0.0
var current_jump_duration: float = 0.42
var jump_active: bool = false


func _ready() -> void:
	_cache_rest_position()
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not jump_active:
		return

	jump_elapsed += delta
	var progress: float = minf(jump_elapsed / current_jump_duration, 1.0)
	position = rest_position + Vector2(0.0, -sin(progress * PI) * jump_height)
	queue_redraw()

	if progress >= 1.0:
		jump_active = false
		jump_elapsed = 0.0
		position = rest_position
		queue_redraw()


func start_jump(duration: float) -> void:
	_cache_rest_position()
	current_jump_duration = maxf(duration, 0.01)
	jump_elapsed = 0.0
	jump_active = true
	queue_redraw()


func reset_pose() -> void:
	_cache_rest_position()
	jump_active = false
	jump_elapsed = 0.0
	position = rest_position
	queue_redraw()


func is_jump_active() -> bool:
	return jump_active


func _draw() -> void:
	var airborne: float = _get_airborne_amount()
	var shadow_radius: float = 28.0 - airborne * 10.0
	var shadow_center: Vector2 = Vector2(0.0, 72.0 + airborne * jump_height)
	var body_center: Vector2 = Vector2(-8.0, 8.0)
	var head_center: Vector2 = Vector2(42.0, -16.0)
	var foot_y: float = 66.0 - airborne * 18.0

	draw_circle(shadow_center, shadow_radius, Color(0.0, 0.0, 0.0, 0.18))
	draw_line(Vector2(-18.0, 32.0), Vector2(-30.0, foot_y), Color(0.17, 0.11, 0.08), 10.0)
	draw_line(Vector2(2.0, 32.0), Vector2(-4.0, foot_y), Color(0.17, 0.11, 0.08), 10.0)
	draw_line(Vector2(18.0, 32.0), Vector2(18.0, foot_y), Color(0.17, 0.11, 0.08), 10.0)
	draw_line(Vector2(34.0, 30.0), Vector2(36.0, foot_y), Color(0.17, 0.11, 0.08), 10.0)
	draw_line(Vector2(-18.0, 32.0), Vector2(-30.0, foot_y), fur_color.darkened(0.16), 6.0)
	draw_line(Vector2(2.0, 32.0), Vector2(-4.0, foot_y), fur_color.darkened(0.16), 6.0)
	draw_line(Vector2(18.0, 32.0), Vector2(18.0, foot_y), fur_color.darkened(0.16), 6.0)
	draw_line(Vector2(34.0, 30.0), Vector2(36.0, foot_y), fur_color.darkened(0.16), 6.0)

	draw_line(Vector2(-42.0, 0.0), Vector2(-64.0, -18.0 - airborne * 10.0), Color(0.17, 0.11, 0.08), 8.0)
	draw_line(Vector2(-42.0, 0.0), Vector2(-64.0, -18.0 - airborne * 10.0), fur_color.darkened(0.12), 4.0)

	draw_circle(body_center, 34.0, fur_color)
	draw_circle(Vector2(-30.0, 8.0), 24.0, fur_color.darkened(0.06))
	draw_circle(head_center, 24.0, fur_color)
	draw_circle(head_center + Vector2(15.0, 10.0), 12.0, Color(0.94, 0.89, 0.8))
	draw_circle(head_center + Vector2(6.0, -2.0), 8.0, patch_color)
	draw_circle(head_center + Vector2(12.0, -5.0), 3.0, Color(0.06, 0.04, 0.03))
	draw_circle(head_center + Vector2(-5.0, -4.0), 3.0, Color(0.06, 0.04, 0.03))
	draw_circle(head_center + Vector2(18.0, 4.0), 3.0, Color(0.06, 0.04, 0.03))
	draw_arc(head_center + Vector2(8.0, 10.0), 7.0, 0.15, PI - 0.2, 16, Color(0.46, 0.18, 0.18), 2.0)
	draw_rect(Rect2(Vector2(10.0, -2.0), Vector2(20.0, 7.0)), collar_color, true)

	var left_ear: PackedVector2Array = PackedVector2Array([
		head_center + Vector2(-10.0, -16.0),
		head_center + Vector2(-20.0, -36.0),
		head_center + Vector2(0.0, -24.0),
	])
	var right_ear: PackedVector2Array = PackedVector2Array([
		head_center + Vector2(10.0, -18.0),
		head_center + Vector2(18.0, -36.0),
		head_center + Vector2(20.0, -14.0),
	])
	draw_colored_polygon(left_ear, fur_color.darkened(0.18))
	draw_colored_polygon(right_ear, fur_color.darkened(0.18))


func _cache_rest_position() -> void:
	if has_rest_position:
		return

	rest_position = position
	has_rest_position = true


func _get_airborne_amount() -> float:
	if not jump_active:
		return 0.0

	return sin(clampf(jump_elapsed / current_jump_duration, 0.0, 1.0) * PI)
