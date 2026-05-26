extends Node
class_name GameManager

signal dog_cross_won
signal dog_cross_lost

@export var player: CharacterBody2D
@export var dog: CharacterBody2D
@export var rope: Rope
@export var camera: Camera2D       # ← drag Camera2D di Inspector
@export var win_screen_scene: PackedScene  # ← drag WinScreen.tscn di Inspector
@export var show_win_screen: bool = false
@export var reload_on_loss: bool = false

var game_over: bool = false
var level_won: bool = false

func _ready():
	if player:
		player.fell_in_water.connect(_on_entity_fell)
	if dog:
		dog.fell_in_water.connect(_on_entity_fell)
	if rope:
		rope.rope_snapped.connect(_on_rope_snapped)
	
	call_deferred("_connect_finish_area")

func _connect_finish_area():
	await get_tree().process_frame
	var finish_area = _find_finish_area(get_tree().root)
	if finish_area and finish_area.has_signal("level_completed"):
		finish_area.level_completed.connect(_on_level_completed)

func _find_finish_area(node: Node) -> Node:
	if node.has_signal("level_completed"):
		return node
	for child in node.get_children():
		var found = _find_finish_area(child)
		if found:
			return found
	return null

func _on_entity_fell():
	if game_over or level_won:
		return
	game_over = true
	_trigger_game_over()

func _on_rope_snapped():
	if game_over or level_won:
		return
	game_over = true
	_trigger_game_over()

func _on_level_completed():
	if game_over or level_won:
		return
	level_won = true
	_trigger_win()

func _trigger_game_over():
	_stop_play()
	dog_cross_lost.emit()
	if reload_on_loss:
		await get_tree().create_timer(1.5).timeout
		get_tree().reload_current_scene()

func _trigger_win():
	print("GAME MANAGER TRIGGER")
	_stop_play()
	dog_cross_won.emit()
	if show_win_screen and win_screen_scene:
		var win_screen = win_screen_scene.instantiate()
		get_tree().current_scene.add_child(win_screen)

func _stop_play():
	if camera and "auto_scroll" in camera:
		camera.auto_scroll = false
	if player:
		player.set_process_input(false)
	if dog:
		dog.set_process_input(false)
