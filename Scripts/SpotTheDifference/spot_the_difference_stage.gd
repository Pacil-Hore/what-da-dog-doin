extends Node2D

signal game_finished(did_win: bool)
signal game_won
signal game_lost

# ── Microgame exports (read by GameManager) ────────────────────────────────
@export var time_limit := 10.0
@export var total_differences := 3
@export var instruction_text := "TOUCH 3 DIFFERENCES!"
@export var objective_text: String = "Spot it!"
@export var win_label_text: String = "CLEAN!"
@export var lose_label_text: String = "TOO SLOW!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var disable_freeze_on_loss := true
@export var test_mode := false
@export_range(-1, 9, 1) var forced_combo_index := -1

# ── Node references ────────────────────────────────────────────────────────
@onready var game_canvas: CanvasLayer       = $GameCanvas
@onready var image_container: HBoxContainer = $GameCanvas/MainLayout/GameArea/ImageContainer
@onready var left_image: Control            = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage
@onready var right_image: Control           = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage
@onready var result_label: Label            = $GameCanvas/ResultLabel
@onready var countdown_timer: Timer         = $CountdownTimer
@onready var distraction_manager: CanvasLayer = $DistractionLayer

# Overlay containers
@onready var left_overlays: Control  = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays
@onready var right_overlays: Control = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays
@onready var left_regions: Control   = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions
@onready var right_regions: Control  = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions

var left_counter_label: Label
var right_counter_label: Label

@onready var l_vending: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/VendingMachine
@onready var l_trash: Sprite2D           = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/TrashCan
@onready var l_traffic: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/TrafficLight
@onready var l_hydrant: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/FireHydrant
@onready var l_sign: Sprite2D            = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/ShopSign
@onready var l_dog: AnimatedSprite2D     = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/Overlays/Dog

@onready var r_vending: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/VendingMachine
@onready var r_trash: Sprite2D           = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/TrashCan
@onready var r_traffic: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/TrafficLight
@onready var r_hydrant: Sprite2D         = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/FireHydrant
@onready var r_sign: Sprite2D            = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/ShopSign
@onready var r_dog: AnimatedSprite2D     = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/Overlays/Dog

# Static scene nodes — Left DiffRegions
@onready var l_region_a: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions/Region_A
@onready var l_region_b: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions/Region_B
@onready var l_region_c: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions/Region_C
@onready var l_region_d: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions/Region_D
@onready var l_region_e: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/LeftImage/DiffRegions/Region_E

# Static scene nodes — Right DiffRegions
@onready var r_region_a: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions/Region_A
@onready var r_region_b: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions/Region_B
@onready var r_region_c: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions/Region_C
@onready var r_region_d: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions/Region_D
@onready var r_region_e: DifferenceRegion = $GameCanvas/MainLayout/GameArea/ImageContainer/RightImage/DiffRegions/Region_E

# ── Asset paths ────────────────────────────────────────────────────────────
const ASSET_DIR = "res://Assets/Sprites/spot the difference/"
const PANEL_SIZE = Vector2(574.0, 648.0)
const SPRITE_PATHS = {
	"vending_red":   "vending_machine_red.png",
	"vending_blue":  "vending_machine_blue.png",
	"trash_can":     "trash_can.png",
	"mailbox":       "mailbox.png",
	"hydrant":       "fire_hydrant.png",
	"sign_open":     "open_sign.png",
	"sign_closed":   "closed_sign.png",
}

# ── Combo system ───────────────────────────────────────────────────────────
const COMBOS = [
	["A", "B", "C"], ["A", "B", "D"], ["A", "B", "E"],
	["A", "C", "D"], ["A", "C", "E"], ["A", "D", "E"],
	["B", "C", "D"], ["B", "C", "E"], ["B", "D", "E"],
	["C", "D", "E"]
]

# ── State ──────────────────────────────────────────────────────────────────
var differences_found := 0
var is_finished := false
var active_cases: Array[String] = []
var loaded_textures := {}

static var _combo_bag: Array = []

# ── Ready ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	_validate_combo_table()
	_load_textures()
	_create_counter_labels()
	_set_matching_panel_properties()
	_set_region_layering()
	l_dog.play("idle")
	r_dog.play("idle")
	
	# Pick combo and configure differences
	active_cases = _pick_combo()
	total_differences = active_cases.size()
	instruction_text = "TOUCH %d DIFFERENCES!" % total_differences
	
	_apply_difference_sprites()
	_configure_diff_regions()
	_update_counter()

	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	reset_game()

	if test_mode:
		_run_automated_test()

# ── Scenery & Asset Setup ──────────────────────────────────────────────────

