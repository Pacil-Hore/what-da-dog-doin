extends Control

func _ready():
	$MenuButtons/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$MenuButtons/EndlessButton.pressed.connect(func(): AppManager.start_endless_mode())
	$MenuButtons/QuitButton.pressed.connect(func(): get_tree().quit())
