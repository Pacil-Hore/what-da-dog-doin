extends Control

signal interstitial_done

@onready var lives_label = $VBoxContainer/LivesLabel
@onready var control_icon = $VBoxContainer/ControlIcon
@onready var speed_up_label = $VBoxContainer/SpeedUpLabel
@onready var boss_label = $VBoxContainer/BossLabel

func setup(lives: int, icon_path: String, is_speed_up: bool, is_boss: bool):
	if icon_path != "":
		control_icon.texture = load(icon_path)
		
	lives_label.text = "Lives: " + str(lives)
	
	speed_up_label.visible = is_speed_up
	boss_label.visible = is_boss

func _ready():
	# Wait 2 scaled seconds before emitting done
	await get_tree().create_timer(2.0, false).timeout
	emit_signal("interstitial_done")
