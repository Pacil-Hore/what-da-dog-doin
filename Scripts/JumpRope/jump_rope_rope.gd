@tool
extends Node2D
class_name JumpRopeRope

@export var cycle_duration: float = 0.9
@export var start_phase: float = 0.5:
	set(value):
		start_phase = wrapf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			cycle_phase = start_phase
		_sync_visuals()
@export var left_handle_position: Vector2 = Vector2(-294.0, 112.0):
	set(value):
		left_handle_position = value
		_sync_visuals()
@export var right_handle_position: Vector2 = Vector2(294.0, 112.0):
	set(value):
		right_handle_position = value
		_sync_visuals()
@export var top_center_y: float = -112.0:
	set(value):
		top_center_y = value
		_sync_visuals()
@export var bottom_center_y: float = 210.0:
	set(value):
		bottom_center_y = value
		_sync_visuals()
@export var lateral_sway: float = 92.0:
	set(value):
		lateral_sway = value
		_sync_visuals()
@export var rope_line_path: NodePath = ^"RopeLine"
@export var rope_shadow_line_path: NodePath = ^"ShadowLine"
@export var left_handle_path: NodePath = ^"LeftHandle"
@export var right_handle_path: NodePath = ^"RightHandle"

var cycle_phase: float = 0.0
var is_running: bool = true

@onready var rope_line: Line2D = get_node_or_null(rope_line_path) as Line2D
@onready var rope_shadow_line: Line2D = get_node_or_null(rope_shadow_line_path) as Line2D
@onready var left_handle: Node2D = get_node_or_null(left_handle_path) as Node2D
@onready var right_handle: Node2D = get_node_or_null(right_handle_path) as Node2D


func _ready() -> void:
	cycle_phase = start_phase
	_sync_visuals()


func set_running(value: bool) -> void:
	is_running = value


func reset_cycle() -> void:
	cycle_phase = start_phase
	_sync_visuals()


func get_cycle_phase() -> float:
	return cycle_phase


func advance_cycle(delta: float) -> void:
	if not is_running:
		return

	cycle_phase = wrapf(cycle_phase + delta / maxf(cycle_duration, 0.01), 0.0, 1.0)
	_sync_visuals()


func _sync_visuals() -> void:
	if not is_node_ready():
		return

	var angle: float = cycle_phase * TAU
	var center_y: float = lerpf(top_center_y, bottom_center_y, (1.0 - cos(angle)) * 0.5)
	var sway: float = sin(angle) * lateral_sway
	var rope_points: PackedVector2Array = _build_rope_points(center_y, sway)

	if is_instance_valid(rope_shadow_line):
		rope_shadow_line.points = rope_points

	if is_instance_valid(rope_line):
		rope_line.points = rope_points

	_sync_handle(left_handle, left_handle_position)
	_sync_handle(right_handle, right_handle_position)


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


func _sync_handle(handle_node: Node2D, handle_position: Vector2) -> void:
	if is_instance_valid(handle_node):
		handle_node.position = handle_position
