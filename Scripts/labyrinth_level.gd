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

var original_level_position := Vector2.ZERO
var shake_amount := 0.0

var vignette: Control
var camera: Camera2D


func _ready() -> void:
	original_level_position = position
	maze_bounds = _get_maze_bounds()
	
	# Setup Camera2D centered in viewport
	camera = Camera2D.new()
	camera.position = Vector2(576, 324)
	add_child(camera)
	
	# Create and add vignette
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	add_child(canvas)
	vignette = TimeBorder.new()
	canvas.add_child(vignette)
	
	reset_level()




func _process(delta: float) -> void:
	if is_finished:
		return

	# Handle screen shake
	if shake_amount > 0.0:
		position = original_level_position + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = lerpf(shake_amount, 0.0, delta * 12.0)
		if shake_amount < 0.1:
			shake_amount = 0.0
			position = original_level_position

	# Constant minor shake under high leash tension
	if is_started and is_instance_valid(player) and is_instance_valid(man_sprite):
		var dist = player.global_position.distance_to(man_sprite.global_position)
		if dist > 38.0 and player.velocity.length() > 100.0:
			shake_screen(1.2)

	# Update vignette alpha when time is low
	if is_instance_valid(time_limit_timer) and not is_finished:
		var time_left = time_limit_timer.time_left
		if time_left < 1.5:
			vignette.alpha = 0.2 + 0.25 * sin(time_left * 16.0)
			vignette.queue_redraw()
		else:
			vignette.alpha = 0.0
			vignette.queue_redraw()


func reset_level() -> void:
	is_finished = false
	is_started = false
	shake_amount = 0.0
	position = original_level_position
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
	
	if is_instance_valid(camera):
		camera.position = Vector2(576, 324)
		camera.zoom = Vector2(1.0, 1.0)
	
	if hide_system_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_process(delta: float) -> void:
	if not is_started:
		is_started = true
		player.enabled = true
		
		# (Physics joint disabled: ManSprite now uses kinematic movement via move_and_slide() instead of joint physics)
		pass

	# Check for win condition on every frame to be extremely robust
	if is_started and not is_finished and is_instance_valid(player) and is_instance_valid(man_sprite):
		var overlapping = win_area.get_overlapping_bodies()
		if overlapping.has(player):
			var dist = player.global_position.distance_to(man_sprite.global_position)
			if overlapping.has(man_sprite) or dist <= 85.0:
				finish_level(win_label_text)


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
		Engine.time_scale = 0.25
		if is_instance_valid(camera) and is_instance_valid(player):
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(camera, "position", player.global_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		emit_signal("game_won")
	else:
		emit_signal("game_lost")


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func shake_screen(amount: float) -> void:
	shake_amount = clampf(maxf(shake_amount, amount), 0.0, 10.0)



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
	if not is_finished and is_instance_valid(player) and is_instance_valid(man_sprite):
		var overlapping = win_area.get_overlapping_bodies()
		if overlapping.has(player):
			var dist = player.global_position.distance_to(man_sprite.global_position)
			if overlapping.has(man_sprite) or dist <= 85.0:
				finish_level(win_label_text)


func _on_time_limit_timeout() -> void:
	finish_level(lose_label_text)


# Inner class for drawing a thick border when time is low
class TimeBorder extends Control:
	var alpha := 0.0
	
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	func _draw() -> void:
		if alpha <= 0.01:
			return
		var rect = get_rect()
		var border_color = Color(1.0, 0.0, 0.0, alpha)
		var border_width = 16.0
		# Draw the 4 border lines
		draw_rect(Rect2(0, 0, rect.size.x, border_width), border_color)
		draw_rect(Rect2(0, rect.size.y - border_width, rect.size.x, border_width), border_color)
		draw_rect(Rect2(0, border_width, border_width, rect.size.y - 2 * border_width), border_color)
		draw_rect(Rect2(rect.size.x - border_width, border_width, border_width, rect.size.y - 2 * border_width), border_color)
