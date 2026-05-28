extends Node

signal run_won
signal run_lost

@export_group("Settings")
@export var initial_lives: int = 5
@export var speed_up_threshold: int = 14
@export var speed_up_multiplier: float = 1.5
@export var total_games_per_run: int = 25
@export var default_game_duration: float = 5.0
@export var feedback_duration: float = 1.0

@export_group("Scenes")
@export var interstitial_scene: PackedScene
@export var game_over_scene: PackedScene = preload("res://Scenes/Menus/GameOverScreen.tscn")

@export_group("UI")
@export var objective_overlay_template_path: NodePath = ^"ObjectiveOverlayTemplate"

var scenario_games: Array[PackedScene] = []
var final_game: PackedScene = null
var lives: int = 5
var games_played: int = 0
var speed_multiplier: float = 1.0
var current_game_is_final: bool = false

@onready var timer_bar = $HUDLayer/TimerBar
@onready var feedback_label = $HUDLayer/FeedbackLabel

@onready var music_slow = $MusicSlow
@onready var music_fast = $MusicFast
@onready var music_final = $MusicFinal
@onready var dog_bark = $DogBark
@onready var dog_whimper = $DogWhimper
@onready var win_sound = $WinSound
@onready var victory_effects = $HUDLayer/VictoryEffects

@onready var tug_of_war_particles: CPUParticles2D = $HUDLayer/VictoryEffects/TugOfWarParticles
@onready var toilet_particles: CPUParticles2D = $HUDLayer/VictoryEffects/ToiletParticles
@onready var dog_cross_particles: CPUParticles2D = $HUDLayer/VictoryEffects/DogCrossParticles
@onready var jump_rope_particles: CPUParticles2D = $HUDLayer/VictoryEffects/JumpRopeParticles
@onready var labyrinth_particles: CPUParticles2D = $HUDLayer/VictoryEffects/LabyrinthParticles
@onready var attach_particles: CPUParticles2D = $HUDLayer/VictoryEffects/AttachParticles
@onready var pick_me_particles: CPUParticles2D = $HUDLayer/VictoryEffects/PickMeParticles
@onready var pick_the_rope_particles: CPUParticles2D = $HUDLayer/VictoryEffects/PickTheRopeParticles
@onready var spot_the_difference_particles: CPUParticles2D = $HUDLayer/VictoryEffects/SpotTheDifferenceParticles
@onready var default_confetti_particles: CPUParticles2D = $HUDLayer/VictoryEffects/DefaultConfettiParticles
@onready var left_cannon_particles: CPUParticles2D = $HUDLayer/VictoryEffects/LeftCannonParticles
@onready var right_cannon_particles: CPUParticles2D = $HUDLayer/VictoryEffects/RightCannonParticles

@export var fade_duration: float = 0.8  # durasi crossfade (bisa di-tweak di Inspector)
const SILENT_DB: float = -40.0          # volume "silent" untuk fade

# Track mana yang lagi aktif (biar gak crossfade ke diri sendiri)
var _current_music: AudioStreamPlayer = null

var current_instance: Node
var next_game_scene: PackedScene = null

# Non-repeating randomizer state variables
var _remaining_scenario_games: Array[PackedScene] = []
var _last_played_game: PackedScene = null

# Prevent multiple concurrent round endings (e.g. timeout + action win/loss at the same second)
var _round_active: bool = false
var _active_game_over_screen: Node = null
var _active_win_tweens: Array[Tween] = []

func _ready():
	# Load config from AppManager (set before scene was changed)
	if AppManager.pending_scenario_games.is_empty():
		push_error("GameManager: AppManager.pending_scenario_games is empty!")
	
	scenario_games = AppManager.pending_scenario_games.duplicate()
	final_game = AppManager.pending_final_game
	
	# We don't clear AppManager's pending data here anymore to avoid 
	# accidentally clearing the source arrays if they were passed by reference.
	
	if not timer_bar.timeout.is_connected(_on_timer_timeout):
		timer_bar.timeout.connect(_on_timer_timeout)

	timer_bar.hide()
	call_deferred("start_game_loop")

