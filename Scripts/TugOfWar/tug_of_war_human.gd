@tool
extends Node2D
class_name TugOfWarHuman

@onready var sprite: Sprite2D = $Sprite

var pull_tension: float = 0.0
var smooth_rotation: float = 0.0
var pull_bump: float = 0.0

@onready var dust_particles: CPUParticles2D = $DustParticles
var current_sliding_factor: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	pull_bump = lerp(pull_bump, 0.0, delta * 10.0)
	
	var target_rotation: float = -pull_tension * 0.3
	target_rotation += pull_bump * 0.05
	
	smooth_rotation = lerp_angle(smooth_rotation, target_rotation, delta * 8.0)
	rotation = smooth_rotation
	
	if sprite:
		var squash = 1.0 - pull_bump * 0.05
		var stretch = 1.0 + pull_bump * 0.03
		sprite.scale = Vector2(2.5 * squash, 2.5 * stretch)
		# Keep feet anchored at Y=0 by shifting position relative to stretch factor
		sprite.position.y = -120.0 * stretch

	if dust_particles:
		# Emit dust when actively pulling, sliding under high tension, or sliding fast
		if pull_bump > 0.15 or pull_tension > 0.45 or current_sliding_factor > 0.02:
			dust_particles.emitting = true
			# Scale velocity based on sliding speed
			dust_particles.initial_velocity_min = 30.0 + current_sliding_factor * 150.0
			dust_particles.initial_velocity_max = 80.0 + current_sliding_factor * 250.0
		else:
			dust_particles.emitting = false

func play_pull_wiggle() -> void:
	pull_bump = 1.0

func set_tension(tension: float) -> void:
	pull_tension = clampf(tension, 0.0, 1.0)

func set_sliding(factor: float) -> void:
	current_sliding_factor = factor
