extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var stuck_indicator: Label = $StuckIndicator

var anim_time := 0.0
var anim_speed := 10.0 # FPS

var player: Node2D
var stuck_timer := 0.0
var stuck_flash_time := 0.0
var dust_emitter: CPUParticles2D

func _ready() -> void:
	wall_min_slide_angle = 0.01
	safe_margin = 0.02
	player = get_parent().get_node_or_null("Player")
	if player:
		add_collision_exception_with(player)


		
	# Add dust emitter programmatically
	dust_emitter = CPUParticles2D.new()
	dust_emitter.amount = 10
	dust_emitter.lifetime = 0.3
	dust_emitter.gravity = Vector2.ZERO
	dust_emitter.initial_velocity_min = 5.0
	dust_emitter.initial_velocity_max = 15.0
	dust_emitter.spread = 180.0
	dust_emitter.scale_amount_min = 1.0
	dust_emitter.scale_amount_max = 3.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.85, 0.8, 0.75, 0.4))
	gradient.set_color(1, Color(0.85, 0.8, 0.75, 0.0))
	dust_emitter.color_ramp = gradient
	
	dust_emitter.emitting = false
	dust_emitter.show_behind_parent = true
	add_child(dust_emitter)

func _process(_delta: float) -> void:
	# Keep stuck indicator upright
	if is_instance_valid(stuck_indicator):
		stuck_indicator.rotation = -global_rotation

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		if dust_emitter != null:
			dust_emitter.emitting = false
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Rotate man to face the player
	var look_dir = player.global_position - global_position
	if look_dir.length_squared() > 10.0:
		rotation = look_dir.angle() + PI / 2.0
	
	# Leash behavior: pull man towards player if distance > 60 px
	var leash_length = 60.0
	var tension := 0.0
	if dist > leash_length:
		var pull_dir = (player.global_position - global_position).normalized()
		# Proportional speed: pulls faster when stretched further
		var pull_speed = (dist - leash_length) * 30.0
		# Clamp speed to player's max speed (800.0)
		pull_speed = clampf(pull_speed, 0.0, 800.0)

		velocity = pull_dir * pull_speed
		tension = clampf((dist - leash_length) / 20.0, 0.0, 1.0)
	else:
		velocity = Vector2.ZERO
		
	# Micro-shake sprite under high tension
	if sprite != null:
		if tension > 0.6:
			var jitter_amount = (tension - 0.6) * 5.0 # Up to 2.0 pixels
			sprite.position = Vector2(randf_range(-jitter_amount, jitter_amount), randf_range(-jitter_amount, jitter_amount))
		else:
			sprite.position = Vector2.ZERO
	if is_on_wall():
		var normal := get_wall_normal()
		if velocity.dot(normal) < 0.0:
			velocity = velocity.slide(normal)
			
	move_and_slide()
	
	# Emit dust particles when moving
	if dust_emitter != null:
		dust_emitter.emitting = velocity.length() > 30.0
	
	# Shake screen on high speed wall impacts
	if velocity.length() > 100.0:
		for i in get_slide_collision_count():
			var parent = get_parent()
			if parent and parent.has_method("shake_screen"):
				parent.shake_screen(velocity.length() * 0.005)
				break # Only shake once per frame

	# Handle animation
	if velocity.length() > 15.0:
		anim_time += delta * anim_speed
		sprite.frame = int(anim_time) % 8
	else:
		sprite.frame = 0
		anim_time = 0.0

	# Stuck detection
	if is_instance_valid(stuck_indicator):
		var is_pulling = dist > 75.0 and player.velocity.length() > 80.0
		var is_stationary = velocity.length() < 25.0
		
		if is_pulling and is_stationary:
			stuck_timer += delta
			if stuck_timer > 0.4:
				stuck_indicator.visible = true
				stuck_flash_time += delta * 15.0
				stuck_indicator.modulate.a = 0.4 + 0.6 * abs(sin(stuck_flash_time))
		else:
			stuck_timer = 0.0
			stuck_indicator.visible = false
			stuck_flash_time = 0.0

func reset_ragdoll(spawn_position: Vector2) -> void:
	stuck_timer = 0.0
	stuck_flash_time = 0.0
	if is_instance_valid(stuck_indicator):
		stuck_indicator.visible = false

	# Teleport the body
	global_position = spawn_position
	velocity = Vector2.ZERO
	rotation = PI / 2.0 # Match original Sprite2D rotation (90 degrees / facing right)
