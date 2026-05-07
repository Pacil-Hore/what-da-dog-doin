extends Area2D

@export var win_screen_scene: PackedScene
@export var show_win_screen: bool = false

signal level_completed

var entities_arrived: Array = []
var triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("FinishArea ready! Path: ", get_path())

func _on_body_entered(body):
	if not body is CharacterBody2D:
		return
	
	# Skip kalau entity udah mati
	if "is_alive" in body and not body.is_alive:
		return
	
	# Set safe area (biar gak ke-detect "jatuh")
	if "is_on_safe_area" in body:
		body.is_on_safe_area = true
	
	# Track yang udah sampe
	if body not in entities_arrived:
		entities_arrived.append(body)
		print(body.name, " sampe finish! Total: ", entities_arrived.size())
	
	# Cek menang
	if not triggered and entities_arrived.size() >= 2:
		triggered = true
		print("LEVEL COMPLETED!")
		level_completed.emit()
		if show_win_screen:
			_show_win_screen()

func _on_body_exited(body):
	if not body is CharacterBody2D:
		return
	if "is_on_safe_area" in body:
		body.is_on_safe_area = false

func _show_win_screen():
	# Stop kamera
	var camera = get_viewport().get_camera_2d()
	if camera and "auto_scroll" in camera:
		camera.auto_scroll = false
	
	# Disable input
	for body in entities_arrived:
		body.set_process_input(false)
	
	# Tampilkan win screen
	if win_screen_scene:
		var win_screen = win_screen_scene.instantiate()
		get_tree().current_scene.add_child(win_screen)
