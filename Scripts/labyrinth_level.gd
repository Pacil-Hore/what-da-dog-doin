extends Node2D

@export var time_limit := 5.0
@export var win_label_text := "You Win"
@export var lose_label_text := "You Lose"
@export var hide_system_cursor := true

@onready var maze: Node2D = $LabyrinthLevel
@onready var tile_map: TileMapLayer = $LabyrinthLevel/TileMapLayer
@onready var player: PlayerMouse = $Player
@onready var win_area: Area2D = $WinArea
@onready var start_point: Marker2D = $StartPoint
@onready var time_limit_timer: Timer = $TimeLimit
@onready var timer_label: Label = $HUD/TimerLabel
@onready var result_label: Label = $HUD/ResultLabel

var time_left := 0.0
var is_finished := false
var maze_bounds := Rect2()


func _ready() -> void:
	maze_bounds = _get_maze_bounds()
	reset_level()


func _process(delta: float) -> void:
	if is_finished:
		return

	time_left = max(time_left - delta, 0.0)
	timer_label.text = "Time: %.1f" % time_left


func reset_level() -> void:
	is_finished = false
	time_left = time_limit
	player.enabled = true
	player.global_position = start_point.global_position
	player.movement_bounds = maze_bounds.grow(-player.cursor_radius)
	player.has_movement_bounds = true
	result_label.text = ""
	timer_label.text = "Time: %.1f" % time_left
	time_limit_timer.start(time_limit)
	_warp_mouse_to_player()
	if hide_system_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func finish_level(message: String) -> void:
	if is_finished:
		return

	is_finished = true
	player.enabled = false
	time_limit_timer.stop()
	result_label.text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _get_maze_bounds() -> Rect2:
	var used_rect := tile_map.get_used_rect()
	var tile_size := Vector2(tile_map.tile_set.tile_size)
	var top_left := tile_map.global_position + Vector2(used_rect.position) * tile_size
	var maze_size := Vector2(used_rect.size) * tile_size

	return Rect2(top_left, maze_size)


func _warp_mouse_to_player() -> void:
	await get_tree().process_frame
	get_viewport().warp_mouse(player.get_global_transform_with_canvas().origin)


func _on_win_area_body_entered(body: Node2D) -> void:
	if body != player:
		return

	finish_level(win_label_text)


func _on_time_limit_timeout() -> void:
	finish_level(lose_label_text)
