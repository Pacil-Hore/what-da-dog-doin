extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Pick the right place!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var time_limit: float = 3.0
@export var instruction_text: String = "Left click the best toilet spot before time runs out."
@export var win_label_text: String = "Good dog!"
@export var lose_label_text: String = "That spot won't work!"
@export var timeout_label_text: String = "Time is up!"
@export var disable_freeze_on_loss := true

@onready var billboard_spot: ToiletSpot = $Hotspots/BillboardSpot
@onready var grass_spot: ToiletSpot = $Hotspots/GrassSpot
@onready var pole_spot: ToiletSpot = $Hotspots/PoleSpot
@onready var car_spot: ToiletSpot = $Hotspots/CarSpot
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")

var spots: Array[ToiletSpot] = []
var correct_spot: ToiletSpot
var is_finished: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var slot_positions: Array[Vector2] = []


func _ready() -> void:
	rng.randomize()
	spots = [billboard_spot, grass_spot, pole_spot, car_spot]
	slot_positions = [
		billboard_spot.position,
		grass_spot.position,
		pole_spot.position,
		car_spot.position,
	]
	for spot in spots:
		if not spot.spot_selected.is_connected(_on_spot_selected):
			spot.spot_selected.connect(_on_spot_selected)

	if is_instance_valid(countdown_timer):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(_delta: float) -> void:
	if is_finished:
		return


func reset_game() -> void:
	is_finished = false
	_randomize_spot_positions()
	_configure_round_layout()

	for spot in spots:
		spot.set_pick_enabled(true)

	if is_instance_valid(countdown_timer):
		countdown_timer.start(time_limit)


func finish_game(did_win: bool, _message: String, selected_spot: ToiletSpot = null, reveal_correct: bool = false) -> void:
	if is_finished:
		return

	is_finished = true
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	for spot in spots:
		spot.set_pick_enabled(false)

	if selected_spot != null:
		if did_win:
			selected_spot.show_success_feedback()
		else:
			selected_spot.show_failure_feedback()

	if reveal_correct and correct_spot != null and correct_spot != selected_spot:
		correct_spot.reveal_as_correct()
	
	if did_win:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _configure_round_layout() -> void:
	var grass_is_correct: bool = rng.randi_range(0, 1) == 0
	billboard_spot.configure_round(false, false)
	car_spot.configure_round(false, false)
	grass_spot.configure_round(grass_is_correct, not grass_is_correct)
	pole_spot.configure_round(not grass_is_correct, grass_is_correct)
	correct_spot = grass_spot if grass_is_correct else pole_spot


func _randomize_spot_positions() -> void:
	var shuffled_positions: Array[Vector2] = slot_positions.duplicate()
	for index in range(shuffled_positions.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: Vector2 = shuffled_positions[index]
		shuffled_positions[index] = shuffled_positions[swap_index]
		shuffled_positions[swap_index] = temp

	for index in range(spots.size()):
		spots[index].position = shuffled_positions[index]


func _on_spot_selected(spot: ToiletSpot) -> void:
	if is_finished:
		return

	if spot.is_correct:
		finish_game(true, win_label_text, spot)
		return

	finish_game(false, lose_label_text, spot, true)


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text, null, true)
