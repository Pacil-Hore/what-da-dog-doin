extends Node

@export_group("Core Scenes")
@export var main_menu_scene: PackedScene
@export var cutscene_a_scene: PackedScene
@export var cutscene_c_scene: PackedScene
@export var game_manager_scene: PackedScene

@export_group("Scenario")
@export var scenario_games: Array[PackedScene] = []
@export var final_game: PackedScene

enum Mode { NONE, ENDLESS, STORY }

var current_mode: Mode = Mode.NONE
var story_stage: int = 0  # 0=cutscene_a, 1=gameplay, 2=cutscene_c

func go_to_main_menu():
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_packed(main_menu_scene)

func start_story_mode():
	current_mode = Mode.STORY
	story_stage = 0
	get_tree().change_scene_to_packed(cutscene_a_scene)

func story_cutscene_done():
	# Called when any cutscene is "continued"
	if story_stage == 0:
		# After cutscene A -> run the scenario
		story_stage = 1
		_launch_game_manager()
	elif story_stage == 2:
		# After cutscene C -> go to main menu
		go_to_main_menu()

func start_endless_mode():
	current_mode = Mode.ENDLESS
	_launch_game_manager()

func _launch_game_manager():
	# Pass via a global dict that GameManager will read
	# IMPORTANT: Use duplicate() to avoid clearing the source arrays in AppManager
	pending_scenario_games = scenario_games.duplicate()
	pending_final_game = final_game
	get_tree().change_scene_to_packed(game_manager_scene)

func on_run_won():
	if current_mode == Mode.STORY:
		if story_stage == 1:
			# Scenario won -> Cutscene C
			story_stage = 2
			get_tree().change_scene_to_packed(cutscene_c_scene)
	else:
		go_to_main_menu()

func on_run_lost():
	go_to_main_menu()

# Pending data for GameManager to pick up on _ready
var pending_scenario_games: Array[PackedScene] = []
var pending_final_game: PackedScene = null
