extends Node

# This script is intended to be added as an Autoload or a child of a microgame for testing.
# It detects if a microgame is running standalone and provides a simple HUD.

func _ready():
	# Wait a frame to ensure current_scene is set
	await get_tree().process_frame
	
	var scene = get_tree().current_scene
	if not scene: return
	
	# Check if this scene is a microgame (has the required signals)
	if scene.has_signal("game_won") and scene.has_signal("game_lost"):
		# Check if it's run standalone (not inside GameManager)
		# GameManager typically has a node named "HUDLayer" or similar
		if not scene.get_parent() is Window: # If parent is not root window, it's probably instanced
			return
			
		_setup_test_hud(scene)

func _setup_test_hud(microgame: Node):
	print("[MicrogameTestHelper] Standalone microgame detected. Setting up test HUD.")
	
	# Create a CanvasLayer for the HUD
	var canvas = CanvasLayer.new()
	canvas.layer = 999
	microgame.add_child(canvas)
	
	# Add a simple background for the timer
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = Vector2(200, 40)
	bg.position = Vector2(10, 10)
	canvas.add_child(bg)
	
	# Add a timer label
	var label = Label.new()
	label.name = "TestTimerLabel"
	label.position = Vector2(20, 20)
	canvas.add_child(label)
	
	# Add a result label
	var result_label = Label.new()
	result_label.name = "TestResultLabel"
	result_label.anchors_preset = Control.PRESET_CENTER
	result_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_label.add_theme_font_size_override("font_size", 48)
	canvas.add_child(result_label)
	
	# Connect signals
	microgame.game_won.connect(func(): result_label.text = "WIN!"; result_label.modulate = Color.GREEN)
	microgame.game_lost.connect(func(): result_label.text = "LOSE..."; result_label.modulate = Color.RED)
	
	# Logic for timer
	var time_limit = 5.0
	if "time_limit" in microgame:
		time_limit = microgame.time_limit
	elif "round_duration" in microgame:
		time_limit = microgame.round_duration
		
	var time_left = time_limit
	# Use a timer to update
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	microgame.add_child(timer)
	timer.timeout.connect(func():
		if result_label.text != "": return
		time_left -= 0.1
		label.text = "DEBUG TIME: %.1f" % max(time_left, 0)
		if time_left <= 0:
			timer.stop()
			if "timeout_wins" in microgame and microgame.timeout_wins:
				microgame.emit_signal("game_won")
			else:
				microgame.emit_signal("game_lost")
	)