func start_game_loop():
	lives = initial_lives
	games_played = 0
	speed_multiplier = 1.0
	Engine.time_scale = speed_multiplier
	
	_round_active = false
	
	# Reset win tweens
	for t in _active_win_tweens:
		if is_instance_valid(t) and t.is_valid():
			t.kill()
	_active_win_tweens.clear()
	
	# Clean up any leftover game over screens or UI elements in HUDLayer
	for child in $HUDLayer.get_children():
		if child != timer_bar and child != feedback_label and child != victory_effects:
			child.queue_free()
	_active_game_over_screen = null
	
	_play_slow_music()
	
	# Reset randomizer pool
	_remaining_scenario_games.clear()
	_last_played_game = null
	
	_pick_next_game()
	_load_interstitial()


func _pick_next_game():
	var is_endless = (AppManager.current_mode == AppManager.Mode.ENDLESS)
	var next_game_num = games_played + 1
	
	if is_endless:
		if next_game_num % 20 == 0:
			next_game_scene = final_game
		else:
			_pick_random_scenario_game()
	else:
		if games_played == total_games_per_run - 1:
			next_game_scene = final_game
		else:
			_pick_random_scenario_game()

func _pick_random_scenario_game():
	if scenario_games.size() == 0:
		push_error("No scenario games assigned to GameManager")
		return
	
	# If the deck/pool is empty, refill it
	if _remaining_scenario_games.is_empty():
		_refill_scenario_game_pool()
	
	# Draw from the deck
	var picked_game = _remaining_scenario_games.pop_back()
	next_game_scene = picked_game
	_last_played_game = picked_game

func _refill_scenario_game_pool():
	var pool = scenario_games.duplicate()
	pool.shuffle()
	
	# Prevent back-to-back repetition across resets
	if pool.size() > 1 and _last_played_game != null and pool[pool.size() - 1] == _last_played_game:
		# Since we pop from the back, pool[pool.size() - 1] is the first game drawn.
		# Swap it with the item at index 0 to avoid immediate repeat.
		var temp = pool[pool.size() - 1]
		pool[pool.size() - 1] = pool[0]
		pool[0] = temp
		
	_remaining_scenario_games = pool

func _load_interstitial():
	# Reset time scale to current speed multiplier to clear any level-specific slow-motion
	Engine.time_scale = speed_multiplier
	dog_bark.play()

	# Reset win tweens
	for t in _active_win_tweens:
		if is_instance_valid(t) and t.is_valid():
			t.kill()
	_active_win_tweens.clear()

	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	if next_game_scene == null:
		push_error("GameManager: next_game_scene is null!")
		AppManager.go_to_main_menu()
		return

	var is_endless = (AppManager.current_mode == AppManager.Mode.ENDLESS)
	var is_speed_up = false
	if is_endless:
		if games_played <= 20:
			is_speed_up = (games_played > 0 and games_played % 10 == 0)
		else:
			is_speed_up = (games_played % 5 == 0)
			
		if is_speed_up:
			speed_multiplier += 0.2
			Engine.time_scale = speed_multiplier

		current_game_is_final = ((games_played + 1) % 20 == 0)
	else:
		is_speed_up = (games_played == speed_up_threshold)
		if is_speed_up:
			speed_multiplier = speed_up_multiplier
			Engine.time_scale = speed_multiplier
			_play_fast_music()
		current_game_is_final = (games_played == total_games_per_run - 1)

	if interstitial_scene == null:
		push_error("GameManager: interstitial_scene is null!")
		AppManager.go_to_main_menu()
		return

	# To get control icon, instantiate the game without adding it to the tree first.
	var temp_game = next_game_scene.instantiate()
	var icon: Texture2D = null
	if "control_icon" in temp_game:
		icon = temp_game.control_icon
	elif "control_icon_path" in temp_game and temp_game.control_icon_path != "":
		icon = load(temp_game.control_icon_path)
	temp_game.queue_free()

	# Instantiate and call setup() BEFORE adding to the tree to avoid 1-frame flickers / old icon swaps
	var interstitial = interstitial_scene.instantiate()
	interstitial.setup(lives, icon, is_speed_up, current_game_is_final, games_played + 1, total_games_per_run, is_endless)
	add_child(interstitial)
	current_instance = interstitial

	interstitial.interstitial_done.connect(_on_interstitial_done)

