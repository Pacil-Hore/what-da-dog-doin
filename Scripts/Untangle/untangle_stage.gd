extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Spin to untangle!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var time_limit := 5.0
@export var rotations_per_state := 5
@export var win_label_text := "Untangled!"
@export var lose_label_text := "Still tangled!"
@export var timeout_label_text := "Still tangled!"
@export var state_art_position := Vector2(576.0, 360.0)
@export var hide_legacy_scene_art := true

@onready var state_object = $StateObject
@onready var motion_detector = $CircularMotionDetector
@onready var motion_guide = $MotionGuide
@onready var countdown_timer: Timer = get_node_or_null("CountdownTimer")
@onready var spin_progress_bar: ProgressBar = get_node_or_null("HUD/SpinProgressBar")

var is_finished: bool = false
var rotations_in_current_state := 0

@onready var trail_particles: CPUParticles2D = $SpinTrailParticles
@onready var victory_particles: CPUParticles2D = $VictoryConfettiParticles
@onready var state_clear_particles: CPUParticles2D = $StateClearParticles
@onready var left_confetti: CPUParticles2D = $LeftConfettiCannon
@onready var right_confetti: CPUParticles2D = $RightConfettiCannon
@onready var win_banner: Label = $HUD/WinBanner


func _ready() -> void:
	state_object.position = state_art_position
	motion_guide.position = state_art_position
	if hide_legacy_scene_art:
		_hide_legacy_scene_art()
	motion_guide.min_radius = motion_detector.min_radius
	motion_guide.max_radius = motion_detector.max_radius
	motion_detector.rotation_completed.connect(_on_rotation_completed)
	motion_detector.progress_changed.connect(_on_motion_progress_changed)
	if is_instance_valid(countdown_timer):
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()


func _process(_delta: float) -> void:
	if is_finished:
		if is_instance_valid(trail_particles):
			trail_particles.emitting = false
		return
	motion_detector.sample(get_global_mouse_position(), state_object.global_position, _delta)

	# 1. Update spin particle trail pos & emission
	if is_instance_valid(trail_particles):
		var mouse_pos = get_global_mouse_position()
		var dist = mouse_pos.distance_to(state_object.global_position)
		if dist >= motion_detector.min_radius and dist <= motion_detector.max_radius:
			trail_particles.global_position = mouse_pos
			trail_particles.emitting = true
		else:
			trail_particles.emitting = false

	# 2. Guide ring warning color modulation (subtler warning, only within 10px)
	if is_instance_valid(motion_guide):
		var mouse_dist = get_global_mouse_position().distance_to(state_object.global_position)
		var inner_line = motion_guide.get_node_or_null("InnerLine") as Line2D
		var outer_line = motion_guide.get_node_or_null("OuterLine") as Line2D
		var default_ring_color = Color(0.02, 0.02, 0.02, 0.08)
		var warning_color = Color(0.8, 0.3, 0.3, 0.2) # Muted red, low alpha
		
		if inner_line:
			if abs(mouse_dist - motion_detector.min_radius) < 10.0:
				inner_line.default_color = warning_color
				inner_line.width = 2.5
			else:
				inner_line.default_color = default_ring_color
				inner_line.width = 2.0
				
		if outer_line:
			if abs(mouse_dist - motion_detector.max_radius) < 10.0:
				outer_line.default_color = warning_color
				outer_line.width = 2.5
			else:
				outer_line.default_color = default_ring_color
				outer_line.width = 2.0

	# 3. Timer UI warning feedback (subtler flashing/shaking, triggered under 1.5 seconds)
	if is_instance_valid(countdown_timer) and not countdown_timer.is_stopped():
		var time_left = countdown_timer.time_left
		if time_left < 1.5:
			var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.015)
			var alert_color = Color(1.0, 1.0 - pulse * 0.4, 1.0 - pulse * 0.4, 1.0) # Pinkish/soft red
			
			if is_instance_valid(spin_progress_bar):
				spin_progress_bar.modulate = alert_color
				var jitter = Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6))
				spin_progress_bar.position = Vector2(576.0 - 220.0, 86.0) + jitter
				
			var progress_label = get_node_or_null("HUD/ProgressLabel")
			if is_instance_valid(progress_label):
				progress_label.modulate = alert_color
		else:
			if is_instance_valid(spin_progress_bar):
				spin_progress_bar.modulate = Color.WHITE
				spin_progress_bar.position = Vector2(576.0 - 220.0, 86.0)
			var progress_label = get_node_or_null("HUD/ProgressLabel")
			if is_instance_valid(progress_label):
				progress_label.modulate = Color.WHITE


