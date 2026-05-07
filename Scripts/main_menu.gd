extends Control

func _ready():
	$VBox/StoryButton.pressed.connect(func(): AppManager.start_story_mode())
	$VBox/PickStageButton.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/Menus/StageSelect.tscn"))
	$VBox/QuitButton.pressed.connect(func(): get_tree().quit())