func _on_interstitial_done():
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	var game_instance = next_game_scene.instantiate()
	add_child(game_instance)
	current_instance = game_instance
	
	if AppManager.current_mode == AppManager.Mode.ENDLESS:
		if "show_win_screen" in game_instance:
			game_instance.show_win_screen = false
		var manager = game_instance.get_node_or_null("GameManager")
		if manager and "show_win_screen" in manager:
			manager.show_win_screen = false
	
	# Pause gameplay until objective is shown
	game_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	var overlay_template = get_node_or_null(objective_overlay_template_path)
	if overlay_template == null:
		push_error("GameManager: objective overlay template is not assigned.")
		AppManager.go_to_main_menu()
		return

	var overlay = overlay_template.duplicate()
	overlay.visible = true
	add_child(overlay) 
	
	var obj_text = "Go!"
	if "objective_text" in game_instance:
		obj_text = game_instance.objective_text
		
	overlay.setup(obj_text)
	
	# Wait for overlay to be destroyed (it queue_frees itself)
	await overlay.tree_exited
	
	# Resume gameplay
	if is_instance_valid(game_instance):
		game_instance.process_mode = Node.PROCESS_MODE_INHERIT
		_round_active = true
		
		if current_game_is_final:
			_play_final_music()
			timer_bar.stop()
			timer_bar.hide()
		else:
			var duration = default_game_duration
			if "time_limit" in game_instance:
				duration = game_instance.time_limit
			elif "round_duration" in game_instance:
				duration = game_instance.round_duration
			
			timer_bar.start(duration)

	if game_instance.has_signal("game_won"):
		game_instance.game_won.connect(_on_game_won)
	if game_instance.has_signal("game_lost"):
		game_instance.game_lost.connect(_on_game_lost)