func _set_matching_panel_properties() -> void:
	for panel in [left_image, right_image]:
		panel.custom_minimum_size = PANEL_SIZE
		panel.clip_contents = true

func _set_region_layering() -> void:
	for regions in [left_regions, right_regions]:
		regions.z_index = 80
		regions.z_as_relative = false
		regions.show_behind_parent = false
		regions.clip_contents = false
		regions.get_parent().move_child(regions, regions.get_parent().get_child_count() - 1)

func _create_counter_labels() -> void:
	left_counter_label = _make_counter_label(left_image)
	right_counter_label = _make_counter_label(right_image)

func _make_counter_label(parent: Control) -> Label:
	var label := Label.new()
	label.name = "DifferenceCounter"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 30
	label.text = "0/3"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.size = Vector2(86, 42)
	label.position = Vector2(PANEL_SIZE.x - label.size.x - 14.0, 14.0)
	parent.add_child(label)
	return label

func _apply_difference_sprites() -> void:
	# Map case key -> [left node, right node, left tex key, right tex key]
	var case_nodes := {
		"A": [l_vending,  r_vending,  "vending_red",   "vending_blue"],
		"B": [l_trash,    r_trash,    "trash_can",      "mailbox"],
		"C": [l_traffic,  r_traffic,  "traffic_light",  ""],
		"D": [l_hydrant,  r_hydrant,  "",               "hydrant"],
		"E": [l_sign,     r_sign,     "sign_open",      "sign_closed"],
	}
	for key in case_nodes:
		var info   = case_nodes[key]
		var l_node: Sprite2D = info[0]
		var r_node: Sprite2D = info[1]
		var l_key: String    = info[2]
		var r_key: String    = info[3]
		var is_active        = key in active_cases

		if key == "C":
			l_node.visible = true
			r_node.visible = not is_active
			continue

		# Left panel — always show left variant
		if l_key != "" and loaded_textures.has(l_key):
			l_node.texture = loaded_textures[l_key]
			l_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			l_node.visible = true
		else:
			l_node.visible = false  # Case D: no hydrant on left

		# Right panel — active = different variant, inactive = same as left
		if is_active:
			if r_key != "" and loaded_textures.has(r_key):
				r_node.texture = loaded_textures[r_key]
				r_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				r_node.visible = true
			else:
				r_node.visible = false  # Case C: traffic light absent on right
		else:
			# Mirror the left side exactly
			if l_key != "" and loaded_textures.has(l_key):
				r_node.texture = loaded_textures[l_key]
				r_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				r_node.visible = true
			else:
				r_node.visible = false

func _configure_diff_regions() -> void:
	# Map case key -> [left region, right region]
	var region_map := {
		"A": [l_region_a, r_region_a],
		"B": [l_region_b, r_region_b],
		"C": [l_region_c, r_region_c],
		"D": [l_region_d, r_region_d],
		"E": [l_region_e, r_region_e],
	}
	for key in region_map:
		var pair = region_map[key]
		var lr: DifferenceRegion = pair[0]
		var rr: DifferenceRegion = pair[1]
		var is_active = key in active_cases
		# Only active regions are clickable; inactive are non-interactive
		lr.mouse_filter = Control.MOUSE_FILTER_STOP if is_active else Control.MOUSE_FILTER_IGNORE
		rr.mouse_filter = Control.MOUSE_FILTER_STOP if is_active else Control.MOUSE_FILTER_IGNORE
		lr.visible = is_active
		rr.visible = is_active
		if is_active:
			if not lr.found.is_connected(_on_difference_found):
				lr.found.connect(_on_difference_found)
			if not rr.found.is_connected(_on_difference_found):
				rr.found.connect(_on_difference_found)

# ── Texture loading ────────────────────────────────────────────────────────

func _load_textures() -> void:
	for key in SPRITE_PATHS:
		var path = ASSET_DIR + SPRITE_PATHS[key]
		var tex = load(path)
		if tex:
			loaded_textures[key] = tex
		else:
			push_warning("SpotTheDifference: failed to load " + path)

func _pick_combo() -> Array[String]:
	if test_mode and forced_combo_index >= 0 and forced_combo_index < COMBOS.size():
		var forced_result: Array[String] = []
		for c in COMBOS[forced_combo_index]:
			forced_result.append(c)
		return forced_result

	if _combo_bag.is_empty():
		_combo_bag = COMBOS.duplicate()
		_combo_bag.shuffle()
	var combo = _combo_bag.pop_front()
	var result: Array[String] = []
	for c in combo:
		result.append(c)
	return result

