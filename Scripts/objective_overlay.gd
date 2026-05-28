extends CanvasLayer

@onready var dimmer: ColorRect = $Control/Dimmer
@onready var banner: ColorRect = $Control/Banner
@onready var border_top: ColorRect = $Control/Banner/BorderTop
@onready var border_bottom: ColorRect = $Control/Banner/BorderBottom
@onready var vbox: VBoxContainer = $Control/VBoxContainer
@onready var label: Label = $Control/VBoxContainer/ObjectiveLabel

func setup(objective_text: String, game_key: String = ""):
	# 1. Parse Game Theme and Custom Animation configurations
	var theme_color = Color(1.0, 0.85, 0.1) # Default Gold
	var border_color = Color(1.0, 0.85, 0.1)
	var text_color = Color(1.0, 0.95, 0.8)
	var outline_color = Color(0.12, 0.05, 0.0)
	var anim_type = "default"
	
	var k = game_key.to_lower()
	if "tugofwar" in k:
		theme_color = Color(0.0, 0.95, 1.0) # Neon Cyan
		border_color = Color(0.0, 0.95, 1.0)
		text_color = Color(0.8, 0.98, 1.0)
		outline_color = Color(0.0, 0.18, 0.35)
		anim_type = "stretch"
	elif "toilet" in k:
		theme_color = Color(0.0, 0.64, 1.0) # Water Blue
		border_color = Color(0.0, 0.64, 1.0)
		text_color = Color(0.85, 0.95, 1.0)
		outline_color = Color(0.01, 0.08, 0.28)
		anim_type = "wave"
	elif "dogcross" in k:
		theme_color = Color(1.0, 0.18, 0.58) # Heart Pink
		border_color = Color(1.0, 0.18, 0.58)
		text_color = Color(1.0, 0.9, 0.95)
		outline_color = Color(0.35, 0.0, 0.15)
		anim_type = "spin"
	elif "jumprope" in k:
		theme_color = Color(0.15, 0.95, 0.15) # Neon Green
		border_color = Color(0.15, 0.95, 0.15)
		text_color = Color(0.9, 1.0, 0.9)
		outline_color = Color(0.02, 0.25, 0.02)
		anim_type = "bounce"
	elif "labyrinth" in k:
		theme_color = Color(0.68, 0.18, 1.0) # Mystery Purple
		border_color = Color(0.68, 0.18, 1.0)
		text_color = Color(0.95, 0.85, 1.0)
		outline_color = Color(0.2, 0.0, 0.35)
		anim_type = "elastic"
	elif "attach" in k:
		theme_color = Color(1.0, 0.1, 0.1) # Danger Red
		border_color = Color(1.0, 0.1, 0.1)
		text_color = Color(1.0, 0.9, 0.9)
		outline_color = Color(0.35, 0.0, 0.02)
		anim_type = "flash"
	elif "pickme" in k:
		theme_color = Color(1.0, 0.48, 0.0) # Bouncy Orange
		border_color = Color(1.0, 0.48, 0.0)
		text_color = Color(1.0, 0.95, 0.85)
		outline_color = Color(0.3, 0.08, 0.0)
		anim_type = "bounce_in"
	elif "picktherope" in k:
		theme_color = Color(0.0, 0.8, 0.8) # Rope Teal
		border_color = Color(0.0, 0.8, 0.8)
		text_color = Color(0.85, 1.0, 1.0)
		outline_color = Color(0.0, 0.22, 0.22)
		anim_type = "wobble"
	elif "spot" in k or "difference" in k:
		theme_color = Color(1.0, 0.72, 0.0) # Gold Orange
		border_color = Color(1.0, 0.72, 0.0)
		text_color = Color(1.0, 0.95, 0.8)
		outline_color = Color(0.25, 0.12, 0.0)
		anim_type = "flip"
	elif "untangle" in k:
		theme_color = Color(0.35, 0.95, 0.35) # Mint Green
		border_color = Color(0.35, 0.95, 0.35)
		text_color = Color(0.9, 1.0, 0.9)
		outline_color = Color(0.04, 0.22, 0.04)
		anim_type = "wobble"

	# 2. Apply Custom Colors to existing scene nodes
	label.text = objective_text.to_upper()
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 20)
	
	banner.color = Color(theme_color.r * 0.08, theme_color.g * 0.08, theme_color.b * 0.12, 0.82)
	border_top.color = border_color
	border_bottom.color = border_color

	# 3. Position and Pivot calculations (modular and clean)
	label.reset_size()
	label.pivot_offset = label.size / 2
	
	vbox.reset_size()
	var center_pos = Vector2(576, 324) - vbox.size / 2
	vbox.position = center_pos
	vbox.pivot_offset = vbox.size / 2
	
	# 4. Set Initial Transform States (Toned down)
	var start_scale = Vector2.ONE
	var start_rotation = 0.0
	var start_pos_offset = Vector2.ZERO
	var banner_start_scale = Vector2(1.0, 0.0) # Vertically collapsed

	if anim_type == "stretch":
		banner_start_scale = Vector2(0.6, 0.0) # Moderately collapsed horizontally
		start_scale = Vector2(0.3, 1.4) # Less extreme stretch
	elif anim_type == "wave":
		start_scale = Vector2(0.5, 0.5)
		start_rotation = -0.06 # Very subtle rotation
	elif anim_type == "spin":
		start_scale = Vector2(0.5, 0.5)
		start_rotation = -0.3 # Very subtle rotation (no giant flip)
	elif anim_type == "bounce":
		start_scale = Vector2(0.9, 1.15)
		start_pos_offset = Vector2(0, -90) # Moderated drop distance
	elif anim_type == "elastic":
		start_scale = Vector2(0.4, 0.4)
	elif anim_type == "flash":
		start_scale = Vector2(0.5, 0.5)
	elif anim_type == "bounce_in":
		start_scale = Vector2(0.4, 0.4)
	elif anim_type == "wobble":
		start_scale = Vector2(0.4, 0.4)
		start_pos_offset = Vector2(-70, 0) # Less extreme slide
	elif anim_type == "flip":
		start_scale = Vector2(1.0, 0.0)
	else:
		start_scale = Vector2(0.5, 0.5)

	banner.scale = banner_start_scale
	label.scale = start_scale
	label.rotation = start_rotation
	vbox.position = center_pos + start_pos_offset
	dimmer.color.a = 0.0

	# 5. Intro Animation Timeline (Toned down, smooth, and fast)
	var intro_tween = create_tween().set_parallel(true)
	intro_tween.tween_property(dimmer, "color:a", 0.45, 0.18) # Subtler dimmer
	intro_tween.tween_property(banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var label_tween = intro_tween.chain().set_parallel(true)
	if anim_type == "bounce":
		label_tween.tween_property(vbox, "position", center_pos, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif anim_type == "stretch":
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif anim_type == "spin":
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(label, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif anim_type == "flip":
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif anim_type == "wobble":
		label_tween.tween_property(vbox, "position", center_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif anim_type == "flash":
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		for i in range(2): # Less flashing iterations
			label_tween.tween_property(label, "theme_override_colors/font_outline_color", Color(1.0, 1.0, 1.0), 0.08)
			label_tween.tween_property(label, "theme_override_colors/font_outline_color", outline_color, 0.08)
	else:
		label_tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if start_rotation != 0.0:
			label_tween.tween_property(label, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await intro_tween.finished

	# 6. Continuous Loop Animations (Toned down, extremely subtle)
	var active_tweens: Array[Tween] = []
	var wiggle = create_tween().set_loops()
	active_tweens.append(wiggle)
	
	if anim_type == "stretch":
		wiggle.set_parallel(false)
		wiggle.tween_property(label, "scale", Vector2(1.04, 0.96), 0.28).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "scale", Vector2(0.96, 1.04), 0.28).set_trans(Tween.TRANS_SINE)
	elif anim_type == "wave":
		wiggle.set_parallel(true)
		var inner_wobble_y = create_tween().set_loops()
		active_tweens.append(inner_wobble_y)
		inner_wobble_y.tween_property(vbox, "position:y", center_pos.y - 4.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		inner_wobble_y.tween_property(vbox, "position:y", center_pos.y + 4.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		wiggle.tween_property(label, "rotation", 0.015, 0.4).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "rotation", -0.015, 0.4).set_trans(Tween.TRANS_SINE)
	elif anim_type == "spin":
		wiggle.set_parallel(false)
		wiggle.tween_property(label, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		wiggle.tween_property(label, "scale", Vector2(0.98, 0.98), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		wiggle.tween_property(label, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		wiggle.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		wiggle.tween_interval(0.4) # Longer rest between pulses
	elif anim_type == "bounce":
		wiggle.set_parallel(false)
		wiggle.tween_property(vbox, "position:y", center_pos.y - 8.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		wiggle.tween_property(label, "scale", Vector2(0.96, 1.06), 0.08)
		wiggle.tween_property(vbox, "position:y", center_pos.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		wiggle.tween_property(label, "scale", Vector2(1.06, 0.94), 0.08)
		wiggle.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
		wiggle.tween_interval(0.3)
	elif anim_type == "elastic":
		wiggle.set_parallel(true)
		wiggle.tween_property(label, "rotation", 0.02, 0.35).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "rotation", -0.02, 0.35).set_trans(Tween.TRANS_SINE)
		var hover = create_tween().set_loops()
		active_tweens.append(hover)
		hover.tween_property(vbox, "position:x", center_pos.x - 3.0, 0.3).set_trans(Tween.TRANS_SINE)
		hover.tween_property(vbox, "position:x", center_pos.x + 3.0, 0.3).set_trans(Tween.TRANS_SINE)
	elif anim_type == "flash":
		wiggle.set_parallel(false)
		wiggle.tween_property(label, "theme_override_colors/font_outline_color", Color(1.0, 0.4, 0.4), 0.18)
		wiggle.tween_property(label, "theme_override_colors/font_outline_color", outline_color, 0.18)
		
		var jitter = create_tween().set_loops()
		active_tweens.append(jitter)
		jitter.tween_property(vbox, "position", center_pos + Vector2(randf_range(-1,1), randf_range(-1,1)), 0.1)
		jitter.tween_property(vbox, "position", center_pos, 0.1)
	elif anim_type == "bounce_in":
		wiggle.set_parallel(false)
		wiggle.tween_property(vbox, "position:y", center_pos.y - 5.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		wiggle.tween_property(label, "rotation", 0.03, 0.08)
		wiggle.tween_property(vbox, "position:y", center_pos.y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		wiggle.tween_property(label, "rotation", -0.03, 0.08)
		wiggle.tween_property(label, "rotation", 0.0, 0.1)
		wiggle.tween_interval(0.3)
	elif anim_type == "wobble":
		wiggle.set_parallel(true)
		wiggle.tween_property(label, "rotation", 0.03, 0.3).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "rotation", -0.03, 0.3).set_trans(Tween.TRANS_SINE)
		
		var rope_sway = create_tween().set_loops()
		active_tweens.append(rope_sway)
		rope_sway.tween_property(vbox, "position:y", center_pos.y - 3.0, 0.3).set_trans(Tween.TRANS_SINE)
		rope_sway.tween_property(vbox, "position:y", center_pos.y + 3.0, 0.3).set_trans(Tween.TRANS_SINE)
	elif anim_type == "flip":
		wiggle.set_parallel(true)
		wiggle.tween_property(label, "scale", Vector2(1.03, 1.03), 0.35).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_SINE)
		
		var outline_pulse = create_tween().set_loops()
		active_tweens.append(outline_pulse)
		outline_pulse.tween_property(label, "theme_override_constants/outline_size", 22, 0.35)
		outline_pulse.tween_property(label, "theme_override_constants/outline_size", 20, 0.35)
	else:
		wiggle.tween_property(label, "rotation", 0.01, 0.22).set_trans(Tween.TRANS_SINE)
		wiggle.tween_property(label, "rotation", -0.01, 0.22).set_trans(Tween.TRANS_SINE)

	# 7. Display Duration (0.8 seconds)
	await get_tree().create_timer(0.8, false).timeout
	
	# Kill active loops cleanly
	for t in active_tweens:
		if t.is_valid():
			t.kill()
	
	# Reset transforms to baseline to ensure smooth outro transition
	label.rotation = 0.0
	vbox.position = center_pos
	label.add_theme_color_override("font_outline_color", outline_color)

	# 8. Outro transition (clean fade and collapse)
	var outro_tween = create_tween().set_parallel(true)
	outro_tween.tween_property(label, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outro_tween.tween_property(banner, "scale:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if anim_type == "stretch":
		outro_tween.tween_property(banner, "scale:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outro_tween.tween_property(dimmer, "color:a", 0.0, 0.18)
	
	await outro_tween.finished
	queue_free()
