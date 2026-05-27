@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name PickMeTrashCan

signal trash_can_picked(trash_can: PickMeTrashCan)

@export var has_clue := false
@export_range(1, 3, 1) var bin_variant := 1
@export var reveal_lift := 100.0
@export var reveal_duration := 0.55
@export var reveal_rotation_degrees := 0.0
@export var cue_shake_duration := 0.48
@export var cue_shake_distance := 10.0
@export var click_squash_duration := 0.18
@export var wrong_shake_duration := 0.26

var is_revealed := false
var closed_position := Vector2.ZERO
var hidden_contents_position := Vector2.ZERO
var revealed_contents_position := Vector2.ZERO
var cue_tween: Tween
var feedback_tween: Tween
var reveal_tween: Tween

@onready var shell: Node2D = $Shell
@onready var contents: Node2D = $Contents


func _ready() -> void:
	super()
	closed_position = position
	revealed_contents_position = Vector2(0.0, -70.0)
	hidden_contents_position = revealed_contents_position + Vector2(0.0, reveal_lift)
	contents.position = hidden_contents_position
	_set_variant_from_name()
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	_sync_visuals()
	queue_redraw()


func play_clue_cue() -> void:
	if is_revealed:
		return

	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	cue_tween = create_tween()
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.35, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.35, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x, cue_shake_duration * 0.08)
	cue_tween.tween_interval(cue_shake_duration * 0.1)
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance, cue_shake_duration * 0.14)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance, cue_shake_duration * 0.14)
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.6, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.45, cue_shake_duration * 0.1)
	cue_tween.tween_property(self, "position:x", closed_position.x, cue_shake_duration * 0.08)


func play_pick_feedback(did_pick_correctly: bool) -> void:
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	scale = default_scale
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "scale", default_scale * Vector2(1.08, 0.9), click_squash_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(self, "scale", default_scale, click_squash_duration * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not did_pick_correctly:
		feedback_tween.tween_callback(play_wrong_feedback)


func play_wrong_feedback() -> void:
	if is_revealed:
		return

	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	cue_tween = create_tween()
	cue_tween.tween_property(self, "rotation_degrees", -4.0, wrong_shake_duration * 0.2)
	cue_tween.parallel().tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.7, wrong_shake_duration * 0.2)
	cue_tween.tween_property(self, "rotation_degrees", 4.0, wrong_shake_duration * 0.22)
	cue_tween.parallel().tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.7, wrong_shake_duration * 0.22)
	cue_tween.tween_property(self, "rotation_degrees", 0.0, wrong_shake_duration * 0.28)
	cue_tween.parallel().tween_property(self, "position:x", closed_position.x, wrong_shake_duration * 0.28)


func reveal(did_win: bool = true) -> void:
	if is_revealed:
		return

	is_revealed = true
	set_pick_enabled(false)
	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	scale = default_scale
	rotation = 0.0
	contents.position = hidden_contents_position
	_sync_visuals()
	queue_redraw()

	if is_instance_valid(reveal_tween):
		reveal_tween.kill()
	reveal_tween = create_tween()
	var duration := reveal_duration * (0.85 if did_win else 1.18)
	var transition := Tween.TRANS_BACK if did_win else Tween.TRANS_SINE
	reveal_tween.tween_property(contents, "position:y", revealed_contents_position.y, duration).set_trans(transition).set_ease(Tween.EASE_OUT)


func reset_trash_can(clue_enabled: bool) -> void:
	has_clue = clue_enabled
	is_revealed = false
	if is_instance_valid(cue_tween):
		cue_tween.kill()
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	if is_instance_valid(reveal_tween):
		reveal_tween.kill()
	position = closed_position
	rotation = 0.0
	scale = default_scale
	contents.position = hidden_contents_position
	_sync_visuals()
	set_pick_enabled(true)
	queue_redraw()


func _sync_visuals() -> void:
	shell.set("has_clue", has_clue)
	shell.set("bin_variant", bin_variant)
	contents.set("has_clue", has_clue)
	contents.visible = is_revealed


func _set_variant_from_name() -> void:
	if name.contains("Right"):
		bin_variant = 3
	elif name.contains("Middle"):
		bin_variant = 2
	else:
		bin_variant = 1


func _on_picked(_pickable: Variant) -> void:
	trash_can_picked.emit(self)
