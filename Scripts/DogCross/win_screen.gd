extends CanvasLayer

@export var main_menu_scene: PackedScene  # drag scene main menu di Inspector

@onready var back_button: Button = %BackButton

func _ready():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	if main_menu_scene:
		get_tree().change_scene_to_packed(main_menu_scene)
	else:
		print("WARNING: main_menu_scene belum di-assign!")
