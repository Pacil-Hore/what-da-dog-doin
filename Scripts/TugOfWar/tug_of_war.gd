extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Pull!"
@export var control_hint: String = "Space"
@export var control_icon: Texture2D
@export var time_limit: float = 5.0
@export var win_label_text: String = "PULLED!"
@export var lose_label_text: String = "Dragged off!"
@export var disable_freeze_on_loss: bool = true

var human: TugOfWarHuman
var dog: TugOfWarDog
var leash: Line2D
var win_meter: ProgressBar
var warning_label: Label

@export var player_pull_strength := 0.06
@export var dog_base_drain_rate := 0.16
@export var dog_yank_strength := 0.09

@export_group("Leash Settings")
@export var leash_droop := 25.0

var gauge_value := 0.5
var display_gauge := 0.5
var time_left := 5.0
var is_finished := false
var game_started := true

var last_ticks := 0.0
var end_transition_progress := 0.0
var end_transition_start_gauge := 0.5
var has_saved_transition_start := false



var next_yank_timer := 0.8
var yank_duration_timer := 0.0
var is_yanking := false

var warning_pulse := 0.0
var shake_offset := Vector2.ZERO
var shake_intensity := 0.0

var leash_start := Vector2(295, 435)
var leash_end := Vector2(865, 400)
var initial_human_pos := Vector2(260, 420)
var initial_dog_pos := Vector2(890, 420)
var initial_leash_points: PackedVector2Array = []

var visual_tension := 0.3

var sky: ColorRect
var original_sky_color: Color
var sky_flash_timer := 0.0
var pull_heave := 0.0

# Scene node references
@onready var camera: Camera2D = $Camera2D
@onready var pull_player: AudioStreamPlayer = $PullPlayer
@onready var yank_player: AudioStreamPlayer = $YankPlayer
@onready var win_player: AudioStreamPlayer = $WinPlayer
@onready var lose_player: AudioStreamPlayer = $LosePlayer

# Programmatic Audio Stream Resources
var pull_sfx: AudioStreamWAV
var yank_sfx: AudioStreamWAV

func _ready() -> void:
	human = $Human
	dog = $Dog
	leash = $LeashLine
	win_meter = $HUD/CenterContainer/VBoxContainer/WinMeter
	warning_label = $HUD/WarningLabel
	
	initial_leash_points = leash.points.duplicate()
	initial_human_pos = human.position
	initial_dog_pos = dog.position
	
	time_left = time_limit
	gauge_value = 0.5
	display_gauge = 0.5
	is_finished = false
	is_yanking = false
	game_started = true
	next_yank_timer = randf_range(0.8, 1.4)
	
	last_ticks = Time.get_ticks_usec()
	end_transition_progress = 0.0
	end_transition_start_gauge = 0.5
	has_saved_transition_start = false
	
	warning_label.visible = false
	win_meter.value = gauge_value * 100.0
	
	var bg_style = win_meter.get_theme_stylebox("background") as StyleBoxFlat
	if bg_style:
		bg_style.border_color = Color(1.0, 1.0, 1.0)
		
	# Set pivot center for progress bar pulsing
	win_meter.pivot_offset = Vector2(250, 18)
	
	# Make the scene camera current
	if camera:
		camera.make_current()
	
	visual_tension = 0.3
		
	# Generate chiptune SFX
	_init_sfx()
	
	# Assign streams to player nodes
	if pull_player:
		pull_player.stream = pull_sfx
	if yank_player:
		yank_player.stream = yank_sfx
	
	_update_positions()

