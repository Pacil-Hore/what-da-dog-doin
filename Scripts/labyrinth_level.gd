extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Exit the labyrinth!"
@export var control_hint: String = "Mouse"
@export var control_icon: Texture2D

@export var time_limit := 5.0
@export var win_label_text := "You Win"
@export var lose_label_text := "You Lose"
@export var hide_system_cursor := true

@onready var maze: Node2D = $MazeObject
@onready var tile_map: TileMapLayer = $MazeObject/TileMapLayer
@onready var player: PlayerMouse = $Player
@onready var win_area: Area2D = $WinArea
@onready var start_point: Marker2D = $StartPoint
@onready var time_limit_timer: Timer = get_node_or_null("TimeLimit")
@onready var man_sprite: Node2D = get_node_or_null("ManSprite")
@onready var joint: DampedSpringJoint2D = get_node_or_null("DampedSpringJoint2D")

var is_finished := false
var is_started := false
var maze_bounds := Rect2()


func _ready() -> void:
	maze_bounds = _get_maze_bounds()
	reset_level()


func _process(_delta: float) -> void:
	if is_finished:
		return


func reset_level() -> void:
	is_finished = false
	is_started = false
	player.enabled = false # Disable until physics process starts
	player.global_position = start_point.global_position
	if is_instance_valid(man_sprite) and man_sprite.has_method("reset_ragdoll"):
		man_sprite.reset_ragdoll(start_point.global_position + Vector2(0, 40))
		
	if is_instance_valid(joint):
		# Destroy old joint to prevent physics bugs when teleporting/pausing
		joint.queue_free()
		joint = null
	player.movement_bounds = maze_bounds.grow(-player.collision_radius)
	player.has_movement_bounds = true
	if is_instance_valid(time_limit_timer):
		time_limit_timer.start(time_limit)
	
	_warp_mouse_to_player()
	
	if hide_system_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_process(delta: float) -> void:
	if not is_started:
		is_started = true
		player.enabled = true
		
		# Recreate joint after unpause to ensure physics constraint is fresh
		joint = DampedSpringJoint2D.new()
		joint.global_position = player.global_position
		joint.length = 40.0
		joint.rest_length = 30.0
		joint.stiffness = 64.0
		joint.damping = 2.0
		add_child(joint)
		joint.node_a = joint.get_path_to(player)
		joint.node_b = joint.get_path_to(man_sprite)
		
		if man_sprite is RigidBody2D:
			man_sprite.sleeping = false

func finish_level(message: String) -> void:
	if is_finished:
		return

	is_finished = true
	player.enabled = false
	if is_instance_valid(time_limit_timer):
		time_limit_timer.stop()
	# result_label.text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if message == win_label_text:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")



func _get_maze_bounds() -> Rect2:
	var used_rect := tile_map.get_used_rect()
	var tile_size := Vector2(tile_map.tile_set.tile_size)
	var top_left := tile_map.global_position + Vector2(used_rect.position) * tile_size * tile_map.scale
	var maze_size := Vector2(used_rect.size) * tile_size * tile_map.scale

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
