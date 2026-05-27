@tool
extends Node2D

@export var full_background_sprite_path: NodePath = ^"FullBackground"
@export var full_background_texture: Texture2D:
	set(value):
		full_background_texture = value
		_sync_full_background()
@export var full_background_region: Rect2:
	set(value):
		full_background_region = value
		_sync_full_background()
@export var full_background_scale_to_size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		full_background_scale_to_size = value
		_sync_full_background()

var full_background_sprite: Sprite2D


func _ready() -> void:
	_cache_child_nodes()
	_sync_full_background()


func _cache_child_nodes() -> void:
	if String(full_background_sprite_path) == "":
		full_background_sprite = null
		return

	full_background_sprite = get_node_or_null(full_background_sprite_path) as Sprite2D


func _sync_full_background() -> void:
	if not is_node_ready():
		return
	if not is_instance_valid(full_background_sprite):
		return

	if full_background_texture != null:
		full_background_sprite.texture = full_background_texture

	var texture_size: Vector2 = Vector2.ZERO
	if full_background_region.size.x > 0.0 and full_background_region.size.y > 0.0:
		full_background_sprite.region_enabled = true
		full_background_sprite.region_rect = full_background_region
		texture_size = full_background_region.size
	elif full_background_sprite.texture != null:
		full_background_sprite.region_enabled = false
		texture_size = full_background_sprite.texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	full_background_sprite.centered = false
	full_background_sprite.scale = Vector2(
		full_background_scale_to_size.x / texture_size.x,
		full_background_scale_to_size.y / texture_size.y
	)
