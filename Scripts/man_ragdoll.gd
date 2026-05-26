extends RigidBody2D
class_name ManRagdoll

func _ready() -> void:
	# Add exception for the player so they don't collide
	var player = get_parent().get_node_or_null("Player")
	if player:
		add_collision_exception_with(player)

func reset_ragdoll(spawn_position: Vector2) -> void:
	# Teleport the body
	global_position = spawn_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = PI / 2.0 # Match original Sprite2D rotation (90 degrees / facing right)

	# Sync with physics server
	PhysicsServer2D.body_set_state(
		get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		global_transform
	)
	PhysicsServer2D.body_set_state(
		get_rid(),
		PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY,
		Vector2.ZERO
	)
	PhysicsServer2D.body_set_state(
		get_rid(),
		PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY,
		0.0
	)
