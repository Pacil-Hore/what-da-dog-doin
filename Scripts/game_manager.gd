extends Node

signal run_won
signal run_lost

@export_group("Settings")
@export var initial_lives: int = 5
@export var speed_up_threshold: int = 14
@export var speed_up_multiplier: float = 1.5
@export var total_games_per_run: int = 25

@export_group("Scenes")
@export var interstitial_scene: PackedScene

var microgames: Array[PackedScene] = []
var boss_game: PackedScene = null
var lives: int = 5
var games_played: int = 0
var speed_multiplier: float = 1.0

var current_instance: Node
var next_game_scene: PackedScene = null

func _ready():
	# Load config from AppManager (set before scene was changed)
	if AppManager.pending_microgames.is_empty():
		push_error("GameManager: AppManager.pending_microgames is empty!")
	
	microgames = AppManager.pending_microgames.duplicate()
	boss_game = AppManager.pending_boss
	
	# We don't clear AppManager's pending data here anymore to avoid 
	# accidentally clearing the source arrays if they were passed by reference.
	# They will be overwritten anyway on the next launch.

	call_deferred("start_game_loop")

func start_game_loop():
	lives = initial_lives
	games_played = 0
	speed_multiplier = 1.0
	Engine.time_scale = speed_multiplier
	_pick_next_game()
	_load_interstitial()

func _pick_next_game():
	if games_played == total_games_per_run - 1:
		next_game_scene = boss_game
	else:
		if microgames.size() == 0:
			push_error("No microgames assigned to GameManager")
			return
		next_game_scene = microgames.pick_random()

func _load_interstitial():
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	if next_game_scene == null:
		push_error("GameManager: next_game_scene is null!")
		AppManager.go_to_main_menu()
		return

	var is_speed_up = (games_played == speed_up_threshold)
	if is_speed_up:
		speed_multiplier = speed_up_multiplier
		Engine.time_scale = speed_multiplier

	var is_boss = (games_played == total_games_per_run - 1)

	if interstitial_scene == null:
		push_error("GameManager: interstitial_scene is null!")
		AppManager.go_to_main_menu()
		return

	var interstitial = interstitial_scene.instantiate()
	add_child(interstitial)
	current_instance = interstitial

	# To get control icon, we'll instantiate the game but not add it yet
	var temp_game = next_game_scene.instantiate()
	var icon_path = "res://assets/generated/placeholder_icon.png"
	if "control_icon_path" in temp_game:
		icon_path = temp_game.control_icon_path
	temp_game.queue_free()

	interstitial.setup(lives, icon_path, is_speed_up, is_boss)
	interstitial.interstitial_done.connect(_on_interstitial_done)

func _on_interstitial_done():
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	var game_instance = next_game_scene.instantiate()
	add_child(game_instance)
	current_instance = game_instance
	
	# Pause gameplay until objective is shown
	game_instance.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Show objective overlay
	var overlay_scene = load("res://Scenes/ObjectiveOverlay.tscn")
	var overlay = overlay_scene.instantiate()
	# Use a separate CanvasLayer so it's not affected by game's process mode
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

	if game_instance.has_signal("game_won"):
		game_instance.game_won.connect(_on_game_won)
	if game_instance.has_signal("game_lost"):
		game_instance.game_lost.connect(_on_game_lost)

func _on_game_won():
	games_played += 1
	if games_played == total_games_per_run:
		Engine.time_scale = 1.0
		emit_signal("run_won")
		AppManager.on_run_won()
		return
	_pick_next_game()
	_load_interstitial()

func _on_game_lost():
	lives -= 1
	if lives <= 0:
		Engine.time_scale = 1.0
		emit_signal("run_lost")
		AppManager.on_run_lost()
		return
	
	# If it's not the boss, proceed to the next game
	# If it IS the boss (games_played == total_games_per_run - 1), we don't increment
	# so that _pick_next_game() keeps choosing the boss.
	if games_played < total_games_per_run - 1:
		games_played += 1
		_pick_next_game()
	else:
		# Retry boss
		_pick_next_game()
	
	_load_interstitial()
