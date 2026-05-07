extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Pick the right one!"
@export var control_hint: String = "Mouse"
@export var control_icon_path: String = "res://assets/generated/mouse_icon.png"

@export var time_limit := 3.0
@export var win_label_text := "You picked the clue!"
@export var lose_label_text := "Wrong trash can!"
@export var timeout_label_text := "Time is up!"
@export var auto_randomize_clue := true

@onready var left_trash_can: PickMeTrashCan = $TrashCans/LeftTrashCan
@onready var right_trash_can: PickMeTrashCan = $TrashCans/RightTrashCan
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")

var trash_cans: Array[PickMeTrashCan] = []
var time_left := 0.0
var is_finished := false


func _ready() -> void:
	trash_cans = [left_trash_can, right_trash_can]
	for trash_can in trash_cans:
		trash_can.trash_can_picked.connect(_on_trash_can_picked)

	if is_instance_valid(countdown_timer):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(delta: float) -> void:
	if is_finished:
		return

	time_left = max(time_left - delta, 0.0)


func reset_game() -> void:
	is_finished = false
	time_left = time_limit

	var clue_index := randi_range(0, trash_cans.size() - 1) if auto_randomize_clue else 0
	for index in range(trash_cans.size()):
		trash_cans[index].reset_trash_can(index == clue_index)

	if is_instance_valid(countdown_timer):
		countdown_timer.start(time_limit)


func finish_game(did_win: bool, message: String) -> void:
	if is_finished:
		return

	is_finished = true
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	for trash_can in trash_cans:
		trash_can.set_pick_enabled(false)
		trash_can.reveal()
	
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _on_trash_can_picked(trash_can: PickMeTrashCan) -> void:
	if trash_can.has_clue:
		finish_game(true, win_label_text)
	else:
		finish_game(false, lose_label_text)


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text)
