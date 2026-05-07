extends Sprite2D

var item_type: String = ""
var drag_stage: Node = null
var drag_origin: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	drag_origin = position
	set_process(true)


func setup(type: String, texture_source: Texture2D, stage: Node) -> void:
	item_type = type
	texture = texture_source
	drag_stage = stage
	drag_origin = position


func start_drag() -> void:
	_begin_drag()


func stop_drag() -> void:
	if dragging:
		_end_drag()


func _process(_delta: float) -> void:
	if not dragging:
		return

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()
		return

	global_position = get_global_mouse_position() + drag_offset


func _begin_drag() -> void:
	if drag_stage == null:
		return

	dragging = true
	drag_offset = global_position - get_global_mouse_position()
	top_level = true
	z_index = 100


func _end_drag() -> void:
	dragging = false
	var did_consume_drop := false
	if drag_stage != null and drag_stage.has_method("handle_item_drop"):
		did_consume_drop = drag_stage.handle_item_drop(item_type, global_position)

	top_level = false
	position = drag_origin
	z_index = 0

	if did_consume_drop:
		return
