extends Control

signal restart_requested
signal menu_requested

@onready var score_label = %ScoreLabel
@onready var restart_button = %RestartButton
@onready var main_menu_button = %MainMenuButton

func setup(games_played: int):
	# Ensure the node is ready before modifying text (in case setup is called immediately after instantiate)
	if not is_inside_tree():
		await ready
	score_label.text = "You finished %d games!" % games_played

func _ready():
	restart_button.pressed.connect(func(): restart_requested.emit())
	main_menu_button.pressed.connect(func(): menu_requested.emit())
