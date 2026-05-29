extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Blink and you'll miss it!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var time_limit := 3.0
@export var win_label_text := "CORRECT!"
@export var lose_label_text := "EMPTY BIN!"
@export var timeout_label_text := "TOO SLOW!"
@export var auto_randomize_clue := true
@export var disable_freeze_on_loss := true
@export var reveal_delay := 0.2

@onready var trash_cans_parent: Node2D = $TrashCans
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")

var trash_cans: Array[PickMeTrashCan] = []
var is_finished := false
var round_elapsed := 0.0
var clue_cued := false
var click_player: AudioStreamPlayer


func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://Assets/SFX/sfx_menu_select2.wav")
	click_player.bus = &"SFX"
	add_child(click_player)

	for child in trash_cans_parent.get_children():
		if child is PickMeTrashCan:
			trash_cans.append(child)

	for trash_can in trash_cans:
		trash_can.trash_can_picked.connect(_on_trash_can_picked)

	if is_instance_valid(countdown_timer):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(_delta: float) -> void:
	if is_finished:
		return

	round_elapsed += _delta
	if not clue_cued and round_elapsed >= time_limit * 0.5:
		clue_cued = true
		for trash_can in trash_cans:
			if trash_can.has_clue:
				trash_can.play_clue_cue()
				break

	if round_elapsed >= time_limit:
		finish_game(false, timeout_label_text)


func _input(event: InputEvent) -> void:
	if is_finished:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_pick_at(event.position)


func reset_game() -> void:
	is_finished = false
	round_elapsed = 0.0
	clue_cued = false

	var clue_index := randi_range(0, trash_cans.size() - 1) if auto_randomize_clue else 0
	for index in range(trash_cans.size()):
		trash_cans[index].reset_trash_can(index == clue_index)

	if is_instance_valid(countdown_timer):
		countdown_timer.start(time_limit)


func finish_game(did_win: bool, _message: String, selected_trash_can: PickMeTrashCan = null) -> void:
	if is_finished:
		return

	is_finished = true
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	var has_selection := is_instance_valid(selected_trash_can)
	for trash_can in trash_cans:
		trash_can.set_pick_enabled(false)
		trash_can.scale = trash_can.default_scale
		trash_can.set_selected_focus(has_selection and trash_can == selected_trash_can)

	if is_instance_valid(selected_trash_can):
		selected_trash_can.play_pick_feedback(did_win)

	await get_tree().create_timer(reveal_delay, false).timeout

	for trash_can in trash_cans:
		if trash_can.has_clue:
			trash_can.reveal(did_win)
			break
	
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _on_trash_can_picked(trash_can: PickMeTrashCan) -> void:
	if is_instance_valid(click_player):
		click_player.play()

	if trash_can.has_clue:
		finish_game(true, win_label_text, trash_can)
	else:
		finish_game(false, lose_label_text, trash_can)


func _try_pick_at(global_point: Vector2) -> void:
	for trash_can in trash_cans:
		if trash_can.contains_global_point(global_point):
			_on_trash_can_picked(trash_can)
			get_viewport().set_input_as_handled()
			return


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text)
