extends Control

signal interstitial_done

@export var display_duration: float = 2.0

@onready var lives_label = $VBoxContainer/LivesLabel
@onready var game_number_label = $VBoxContainer/GameNumberLabel
@onready var control_icon = $VBoxContainer/ControlIcon
@onready var speed_up_label = $VBoxContainer/SpeedUpLabel
@onready var final_label = $VBoxContainer/FinalLabel

func setup(lives: int, icon: Texture2D, is_speed_up: bool, is_final: bool, current_game: int, total_games: int, is_endless: bool = false):
	if icon != null:
		control_icon.texture = icon
		
	lives_label.text = "Lives: " + str(lives)
	if is_endless:
		game_number_label.text = "Game %d/?" % current_game
	else:
		game_number_label.text = "Game %d/%d" % [current_game, total_games]
	
	speed_up_label.visible = is_speed_up
	final_label.visible = is_final

func _ready():
	await get_tree().create_timer(display_duration, false).timeout
	emit_signal("interstitial_done")
