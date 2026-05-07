extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Spin to untangle!"
@export var control_hint: String = "Mouse"
@export var control_icon_path: String = "res://assets/generated/mouse_icon.png"

@export var time_limit := 5.0
@export var rotations_per_state := 5
@export var win_label_text := "Untangled!"
@export var timeout_label_text := "Time is up!"

@onready var state_object = $StateObject
@onready var motion_detector = $CircularMotionDetector
@onready var motion_guide = $MotionGuide
@onready var countdown_timer: Timer = $CountdownTimer
@onready var timer_label: Label = $HUD/TimerLabel
@onready var progress_label: Label = $HUD/ProgressLabel
@onready var result_label: Label = $HUD/ResultLabel

var time_left := 0.0
var is_finished := false
var rotations_in_current_state := 0


func _ready() -> void:
	motion_guide.min_radius = motion_detector.min_radius
	motion_guide.max_radius = motion_detector.max_radius
	motion_detector.rotation_completed.connect(_on_rotation_completed)
	motion_detector.progress_changed.connect(_on_motion_progress_changed)
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(delta: float) -> void:
	if is_finished:
		return

	time_left = max(time_left - delta, 0.0)
	timer_label.text = "Time: %.1f" % time_left
	motion_detector.sample(get_global_mouse_position(), state_object.global_position, delta)


func reset_game() -> void:
	is_finished = false
	time_left = time_limit
	rotations_in_current_state = 0
	result_label.text = ""
	state_object.set_state_index(0)
	motion_guide.set_progress(0.0)
	motion_detector.reset()
	motion_detector.set_motion_enabled(true)
	countdown_timer.start(time_limit)
	_update_hud()


func finish_game(did_win: bool, message: String) -> void:
	if is_finished:
		return

	is_finished = true
	countdown_timer.stop()
	motion_detector.set_motion_enabled(false)
	result_label.text = message
	
	await get_tree().create_timer(1.0, false).timeout
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _update_hud() -> void:
	timer_label.text = "Time: %.1f" % time_left
	progress_label.text = "Rotations: %d/%d" % [rotations_in_current_state, rotations_per_state]


func _on_rotation_completed(_total_rotations: int) -> void:
	if is_finished:
		return

	rotations_in_current_state += 1
	if rotations_in_current_state >= rotations_per_state:
		rotations_in_current_state = 0
		state_object.advance_state()
		if state_object.is_completed():
			_update_hud()
			finish_game(true, win_label_text)
			return

	_update_hud()


func _on_motion_progress_changed(progress: float) -> void:
	motion_guide.set_progress(progress)


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text)
