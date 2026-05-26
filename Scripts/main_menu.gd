extends Control

func _ready():
	$MenuButtons/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$MenuButtons/PickStageButton.pressed.connect(func(): AppManager.go_to_stage_select())
	$MenuButtons/QuitButton.pressed.connect(func(): get_tree().quit())
