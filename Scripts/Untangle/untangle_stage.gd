extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Spin to untangle!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var time_limit := 5.0
@export var rotations_per_state := 5
@export var win_label_text := "Untangled!"
@export var timeout_label_text := "Time is up!"

@onready var state_object = $StateObject
@onready var motion_detector = $CircularMotionDetector
@onready var motion_guide = $MotionGuide
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")
@onready var spin_progress_bar: ProgressBar = get_node_or_null("HUD/SpinProgressBar")

var is_finished: bool = false
var rotations_in_current_state := 0


func _ready() -> void:
	motion_guide.min_radius = motion_detector.min_radius
	motion_guide.max_radius = motion_detector.max_radius
	motion_detector.rotation_completed.connect(_on_rotation_completed)
	motion_detector.progress_changed.connect(_on_motion_progress_changed)
	if is_instance_valid(countdown_timer):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(_delta: float) -> void:
	if is_finished:
		return
	motion_detector.sample(get_global_mouse_position(), state_object.global_position, _delta)


func reset_game() -> void:
	is_finished = false
	rotations_in_current_state = 0
	state_object.set_state_index(0)
	motion_guide.set_progress(0.0)
	motion_detector.reset()
	motion_detector.set_motion_enabled(true)
	if is_instance_valid(countdown_timer):
		countdown_timer.start(time_limit)
	_update_hud()


func finish_game(did_win: bool, _message: String) -> void:
	if is_finished:
		return

	is_finished = true
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	motion_detector.set_motion_enabled(false)
	
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _update_hud() -> void:
	if is_instance_valid(spin_progress_bar):
		spin_progress_bar.max_value = _get_total_required_rotations()
		spin_progress_bar.value = _get_completed_rotation_count()

	var progress_label = get_node_or_null("HUD/ProgressLabel")
	if is_instance_valid(progress_label):
		var state_name = "A"
		if is_instance_valid(state_object):
			var labels = state_object.state_labels
			if state_object.current_state_index < labels.size():
				state_name = labels[state_object.current_state_index]
		
		progress_label.text = "Step %s: %d / %d" % [state_name, rotations_in_current_state, rotations_per_state]


func _get_total_required_rotations() -> int:
	return max(1, rotations_per_state * state_object.completed_state_index)


func _get_completed_rotation_count() -> int:
	return clampi(
		state_object.current_state_index * rotations_per_state + rotations_in_current_state,
		0,
		_get_total_required_rotations()
	)


func _on_rotation_completed(_total_rotations: int) -> void:
	if is_finished:
		return
		
	rotations_in_current_state += 1
	_update_hud() # Update immediately on rotation
	
	if rotations_in_current_state >= rotations_per_state:
		rotations_in_current_state = 0
		state_object.advance_state()
		if state_object.is_completed():
			finish_game(true, win_label_text)
			return
		_update_hud() # Update again for new state


func _on_motion_progress_changed(progress: float) -> void:
	motion_guide.set_progress(progress)


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text)
