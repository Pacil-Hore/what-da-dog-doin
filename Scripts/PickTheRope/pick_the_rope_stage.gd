extends Node2D
class_name PickTheRopeStage

signal game_finished(did_win: bool)

@export var start_delay_duration: float = 0.25
@export var time_limit: float = 4.0
@export var rope_count: int = 4
@export var instruction_text: String = "Trace your dog's leash and click the right hook before time runs out."
@export var win_label_text: String = "You found the right leash!"
@export var lose_label_text: String = "Wrong hook!"
@export var timeout_label_text: String = "Time is up!"

@onready var board: PickTheRopeBoard = $Board
@onready var countdown_timer: Timer = $CountdownTimer
@onready var timer_label: Label = $HUD/TimerLabel
@onready var instruction_label: Label = $HUD/InstructionLabel
@onready var result_label: Label = $HUD/ResultLabel

var time_left: float = 0.0
var start_delay_left: float = 0.0
var is_finished: bool = false
var is_round_active: bool = false


func _ready() -> void:
	if not board.hook_selected.is_connected(_on_hook_selected):
		board.hook_selected.connect(_on_hook_selected)

	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(delta: float) -> void:
	if is_finished:
		return

	if not is_round_active:
		start_delay_left = maxf(start_delay_left - delta, 0.0)
		_update_hud()
		if start_delay_left <= 0.0:
			_start_round()
		return

	time_left = maxf(time_left - delta, 0.0)
	_update_hud()


func reset_game() -> void:
	is_finished = false
	is_round_active = false
	time_left = maxf(time_limit, 0.0)
	start_delay_left = maxf(start_delay_duration, 0.0)
	result_label.text = ""
	instruction_label.text = instruction_text
	countdown_timer.stop()

	board.rope_count = rope_count
	board.reset_round()
	board.set_pick_enabled(false)
	_update_hud()

	if start_delay_left <= 0.0:
		_start_round()


func finish_game(did_win: bool, message: String, selected_hook_index: int = -1, reveal_correct: bool = true) -> void:
	if is_finished:
		return

	is_finished = true
	is_round_active = false
	countdown_timer.stop()
	board.set_pick_enabled(false)

	if reveal_correct:
		board.reveal_result(selected_hook_index, board.get_correct_hook_index())

	result_label.text = message
	if did_win and win_label_text != "":
		instruction_label.text = win_label_text

	game_finished.emit(did_win)


func _start_round() -> void:
	if is_finished or is_round_active:
		return

	is_round_active = true
	time_left = maxf(time_limit, 0.0)
	board.set_pick_enabled(true)
	countdown_timer.start(time_limit)
	_update_hud()


func _update_hud() -> void:
	if is_round_active:
		timer_label.text = "Time: %.1f" % time_left
	else:
		timer_label.text = "Start in: %.1f" % start_delay_left


func _on_hook_selected(hook_index: int) -> void:
	if is_finished or not is_round_active:
		return

	var correct_hook_index: int = board.get_correct_hook_index()
	if hook_index == correct_hook_index:
		finish_game(true, win_label_text, hook_index, true)
		return

	finish_game(false, lose_label_text, hook_index, true)


func _on_countdown_timer_timeout() -> void:
	if is_finished:
		return

	finish_game(false, timeout_label_text, -1, true)
