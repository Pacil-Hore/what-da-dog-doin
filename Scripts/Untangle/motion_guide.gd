@tool
extends Node2D

## Circular motion guide that shows the target ring and progress arc.
## Uses Line2D children so the guide remains editable from the scene tree.

@export var min_radius := 48.0:
	set(value):
		min_radius = value
		_refresh()
@export var max_radius := 260.0:
	set(value):
		max_radius = value
		_refresh()
@export var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		_refresh()

var _guide_line: Line2D
var _inner_line: Line2D
var _outer_line: Line2D
var _progress_line: Line2D



func set_progress(value: float) -> void:
	progress = value


func _ready() -> void:
	_ensure_children()
	_refresh()


func _ensure_children() -> void:
	_guide_line = _get_or_create_line("GuideLine", Color(0.02, 0.02, 0.02, 0.16), 3.0)
	_inner_line = _get_or_create_line("InnerLine", Color(0.02, 0.02, 0.02, 0.08), 2.0)
	_outer_line = _get_or_create_line("OuterLine", Color(0.02, 0.02, 0.02, 0.08), 2.0)
	_progress_line = _get_or_create_line("ProgressLine", Color(0.02, 0.02, 0.02, 0.7), 7.0)


func _get_or_create_line(node_name: String, color: Color, width: float) -> Line2D:
	var line := get_node_or_null(node_name) as Line2D
	if line == null:
		line = Line2D.new()
		line.name = node_name
		line.default_color = color
		line.width = width
		add_child(line)
		if Engine.is_editor_hint():
			line.owner = get_tree().edited_scene_root
	return line


func _build_arc_points(center: Vector2, radius: float, start_angle: float, end_angle: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _refresh() -> void:
	if not is_inside_tree():
		return
	_ensure_children()

	var target_radius := (min_radius + max_radius) * 0.5

	# Guide circle
	if is_instance_valid(_guide_line):
		_guide_line.clear_points()
		for p in _build_arc_points(Vector2.ZERO, target_radius, 0.0, TAU, 64):
			_guide_line.add_point(p)

	# Inner circle
	if is_instance_valid(_inner_line):
		_inner_line.clear_points()
		for p in _build_arc_points(Vector2.ZERO, min_radius, 0.0, TAU, 64):
			_inner_line.add_point(p)

	# Outer circle
	if is_instance_valid(_outer_line):
		_outer_line.clear_points()
		for p in _build_arc_points(Vector2.ZERO, max_radius, 0.0, TAU, 64):
			_outer_line.add_point(p)

	# Progress arc
	if is_instance_valid(_progress_line):
		_progress_line.clear_points()
		if progress > 0.0:
			var start_angle := -PI * 0.5
			var end_angle := start_angle + TAU * progress
			for p in _build_arc_points(Vector2.ZERO, target_radius, start_angle, end_angle, 64):
				_progress_line.add_point(p)
