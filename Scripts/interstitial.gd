extends Control

signal interstitial_done

@export var display_duration: float = 2.0

@onready var lives_label = $VBoxContainer/LivesLabel
@onready var control_icon = $VBoxContainer/ControlIcon
@onready var speed_up_label = $VBoxContainer/SpeedUpLabel
@onready var boss_label = $VBoxContainer/BossLabel

func setup(lives: int, icon: Texture2D, is_speed_up: bool, is_boss: bool):
	if icon != null:
		control_icon.texture = icon
		
	lives_label.text = "Lives: " + str(lives)
	
	speed_up_label.visible = is_speed_up
	boss_label.visible = is_boss

func _ready():
	await get_tree().create_timer(display_duration, false).timeout
	emit_signal("interstitial_done")
