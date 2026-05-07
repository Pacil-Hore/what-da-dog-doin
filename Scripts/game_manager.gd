extends Node

signal run_won
signal run_lost

var microgames: Array[PackedScene] = []
var boss_game: PackedScene = null
var interstitial_scene: PackedScene = preload("res://Scenes/Interstitial.tscn")

var lives: int = 5
var games_played: int = 0
var speed_multiplier: float = 1.0

var current_instance: Node

func _ready():
	# Load config from AppManager (set before scene was changed)
	microgames = AppManager.pending_microgames.duplicate()
	boss_game = AppManager.pending_boss
	# Clear pending so they don't bleed over
	AppManager.pending_microgames.clear()
	AppManager.pending_boss = null

	call_deferred("start_game_loop")

func start_game_loop():
	lives = 5
	games_played = 0
	speed_multiplier = 1.0
	Engine.time_scale = speed_multiplier
	_load_interstitial()

func _load_interstitial():
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	var is_speed_up = (games_played == 14)
	if is_speed_up:
		speed_multiplier = 1.5
		Engine.time_scale = speed_multiplier

	var is_boss = (games_played == 24)

	if interstitial_scene == null:
		push_error("interstitial_scene is not assigned in GameManager")
		return

	var interstitial = interstitial_scene.instantiate()
	add_child(interstitial)
	current_instance = interstitial

	interstitial.setup(lives, games_played + 1, is_speed_up, is_boss)
	interstitial.interstitial_done.connect(_on_interstitial_done)

func _on_interstitial_done():
	if current_instance != null:
		current_instance.queue_free()
		current_instance = null

	var next_scene: PackedScene
	if games_played == 24:
		next_scene = boss_game
	else:
		if microgames.size() == 0:
			push_error("No microgames assigned to GameManager")
			return
		next_scene = microgames.pick_random()

	var game_instance = next_scene.instantiate()
	add_child(game_instance)
	current_instance = game_instance

	if game_instance.has_signal("game_won"):
		game_instance.game_won.connect(_on_game_won)
	if game_instance.has_signal("game_lost"):
		game_instance.game_lost.connect(_on_game_lost)

func _on_game_won():
	games_played += 1
	if games_played == 25:
		Engine.time_scale = 1.0
		emit_signal("run_won")
		AppManager.on_run_won()
		return
	_load_interstitial()

func _on_game_lost():
	lives -= 1
	games_played += 1
	if lives <= 0:
		Engine.time_scale = 1.0
		emit_signal("run_lost")
		AppManager.on_run_lost()
		return
	if games_played == 25:
		Engine.time_scale = 1.0
		emit_signal("run_lost")
		AppManager.on_run_lost()
		return
	_load_interstitial()
