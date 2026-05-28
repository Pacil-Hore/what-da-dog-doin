extends Control

@onready var menu_music = $MenuMusic

func _ready():
	# Mulai musik menu
	menu_music.play()
	
	$MenuButtons/StoryButton.pressed.connect(_on_story_pressed)
	$MenuButtons/EndlessButton.pressed.connect(_on_endless_pressed)
	$MenuButtons/QuitButton.pressed.connect(func(): get_tree().quit())

func _on_story_pressed():
	_stop_music_and_start(func(): AppManager.start_story_mode())

func _on_endless_pressed():
	_stop_music_and_start(func(): AppManager.start_endless_mode())

func _stop_music_and_start(start_callback: Callable):
	# Fade out musik menu, terus mulai game
	var tween = create_tween()
	tween.tween_property(menu_music, "volume_db", -40.0, 0.5)
	tween.tween_callback(menu_music.stop)
	tween.tween_callback(start_callback)
