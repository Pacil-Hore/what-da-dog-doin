extends Control

func _ready():
	$MenuButtons/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$MenuButtons/FreePlayButton.pressed.connect(func(): AppManager.start_free_play())
	$MenuButtons/QuitButton.pressed.connect(func(): get_tree().quit())
