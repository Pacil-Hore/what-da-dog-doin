@tool
extends Node2D

signal state_changed(state_index: int)

@export var current_state_index := 0:
	set(value):
		current_state_index = clampi(value, 0, max(get_state_count() - 1, 0))
		_sync_state()

@export var completed_state_index := 2
@export var state_labels: Array[String] = ["A", "B", "C"]:
	set(value):
		state_labels = value
		_sync_state()
@export var visual_container_path := NodePath("Visuals")
@export var state_label_path := NodePath("StateLabel")


func _ready() -> void:
	_sync_state()


func set_state_index(value: int) -> void:
	current_state_index = value


func advance_state() -> void:
	set_state_index(current_state_index + 1)


func is_completed() -> bool:
	return current_state_index >= completed_state_index


func get_state_count() -> int:
	var visual_container: Node = get_node_or_null(visual_container_path)
	if visual_container != null:
		return visual_container.get_child_count()
	return max(state_labels.size(), completed_state_index + 1)


func _draw() -> void:
	draw_circle(Vector2(0.0, 10.0), 80.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, 76.0, Color(0.05, 0.06, 0.075))
	draw_circle(Vector2.ZERO, 69.0, Color(0.18, 0.21, 0.24))
	draw_arc(Vector2.ZERO, 76.0, -PI * 0.8, PI * 0.2, 64, Color(1.0, 1.0, 1.0, 0.12), 4.0)


func _sync_state() -> void:
	if not is_inside_tree():
		return

	_sync_visuals()
	_sync_label()
	queue_redraw()
	state_changed.emit(current_state_index)


func _sync_visuals() -> void:
	var visual_container: Node = get_node_or_null(visual_container_path)
	if visual_container == null:
		return

	for index in range(visual_container.get_child_count()):
		var visual: Node = visual_container.get_child(index)
		if visual is CanvasItem:
			visual.visible = index == current_state_index


func _sync_label() -> void:
	var state_label := get_node_or_null(state_label_path) as Label
	if state_label == null:
		return
	if current_state_index >= 0 and current_state_index < state_labels.size():
		state_label.text = state_labels[current_state_index]
	else:
		state_label.text = str(current_state_index)
