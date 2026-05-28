@tool
extends Node2D
class_name TugOfWarDog

@onready var sprite: Sprite2D = $Sprite

var pull_tension: float = 0.0
var is_yanking: bool = false
var yank_timer: float = 0.0
var yank_bump: float = 0.0
var smooth_rotation: float = 0.0

var dust_particles: CPUParticles2D
var current_sliding_factor: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Set up dust particles at feet programmatically
	dust_particles = CPUParticles2D.new()
	add_child(dust_particles)
	dust_particles.position = Vector2(0, 0)
	dust_particles.amount = 15
	dust_particles.lifetime = 0.5
	dust_particles.explosiveness = 0.2
	dust_particles.spread = 35.0
	dust_particles.gravity = Vector2(0, 120)
	dust_particles.initial_velocity_min = 30.0
	dust_particles.initial_velocity_max = 80.0
	dust_particles.direction = Vector2(1.0, -0.2) # Shoot right (backwards for dog)
	dust_particles.color = Color(0.55, 0.44, 0.33) # Earthy dust color
	dust_particles.scale_amount_min = 3.0
	dust_particles.scale_amount_max = 6.0
	dust_particles.emitting = false

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if is_yanking:
		yank_timer += delta * 12.0
		yank_bump = lerp(yank_bump, 1.0, delta * 15.0)
		
		var target_rot: float = sin(yank_timer) * 0.08 * yank_bump
		smooth_rotation = lerp_angle(smooth_rotation, target_rot, delta * 12.0)
	else:
		yank_bump = lerp(yank_bump, 0.0, delta * 8.0)
		
		var target_rot: float = pull_tension * 0.2
		smooth_rotation = lerp_angle(smooth_rotation, target_rot, delta * 6.0)
	
	rotation = smooth_rotation
	
	if sprite:
		var squash = 1.0 - yank_bump * 0.08
		var stretch = 1.0 + yank_bump * 0.05
		sprite.scale = Vector2(-3.0 * squash, 3.0 * stretch)
		
		# Add a micro high-frequency growl shake to the sprite position during yanks
		var shake = Vector2.ZERO
		if is_yanking:
			shake = Vector2(
				randf_range(-1.0, 1.0) * yank_bump * 3.0,
				randf_range(-1.0, 1.0) * yank_bump * 3.0
			)
		sprite.position = Vector2(shake.x, -72.0 * stretch + shake.y)

	if dust_particles:
		# Emit dust when dog is yanking, getting pulled, or sliding fast
		if yank_bump > 0.15 or pull_tension > 0.55 or current_sliding_factor > 0.02:
			dust_particles.emitting = true
			# Scale velocity based on sliding speed
			dust_particles.initial_velocity_min = 30.0 + current_sliding_factor * 150.0
			dust_particles.initial_velocity_max = 80.0 + current_sliding_factor * 250.0
		else:
			dust_particles.emitting = false

func set_yank(active: bool) -> void:
	is_yanking = active
	if active:
		yank_timer = 0.0

func set_tension(tension: float) -> void:
	pull_tension = clampf(tension, 0.0, 1.0)

func set_sliding(factor: float) -> void:
	current_sliding_factor = factor
