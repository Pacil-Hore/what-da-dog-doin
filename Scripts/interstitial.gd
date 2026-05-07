extends Control

signal interstitial_done

@onready var lives_label = $VBoxContainer/LivesLabel
@onready var game_number_label = $VBoxContainer/GameNumberLabel
@onready var speed_up_label = $VBoxContainer/SpeedUpLabel

func setup(lives: int, game_num: int, is_speed_up: bool, is_boss: bool):
	if is_boss:
		game_number_label.text = "BOSS STAGE"
	else:
		game_number_label.text = "Game: " + str(game_num)
		
	lives_label.text = "Lives: " + str(lives)
	
	if is_speed_up:
		speed_up_label.visible = true
	else:
		speed_up_label.visible = false

func _ready():
	# Wait 2 scaled seconds before emitting done
	await get_tree().create_timer(2.0, false).timeout
	emit_signal("interstitial_done")
