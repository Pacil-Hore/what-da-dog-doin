extends Node

@export var microgames: Array[PackedScene] = [
	preload("res://Scenes/park/Labyrinth/labyrinth_level.tscn"),
	preload("res://Scenes/park/JumpRope/JumpRopeStage.tscn"),
	preload("res://Scenes/park/PickMe/PickMeStage.tscn"),
	preload("res://Scenes/park/Untangle/UntangleStage.tscn"),
	preload("res://Scenes/street/PickTheRope/PickTheRopeStage.tscn"),
	preload("res://Scenes/street/Toilet/ToiletStage.tscn"),
	preload("res://Scenes/Placeholders/PlaceholderGame1.tscn"),
	preload("res://Scenes/Placeholders/PlaceholderGame2.tscn")
]
@export var boss_game: PackedScene = preload("res://Scenes/Placeholders/PlaceholderBoss.tscn")
@export var interstitial_scene: PackedScene = preload("res://Scenes/Interstitial.tscn")

var lives: int = 5
var games_played: int = 0
var speed_multiplier: float = 1.0

var current_instance: Node

func _ready():
	# Allow microgames arrays to be set in inspector
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
		
	var is_speed_up = (games_played == 14) # the 15th game
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
		print("YOU WIN!")
		start_game_loop()
		return
	_load_interstitial()

func _on_game_lost():
	lives -= 1
	games_played += 1
	if lives <= 0:
		print("GAME OVER!")
		start_game_loop()
		return
	if games_played == 25:
		print("YOU LOSE ON BOSS!")
		start_game_loop()
		return
	_load_interstitial()
