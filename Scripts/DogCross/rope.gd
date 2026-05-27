extends Node2D
class_name Rope

@export var entity_a: CharacterBody2D
@export var entity_b: CharacterBody2D
@export var max_steps: int = 3
@export var step_size: float = 162.0

# Offset manual per rope instance (buat geser tali tanpa ngubah entity)
@export var offset_a: Vector2 = Vector2.ZERO
@export var offset_b: Vector2 = Vector2.ZERO

@onready var line: Line2D = $Line2D

signal rope_snapped
var has_snapped: bool = false

func _process(_delta):
	if not entity_a or not entity_b:
		return
	
	var pos_a = _get_attachment_position(entity_a) + offset_a
	var pos_b = _get_attachment_position(entity_b) + offset_b
	
	line.clear_points()
	line.add_point(line.to_local(pos_a))
	line.add_point(line.to_local(pos_b))
	
	var distance = pos_a.distance_to(pos_b)
	var max_distance = step_size * max_steps
	var ratio = distance / max_distance
	
	if ratio < 0.7:
		line.default_color = Color.RED
	elif ratio < 1.0:
		line.default_color = Color.RED.lerp(Color.YELLOW, (ratio - 0.7) / 0.3)
	
	if not has_snapped and entity_a.is_alive and entity_b.is_alive:
		if not entity_a.is_moving and not entity_b.is_moving:
			if distance > max_distance:
				_snap_rope()

func _get_attachment_position(entity: Node) -> Vector2:
	# Kalau entity punya rope_offset (animated), pakai itu
	if "rope_offset" in entity:
		return entity.global_position + entity.rope_offset
	# Fallback: pakai center entity
	return entity.global_position

func _snap_rope():
	has_snapped = true
	line.default_color = Color.DARK_RED
	rope_snapped.emit()
	
	if entity_a.has_method("fall_in_water"):
		entity_a.fall_in_water()
	if entity_b.has_method("fall_in_water"):
		entity_b.fall_in_water()
