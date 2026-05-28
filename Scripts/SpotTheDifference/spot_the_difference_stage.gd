extends Node2D

signal game_finished(did_win: bool)
signal game_won
signal game_lost

@export var time_limit := 10.0
@export var total_differences := 4
@export var instruction_text := "TOUCH 4 DIFFERENCES!"
@export var objective_text: String = "Spot it!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D
@export var win_label_text: String = "SPOTTED!"
@export var lose_label_text: String = "Missed it!"

@export var disable_freeze_on_loss := true

@onready var title_label: Label = $GameCanvas/MainLayout/Header/Title
@onready var game_canvas: CanvasLayer = $GameCanvas
@onready var game_field: VBoxContainer = $GameCanvas/MainLayout
@onready var image_container: HBoxContainer = $GameCanvas/MainLayout/GameArea/ImageContainer
@onready var modified_image: TextureRect = $GameCanvas/MainLayout/GameArea/ImageContainer/ModifiedImage
@onready var original_image: TextureRect = $GameCanvas/MainLayout/GameArea/ImageContainer/OriginalImage
@onready var timer_label: Label = $GameCanvas/MainLayout/Header/TimerRibbon/TimerLabel
@onready var timer_ribbon: Control = $GameCanvas/MainLayout/Header/TimerRibbon
@onready var progress_icons: HBoxContainer = $GameCanvas/MainLayout/Header/ProgressIcons
@onready var result_label: Label = $GameCanvas/ResultLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var distraction_manager: CanvasLayer = $DistractionLayer
@onready var fuse_fill: ColorRect = $GameCanvas/MainLayout/Footer/FuseBar/FuseFill
@onready var fuse_bar: Control = $GameCanvas/MainLayout/Footer/FuseBar

var differences_found := 0
var is_finished := false

func _ready() -> void:
	_setup_differences()
	if not countdown_timer.timeout.is_connected(_on_countdown_timer_timeout):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()

func reset_game() -> void:
	is_finished = false
	differences_found = 0
	result_label.text = ""
	result_label.modulate.a = 0
	
	title_label.text = instruction_text
	
	# Reset Icons: Show all icons as active at start (Count remaining)
	for icon in progress_icons.get_children():
		icon.modulate = Color.WHITE
		icon.scale = Vector2.ONE
		icon.visible = true
	
	# Start timer
	countdown_timer.wait_time = time_limit
	countdown_timer.start()
	
	_show_instruction()

func _process(_delta: float) -> void:
	if is_finished: return
	
	var time_left = countdown_timer.time_left
	timer_label.text = "%.1f" % time_left
	
	# Fuse Bar Animation: Fill shrinks left as time runs out
	var progress = time_left / time_limit
	var full_width = fuse_bar.size.x
	fuse_fill.size.x = progress * full_width
	
	# Color transition: yellow → orange → red as time runs low
	var fill_color = Color(0.98, 0.75, 0.1).lerp(Color(1.0, 0.15, 0.05), 1.0 - progress)
	fuse_fill.color = fill_color
	
	# WarioWare Low Time Juice: Ribbon Shake & Color Flash
	# WarioWare Low Time Juice: Ribbon Shake & Color Flash
	if time_left < 2.5:
		timer_ribbon.position.x = (fuse_bar.size.x / 2 - 60) + randf_range(-4, 4)
		timer_label.modulate = Color.RED if Engine.get_frames_drawn() % 6 < 3 else Color.BLACK
	else:
		timer_label.modulate = Color.BLACK
		timer_ribbon.position.x = fuse_bar.size.x / 2 - 60

func _setup_differences() -> void:
	# Setup both original and modified image containers
	var containers = [
		modified_image.get_node("Differences"),
		original_image.get_node("DifferencesOriginal")
	]
	
	total_differences = 0
	var registered_names = [] # To count unique differences across both images
	
	for container in containers:
		container.gui_input.connect(_on_difference_container_gui_input)
		for diff in container.get_children():
			if diff.has_signal("found"):
				if not diff.found.is_connected(_on_difference_found):
					diff.found.connect(_on_difference_found)
				
				# Unique differences are identified by their base name (without '1' or '2')
				var actual_base = diff.name.rstrip("12")
				if not registered_names.has(actual_base):
					registered_names.append(actual_base)
					total_differences += 1

func _on_difference_found(region: DifferenceRegion) -> void:
	if is_finished: return
	
	# Mark both regions (on original and modified) as found
	var base_name = region.name.rstrip("12")
	_sync_difference_state(base_name)
	
	differences_found += 1
	_update_hud()
	
	if differences_found >= total_differences:
		finish_game(true)

func _sync_difference_state(base_name: String) -> void:
	var containers = [
		modified_image.get_node("Differences"),
		original_image.get_node("DifferencesOriginal")
	]
	for container in containers:
		for diff in container.get_children():
			if diff.name.begins_with(base_name):
				diff.is_found = true

func _on_difference_container_gui_input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_miss()

func _handle_miss() -> void:
	# Penalty
	countdown_timer.start(max(0.1, countdown_timer.time_left - 0.5))
	
	# Aggressive UI Shake (on the image container)
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var original_pos = image_container.position
	for i in range(6):
		tween.tween_property(image_container, "position", original_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.04)
	tween.tween_property(image_container, "position", original_pos, 0.04)
	
	# Flash red background
	var bg = $GameCanvas/Background
	var flash = create_tween()
	flash.tween_property(bg, "color", Color(0.4, 0.0, 0.0), 0.05)
	flash.tween_property(bg, "color", Color(0.04, 0.04, 0.04), 0.15)

func _update_hud() -> void:
	# Countdown style: Hide icons as differences are found
	var icons = progress_icons.get_children()
	
	# Update icons visibility to show how many are left
	for i in range(icons.size()):
		var icon = icons[i]
		if i < differences_found:
			if icon.visible:
				# Add a small pop effect before hiding
				var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(icon, "scale", Vector2.ZERO, 0.3)
				tween.tween_callback(func(): icon.visible = false)
		else:
			icon.visible = true
			icon.scale = Vector2.ONE

func _show_instruction() -> void:
	result_label.text = instruction_text
	result_label.modulate.a = 1.0
	result_label.scale = Vector2(1.8, 1.8)
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.3)
	
	await get_tree().create_timer(0.8).timeout
	if not is_finished:
		create_tween().tween_property(result_label, "modulate:a", 0.0, 0.2)

func finish_game(did_win: bool) -> void:
	if is_finished: return
	is_finished = true
	countdown_timer.stop()
	
	result_label.modulate.a = 1.0
	if did_win:
		result_label.text = "CLEAN!"
		result_label.modulate = Color("#4caf50")
		game_won.emit()
	else:
		result_label.text = "TOO SLOW!"
		result_label.modulate = Color("#f44336")
		_handle_miss()
		game_lost.emit()
		
	game_finished.emit(did_win)

func _on_countdown_timer_timeout() -> void:
	if not is_finished:
		finish_game(false)