func _init_sfx() -> void:
	# 1. Pull SFX (low-pitched thud sweep)
	pull_sfx = AudioStreamWAV.new()
	pull_sfx.format = AudioStreamWAV.FORMAT_16_BITS
	pull_sfx.mix_rate = 11025
	pull_sfx.stereo = false
	
	var pull_data = PackedByteArray()
	var pull_samples = int(0.05 * 11025) # 50 ms
	for i in range(pull_samples):
		var t = float(i) / 11025.0
		var progress = float(i) / pull_samples
		var freq = lerp(130.0, 50.0, progress)
		var amplitude = 1.0 - progress
		var sample_val = int(sin(2.0 * PI * freq * t) * 12000.0 * amplitude)
		pull_data.append(sample_val & 0xFF)
		pull_data.append((sample_val >> 8) & 0xFF)
	pull_sfx.data = pull_data
	
	# 2. Yank SFX (sharp snapping sweep)
	yank_sfx = AudioStreamWAV.new()
	yank_sfx.format = AudioStreamWAV.FORMAT_16_BITS
	yank_sfx.mix_rate = 11025
	yank_sfx.stereo = false
	
	var yank_data = PackedByteArray()
	var yank_samples = int(0.12 * 11025) # 120 ms
	for i in range(yank_samples):
		var t = float(i) / 11025.0
		var progress = float(i) / yank_samples
		var freq = lerp(260.0, 80.0, progress)
		var amplitude = 1.0 - progress
		var sine = sin(2.0 * PI * freq * t)
		var shape = sine + 0.3 * (1.0 if sine > 0.0 else -1.0) # slightly distorted
		var sample_val = int(shape * 14000.0 * amplitude)
		yank_data.append(sample_val & 0xFF)
		yank_data.append((sample_val >> 8) & 0xFF)
	yank_sfx.data = yank_data

func _play_sfx(player: AudioStreamPlayer, volume_db: float = 0.0) -> void:
	if player:
		player.volume_db = volume_db
		player.play()

func _play_synth_note(player: AudioStreamPlayer, freq: float, duration: float, volume_db: float = 0.0) -> void:
	if not player:
		return
		
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 11025
	sound.stereo = false
	
	var data = PackedByteArray()
	var samples = int(duration * 11025)
	for i in range(samples):
		var t = float(i) / 11025.0
		var progress = float(i) / samples
		var amplitude = 1.0 - progress
		var sample_val = int(sin(2.0 * PI * freq * t) * 10000.0 * amplitude)
		data.append(sample_val & 0xFF)
		data.append((sample_val >> 8) & 0xFF)
	sound.data = data
	
	player.stream = sound
	player.volume_db = volume_db
	player.play()

func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W or event.physical_keycode == KEY_W:
			game_started = true
			get_viewport().set_input_as_handled()
			_trigger_win()
			return
		elif event.keycode == KEY_L or event.physical_keycode == KEY_L:
			game_started = true
			get_viewport().set_input_as_handled()
			_trigger_loss()
			return
			
	var is_pull_input = false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_pull_input = true
	elif event is InputEventKey:
		if event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
			is_pull_input = true
			
	if is_pull_input:
		game_started = true
		get_viewport().set_input_as_handled()
		
		# Play pull sound effect
		_play_sfx(pull_player, -8.0)
		
		# Pulse progress bar scale
		if win_meter:
			win_meter.scale = Vector2(1.04, 1.1)
		
		# Adrenaline clutch boost near loss!
		var strength = player_pull_strength
		if gauge_value > 0.75:
			strength *= 1.15
			
		gauge_value = maxf(gauge_value - strength, 0.0)
		human.play_pull_wiggle()
		shake_intensity = 0.12
		visual_tension = minf(visual_tension + 0.25, 1.0)
		pull_heave = 6.0 # Trigger vertical planting heave
		
		if gauge_value <= 0.0:
			_trigger_win()

