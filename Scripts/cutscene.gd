extends Control

@export var cutscene_title: String = "Cutscene"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	
	$ContinueButton.pressed.connect(_on_continue)
	video_player.finished.connect(_on_continue)

func _on_continue():
	AppManager.story_cutscene_done()