func _validate_combo_table() -> void:
	var expected := {
		"ABC": true, "ABD": true, "ABE": true, "ACD": true, "ACE": true,
		"ADE": true, "BCD": true, "BCE": true, "BDE": true, "CDE": true,
	}
	if COMBOS.size() != expected.size():
		push_error("SpotTheDifference: combo table must contain exactly 10 combinations.")
		return
	var seen := {}
	for combo in COMBOS:
		if combo.size() != 3:
			push_error("SpotTheDifference: every combo must contain exactly 3 cases.")
			return
		var sorted_combo: Array = combo.duplicate()
		sorted_combo.sort()
		var key := ""
		for case_key in sorted_combo:
			key += case_key
		if not expected.has(key) or seen.has(key):
			push_error("SpotTheDifference: invalid or duplicate combo " + key)
			return
		seen[key] = true

# ── Game loop ──────────────────────────────────────────────────────────────

func reset_game() -> void:
	is_finished = false
	differences_found = 0
	_update_counter()
	result_label.text = ""
	result_label.modulate.a = 0.0
	result_label.pivot_offset = result_label.size / 2.0

	if is_instance_valid(distraction_manager):
		distraction_manager.clear_all_distractions()
		distraction_manager.start()

	countdown_timer.wait_time = time_limit
	countdown_timer.start()
	_show_instruction()

func _on_difference_found(region: DifferenceRegion) -> void:
	if is_finished: return
	# Sync both panels for the same region letter (A/B/C/D/E)
	var letter = region.name.substr(region.name.length() - 1, 1)  # "Region_A" → "A"
	_sync_region_pair(letter)
	differences_found += 1
	_update_counter()
	if differences_found >= total_differences:
		finish_game(true)

func _update_counter() -> void:
	var counter_text := "%d/%d" % [differences_found, total_differences]
	if is_instance_valid(left_counter_label):
		left_counter_label.text = counter_text
	if is_instance_valid(right_counter_label):
		right_counter_label.text = counter_text

func _sync_region_pair(letter: String) -> void:
	_set_region_layering()
	for container in [left_regions, right_regions]:
		for child in container.get_children():
			if child.name.ends_with(letter):
				container.move_child(child, container.get_child_count() - 1)
				(child as DifferenceRegion).is_found = true

func _on_countdown_timer_timeout() -> void:
	if not is_finished:
		finish_game(false)

func _show_instruction() -> void:
	# Only show our local label in standalone / test mode
	if not (get_parent() is Window):
		return
	result_label.text = instruction_text
	result_label.modulate = Color.WHITE
	result_label.modulate.a = 1.0
	result_label.scale = Vector2(1.8, 1.8)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.3)
	await get_tree().create_timer(0.8).timeout
	if not is_finished:
		create_tween().tween_property(result_label, "modulate:a", 0.0, 0.2)

func finish_game(did_win: bool, _message: String = "") -> void:
	if is_finished: return
	is_finished = true
	countdown_timer.stop()

	if is_instance_valid(distraction_manager):
		distraction_manager.stop()
		distraction_manager.clear_all_distractions()

	# result_label intentionally hidden — GameManager shows feedback_label,
	# microgame_test_helper shows TestResultLabel. Showing ours causes overlap.
	result_label.visible = false

	if did_win:
		game_won.emit()
	else:
		_handle_miss()
		game_lost.emit()
	game_finished.emit(did_win)

func _on_diff_container_gui_input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_miss()

func _handle_miss() -> void:
	countdown_timer.start(max(0.1, countdown_timer.time_left - 0.5))
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var original_pos = image_container.position
	for i in range(6):
		tween.tween_property(image_container, "position",
			original_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.04)
	tween.tween_property(image_container, "position", original_pos, 0.04)
	var bg = $GameCanvas/Background
	var flash = create_tween()
	flash.tween_property(bg, "color", Color(0.4, 0.0, 0.0), 0.05)
	flash.tween_property(bg, "color", Color(0.04, 0.04, 0.04), 0.15)

# ── Automated Test ─────────────────────────────────────────────────────────

func _run_automated_test() -> void:
	await get_tree().create_timer(1.0).timeout
	print("[SpotTheDifference TEST] Starting — active cases: ", active_cases)
	for case_key in active_cases:
		await get_tree().create_timer(1.0).timeout
		print("[SpotTheDifference TEST] Clicking difference: ", case_key)
		# Map letter -> left region node
		var region_map := {
			"A": l_region_a, "B": l_region_b, "C": l_region_c,
			"D": l_region_d, "E": l_region_e
		}
		if region_map.has(case_key):
			(region_map[case_key] as DifferenceRegion)._on_found()
