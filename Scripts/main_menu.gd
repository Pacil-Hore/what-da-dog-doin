extends Control

func _ready():
	$VBox/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$VBox/FreePlayButton.pressed.connect(func(): AppManager.start_free_play())
	$VBox/QuitButton.pressed.connect(func(): get_tree().quit())
