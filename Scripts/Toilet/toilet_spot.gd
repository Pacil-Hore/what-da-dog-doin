@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name ToiletSpot

signal spot_selected(spot: ToiletSpot)

enum SpotType {
	BILLBOARD,
	GRASS_PATCH,
	POLE_AREA,
	CAR,
}

@export_enum("Billboard", "Grass Patch", "Pole Area", "Car") var spot_type: int = SpotType.BILLBOARD

@export var is_correct := false:
	set(value):
		is_correct = value
		_sync_feedback()

@export var blocked_variant := false:
	set(value):
		blocked_variant = value
		_sync_visuals()

@export var layout_bounds: Rect2 = Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0))

@export_group("Node Paths")
@export var normal_visual_path: NodePath = ^"VisualSprite"
@export var blocked_visual_path: NodePath = ^"BlockedSprite"
@export var blocked_overlay_path: NodePath = ^"BlockedOverlaySprite"
@export var feedback_root_path: NodePath = ^"Feedback"
@export var feedback_fill_path: NodePath = ^"Feedback/Fill"
@export var feedback_outline_path: NodePath = ^"Feedback/Outline"
@export var correct_marker_path: NodePath = ^"Feedback/CorrectMarker"

var normal_visual: CanvasItem
var blocked_visual: CanvasItem
var blocked_overlay: CanvasItem
var feedback_root: CanvasItem
var feedback_fill: Polygon2D
var feedback_outline: Line2D
var correct_marker: CanvasItem
var correct_marker_default_scale: Vector2 = Vector2.ONE

var feedback_color: Color = Color.TRANSPARENT
var is_revealed: bool = false
var feedback_tween: Tween
var feedback_intensity := 0.0:
	set(value):
		feedback_intensity = value
		_sync_feedback()


func _ready() -> void:
	super()
	_cache_child_nodes()
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	_sync_visuals()
	clear_feedback()


func configure_round(correct: bool, blocked: bool) -> void:
	is_correct = correct
	blocked_variant = blocked
	clear_feedback()
	set_pick_enabled(true)


func clear_feedback() -> void:
	if feedback_tween != null:
		feedback_tween.kill()
		feedback_tween = null

	feedback_color = Color.TRANSPARENT
	feedback_intensity = 0.0
	is_revealed = false
	scale = default_scale
	_sync_feedback()


func show_success_feedback() -> void:
	_play_feedback(Color(0.21, 0.73, 0.33), 0.42)


func show_failure_feedback() -> void:
	_play_feedback(Color(0.86, 0.21, 0.19), 0.35)


func reveal_as_correct() -> void:
	_play_feedback(Color(0.28, 0.76, 0.37), 0.26)


func get_layout_bounds() -> Rect2:
	return layout_bounds


func _cache_child_nodes() -> void:
	normal_visual = _get_canvas_item(normal_visual_path)
	blocked_visual = _get_canvas_item(blocked_visual_path)
	blocked_overlay = _get_canvas_item(blocked_overlay_path)
	feedback_root = _get_canvas_item(feedback_root_path)
	feedback_fill = get_node_or_null(feedback_fill_path) as Polygon2D
	feedback_outline = get_node_or_null(feedback_outline_path) as Line2D
	correct_marker = _get_canvas_item(correct_marker_path)

	var marker_node := correct_marker as Node2D
	if marker_node != null:
		correct_marker_default_scale = marker_node.scale


func _get_canvas_item(path: NodePath) -> CanvasItem:
	if String(path) == "":
		return null

	return get_node_or_null(path) as CanvasItem


func _sync_visuals() -> void:
	if not is_node_ready():
		return

	var use_blocked_visual: bool = blocked_variant and is_instance_valid(blocked_visual)
	if is_instance_valid(normal_visual):
		normal_visual.visible = not use_blocked_visual
	if is_instance_valid(blocked_visual):
		blocked_visual.visible = blocked_variant
	if is_instance_valid(blocked_overlay):
		blocked_overlay.visible = blocked_variant


func _sync_feedback() -> void:
	if not is_node_ready():
		return

	var feedback_visible: bool = feedback_intensity > 0.0
	if is_instance_valid(feedback_root):
		feedback_root.visible = feedback_visible

	var fill_color := feedback_color
	fill_color.a = 0.08 + feedback_intensity * 0.12
	if is_instance_valid(feedback_fill):
		feedback_fill.color = fill_color

	var outline_color := feedback_color
	outline_color.a = 0.28 + feedback_intensity * 0.48
	if is_instance_valid(feedback_outline):
		feedback_outline.default_color = outline_color

	if is_instance_valid(correct_marker):
		correct_marker.visible = feedback_visible and is_revealed and is_correct
		correct_marker.modulate = outline_color

	var marker_node := correct_marker as Node2D
	if marker_node != null:
		marker_node.scale = correct_marker_default_scale * (1.0 + feedback_intensity * 0.3)


func _play_feedback(color: Color, settled_intensity: float) -> void:
	if feedback_tween != null:
		feedback_tween.kill()

	feedback_color = color
	is_revealed = true
	feedback_intensity = 0.0
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "feedback_intensity", 1.0, 0.12)
	feedback_tween.tween_property(self, "feedback_intensity", settled_intensity, 0.18)
	feedback_tween.finished.connect(_on_feedback_finished)


func _on_feedback_finished() -> void:
	feedback_tween = null


func _on_picked(_pickable: Variant) -> void:
	spot_selected.emit(self)
