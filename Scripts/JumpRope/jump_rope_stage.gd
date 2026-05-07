extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Jump!"
@export var control_hint: String = "Spacebar"
@export var control_icon_path: String = "res://assets/generated/spacebar_icon.png"

@export var start_delay_duration: float = 0.0
@export var round_duration: float = 5.0
@export var rope_cycle_duration: float = 1.05
@export var final_rope_cycle_duration: float = 0.72
@export var jump_duration: float = 0.42
@export var max_misses: int = 3
@export var win_label_text: String = "Safe landing!"
@export var lose_label_text: String = "The rope tripped the dog!"
@export var timeout_label_text: String = "You kept the rhythm!"
@export var instruction_text: String = "Press Space or left click before the rope hits the dog's paws."
@export var timeout_wins: bool = true

@onready var rope: JumpRopeRope = $Playfield/Rope
@onready var dog: JumpRopeDog = $Playfield/Dog
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")

var time_left: float = 0.0
var start_delay_left: float = 0.0
var miss_count: int = 0
var is_finished: bool = false
var is_round_active: bool = false

const ROPE_IMPACT_PHASE: float = 0.5


func _ready() -> void:
	rope.cycle_duration = rope_cycle_duration
	if is_instance_valid(countdown_timer):
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
	if time_left <= 0.0:
		return

	_sync_rope_speed()
	var previous_phase: float = rope.get_cycle_phase()
	rope.advance_cycle(delta)
	var current_phase: float = rope.get_cycle_phase()
	if _did_phase_cross(previous_phase, current_phase, ROPE_IMPACT_PHASE):
		_resolve_rope_impact()


func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		return

	if _is_jump_input(event):
		_attempt_jump()
		get_viewport().set_input_as_handled()


func reset_game() -> void:
	is_finished = false
	is_round_active = false
	time_left = round_duration
	start_delay_left = maxf(start_delay_duration, 0.0)
	miss_count = 0
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	rope.cycle_duration = rope_cycle_duration
	rope.reset_cycle()
	rope.set_running(false)
	dog.reset_pose()
	_update_hud()
	if start_delay_left <= 0.0:
		_start_round()


func finish_game(did_win: bool, message: String) -> void:
	if is_finished:
		return

	is_finished = true
	is_round_active = false
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	if is_instance_valid(rope):
		rope.set_running(false)
	
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _attempt_jump() -> void:
	if not is_round_active or time_left <= 0.0:
		return

	if dog.is_jump_active():
		return

	dog.start_jump(jump_duration)


func _is_jump_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed

	if event is InputEventKey:
		return event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE)

	return false


func _did_phase_cross(previous_phase: float, current_phase: float, target_phase: float) -> bool:
	if previous_phase <= current_phase:
		return previous_phase < target_phase and target_phase <= current_phase

	return previous_phase < target_phase or target_phase <= current_phase


func _sync_rope_speed() -> void:
	var round_progress: float = 1.0 - (time_left / maxf(round_duration, 0.01))
	rope.cycle_duration = lerpf(rope_cycle_duration, final_rope_cycle_duration, clampf(round_progress, 0.0, 1.0))


func _start_round() -> void:
	if is_finished or is_round_active:
		return

	is_round_active = true
	time_left = round_duration
	rope.cycle_duration = rope_cycle_duration
	rope.set_running(true)
	if is_instance_valid(countdown_timer):
		countdown_timer.start(round_duration)
	_update_hud()


func _resolve_rope_impact() -> void:
	if dog.is_jump_active():
		return

	_register_miss()


func _register_miss() -> void:
	if is_finished:
		return

	miss_count += 1
	_update_hud()
	if miss_count >= max_misses:
		finish_game(false, lose_label_text)


func _update_hud() -> void:
	pass


func _on_countdown_timer_timeout() -> void:
	if is_finished:
		return

	finish_game(true, timeout_label_text if timeout_label_text != "" else win_label_text)
