extends Control

func _ready():
	$VBox/ParkButton.pressed.connect(func(): AppManager.start_free_play("park"))
	$VBox/StreetButton.pressed.connect(func(): AppManager.start_free_play("street"))
	$VBox/BackButton.pressed.connect(func(): AppManager.go_to_main_menu())
