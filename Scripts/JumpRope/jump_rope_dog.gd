@tool
extends Node2D
class_name JumpRopeDog

@export var body_sprite_path: NodePath = ^"BodySprite"
@export var shadow_path: NodePath = ^"Shadow"
@export var jump_height: float = 92.0:
	set(value):
		jump_height = value
		_sync_visuals()

var rest_position: Vector2 = Vector2.ZERO
var has_rest_position: bool = false
var jump_elapsed: float = 0.0
var current_jump_duration: float = 0.42
var jump_active: bool = false
var default_frame_index: int = 0
var shadow_rest_position: Vector2 = Vector2.ZERO
var shadow_rest_scale: Vector2 = Vector2.ONE

@onready var body_sprite: Sprite2D = get_node_or_null(body_sprite_path) as Sprite2D
@onready var shadow_node: Node2D = get_node_or_null(shadow_path) as Node2D


func _ready() -> void:
	_cache_rest_position()
	_cache_visual_defaults()
	_sync_visuals()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not jump_active:
		return

	jump_elapsed += delta
	var progress: float = minf(jump_elapsed / current_jump_duration, 1.0)
	position = rest_position + Vector2(0.0, -sin(progress * PI) * jump_height)

	if progress >= 1.0:
		jump_active = false
		jump_elapsed = 0.0
		position = rest_position

	_sync_visuals()


func start_jump(duration: float) -> void:
	_cache_rest_position()
	current_jump_duration = maxf(duration, 0.01)
	jump_elapsed = 0.0
	jump_active = true
	_sync_visuals()


func reset_pose() -> void:
	_cache_rest_position()
	jump_active = false
	jump_elapsed = 0.0
	position = rest_position
	_sync_visuals()


func is_jump_active() -> bool:
	return jump_active


func _cache_rest_position() -> void:
	if not has_rest_position:
		rest_position = position
		has_rest_position = true


func _cache_visual_defaults() -> void:
	if is_instance_valid(body_sprite):
		default_frame_index = body_sprite.frame

	if is_instance_valid(shadow_node):
		shadow_rest_position = shadow_node.position
		shadow_rest_scale = shadow_node.scale


func _get_airborne_amount() -> float:
	if not jump_active:
		return 0.0

	return sin(clampf(jump_elapsed / current_jump_duration, 0.0, 1.0) * PI)


func _get_sprite_frame_index(safe_frame_count: int) -> int:
	if not jump_active:
		return clampi(default_frame_index, 0, safe_frame_count - 1)

	var progress: float = clampf(jump_elapsed / current_jump_duration, 0.0, 1.0)
	return clampi(int(progress * float(safe_frame_count)), 0, safe_frame_count - 1)


func _sync_visuals() -> void:
	if not is_node_ready():
		return

	_sync_body_sprite()
	_sync_shadow()


func _sync_body_sprite() -> void:
	if not is_instance_valid(body_sprite):
		return

	var safe_frame_count: int = maxi(body_sprite.hframes, 1)
	body_sprite.frame = _get_sprite_frame_index(safe_frame_count)


func _sync_shadow() -> void:
	if not is_instance_valid(shadow_node):
		return

	var airborne: float = _get_airborne_amount()
	var shrink: float = lerpf(1.0, 0.65, airborne)
	shadow_node.position = shadow_rest_position + Vector2(0.0, airborne * jump_height)
	shadow_node.scale = shadow_rest_scale * shrink
