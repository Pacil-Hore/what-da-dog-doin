extends Area2D
class_name Platform

enum PlatformType { SMALL_ROCK, BIG_ROCK, WOOD_LOG }

# Texture untuk masing-masing type
@export var small_rock_texture: Texture2D
@export var big_rock_texture: Texture2D
@export var wood_log_texture: Texture2D

@export var type: PlatformType = PlatformType.SMALL_ROCK:
	set(value):
		type = value
		_apply_type_settings()

@export var size: Vector2 = Vector2(162, 162):
	set(value):
		size = value
		_update_size()

@export var current_speed: float = 0.0
@export var current_direction: Vector2 = Vector2.ZERO

var capacity: int = 1
var occupants: Array = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D    # ← ganti dari color_rect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_type_settings()
	_update_size()

func _apply_type_settings() -> void:
	match type:
		PlatformType.SMALL_ROCK:
			capacity = 1
			current_speed = 0.0
			if sprite and small_rock_texture:
				sprite.texture = small_rock_texture
		PlatformType.BIG_ROCK:
			capacity = 2
			current_speed = 0.0
			if sprite and big_rock_texture:
				sprite.texture = big_rock_texture
		PlatformType.WOOD_LOG:
			capacity = 2
			if sprite and wood_log_texture:
				sprite.texture = wood_log_texture

func _update_size() -> void:
	if collision_shape:
		var new_shape = RectangleShape2D.new()
		new_shape.size = size
		collision_shape.shape = new_shape
		collision_shape.position = Vector2.ZERO
	
	# Scale sprite biar match dengan size yang diinginkan
	if sprite and sprite.texture:
		var texture_size = sprite.texture.get_size()
		sprite.scale = size / texture_size
		sprite.position = Vector2.ZERO  # sprite centered, jadi position 0,0

func _process(delta: float) -> void:
	if type == PlatformType.WOOD_LOG and current_speed > 0:
		var movement = current_direction.normalized() * current_speed * delta
		position += movement
		for occupant in occupants:
			if "is_moving" in occupant and occupant.is_moving:
				continue
			occupant.position += movement
		
		if occupants.is_empty():
			if position.x > 1600 or position.x < -400:
				queue_free()

func can_accept(_entity: Node) -> bool:
	return occupants.size() < capacity

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		if can_accept(body):
			occupants.append(body)
			if "current_platform" in body:
				body.current_platform = self
		else:
			if body.has_method("fall_in_water"):
				body.fall_in_water()

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body in occupants:
		occupants.erase(body)

func remove_occupant(entity: Node) -> void:
	if entity in occupants:
		occupants.erase(entity)
