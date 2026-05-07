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
@export var rope_color: Color = Color(0.9, 0.37, 0.39)
@export var hook_metal_color: Color = Color(0.76, 0.78, 0.82)
@export var ring_radius: float = 16.0
@export var feedback_state: int = FeedbackState.NEUTRAL:
	set(value):
		feedback_state = value
		queue_redraw()

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
	queue_redraw()


func reset_hook(index: int, new_rope_color: Color) -> void:
	hook_index = index
	rope_color = new_rope_color
	feedback_state = FeedbackState.NEUTRAL
	is_hovered = false
	scale = default_scale
	set_pick_enabled(true)
	queue_redraw()


func set_feedback_state(value: int) -> void:
	feedback_state = value
	queue_redraw()


func _draw() -> void:
	var glow_color: Color = Color.TRANSPARENT
	var clasp_color: Color = rope_color
	var ring_color: Color = hook_metal_color
	var rope_tail_color: Color = rope_color
	var ring_shadow_color: Color = Color(0.11, 0.1, 0.09, 0.26)

	match feedback_state:
		FeedbackState.CORRECT:
			glow_color = Color(0.28, 0.77, 0.39, 0.28)
			clasp_color = Color(0.28, 0.77, 0.39)
		FeedbackState.WRONG:
			glow_color = Color(0.88, 0.26, 0.23, 0.28)
			clasp_color = Color(0.88, 0.26, 0.23)
		FeedbackState.DIMMED:
			var dim_metal: Color = hook_metal_color.darkened(0.2)
			dim_metal.a = 0.38
			ring_color = dim_metal
			var dim_tail: Color = rope_color.darkened(0.2)
			dim_tail.a = 0.24
			rope_tail_color = dim_tail
			ring_shadow_color.a = 0.08
		_:
			if pick_enabled and is_hovered:
				glow_color = Color(1.0, 1.0, 1.0, 0.14)
				clasp_color = rope_color.lightened(0.16)

	if glow_color.a > 0.0:
		draw_circle(Vector2.ZERO, ring_radius + 12.0, glow_color)

	draw_circle(Vector2(0.0, 4.0), ring_radius + 4.0, ring_shadow_color, false, 7.0)
	draw_circle(Vector2.ZERO, ring_radius, Color(0.26, 0.29, 0.34), false, 5.0)
	draw_circle(Vector2.ZERO, ring_radius, ring_color, false, 2.8)
	draw_line(Vector2(-2.0, -20.0), Vector2(-2.0, -4.0), Color(0.26, 0.29, 0.34), 5.0)
	draw_line(Vector2(-2.0, -20.0), Vector2(-2.0, -4.0), ring_color, 2.6)
	draw_line(Vector2(6.0, -6.0), Vector2(16.0, 8.0), clasp_color, 3.0)
	draw_line(Vector2(-1.0, ring_radius + 4.0), Vector2(4.0, ring_radius + 26.0), Color(0.13, 0.1, 0.08, 0.22), 7.0)
	draw_line(Vector2.ZERO + Vector2(0.0, ring_radius + 4.0), Vector2(4.0, ring_radius + 26.0), rope_tail_color, 4.2)


func _on_picked(_pickable: Variant) -> void:
	hook_pressed.emit(hook_index)


func _on_mouse_entered_local() -> void:
	is_hovered = true
	queue_redraw()


func _on_mouse_exited_local() -> void:
	is_hovered = false
	queue_redraw()
