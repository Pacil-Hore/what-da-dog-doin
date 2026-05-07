extends Node

# Scenes
const MAIN_MENU_SCENE = "res://Scenes/Menus/MainMenu.tscn"
const STAGE_SELECT_SCENE = "res://Scenes/Menus/StageSelect.tscn"
const CUTSCENE_A_SCENE = "res://Scenes/Cutscenes/CutsceneA.tscn"
const CUTSCENE_B_SCENE = "res://Scenes/Cutscenes/CutsceneB.tscn"
const CUTSCENE_C_SCENE = "res://Scenes/Cutscenes/CutsceneC.tscn"
const GAME_MANAGER_SCENE = "res://Scenes/GameManager.tscn"

# Scenario configs: arrays of scene paths
const PARK_MICROGAMES: Array[String] = [
	"res://Scenes/park/Labyrinth/labyrinth_level.tscn",
	"res://Scenes/park/JumpRope/JumpRopeStage.tscn",
	"res://Scenes/park/PickMe/PickMeStage.tscn",
	"res://Scenes/park/Untangle/UntangleStage.tscn",
	"res://Scenes/park/PlaceholderPark1.tscn",
	"res://Scenes/park/PlaceholderPark2.tscn",
	"res://Scenes/park/PlaceholderPark3.tscn",
	"res://Scenes/park/PlaceholderPark4.tscn",
]
const PARK_BOSS: String = "res://Scenes/park/PlaceholderParkBoss.tscn"

const STREET_MICROGAMES: Array[String] = [
	"res://Scenes/street/PickTheRope/PickTheRopeStage.tscn",
	"res://Scenes/street/Toilet/ToiletStage.tscn",
	"res://Scenes/street/PlaceholderStreet1.tscn",
	"res://Scenes/street/PlaceholderStreet2.tscn",
	"res://Scenes/street/PlaceholderStreet3.tscn",
	"res://Scenes/street/PlaceholderStreet4.tscn",
	"res://Scenes/street/PlaceholderStreet5.tscn",
	"res://Scenes/street/PlaceholderStreet6.tscn",
]
const STREET_BOSS: String = "res://Scenes/street/PlaceholderStreetBoss.tscn"

enum Mode { NONE, FREE_PLAY, STORY }

var current_mode: Mode = Mode.NONE
var story_stage: int = 0  # 0=cutscene_a, 1=park, 2=cutscene_b, 3=street, 4=cutscene_c

func go_to_main_menu():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func start_story_mode():
	current_mode = Mode.STORY
	story_stage = 0
	get_tree().change_scene_to_file(CUTSCENE_A_SCENE)

func story_cutscene_done():
	# Called when any cutscene is "continued"
	if story_stage == 0:
		# After cutscene A -> run Park
		story_stage = 1
		_launch_game_manager(PARK_MICROGAMES, PARK_BOSS)
	elif story_stage == 2:
		# After cutscene B -> run Street
		story_stage = 3
		_launch_game_manager(STREET_MICROGAMES, STREET_BOSS)
	elif story_stage == 4:
		# After cutscene C -> go to main menu
		go_to_main_menu()

func start_free_play(scenario: String):
	current_mode = Mode.FREE_PLAY
	if scenario == "park":
		_launch_game_manager(PARK_MICROGAMES, PARK_BOSS)
	elif scenario == "street":
		_launch_game_manager(STREET_MICROGAMES, STREET_BOSS)

func _launch_game_manager(microgames: Array[String], boss: String):
	# Store the config so GameManager can read it
	var packed_microgames: Array[PackedScene] = []
	for path in microgames:
		var scene = load(path) as PackedScene
		if scene:
			packed_microgames.append(scene)
		else:
			push_warning("AppManager: Could not load microgame: " + path)
	
	var boss_scene = load(boss) as PackedScene
	if not boss_scene:
		push_warning("AppManager: Could not load boss: " + boss)
	
	# Pass via a global dict that GameManager will read
	pending_microgames = packed_microgames
	pending_boss = boss_scene
	get_tree().change_scene_to_file(GAME_MANAGER_SCENE)

func on_run_won():
	if current_mode == Mode.STORY:
		if story_stage == 1:
			# Park won -> Cutscene B
			story_stage = 2
			get_tree().change_scene_to_file(CUTSCENE_B_SCENE)
		elif story_stage == 3:
			# Street won -> Cutscene C
			story_stage = 4
			get_tree().change_scene_to_file(CUTSCENE_C_SCENE)
	else:
		go_to_main_menu()

func on_run_lost():
	go_to_main_menu()

# Pending data for GameManager to pick up on _ready
var pending_microgames: Array[PackedScene] = []
var pending_boss: PackedScene = null