func _process(delta: float) -> void:
	# Compute rock-solid unscaled real-world delta from microseconds clock
	var current_ticks = Time.get_ticks_usec()
	var real_delta = (current_ticks - last_ticks) / 1000000.0
	last_ticks = current_ticks
	
	# Clamp real_delta to prevent extreme jumps on focus loss or loading
	real_delta = clampf(real_delta, 0.0, 0.1)

	var use_delta = delta
	if is_finished:
		use_delta = real_delta
		
	shake_intensity = lerp(shake_intensity, 0.0, use_delta * 12.0)
	if camera:
		camera.offset = Vector2(
			randf_range(-1, 1) * shake_intensity * 8.0,
			randf_range(-1, 1) * shake_intensity * 8.0
		)
		
	# Decay win_meter scale back to normal
	if win_meter:
		win_meter.scale = win_meter.scale.lerp(Vector2.ONE, use_delta * 12.0)
		
	# Decay vertical heave jolt
	pull_heave = lerp(pull_heave, 0.0, use_delta * 15.0)
	
	# Process red sky flash
	if sky_flash_timer > 0.0 and sky:
		sky_flash_timer -= use_delta
		var flash_factor = clampf(sky_flash_timer / 0.15, 0.0, 1.0)
		sky.color = original_sky_color.lerp(Color(0.9, 0.25, 0.25), flash_factor * 0.35)
	elif sky:
		sky.color = original_sky_color
		
	if is_finished:
		if not has_saved_transition_start:
			has_saved_transition_start = true
			end_transition_start_gauge = display_gauge
			end_transition_progress = 0.0
			
		# Smoothly advance transition progress linearly using real delta
		end_transition_progress = move_toward(end_transition_progress, 1.0, use_delta * 3.5) # ~0.28s to complete
		
		# Smoothly interpolate gauge value dynamically from the start value to the target
		display_gauge = lerp(end_transition_start_gauge, gauge_value, end_transition_progress)
		
		var target_tension = 0.8
		visual_tension = lerp(visual_tension, target_tension, use_delta * 4.0)
		_update_positions()
		win_meter.value = display_gauge * 100.0
		_update_ui_elements()
		return
		
	if not game_started:
		_update_positions()
		return
		
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_trigger_loss()
		return
			
	_update_dog_ai(delta)
	
	if gauge_value >= 1.0:
		_trigger_loss()
		return
	
	display_gauge = lerp(display_gauge, gauge_value, delta * 25.0)
	
	# Decay visual tension back to baseline
	var target_tension = 0.25
	if is_yanking:
		target_tension = 0.85
	
	visual_tension = lerp(visual_tension, target_tension, delta * 4.0)
		
	_update_positions()
	win_meter.value = display_gauge * 100.0
	_update_ui_elements()

	
	if warning_label.visible:
		warning_pulse += delta * 12.0
		warning_label.modulate.a = 0.6 + sin(warning_pulse) * 0.4
		warning_label.scale = Vector2.ONE * (1.0 + sin(warning_pulse * 0.7) * 0.08)
 
func _update_dog_ai(delta: float) -> void:
	var active_drain = dog_base_drain_rate * delta
	# Dog struggles harder near win!
	if gauge_value > 0.8:
		active_drain *= 1.15
	
	if is_yanking:
		yank_duration_timer -= delta
		active_drain += dog_base_drain_rate * 0.5 * delta
		if yank_duration_timer <= 0.0:
			is_yanking = false
			dog.set_yank(false)
			warning_label.visible = false
			warning_label.modulate.a = 1.0
			warning_label.scale = Vector2.ONE
	else:
		next_yank_timer -= delta
		if next_yank_timer <= 0.0:
			is_yanking = true
			yank_duration_timer = 0.4
			gauge_value = minf(gauge_value + dog_yank_strength, 1.0)
			dog.set_yank(true)
			warning_label.visible = true
			warning_pulse = 0.0
			shake_intensity = 0.45
			visual_tension = minf(visual_tension + 0.45, 1.0)
			sky_flash_timer = 0.15 # Trigger red sky flash
			
			# Play dog yank sound
			_play_sfx(yank_player, -4.0)
			# Cringe progress bar scale
			if win_meter:
				win_meter.scale = Vector2(0.96, 0.9)
			
			next_yank_timer = randf_range(0.9, 1.5)
			
	gauge_value = minf(gauge_value + active_drain, 1.0)
 
