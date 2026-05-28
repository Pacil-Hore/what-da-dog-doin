@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name PickMeTrashCan

signal trash_can_picked(trash_can: PickMeTrashCan)

@export var has_clue := false
@export_range(1, 3, 1) var bin_variant := 1
@export var bin_textures: Array[Texture2D] = [
	preload("res://Assets/Sprites/PickMe/FREE Pixel Art Trash Pack - Animated/Dumpster 1 - No Lid.png"),
	preload("res://Assets/Sprites/PickMe/FREE Pixel Art Trash Pack - Animated/Dumpster 2 - No Lid.png"),
	preload("res://Assets/Sprites/PickMe/FREE Pixel Art Trash Pack - Animated/Dumpster 3 - No Lid.png"),
]
@export var reveal_lift := 120.0
@export var reveal_duration := 0.55
@export var reveal_rotation_degrees := 0.0
@export var cue_shake_duration := 0.48
@export var cue_shake_distance := 10.0
@export var click_squash_duration := 0.18
@export var wrong_shake_duration := 0.26

# Dog idle animation config
const DOG_FRAME_COUNT := 8
const DOG_FRAME_SIZE := 48
const DOG_IDLE_FPS := 6.0

var is_revealed := false
var closed_position := Vector2.ZERO
var hidden_contents_position := Vector2.ZERO
var revealed_contents_position := Vector2.ZERO
var cue_tween: Tween
var feedback_tween: Tween
var reveal_tween: Tween

# Dog idle animation state
var _dog_frame := 0
var _idle_playing := false

@onready var shell: Sprite2D = $Shell
@onready var contents: Node2D = $Contents
@onready var clue_sprite: Sprite2D = $Contents/ClueSprite
@onready var junk_sprite: Sprite2D = $Contents/JunkSprite
@onready var reveal_particles: GPUParticles2D = $Contents/RevealParticles
@onready var _idle_timer: Timer = Timer.new()


func _ready() -> void:
	super()
	closed_position = position
	revealed_contents_position = Vector2(0.0, -90.0)
	hidden_contents_position = revealed_contents_position + Vector2(0.0, reveal_lift)
	contents.position = hidden_contents_position
	_set_variant_from_name()
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	_sync_visuals()
	_setup_idle_timer()
	_setup_reveal_particles()
	queue_redraw()


func _setup_idle_timer() -> void:
	_idle_timer.wait_time = 1.0 / DOG_IDLE_FPS
	_idle_timer.one_shot = false
	_idle_timer.timeout.connect(_on_idle_timer_timeout)
	add_child(_idle_timer)


func _setup_reveal_particles() -> void:
	if Engine.is_editor_hint():
		return
	if not is_instance_valid(reveal_particles):
		return

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 75.0
	mat.initial_velocity_min = 60.0
	mat.initial_velocity_max = 130.0
	mat.gravity = Vector3(0.0, 180.0, 0.0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.95, 0.6, 1.0)

	# Color ramp: bright → transparent
	var color_ramp := Gradient.new()
	color_ramp.set_offset(0, 0.0)
	color_ramp.set_color(0, Color(1.0, 1.0, 0.8, 1.0))
	color_ramp.add_point(0.5, Color(1.0, 0.85, 0.3, 0.85))
	color_ramp.set_offset(1, 1.0)
	color_ramp.set_color(1, Color(1.0, 0.6, 0.2, 0.0))
	var color_ramp_tex := GradientTexture1D.new()
	color_ramp_tex.gradient = color_ramp
	mat.color_ramp = color_ramp_tex

	# Scale curve: grow then shrink
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.0))
	scale_curve.add_point(Vector2(0.15, 1.0))
	scale_curve.add_point(Vector2(0.7, 0.8))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_curve_tex := CurveTexture.new()
	scale_curve_tex.curve = scale_curve
	mat.scale_curve = scale_curve_tex

	reveal_particles.process_material = mat


func play_clue_cue() -> void:
	if is_revealed:
		return

	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	cue_tween = create_tween()
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.35, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.35, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x, cue_shake_duration * 0.08)
	cue_tween.tween_interval(cue_shake_duration * 0.1)
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance, cue_shake_duration * 0.14)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance, cue_shake_duration * 0.14)
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.6, cue_shake_duration * 0.12)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.45, cue_shake_duration * 0.1)
	cue_tween.tween_property(self, "position:x", closed_position.x, cue_shake_duration * 0.08)


