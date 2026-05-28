@tool
extends Node2D
class_name JumpRopeDog

@export var body_sprite_path: NodePath = ^"BodySprite"
@export var shadow_path: NodePath = ^"Shadow"
@export var idle_animation_name: StringName = &"dog_idle"
@export var jump_animation_name: StringName = &"dog_run"
@export var jump_height: float = 92.0:
	set(value):
		jump_height = value
		_sync_visuals()
@export var jump_squash_amount: float = 0.08:
	set(value):
		jump_squash_amount = maxf(value, 0.0)
		_sync_visuals()
@export var jump_stretch_amount: float = 0.08:
	set(value):
		jump_stretch_amount = maxf(value, 0.0)
		_sync_visuals()
@export_range(0.2, 1.0, 0.01) var shadow_airborne_shrink: float = 0.65:
	set(value):
		shadow_airborne_shrink = clampf(value, 0.2, 1.0)
		_sync_visuals()
@export var miss_impact_duration: float = 0.24
@export var miss_impact_shake_distance: float = 12.0
@export var miss_impact_tint: Color = Color(1.0, 0.42, 0.36, 1.0)
@export var miss_impact_squash: Vector2 = Vector2(1.1, 0.9)

var rest_position: Vector2 = Vector2.ZERO
var has_rest_position: bool = false
var jump_elapsed: float = 0.0
var current_jump_duration: float = 0.42
var jump_active: bool = false
var body_rest_position: Vector2 = Vector2.ZERO
var body_rest_scale: Vector2 = Vector2.ONE
var body_rest_flip_h: bool = false
var body_rest_modulate: Color = Color.WHITE
var body_frame_size: Vector2 = Vector2(48.0, 48.0)
var shadow_rest_position: Vector2 = Vector2.ZERO
var shadow_rest_scale: Vector2 = Vector2.ONE
var impact_tween: Tween

@onready var body_sprite: AnimatedSprite2D = get_node_or_null(body_sprite_path) as AnimatedSprite2D
@onready var shadow_node: Node2D = get_node_or_null(shadow_path) as Node2D


func _ready() -> void:
	_cache_rest_position()
	_cache_visual_defaults()
	_play_body_animation(idle_animation_name, true)
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
		_finish_jump()
		return

	_sync_visuals()


func start_jump(duration: float) -> void:
	_cache_rest_position()
	_stop_impact_feedback()
	current_jump_duration = maxf(duration, 0.01)
	jump_elapsed = 0.0
	jump_active = true
	_play_body_animation(jump_animation_name, true)
	_sync_visuals()


func reset_pose() -> void:
	_cache_rest_position()
	_stop_impact_feedback()
	jump_active = false
	jump_elapsed = 0.0
	position = rest_position
	_play_body_animation(idle_animation_name, true)
	_sync_visuals()


func is_jump_active() -> bool:
	return jump_active


