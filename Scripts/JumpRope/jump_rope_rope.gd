@tool
extends Node2D
class_name JumpRopeRope

@export var cycle_duration: float = 0.9
@export var start_phase: float = 0.0:
	set(value):
		start_phase = wrapf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			cycle_phase = start_phase
			queue_redraw()
@export var left_handle_position: Vector2 = Vector2(-294.0, 112.0):
	set(value):
		left_handle_position = value
		queue_redraw()
@export var right_handle_position: Vector2 = Vector2(294.0, 112.0):
	set(value):
		right_handle_position = value
		queue_redraw()
@export var top_center_y: float = -112.0:
	set(value):
		top_center_y = value
		queue_redraw()
@export var bottom_center_y: float = 210.0:
	set(value):
		bottom_center_y = value
		queue_redraw()
@export var lateral_sway: float = 92.0:
	set(value):
		lateral_sway = value
		queue_redraw()
@export var rope_color: Color = Color(0.95, 0.78, 0.38):
	set(value):
		rope_color = value
		queue_redraw()
@export var rope_back_color: Color = Color(0.79, 0.63, 0.38, 0.6):
	set(value):
		rope_back_color = value
		queue_redraw()
@export var handle_color: Color = Color(0.63, 0.38, 0.21):
	set(value):
		handle_color = value
		queue_redraw()

var cycle_phase: float = 0.0
var is_running: bool = true


func _ready() -> void:
	cycle_phase = start_phase
	queue_redraw()


func _process(_delta: float) -> void:
	pass


func set_running(value: bool) -> void:
	is_running = value


func reset_cycle() -> void:
	cycle_phase = start_phase
	queue_redraw()


func get_cycle_phase() -> float:
	return cycle_phase


func advance_cycle(delta: float) -> void:
	if not is_running:
		return

	cycle_phase = wrapf(cycle_phase + delta / maxf(cycle_duration, 0.01), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var angle: float = cycle_phase * TAU
	var center_y: float = lerpf(top_center_y, bottom_center_y, (1.0 - cos(angle)) * 0.5)
	var sway: float = sin(angle) * lateral_sway
	var rope_points: PackedVector2Array = _build_rope_points(center_y, sway)
	var average_handle_y: float = (left_handle_position.y + right_handle_position.y) * 0.5
	var front_color: Color = rope_color if center_y >= average_handle_y else rope_back_color

	draw_polyline(rope_points, Color(0.07, 0.07, 0.09, 0.35), 12.0)
	draw_polyline(rope_points, front_color, 7.0)

	_draw_handle(left_handle_position)
	_draw_handle(right_handle_position)


func _build_rope_points(center_y: float, sway: float) -> PackedVector2Array:
	var rope_points: PackedVector2Array = PackedVector2Array()
	var point_count: int = 32
	var average_handle_y: float = (left_handle_position.y + right_handle_position.y) * 0.5
	var center_offset_y: float = center_y - average_handle_y

	for index in range(point_count):
		var t: float = float(index) / float(point_count - 1)
		var point: Vector2 = left_handle_position.lerp(right_handle_position, t)
		var curve: float = 4.0 * t * (1.0 - t)
		point.y += center_offset_y * curve
		point.x += sway * sin(t * PI)
		rope_points.append(point)

	return rope_points


func _draw_handle(handle_position: Vector2) -> void:
	draw_line(handle_position + Vector2(0.0, -14.0), handle_position + Vector2(0.0, 14.0), Color(0.18, 0.11, 0.08), 6.0)
	draw_line(handle_position + Vector2(0.0, -14.0), handle_position + Vector2(0.0, 14.0), handle_color, 3.0)
	draw_circle(handle_position, 7.0, handle_color.lightened(0.1))