func _update_positions() -> void:
	human.set_tension(display_gauge)
	dog.set_tension(1.0 - display_gauge)
	
	# Set sliding speeds for dust particles
	var slide_speed = abs(display_gauge - gauge_value)
	human.set_sliding(slide_speed)
	dog.set_sliding(slide_speed)
	
	var center_shift = (display_gauge - 0.5) * 220.0
	if is_finished:
		if gauge_value == 1.0:
			# Extra drag shift towards dog (right) on loss
			center_shift += end_transition_progress * 320.0
		elif gauge_value == 0.0:
			# Extra pull shift towards human (left) on win
			center_shift -= end_transition_progress * 80.0
	
	human.position.x = initial_human_pos.x + center_shift
	human.position.y = initial_human_pos.y + pull_heave # Apply heave offset
	dog.position.x = initial_dog_pos.x + center_shift
	dog.position.y = initial_dog_pos.y
	
	# Calculate dynamic leash attachment points
	var hand_offset = Vector2(32.5, -105.0)
	var dog_collar_offset = Vector2(-9.0, -45.0)
	
	var hand_pos = human.position + hand_offset.rotated(human.rotation)
	var collar_pos = dog.position + dog_collar_offset.rotated(dog.rotation)
	
	var leash_start_pos = hand_pos
	if is_finished and gauge_value == 1.0:
		leash_start_pos = hand_pos.lerp(collar_pos, end_transition_progress)
	
	# Scale leash thickness based on visual tension (rope stretches and thins)
	var target_width = lerp(6.0, 3.5, clampf((visual_tension - 0.25) / 0.75, 0.0, 1.0))
	leash.width = target_width
	
	# Draw leash using quadratic bezier curve
	leash.clear_points()
	var mid = (leash_start_pos + collar_pos) / 2.0
	var sag_amount = (1.0 - visual_tension) * leash_droop
	var control_point = mid + Vector2(0, sag_amount)
	
	var num_points := 20
	for i in range(num_points):
		var t = float(i) / float(num_points - 1)
		var pt = _quadratic_bezier(leash_start_pos, control_point, collar_pos, t)
		
		# Apply vibration under high tension (e.g. during yanks/pulls)
		if visual_tension > 0.6:
			var wave_factor = sin(t * PI) # maximum in middle, 0 at ends
			var rope_dir = (collar_pos - leash_start_pos).normalized()
			var perp = Vector2(-rope_dir.y, rope_dir.x)
			var vib_freq = Time.get_ticks_msec() * 0.08
			var vib_offset = perp * sin(vib_freq + t * 10.0) * (visual_tension - 0.6) * 5.0 * wave_factor
			pt += vib_offset
			
		leash.add_point(pt)

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func _trigger_win() -> void:
	if is_finished:
		return
	is_finished = true
	gauge_value = 0.0
	
	human.set_tension(0.0)
	dog.set_tension(1.0)
	
	# Play win retro chime
	_play_synth_note(win_player, 440.0, 0.1, -4.0)
	var win_timer = get_tree().create_timer(0.08, false)
	win_timer.timeout.connect(func(): _play_synth_note(win_player, 554.37, 0.15, -4.0))
	
	emit_signal("game_won")

func _trigger_loss() -> void:
	if is_finished:
		return
	is_finished = true
	gauge_value = 1.0
	
	human.set_tension(1.0)
	dog.set_tension(0.0)
	
	# Play lose retro chime
	_play_synth_note(lose_player, 180.0, 0.12, -4.0)
	var lose_timer = get_tree().create_timer(0.1, false)
	lose_timer.timeout.connect(func(): _play_synth_note(lose_player, 120.0, 0.25, -4.0))
	
	emit_signal("game_lost")

func _update_ui_elements() -> void:
	# Update needle indicator positions
	var indicator = win_meter.get_node_or_null("Indicator") as ColorRect
	var indicator_glow = win_meter.get_node_or_null("IndicatorGlow") as ColorRect
	if indicator:
		indicator.position.x = (display_gauge * 500.0) - 3.0
	if indicator_glow:
		indicator_glow.position.x = (display_gauge * 500.0) - 6.0
		
	# Dynamic color coding favor zone flash
	var left_zone = win_meter.get_node_or_null("LeftZone") as ColorRect
	var right_zone = win_meter.get_node_or_null("RightZone") as ColorRect
	
	if left_zone:
		if display_gauge < 0.25:
			var flash = abs(sin(Time.get_ticks_msec() * 0.015))
			left_zone.color = Color(0.12, 0.45, 0.8, 0.7).lerp(Color(0.05, 0.75, 1.0, 0.95), flash)
		else:
			left_zone.color = Color(0.12, 0.45, 0.8, 0.7)
			
	if right_zone:
		if display_gauge > 0.75:
			var flash = abs(sin(Time.get_ticks_msec() * 0.015))
			right_zone.color = Color(0.85, 0.25, 0.25, 0.7).lerp(Color(1.0, 0.15, 0.15, 0.95), flash)
		else:
			right_zone.color = Color(0.85, 0.25, 0.25, 0.7)
			
	var bg_style = win_meter.get_theme_stylebox("background") as StyleBoxFlat
	if bg_style:
		if display_gauge > 0.75:
			var flash = abs(sin(Time.get_ticks_msec() * 0.015))
			bg_style.border_color = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.15, 0.15), flash)
		else:
			bg_style.border_color = Color(1.0, 1.0, 1.0)