func play_miss_impact() -> void:
	if Engine.is_editor_hint() or not is_node_ready():
		return
	if not is_instance_valid(body_sprite):
		return

	_stop_impact_feedback()

	var duration_slice: float = maxf(miss_impact_duration / 4.0, 0.01)
	var shake_distance: float = maxf(miss_impact_shake_distance, 0.0)
	var rest_body_position: Vector2 = _get_body_position_for_scale(body_rest_scale)
	var squash_scale: Vector2 = Vector2(
		body_rest_scale.x * miss_impact_squash.x,
		body_rest_scale.y * miss_impact_squash.y
	)

	body_sprite.position = rest_body_position
	body_sprite.scale = body_rest_scale
	body_sprite.modulate = miss_impact_tint
	impact_tween = create_tween()
	impact_tween.tween_property(body_sprite, "position", rest_body_position + Vector2(-shake_distance, 0.0), duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact_tween.parallel().tween_property(body_sprite, "scale", squash_scale, duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(body_sprite, "position", rest_body_position + Vector2(shake_distance * 0.75, 0.0), duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	impact_tween.parallel().tween_property(body_sprite, "scale", body_rest_scale * Vector2(0.96, 1.04), duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(body_sprite, "position", rest_body_position + Vector2(-shake_distance * 0.35, 0.0), duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	impact_tween.tween_property(body_sprite, "position", rest_body_position, duration_slice).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact_tween.parallel().tween_property(body_sprite, "scale", body_rest_scale, duration_slice).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact_tween.parallel().tween_property(body_sprite, "modulate", body_rest_modulate, duration_slice).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact_tween.finished.connect(_on_impact_tween_finished)


func _cache_rest_position() -> void:
	if not has_rest_position:
		rest_position = position
		has_rest_position = true


func _cache_visual_defaults() -> void:
	if is_instance_valid(body_sprite):
		body_rest_position = body_sprite.position
		body_rest_scale = body_sprite.scale
		body_rest_flip_h = body_sprite.flip_h
		body_rest_modulate = body_sprite.modulate
		body_frame_size = _get_body_frame_size()

	if is_instance_valid(shadow_node):
		shadow_rest_position = shadow_node.position
		shadow_rest_scale = shadow_node.scale


func _finish_jump() -> void:
	jump_active = false
	jump_elapsed = 0.0
	position = rest_position
	_play_body_animation(idle_animation_name, false)
	_sync_visuals()


func _get_jump_progress() -> float:
	if not jump_active:
		return 0.0

	return clampf(jump_elapsed / current_jump_duration, 0.0, 1.0)


func _get_airborne_amount() -> float:
	if not jump_active:
		return 0.0

	return sin(_get_jump_progress() * PI)


func _get_ground_squash_amount() -> float:
	if not jump_active:
		return 0.0

	var progress: float = _get_jump_progress()
	var takeoff_squash: float = 1.0 - clampf(progress / 0.16, 0.0, 1.0)
	var landing_squash: float = clampf((progress - 0.84) / 0.16, 0.0, 1.0)
	return maxf(takeoff_squash, landing_squash)


func _sync_visuals() -> void:
	if not is_node_ready():
		return

	_sync_body_sprite()
	_sync_shadow()


func _sync_body_sprite() -> void:
	if not is_instance_valid(body_sprite):
		return

	_play_body_animation(jump_animation_name if jump_active else idle_animation_name, false)

	var airborne: float = _get_airborne_amount()
	var squash: float = _get_ground_squash_amount()
	var scale_x_factor: float = 1.0 + squash * jump_squash_amount - airborne * jump_stretch_amount * 0.45
	var scale_y_factor: float = 1.0 - squash * jump_squash_amount + airborne * jump_stretch_amount
	var target_scale: Vector2 = Vector2(body_rest_scale.x * scale_x_factor, body_rest_scale.y * scale_y_factor)
	body_sprite.scale = target_scale
	body_sprite.position = _get_body_position_for_scale(target_scale)

	body_sprite.flip_h = body_rest_flip_h


func _sync_shadow() -> void:
	if not is_instance_valid(shadow_node):
		return

	var airborne: float = _get_airborne_amount()
	var shrink: float = lerpf(1.0, shadow_airborne_shrink, airborne)
	shadow_node.position = shadow_rest_position + Vector2(0.0, airborne * jump_height)
	shadow_node.scale = shadow_rest_scale * shrink


func _play_body_animation(animation_name: StringName, restart: bool) -> void:
	if not is_instance_valid(body_sprite):
		return
	if body_sprite.sprite_frames == null:
		return
	if not body_sprite.sprite_frames.has_animation(animation_name):
		return

	var animation_changed: bool = body_sprite.animation != animation_name
	if animation_changed:
		body_sprite.animation = animation_name

	if animation_changed or restart:
		body_sprite.frame = 0
		body_sprite.frame_progress = 0.0

	if not Engine.is_editor_hint() and (animation_changed or restart or not body_sprite.is_playing()):
		body_sprite.play(animation_name)


func _get_body_position_for_scale(target_scale: Vector2) -> Vector2:
	var target_position: Vector2 = body_rest_position
	if is_instance_valid(body_sprite) and body_sprite.centered:
		target_position.y += body_frame_size.y * (absf(body_rest_scale.y) - absf(target_scale.y)) * 0.5

	return target_position


func _get_body_frame_size() -> Vector2:
	if not is_instance_valid(body_sprite):
		return body_frame_size
	if body_sprite.sprite_frames == null:
		return body_frame_size
	if not body_sprite.sprite_frames.has_animation(body_sprite.animation):
		return body_frame_size
	if body_sprite.sprite_frames.get_frame_count(body_sprite.animation) <= 0:
		return body_frame_size

	var frame_texture: Texture2D = body_sprite.sprite_frames.get_frame_texture(body_sprite.animation, 0)
	if frame_texture == null:
		return body_frame_size

	return frame_texture.get_size()


func _stop_impact_feedback() -> void:
	if impact_tween != null:
		impact_tween.kill()
		impact_tween = null

	if is_node_ready() and is_instance_valid(body_sprite):
		body_sprite.modulate = body_rest_modulate


func _on_impact_tween_finished() -> void:
	impact_tween = null
	if is_instance_valid(body_sprite):
		body_sprite.position = _get_body_position_for_scale(body_rest_scale)
		body_sprite.scale = body_rest_scale
		body_sprite.modulate = body_rest_modulate