func _on_game_won():
	if not _round_active:
		return
	_round_active = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Immediate visual freeze and feedback
	timer_bar.stop()
	
	win_sound.play()
	
	var msg = "WIN!"
	var g_name = ""
	if is_instance_valid(current_instance):
		g_name = _get_current_game_key()
		if "win_label_text" in current_instance:
			msg = current_instance.win_label_text

	# Kill any existing win tweens
	for t in _active_win_tweens:
		if is_instance_valid(t) and t.is_valid():
			t.kill()
	_active_win_tweens.clear()

	var is_untangle = "untangle" in g_name

	if not is_untangle:
		# 1. Custom Feedback Label animations and styles
		_animate_feedback_label(g_name, msg)
		
		# 2. Time Dilation
		var target_time_scale = 0.25
		var slow_duration = 0.15 # in game seconds
		var pause_duration = 0.05 # in game seconds
		
		if "tugofwar" in g_name:
			target_time_scale = 0.1
			pause_duration = 0.02
			slow_duration = 0.2
		elif "toilet" in g_name:
			target_time_scale = 0.3
			pause_duration = 0.08
			slow_duration = 0.12
		elif "dogcross" in g_name:
			target_time_scale = 0.15
			pause_duration = 0.04
			slow_duration = 0.22
		elif "jumprope" in g_name:
			target_time_scale = 0.2
			pause_duration = 0.05
			slow_duration = 0.2
		elif "labyrinth" in g_name:
			target_time_scale = 0.25
			pause_duration = 0.0
			slow_duration = 0.3
		elif "attach" in g_name:
			target_time_scale = 0.05
			pause_duration = 0.01
			slow_duration = 0.1
		elif "pickme" in g_name:
			target_time_scale = 0.25
			pause_duration = 0.05
			slow_duration = 0.2
		elif "picktherope" in g_name:
			target_time_scale = 0.3
			pause_duration = 0.05
			slow_duration = 0.25
		elif "spot" in g_name:
			target_time_scale = 0.1
			pause_duration = 0.15
			slow_duration = 0.1
			
		Engine.time_scale = target_time_scale
		var time_tween = create_tween()
		if pause_duration > 0:
			time_tween.tween_interval(pause_duration)
		time_tween.tween_property(Engine, "time_scale", speed_multiplier, slow_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_active_win_tweens.append(time_tween)
		
		# 3. Screenshake
		_shake_current_stage(g_name)
		
		# 4. Spawning particles
		_spawn_victory_particles(g_name)
	else:
		# If it is Untangle, it does its own win banner and animations. Just display empty string to suppress.
		feedback_label.text = ""
		feedback_label.show()

	games_played += 1
	var is_endless = (AppManager.current_mode == AppManager.Mode.ENDLESS)
	if not is_endless and games_played == total_games_per_run:
		# Make sure time scale is restored on win
		Engine.time_scale = 1.0
		emit_signal("run_won")
		AppManager.on_run_won()
		return
	
	# Wait using real time so it's consistent regardless of game speed
	await get_tree().create_timer(feedback_duration, true, false, true).timeout
	feedback_label.hide()
	timer_bar.hide()
	_pick_next_game()
	_load_interstitial()

func _on_game_lost():
	if not _round_active:
		return
	_round_active = false

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Immediate visual freeze and feedback
	timer_bar.stop()
	if is_instance_valid(current_instance):
		var disable_freeze = false
		if "disable_freeze_on_loss" in current_instance:
			disable_freeze = current_instance.disable_freeze_on_loss
		if not disable_freeze:
			current_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	dog_whimper.play()
	
	var msg = "LOSE..."
	var g_name = ""
	if is_instance_valid(current_instance):
		g_name = _get_current_game_key()
	if is_instance_valid(current_instance):
		if "lose_label_text" in current_instance:
			msg = current_instance.lose_label_text
	if current_game_is_final and lives <= 1:
		msg = "You Lose"
	
	for t in _active_win_tweens:
		if is_instance_valid(t) and t.is_valid():
			t.kill()
	_active_win_tweens.clear()

	_animate_loss_feedback_label(g_name, msg)
	_shake_current_stage(g_name, 1.35)

	Engine.time_scale = min(speed_multiplier, 0.35)
	var loss_time_tween := create_tween()
	loss_time_tween.tween_interval(0.06)
	loss_time_tween.tween_property(Engine, "time_scale", speed_multiplier, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_win_tweens.append(loss_time_tween)

	lives -= 1
	if lives <= 0:
		Engine.time_scale = 1.0
		if AppManager.current_mode == AppManager.Mode.ENDLESS:
			await get_tree().create_timer(feedback_duration).timeout
			_show_game_over_screen()
		else:
			emit_signal("run_lost")
			AppManager.on_run_lost()
		return
	
	await get_tree().create_timer(feedback_duration).timeout
	feedback_label.hide()
	timer_bar.hide()
	
	var is_endless = (AppManager.current_mode == AppManager.Mode.ENDLESS)
	if is_endless:
		if not current_game_is_final:
			games_played += 1
		_pick_next_game()
	else:
		if games_played < total_games_per_run - 1:
			games_played += 1
			_pick_next_game()
		else:
			# Retry final game
			_pick_next_game()
	
	_load_interstitial()


func _get_current_game_key() -> String:
	if not is_instance_valid(current_instance):
		return ""

	var key := current_instance.name.to_lower()
	var scene_path := current_instance.scene_file_path.to_lower()
	if scene_path != "":
		key += "|" + scene_path
	return key

func _on_timer_timeout():
	if current_instance != null:
		if "timeout_wins" in current_instance and current_instance.timeout_wins:
			_on_game_won()
		else:
			_on_game_lost()

func _show_feedback(text: String, color: Color):
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.show()

func _show_game_over_screen():
	if _active_game_over_screen != null:
		return
		
	# Hide HUD elements
	music_slow.stop()
	music_fast.stop()
	timer_bar.hide()
	feedback_label.hide()
	
	if game_over_scene == null:
		push_error("GameManager: game_over_scene is null!")
		AppManager.go_to_main_menu()
		return
		
	var game_over_screen = game_over_scene.instantiate()
	_active_game_over_screen = game_over_screen
	$HUDLayer.add_child(game_over_screen)
	game_over_screen.setup(games_played)
	game_over_screen.restart_requested.connect(func():
		_active_game_over_screen = null
		game_over_screen.queue_free()
		start_game_loop()
	)
	game_over_screen.menu_requested.connect(func():
		_active_game_over_screen = null
		game_over_screen.queue_free()
		AppManager.go_to_main_menu()
	)


func _play_slow_music():
	_crossfade_to(music_slow)

func _play_fast_music():
	_crossfade_to(music_fast)

func _play_final_music():
	_crossfade_to(music_final)

func _crossfade_to(target: AudioStreamPlayer):
	# Kalau target udah jadi musik aktif, skip
	if _current_music == target and target.playing:
		return
	
	var previous = _current_music
	_current_music = target
	
	# Mulai target dari silent
	target.volume_db = SILENT_DB
	target.play()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in target
	tween.tween_property(target, "volume_db", 0.0, fade_duration)
	
	# Fade out previous (kalau ada & beda dari target)
	if previous != null and previous != target and previous.playing:
		tween.tween_property(previous, "volume_db", SILENT_DB, fade_duration)
		# Stop previous setelah fade selesai
		tween.chain().tween_callback(previous.stop)


func _animate_feedback_label(g_name: String, msg: String):
	feedback_label.text = msg
	feedback_label.position = Vector2.ZERO
	feedback_label.pivot_offset = Vector2(576, 324)
	feedback_label.rotation = 0.0
	feedback_label.scale = Vector2.ONE
	feedback_label.modulate = Color.WHITE
	
	# Default colors
	var font_color = Color(1.0, 0.85, 0.2) # Gold
	var outline_color = Color(0.1, 0.05, 0.0) # Dark brown
	var outline_size = 16
	var font_size = 72
	
	var anim_type = "elastic"
	
	if "tugofwar" in g_name:
		font_color = Color(0.2, 0.7, 1.0) # Electric blue
		outline_color = Color(0.0, 0.1, 0.3)
		anim_type = "stretchy"
		feedback_label.text = "PULLED!"
	elif "toilet" in g_name:
		font_color = Color(1.0, 0.9, 0.3) # Bright yellow
		outline_color = Color(0.2, 0.1, 0.0)
		anim_type = "wave"
	elif "dogcross" in g_name:
		font_color = Color(1.0, 0.4, 0.6) # Pink
		outline_color = Color(0.3, 0.0, 0.1)
		anim_type = "spin"
		feedback_label.text = "SAFE!"
	elif "jumprope" in g_name:
		font_color = Color(0.3, 0.9, 0.4) # Neon green
		outline_color = Color(0.0, 0.2, 0.0)
		anim_type = "drop"
	elif "labyrinth" in g_name:
		font_color = Color(0.8, 0.4, 1.0) # Purple
		outline_color = Color(0.2, 0.0, 0.3)
		anim_type = "elastic"
		feedback_label.text = "ESCAPED!"
	elif "attach" in g_name:
		font_color = Color(1.0, 0.3, 0.3) # Neon red
		outline_color = Color(0.2, 0.0, 0.0)
		anim_type = "flash"
	elif "pickme" in g_name:
		font_color = Color(1.0, 0.6, 0.1) # Orange
		outline_color = Color(0.2, 0.1, 0.0)
		anim_type = "bounce"
		feedback_label.text = "CORRECT!"
		feedback_label.position.y = -130.0
	elif "picktherope" in g_name:
		font_color = Color(0.2, 0.9, 0.8) # Teal
		outline_color = Color(0.0, 0.2, 0.2)
		anim_type = "wobble"
		feedback_label.text = "FOUND IT!"
	elif "spot" in g_name:
		font_color = Color(1.0, 0.5, 0.0) # Bright orange
		outline_color = Color(0.2, 0.05, 0.0)
		anim_type = "flip"
		feedback_label.text = "SPOTTED!"
		
	# Apply theme overrides
	feedback_label.add_theme_color_override("font_color", font_color)
	feedback_label.add_theme_color_override("font_outline_color", outline_color)
	feedback_label.add_theme_constant_override("outline_size", outline_size)
	feedback_label.add_theme_font_size_override("font_size", font_size)
	
	feedback_label.show()
	
	var label_tween = create_tween()
	_active_win_tweens.append(label_tween)
	
	match anim_type:
		"stretchy":
			feedback_label.scale = Vector2(0.1, 1.8)
			label_tween.set_parallel(true)
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
		"wave":
			feedback_label.scale = Vector2.ZERO
			label_tween.tween_property(feedback_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			var wave_tween = create_tween().set_loops()
			wave_tween.tween_property(feedback_label, "scale", Vector2(1.05, 0.95), 0.25).set_trans(Tween.TRANS_SINE)
			wave_tween.tween_property(feedback_label, "scale", Vector2(0.95, 1.05), 0.25).set_trans(Tween.TRANS_SINE)
			_active_win_tweens.append(wave_tween)
			
		"spin":
			feedback_label.scale = Vector2.ZERO
			feedback_label.rotation = -PI
			label_tween.set_parallel(true)
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			label_tween.tween_property(feedback_label, "rotation", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		"drop":
			var original_pos = feedback_label.position
			feedback_label.position.y = -150.0
			label_tween.tween_property(feedback_label, "position:y", original_pos.y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
		"flash":
			feedback_label.scale = Vector2.ZERO
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD)
			
			var flash_tween = create_tween().set_loops(6)
			flash_tween.tween_property(feedback_label, "modulate", Color(2.0, 2.0, 2.0), 0.08)
			flash_tween.tween_property(feedback_label, "modulate", Color.WHITE, 0.08)
			_active_win_tweens.append(flash_tween)
			
		"bounce":
			feedback_label.scale = Vector2.ZERO
			label_tween.tween_property(feedback_label, "scale", Vector2(1.4, 1.4), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)
			
		"wobble":
			feedback_label.scale = Vector2.ZERO
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
			var rot_tween = create_tween().set_loops()
			rot_tween.tween_property(feedback_label, "rotation", 0.05, 0.12).set_trans(Tween.TRANS_SINE)
			rot_tween.tween_property(feedback_label, "rotation", -0.05, 0.12).set_trans(Tween.TRANS_SINE)
			_active_win_tweens.append(rot_tween)
			
		"flip":
			feedback_label.scale = Vector2(1.0, 0.0)
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		"elastic", _:
			feedback_label.scale = Vector2.ZERO
			label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _animate_loss_feedback_label(g_name: String, msg: String):
	feedback_label.text = msg
	feedback_label.position = Vector2.ZERO
	feedback_label.pivot_offset = Vector2(576, 324)
	feedback_label.rotation = 0.0
	feedback_label.scale = Vector2.ONE
	feedback_label.modulate = Color.WHITE

	var font_color := Color(1.0, 0.18, 0.12)
	var outline_color := Color(0.12, 0.0, 0.0)
	var outline_size := 18
	var font_size := 76

	if "dogcross" in g_name:
		font_color = Color(0.25, 0.65, 1.0)
		outline_color = Color(0.0, 0.08, 0.22)
	elif "jumprope" in g_name:
		font_color = Color(1.0, 0.35, 0.2)
		outline_color = Color(0.18, 0.02, 0.0)
	elif "pickme" in g_name:
		font_color = Color(1.0, 0.42, 0.08)
		outline_color = Color(0.18, 0.05, 0.0)
	elif "picktherope" in g_name:
		font_color = Color(0.2, 0.95, 0.9)
		outline_color = Color(0.0, 0.16, 0.18)
	elif "toilet" in g_name:
		font_color = Color(0.72, 0.95, 0.28)
		outline_color = Color(0.08, 0.18, 0.0)
	elif "tugofwar" in g_name:
		font_color = Color(1.0, 0.28, 0.28)
		outline_color = Color(0.18, 0.0, 0.0)
	elif "attach" in g_name:
		font_color = Color(1.0, 0.25, 0.25)
		outline_color = Color(0.18, 0.0, 0.0)
	elif "labyrinth" in g_name:
		font_color = Color(0.85, 0.42, 1.0)
		outline_color = Color(0.16, 0.0, 0.24)
	elif "untangle" in g_name:
		font_color = Color(1.0, 0.75, 0.2)
		outline_color = Color(0.2, 0.08, 0.0)
	elif "spot" in g_name:
		font_color = Color(1.0, 0.45, 0.05)
		outline_color = Color(0.2, 0.04, 0.0)

	feedback_label.add_theme_color_override("font_color", font_color)
	feedback_label.add_theme_color_override("font_outline_color", outline_color)
	feedback_label.add_theme_constant_override("outline_size", outline_size)
	feedback_label.add_theme_font_size_override("font_size", font_size)
	feedback_label.show()

	var label_tween := create_tween()
	_active_win_tweens.append(label_tween)
	feedback_label.scale = Vector2(1.55, 0.65)
	feedback_label.modulate = Color(1.6, 1.6, 1.6, 1.0)
	label_tween.set_parallel(true)
	label_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(feedback_label, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(feedback_label, "rotation", -0.035, 0.07).set_trans(Tween.TRANS_SINE)
	label_tween.chain().tween_property(feedback_label, "rotation", 0.025, 0.07).set_trans(Tween.TRANS_SINE)
	label_tween.tween_property(feedback_label, "rotation", 0.0, 0.08).set_trans(Tween.TRANS_SINE)


func _shake_current_stage(g_name: String, multiplier: float = 1.0):
	if not is_instance_valid(current_instance):
		return
		
	var shake_tween = create_tween()
	_active_win_tweens.append(shake_tween)
	
	var shake_type = "radial"
	var intensity = 4.0
	var count = 6
	
	if "tugofwar" in g_name:
		shake_type = "horizontal"
		intensity = 6.0
		count = 8
	elif "toilet" in g_name:
		shake_type = "vertical"
		intensity = 5.0
		count = 6
	elif "dogcross" in g_name:
		shake_type = "diagonal"
		intensity = 2.5
		count = 5
	elif "jumprope" in g_name:
		shake_type = "vertical"
		intensity = 6.0
		count = 6
	elif "labyrinth" in g_name:
		shake_type = "rotational"
		intensity = 3.0
		count = 6
	elif "attach" in g_name:
		shake_type = "radial"
		intensity = 5.0
		count = 4
	elif "pickme" in g_name:
		shake_type = "horizontal"
		intensity = 4.0
		count = 6
	elif "picktherope" in g_name:
		shake_type = "diagonal"
		intensity = 3.0
		count = 6
	elif "spot" in g_name:
		shake_type = "radial"
		intensity = 4.0
		count = 5

	intensity *= multiplier
	count = max(count, int(round(count * multiplier)))

	var original_pos = current_instance.position
	
	for i in range(count):
		var offset = Vector2.ZERO
		match shake_type:
			"horizontal":
				offset = Vector2(randf_range(-intensity, intensity), 0)
			"vertical":
				offset = Vector2(0, randf_range(-intensity, intensity))
			"diagonal":
				var d = randf_range(-intensity, intensity)
				offset = Vector2(d, d * 0.5)
			"rotational":
				offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)).rotated(randf_range(-0.5, 0.5))
			"radial", _:
				offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		
		shake_tween.tween_property(current_instance, "position", original_pos + offset, 0.05)
	
	shake_tween.tween_property(current_instance, "position", original_pos, 0.05)


func _spawn_victory_particles(g_name: String):
	var p: CPUParticles2D = default_confetti_particles
	
	if "tugofwar" in g_name:
		p = tug_of_war_particles
	elif "toilet" in g_name:
		p = toilet_particles
	elif "dogcross" in g_name:
		p = dog_cross_particles
	elif "jumprope" in g_name:
		p = jump_rope_particles
	elif "labyrinth" in g_name:
		p = labyrinth_particles
		if is_instance_valid(p) and is_instance_valid(current_instance) and current_instance.get_node_or_null("Player"):
			p.global_position = current_instance.get_node("Player").global_position
	elif "attach" in g_name:
		p = attach_particles
		if is_instance_valid(p):
			if is_instance_valid(current_instance) and current_instance.get_node_or_null("TargetZone"):
				p.global_position = current_instance.get_node("TargetZone").global_position
			elif is_instance_valid(current_instance) and current_instance.get_node_or_null("Hook"):
				p.global_position = current_instance.get_node("Hook").global_position
	elif "pickme" in g_name:
		p = pick_me_particles
	elif "picktherope" in g_name:
		p = pick_the_rope_particles
	elif "spot" in g_name:
		p = spot_the_difference_particles
		if is_instance_valid(p):
			p.global_position = get_viewport().get_mouse_position()

	if is_instance_valid(p):
		p.emitting = true
		
	# Trigger left and right cannons if it is the default splash
	if p == default_confetti_particles and is_instance_valid(p):
		if is_instance_valid(left_cannon_particles):
			left_cannon_particles.emitting = true
		if is_instance_valid(right_cannon_particles):
			right_cannon_particles.emitting = true
