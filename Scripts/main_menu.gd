extends Control

func _ready():
	$VBox/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$VBox/PickStageButton.pressed.connect(func(): AppManager.go_to_stage_select())
	$VBox/QuitButton.pressed.connect(func(): get_tree().quit())