func reset_game() -> void:
	is_finished = false
	rotations_in_current_state = 0
	state_object.set_state_index(0)
	motion_guide.set_progress(0.0)
	motion_detector.reset()
	motion_detector.set_motion_enabled(true)
	if is_instance_valid(countdown_timer):
		countdown_timer.start(time_limit)
	if is_instance_valid(win_banner):
		win_banner.visible = false
	_update_hud()


func finish_game(did_win: bool, _message: String) -> void:
	if is_finished:
		return

	is_finished = true
	if is_instance_valid(countdown_timer):
		countdown_timer.stop()
	motion_detector.set_motion_enabled(false)
	
	# Stop trail particles
	if is_instance_valid(trail_particles):
		trail_particles.emitting = false
		
	# Reset progress bar modulate and position
	if is_instance_valid(spin_progress_bar):
		spin_progress_bar.modulate = Color.WHITE
		spin_progress_bar.position = Vector2(576.0 - 220.0, 86.0)
	var progress_label = get_node_or_null("HUD/ProgressLabel")
	if is_instance_valid(progress_label):
		progress_label.modulate = Color.WHITE

	if did_win:
		# Suppress game manager's default feedback label
		win_label_text = ""
		emit_signal("game_won")
		
		# Trigger particles
		if is_instance_valid(victory_particles):
			victory_particles.global_position = state_art_position
			victory_particles.emitting = true
		if is_instance_valid(left_confetti):
			left_confetti.global_position = Vector2(50.0, 450.0)
			left_confetti.emitting = true
		if is_instance_valid(right_confetti):
			right_confetti.global_position = Vector2(1102.0, 450.0)
			right_confetti.emitting = true
			
		# Slow-motion impact (time dilation)
		Engine.time_scale = 0.25
		var time_tween = create_tween()
		time_tween.tween_interval(0.05) # ~0.2s of real time at 0.25 time_scale
		time_tween.tween_property(Engine, "time_scale", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Screen shake (rapidly tweening stage position)
		var shake_tween = create_tween()
		for i in range(6):
			var offset = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
			shake_tween.tween_property(self, "position", offset, 0.05)
		shake_tween.tween_property(self, "position", Vector2.ZERO, 0.05)
		
		# Custom juicy win banner overlay
		if is_instance_valid(win_banner):
			win_banner.visible = true
			win_banner.scale = Vector2.ZERO
			win_banner.rotation = 0.0
			
			# Animate the win banner (bounce pop + wiggles)
			var banner_tween = create_tween().set_parallel(true)
			banner_tween.tween_property(win_banner, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			banner_tween.tween_property(win_banner, "rotation", 0.05, 0.1)
			
			var wiggle_tween = create_tween().set_loops(4)
			wiggle_tween.tween_property(win_banner, "rotation", -0.05, 0.125).set_trans(Tween.TRANS_SINE)
			wiggle_tween.tween_property(win_banner, "rotation", 0.05, 0.125).set_trans(Tween.TRANS_SINE)
	else:
		emit_signal("game_lost")


func _update_hud() -> void:
	if is_instance_valid(spin_progress_bar):
		spin_progress_bar.max_value = _get_total_required_rotations()
		spin_progress_bar.value = _get_completed_rotation_count()

	var progress_label = get_node_or_null("HUD/ProgressLabel")
	if is_instance_valid(progress_label):
		var state_name = "A"
		if is_instance_valid(state_object):
			var labels = state_object.state_labels
			if state_object.current_state_index < labels.size():
				state_name = labels[state_object.current_state_index]
		
		progress_label.text = "Step %s: %d / %d" % [state_name, rotations_in_current_state, rotations_per_state]


func _get_total_required_rotations() -> int:
	return max(1, rotations_per_state * state_object.completed_state_index)


func _get_completed_rotation_count() -> int:
	return clampi(
		state_object.current_state_index * rotations_per_state + rotations_in_current_state,
		0,
		_get_total_required_rotations()
	)


func _on_rotation_completed(_total_rotations: int) -> void:
	if is_finished:
		return
		
	rotations_in_current_state += 1
	_update_hud() # Update immediately on rotation
	
	# Show progress text (e.g. "1/5") as spin success indicator
	var progress_text = "%d/%d" % [rotations_in_current_state, rotations_per_state]
	_show_spin_success_indicator(progress_text)
	
	# Rotation completed flash & bounce juice (toned down)
	if is_instance_valid(state_object):
		state_object.modulate = Color(1.3, 1.3, 1.3, 1.0) # Subtle brightness boost
		var flash_tween = create_tween()
		flash_tween.tween_property(state_object, "modulate", Color.WHITE, 0.15)
		
		# Bounce scale (only if we didn't advance to a new state visual)
		if rotations_in_current_state < rotations_per_state or state_object.is_completed():
			var visual_container = state_object.get_node_or_null("Visuals")
			if visual_container and state_object.current_state_index < visual_container.get_child_count():
				var active_visual = visual_container.get_child(state_object.current_state_index)
				var sprite = active_visual.get_node_or_null("StateSprite") as Sprite2D if active_visual else null
				if sprite:
					sprite.scale = state_object.state_sprite_scale * 1.05 # 5% pop instead of 15%
					var scale_tween = create_tween()
					scale_tween.tween_property(sprite, "scale", state_object.state_sprite_scale, 0.15)
	
	if rotations_in_current_state >= rotations_per_state:
		rotations_in_current_state = 0
		var previous_state = state_object.current_state_index
		state_object.advance_state()
		
		# If the state actually advanced (and the game is not fully won yet)
		if state_object.current_state_index > previous_state and not state_object.is_completed():
			_show_state_clear_indicator()
			
		if state_object.is_completed():
			finish_game(true, win_label_text)
			return
		_update_hud() # Update again for new state


func _on_motion_progress_changed(progress: float) -> void:
	motion_guide.set_progress(progress)


func _on_countdown_timer_timeout() -> void:
	finish_game(false, timeout_label_text)


func _hide_legacy_scene_art() -> void:
	var scene_art := get_node_or_null("SceneArt")
	if scene_art == null:
		return

	for node_name in ["HumanSprite", "DogSprite", "LeftLeash", "RightLeash"]:
		var item := scene_art.get_node_or_null(node_name) as CanvasItem
		if item != null:
			item.visible = false





func _show_spin_success_indicator(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Muted green outline style matching retro aesthetic
	label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.2))
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	# Size and center the label properly over the hydrant
	label.size = Vector2(100, 40)
	label.global_position = state_art_position + Vector2(-50, -55)
	
	var hud = get_node_or_null("HUD")
	if hud:
		hud.add_child(label)
	else:
		add_child(label)
		
	# Float upwards and fade out
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -50), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.1)
	
	# Clean up automatically
	tween.chain().tween_callback(label.queue_free)


func _show_state_clear_indicator() -> void:
	var label := Label.new()
	label.text = "GOOD!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Golden color style
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Bright gold
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	
	label.size = Vector2(160, 50)
	label.global_position = state_art_position + Vector2(-80, -70)
	
	var hud = get_node_or_null("HUD")
	if hud:
		hud.add_child(label)
	else:
		add_child(label)
		
	# Float upwards higher, scale pop, and fade out
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = Vector2(80, 25) # center pivot
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 80.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	
	tween.chain().tween_callback(label.queue_free)
	
	# Emit clear sparkles
	if is_instance_valid(state_clear_particles):
		state_clear_particles.global_position = state_art_position
		state_clear_particles.emitting = true
