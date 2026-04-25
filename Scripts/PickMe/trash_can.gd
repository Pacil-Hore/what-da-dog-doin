@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name PickMeTrashCan

signal trash_can_picked(trash_can: PickMeTrashCan)

@export var has_clue := false
@export var reveal_lift := 100.0
@export var reveal_duration := 0.35
@export var reveal_rotation_degrees := 10.0

var is_revealed := false
var closed_shell_position := Vector2.ZERO

@onready var shell: Node2D = $Shell
@onready var contents: Node2D = $Contents


func _ready() -> void:
	super()
	closed_shell_position = shell.position
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	_sync_visuals()
	queue_redraw()


func reveal() -> void:
	if is_revealed:
		return

	is_revealed = true
	set_pick_enabled(false)
	_sync_visuals()
	queue_redraw()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(shell, "position:y", closed_shell_position.y - reveal_lift, reveal_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(shell, "rotation_degrees", reveal_rotation_degrees, reveal_duration)


func reset_trash_can(clue_enabled: bool) -> void:
	has_clue = clue_enabled
	is_revealed = false
	shell.position = closed_shell_position
	shell.rotation = 0.0
	_sync_visuals()
	set_pick_enabled(true)
	queue_redraw()


func _sync_visuals() -> void:
	shell.set("has_clue", has_clue)
	contents.set("has_clue", has_clue)
	contents.visible = is_revealed


func _on_picked(_pickable: Variant) -> void:
	trash_can_picked.emit(self)
