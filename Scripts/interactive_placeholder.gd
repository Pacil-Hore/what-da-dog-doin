extends Node2D

signal game_won
signal game_lost

@export var label_text: String = "Placeholder Game"
@export var objective_text: String = "Placeholder Instruction"
@export var control_hint: String = "Mouse"
@export var control_icon_path: String = "res://assets/generated/placeholder_icon.png"
@export var time_limit: float = 5.0

@onready var title_label: Label = $UI/VBox/TitleLabel
@onready var win_button: Button = $UI/VBox/WinButton
@onready var lose_button: Button = $UI/VBox/LoseButton

var time_left: float = 0.0
var is_done: bool = false

func _ready():
	title_label.text = label_text
	time_left = time_limit
	win_button.pressed.connect(_on_win)
	lose_button.pressed.connect(_on_lose)

func _process(delta: float):
	if is_done:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_on_lose()

func _on_win():
	if is_done:
		return
	is_done = true
	win_button.disabled = true
	lose_button.disabled = true
	await get_tree().create_timer(0.2, false).timeout
	emit_signal("game_won")

func _on_lose():
	if is_done:
		return
	is_done = true
	win_button.disabled = true
	lose_button.disabled = true
	await get_tree().create_timer(0.2, false).timeout
	emit_signal("game_lost")
