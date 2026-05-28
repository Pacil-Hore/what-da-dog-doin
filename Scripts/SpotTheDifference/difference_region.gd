extends Control
class_name DifferenceRegion

signal found(node)

var is_found: bool = false:
	set(value):
		is_found = value
		if is_found:
			_play_found_animation()
		queue_redraw()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 100
	z_as_relative = false
	show_behind_parent = false
	pivot_offset = size / 2
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if is_found: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_found()
		accept_event()

func _on_found() -> void:
	if is_found: return
	var parent_node := get_parent()
	if parent_node:
		parent_node.move_child(self, parent_node.get_child_count() - 1)
	z_index = 100
	z_as_relative = false
	is_found = true
	found.emit(self)

func _play_found_animation() -> void:
	var tween = create_tween().set_parallel(true)
	scale = Vector2.ONE * 1.18
	modulate = Color(2, 2, 2) # Flash white
	
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	queue_redraw()

func _draw() -> void:
	if is_found:
		var center = size / 2
		var radius = min(size.x, size.y) * 0.5
		draw_circle(center, radius, Color(0.2, 1.0, 0.2, 0.26))
		draw_arc(center, radius, 0, TAU, 32, Color(0.2, 1.0, 0.2, 1.0), 4.0, true)