func play_pick_feedback(did_pick_correctly: bool) -> void:
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	scale = default_scale
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "scale", default_scale * Vector2(1.08, 0.9), click_squash_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(self, "scale", default_scale, click_squash_duration * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not did_pick_correctly:
		feedback_tween.tween_callback(play_wrong_feedback)


func play_wrong_feedback() -> void:
	if is_revealed:
		return

	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	rotation_degrees = 0.0
	cue_tween = create_tween()
	cue_tween.tween_property(self, "position:x", closed_position.x - cue_shake_distance * 0.7, wrong_shake_duration * 0.2)
	cue_tween.tween_property(self, "position:x", closed_position.x + cue_shake_distance * 0.7, wrong_shake_duration * 0.22)
	cue_tween.tween_property(self, "position:x", closed_position.x, wrong_shake_duration * 0.28)


func reveal(did_win: bool = true) -> void:
	if is_revealed:
		return

	is_revealed = true
	set_pick_enabled(false)
	if is_instance_valid(cue_tween):
		cue_tween.kill()
	position = closed_position
	scale = default_scale
	rotation = 0.0
	contents.position = hidden_contents_position
	_sync_visuals()
	queue_redraw()

	if is_instance_valid(reveal_tween):
		reveal_tween.kill()

	if did_win:
		_reveal_win()
	else:
		_reveal_loss()


func _reveal_win() -> void:
	reveal_tween = create_tween()
	var duration := reveal_duration * 0.85

	# --- Contents slide up with overshoot ---
	reveal_tween.tween_property(contents, "position:y", revealed_contents_position.y, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# --- Dog pop-in scale: start small → overshoot → settle ---
	clue_sprite.scale = Vector2.ZERO
	reveal_tween.parallel().tween_property(clue_sprite, "scale", Vector2(2.55, 2.55), duration * 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(clue_sprite, "scale", Vector2(2.25, 2.25), duration * 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# --- Dog rotation wiggle (peek-a-boo) ---
	reveal_tween.tween_property(clue_sprite, "rotation_degrees", 8.0, 0.07) \
		.set_trans(Tween.TRANS_SINE)
	reveal_tween.tween_property(clue_sprite, "rotation_degrees", -6.0, 0.07) \
		.set_trans(Tween.TRANS_SINE)
	reveal_tween.tween_property(clue_sprite, "rotation_degrees", 4.0, 0.06) \
		.set_trans(Tween.TRANS_SINE)
	reveal_tween.tween_property(clue_sprite, "rotation_degrees", 0.0, 0.06) \
		.set_trans(Tween.TRANS_SINE)

	# --- Sparkle particles at the peak ---
	reveal_tween.parallel().tween_callback(_emit_reveal_particles).set_delay(duration * 0.4)

	# --- Start idle animation ---
	reveal_tween.tween_callback(_start_idle_animation)


func _reveal_loss() -> void:
	reveal_tween = create_tween()
	var duration := reveal_duration * 1.45

	clue_sprite.visible = has_clue
	clue_sprite.modulate = Color(0.55, 0.55, 0.55, 0.0)
	clue_sprite.scale = Vector2(1.6, 1.6)

	# Smooth fluid slide up with cubic ease-out
	reveal_tween.tween_property(contents, "position:y", revealed_contents_position.y, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Parallel fade-in to the dimmed color
	reveal_tween.parallel().tween_property(clue_sprite, "modulate", Color(0.55, 0.55, 0.55, 0.8), duration * 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Parallel subtle scale up to standard size
	reveal_tween.parallel().tween_property(clue_sprite, "scale", Vector2(2.25, 2.25), duration * 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _emit_reveal_particles() -> void:
	if is_instance_valid(reveal_particles):
		reveal_particles.restart()
		reveal_particles.emitting = true


func _start_idle_animation() -> void:
	_dog_frame = 0
	_idle_playing = true
	_idle_timer.start()


func _stop_idle_animation() -> void:
	_idle_playing = false
	_idle_timer.stop()
	_dog_frame = 0
	if is_instance_valid(clue_sprite):
		clue_sprite.region_rect = Rect2(0, 0, DOG_FRAME_SIZE, DOG_FRAME_SIZE)


func _on_idle_timer_timeout() -> void:
	if not _idle_playing or not is_instance_valid(clue_sprite):
		return
	_dog_frame = (_dog_frame + 1) % DOG_FRAME_COUNT
	clue_sprite.region_rect = Rect2(_dog_frame * DOG_FRAME_SIZE, 0, DOG_FRAME_SIZE, DOG_FRAME_SIZE)


func reset_trash_can(clue_enabled: bool) -> void:
	has_clue = clue_enabled
	is_revealed = false
	if is_instance_valid(cue_tween):
		cue_tween.kill()
	if is_instance_valid(feedback_tween):
		feedback_tween.kill()
	if is_instance_valid(reveal_tween):
		reveal_tween.kill()
	position = closed_position
	rotation = 0.0
	scale = default_scale
	contents.position = hidden_contents_position

	# Reset dog sprite state
	_stop_idle_animation()
	clue_sprite.rotation_degrees = 0.0
	clue_sprite.scale = Vector2(2.25, 2.25)
	clue_sprite.modulate = Color.WHITE

	# Reset shell rotation
	shell.rotation_degrees = 0.0

	_sync_visuals()
	set_pick_enabled(true)
	queue_redraw()


func _sync_visuals() -> void:
	if not bin_textures.is_empty():
		var texture_index := clampi(bin_variant - 1, 0, bin_textures.size() - 1)
		shell.texture = bin_textures[texture_index]
	clue_sprite.visible = has_clue
	junk_sprite.visible = not has_clue
	contents.visible = is_revealed


func _set_variant_from_name() -> void:
	if name.contains("Right"):
		bin_variant = 3
	elif name.contains("Middle"):
		bin_variant = 2
	else:
		bin_variant = 1


func _on_picked(_pickable: Variant) -> void:
	trash_can_picked.emit(self)
