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

var current_instance: Node
var next_game_scene: PackedScene = null

# Non-repeating randomizer state variables
var _remaining_scenario_games: Array[PackedScene] = []
var _last_played_game: PackedScene = null

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
		current_game_is_final = (games_played == total_games_per_run - 1)

	if interstitial_scene == null:
		push_error("GameManager: interstitial_scene is null!")
		AppManager.go_to_main_menu()
		return

	var interstitial = interstitial_scene.instantiate()
	add_child(interstitial)
	current_instance = interstitial

	# To get control icon, instantiate the game without adding it to the tree.
	var temp_game = next_game_scene.instantiate()
	var icon: Texture2D = null
	if "control_icon" in temp_game:
		icon = temp_game.control_icon
	elif "control_icon_path" in temp_game and temp_game.control_icon_path != "":
		icon = load(temp_game.control_icon_path)
	temp_game.queue_free()

	interstitial.setup(lives, icon, is_speed_up, current_game_is_final, games_played + 1, total_games_per_run, is_endless)
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
		
		if current_game_is_final:
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
	# Immediate visual freeze and feedback
	timer_bar.stop()
	
	var msg = "WIN!"
	if is_instance_valid(current_instance):
		if "win_label_text" in current_instance:
			msg = current_instance.win_label_text
	
	feedback_label.text = msg
	feedback_label.modulate = Color.WHITE
	feedback_label.show()
	
	games_played += 1
	var is_endless = (AppManager.current_mode == AppManager.Mode.ENDLESS)
	if not is_endless and games_played == total_games_per_run:
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
	# Immediate visual freeze and feedback
	timer_bar.stop()
	if is_instance_valid(current_instance):
		var disable_freeze = false
		if "disable_freeze_on_loss" in current_instance:
			disable_freeze = current_instance.disable_freeze_on_loss
		if not disable_freeze:
			current_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	var msg = "LOSE..."
	if current_game_is_final:
		msg = "Try Again" if lives > 1 else "You Lose"
	elif is_instance_valid(current_instance):
		if "lose_label_text" in current_instance:
			msg = current_instance.lose_label_text
	
	feedback_label.text = msg
	feedback_label.modulate = Color.WHITE
	feedback_label.show()
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
	# Hide HUD elements
	timer_bar.hide()
	feedback_label.hide()
	
	if game_over_scene == null:
		push_error("GameManager: game_over_scene is null!")
		AppManager.go_to_main_menu()
		return
		
	var game_over_screen = game_over_scene.instantiate()
	$HUDLayer.add_child(game_over_screen)
	game_over_screen.setup(games_played)
	game_over_screen.restart_requested.connect(func():
		game_over_screen.queue_free()
		start_game_loop()
	)
	game_over_screen.menu_requested.connect(func():
		game_over_screen.queue_free()
		AppManager.go_to_main_menu()
	)
