extends Node

@export_group("Core Scenes")
@export var main_menu_scene: PackedScene
@export var stage_select_scene: PackedScene
@export var cutscene_a_scene: PackedScene
@export var cutscene_b_scene: PackedScene
@export var cutscene_c_scene: PackedScene
@export var game_manager_scene: PackedScene

@export_group("Park Scenario")
@export var park_microgames: Array[PackedScene] = []
@export var park_boss: PackedScene

@export_group("Street Scenario")
@export var street_microgames: Array[PackedScene] = []
@export var street_boss: PackedScene

enum Mode { NONE, FREE_PLAY, STORY }

var current_mode: Mode = Mode.NONE
var story_stage: int = 0  # 0=cutscene_a, 1=park, 2=cutscene_b, 3=street, 4=cutscene_c

func go_to_main_menu():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_packed(main_menu_scene)

func start_story_mode():
	current_mode = Mode.STORY
	story_stage = 0
	get_tree().change_scene_to_packed(cutscene_a_scene)

func story_cutscene_done():
	# Called when any cutscene is "continued"
	if story_stage == 0:
		# After cutscene A -> run Park
		story_stage = 1
		_launch_game_manager(park_microgames, park_boss)
	elif story_stage == 2:
		# After cutscene B -> run Street
		story_stage = 3
		_launch_game_manager(street_microgames, street_boss)
	elif story_stage == 4:
		# After cutscene C -> go to main menu
		go_to_main_menu()

func start_free_play(scenario: String):
	current_mode = Mode.FREE_PLAY
	if scenario == "park":
		_launch_game_manager(park_microgames, park_boss)
	elif scenario == "street":
		_launch_game_manager(street_microgames, street_boss)

func _launch_game_manager(microgames: Array[PackedScene], boss: PackedScene):
	# Pass via a global dict that GameManager will read
	# IMPORTANT: Use duplicate() to avoid clearing the source arrays in AppManager
	pending_microgames = microgames.duplicate()
	pending_boss = boss
	get_tree().change_scene_to_packed(game_manager_scene)

func on_run_won():
	if current_mode == Mode.STORY:
		if story_stage == 1:
			# Park won -> Cutscene B
			story_stage = 2
			get_tree().change_scene_to_packed(cutscene_b_scene)
		elif story_stage == 3:
			# Street won -> Cutscene C
			story_stage = 4
			get_tree().change_scene_to_packed(cutscene_c_scene)
	else:
		go_to_main_menu()

func on_run_lost():
	go_to_main_menu()

# Pending data for GameManager to pick up on _ready
var pending_microgames: Array[PackedScene] = []
var pending_boss: PackedScene = null
