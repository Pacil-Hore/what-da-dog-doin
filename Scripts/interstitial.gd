extends Control

signal interstitial_done

@export var display_duration: float = 2.0

@onready var lives_label = $VBoxContainer/LivesLabel
@onready var game_number_label = $VBoxContainer/GameNumberLabel
@onready var control_icon = $VBoxContainer/ControlIcon
@onready var speed_up_label = $VBoxContainer/SpeedUpLabel
@onready var final_label = $VBoxContainer/FinalLabel

# Temporary storage variables for setup data before ready
var _lives: int = 5
var _icon: Texture2D = null
var _is_speed_up: bool = false
var _is_final: bool = false
var _current_game: int = 1
var _total_games: int = 25
var _is_endless: bool = false
var _is_setup_called: bool = false

func setup(lives: int, icon: Texture2D, is_speed_up: bool, is_final: bool, current_game: int, total_games: int, is_endless: bool = false):
	_lives = lives
	_icon = icon
	_is_speed_up = is_speed_up
	_is_final = is_final
	_current_game = current_game
	_total_games = total_games
	_is_endless = is_endless
	_is_setup_called = true
	
	if is_inside_tree():
		_apply_setup()

func _ready():
	if _is_setup_called:
		_apply_setup()
	
	await get_tree().create_timer(display_duration, false).timeout
	emit_signal("interstitial_done")

func _apply_setup():
	if _icon != null:
		control_icon.texture = _icon
	else:
		control_icon.texture = null # Reset texture to avoid showing old/default ones!
		
	lives_label.text = "Lives: " + str(_lives)
	if _is_endless:
		game_number_label.text = "Game %d/?" % _current_game
	else:
		game_number_label.text = "Game %d/%d" % [_current_game, _total_games]
	
	speed_up_label.visible = _is_speed_up
	final_label.visible = _is_final

