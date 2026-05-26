@tool
extends Node2D

@export var body_sprite_path: NodePath = ^"BodySprite"
@export var frame_index: int = 0:
	set(value):
		frame_index = maxi(value, 0)
		_sync_sprite()
@export var use_scripted_frame: bool = false:
	set(value):
		use_scripted_frame = value
		_sync_sprite()

@onready var body_sprite: Sprite2D = get_node_or_null(body_sprite_path) as Sprite2D


func _ready() -> void:
	_sync_sprite()


func _sync_sprite() -> void:
	if not is_node_ready() or not is_instance_valid(body_sprite):
		return

	if not use_scripted_frame:
		return

	var safe_frame_count: int = maxi(body_sprite.hframes, 1)
	body_sprite.frame = clampi(frame_index, 0, safe_frame_count - 1)
