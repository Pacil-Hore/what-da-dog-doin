extends Line2D
class_name RopeLine

# Export variables to make it easy to replace with final assets/textures in the editor
@export var rope_width := 4.0
@export var rope_color := Color(0.45, 0.3, 0.15)
@export var rope_texture: Texture2D
@export var texture_tiling_mode := Line2D.LINE_TEXTURE_TILE

var node_a: Node2D
var node_b: Node2D

func _ready() -> void:
	# Automatically find Player and ManSprite under the parent node
	node_a = get_parent().get_node_or_null("Player")
	node_b = get_parent().get_node_or_null("ManSprite")
	
	# Apply customization settings
	width = rope_width
	default_color = rope_color
	if rope_texture:
		texture = rope_texture
		texture_mode = texture_tiling_mode
	
	antialiased = true
	
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2.ZERO)

func _process(_delta: float) -> void:
	if is_instance_valid(node_a) and is_instance_valid(node_b):
		var start_pos = node_a.global_position
		var end_pos = node_b.global_position
		
		# If node_b (ManSprite) has a HandPosition child, attach the rope to it
		var hand = node_b.get_node_or_null("HandPosition")
		if hand:
			end_pos = hand.global_position
		
		# Convert global positions to local coordinates of the Line2D
		set_point_position(0, to_local(start_pos))
		set_point_position(1, to_local(end_pos))
	else:
		# Fallback search if not found initially (e.g. during reset)
		node_a = get_parent().get_node_or_null("Player")
		node_b = get_parent().get_node_or_null("ManSprite")
		if not (is_instance_valid(node_a) and is_instance_valid(node_b)):
			clear_points()
			add_point(Vector2.ZERO)
			add_point(Vector2.ZERO)
