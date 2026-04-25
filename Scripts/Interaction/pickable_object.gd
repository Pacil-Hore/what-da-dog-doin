@tool
extends Area2D
class_name PickableObject

signal picked(pickable: PickableObject)

@export var pick_enabled := true:
	set(value):
		pick_enabled = value
		input_pickable = value
		queue_redraw()

@export var hover_scale := Vector2(1.04, 1.04)

var default_scale := Vector2.ONE


func _ready() -> void:
	default_scale = scale
	input_pickable = pick_enabled
	_connect_pickable_signals()


func set_pick_enabled(value: bool) -> void:
	pick_enabled = value


func _connect_pickable_signals() -> void:
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not pick_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		picked.emit(self)


func _on_mouse_entered() -> void:
	if pick_enabled:
		scale = default_scale * hover_scale


func _on_mouse_exited() -> void:
	scale = default_scale
