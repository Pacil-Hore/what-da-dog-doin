@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name PickTheRopeHook

signal hook_pressed(hook_index: int)

enum FeedbackState {
	NEUTRAL,
	CORRECT,
	WRONG,
	DIMMED,
}

@export var hook_index: int = 0
@export var rope_color: Color = Color(0.9, 0.37, 0.39):
	set(value):
		rope_color = value
		if is_node_ready():
			_sync_visuals()
@export var hook_metal_color: Color = Color(0.76, 0.78, 0.82):
	set(value):
		hook_metal_color = value
		if is_node_ready():
			_sync_visuals()
@export var feedback_state: int = FeedbackState.NEUTRAL:
	set(value):
		feedback_state = value
		if is_node_ready():
			_sync_visuals()

@onready var glow: Sprite2D = get_node_or_null("Glow") as Sprite2D
@onready var ring_shadow: Sprite2D = get_node_or_null("RingShadow") as Sprite2D
@onready var ring_outer: Sprite2D = get_node_or_null("RingOuter") as Sprite2D
@onready var ring_inner: Sprite2D = get_node_or_null("RingInner") as Sprite2D
@onready var stem_shadow: Line2D = get_node_or_null("StemShadow") as Line2D
@onready var stem: Line2D = get_node_or_null("Stem") as Line2D
@onready var clasp: Line2D = get_node_or_null("Clasp") as Line2D
@onready var rope_tail_shadow: Line2D = get_node_or_null("RopeTailShadow") as Line2D
@onready var rope_tail: Line2D = get_node_or_null("RopeTail") as Line2D

var is_hovered: bool = false


func _ready() -> void:
	super()
	hover_scale = Vector2(1.08, 1.08)
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	if not mouse_entered.is_connected(_on_mouse_entered_local):
		mouse_entered.connect(_on_mouse_entered_local)
	if not mouse_exited.is_connected(_on_mouse_exited_local):
		mouse_exited.connect(_on_mouse_exited_local)
	_sync_visuals()


func reset_hook(index: int, new_rope_color: Color) -> void:
	hook_index = index
	rope_color = new_rope_color
	feedback_state = FeedbackState.NEUTRAL
	is_hovered = false
	scale = default_scale
	set_pick_enabled(true)
	_sync_visuals()


func set_feedback_state(value: int) -> void:
	feedback_state = value


func _sync_visuals() -> void:
	var glow_color: Color = Color.TRANSPARENT
	var clasp_color: Color = rope_color
	var ring_color: Color = hook_metal_color
	var rope_tail_color: Color = rope_color
	var shadow_color: Color = Color(0.11, 0.1, 0.09, 0.26)

	match feedback_state:
		FeedbackState.CORRECT:
			glow_color = Color(0.28, 0.77, 0.39, 0.28)
			clasp_color = Color(0.28, 0.77, 0.39)
			rope_tail_color = clasp_color
		FeedbackState.WRONG:
			glow_color = Color(0.88, 0.26, 0.23, 0.28)
			clasp_color = Color(0.88, 0.26, 0.23)
			rope_tail_color = clasp_color
		FeedbackState.DIMMED:
			ring_color = hook_metal_color.darkened(0.2)
			ring_color.a = 0.38
			rope_tail_color = rope_color.darkened(0.2)
			rope_tail_color.a = 0.24
			clasp_color = rope_tail_color
			shadow_color.a = 0.08
		_:
			if pick_enabled and is_hovered:
				glow_color = Color(1.0, 1.0, 1.0, 0.14)
				clasp_color = rope_color.lightened(0.16)

	_set_sprite_color(glow, glow_color, glow_color.a > 0.0)
	_set_sprite_color(ring_shadow, shadow_color, true)
	_set_sprite_color(ring_outer, ring_color, true)
	_set_sprite_color(ring_inner, Color(0.26, 0.29, 0.34), true)
	_set_line_color(stem_shadow, Color(0.26, 0.29, 0.34))
	_set_line_color(stem, ring_color)
	_set_line_color(clasp, clasp_color)
	_set_line_color(rope_tail_shadow, Color(0.13, 0.1, 0.08, shadow_color.a))
	_set_line_color(rope_tail, rope_tail_color)


func _set_sprite_color(sprite: Sprite2D, color: Color, should_show: bool) -> void:
	if sprite == null:
		return
	sprite.visible = should_show
	sprite.modulate = color


func _set_line_color(line: Line2D, color: Color) -> void:
	if line == null:
		return
	line.default_color = color


func _on_picked(_pickable: Variant) -> void:
	hook_pressed.emit(hook_index)


func _on_mouse_entered_local() -> void:
	is_hovered = true
	_sync_visuals()


func _on_mouse_exited_local() -> void:
	is_hovered = false
	_sync_visuals()
