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

func _process(_delta: float) -> void:
	if is_instance_valid(node_a) and is_instance_valid(node_b):
		var start_pos = node_a.global_position
		var end_pos = node_b.global_position
		
		# If node_b (ManSprite) has a HandPosition child, attach the rope to it
		var hand = node_b.get_node_or_null("HandPosition")
		if hand:
			end_pos = hand.global_position
		
		# Convert global positions to local coordinates of the Line2D
		var local_start = to_local(start_pos)
		var local_end = to_local(end_pos)
		
		# Calculate tension (from 60px rest to 80px stretched)
		var distance = start_pos.distance_to(end_pos)
		var tension = clampf((distance - 60.0) / 20.0, 0.0, 1.0)
		
		# Dynamic sagging curve
		var num_points = 12
		clear_points()
		var sag_amount = maxf(0.0, 60.0 - distance) * 0.6
		
		for i in range(num_points):
			var t = float(i) / float(num_points - 1)
			var point_pos = local_start.lerp(local_end, t)
			var sag_offset = Vector2(0, 4.0 * t * (1.0 - t) * sag_amount)
			add_point(point_pos + sag_offset)
		
		default_color = rope_color.lerp(Color(0.9, 0.2, 0.2), tension)
		width = lerpf(rope_width, rope_width * 0.6, tension)
	else:
		# Fallback search if not found initially (e.g. during reset)
		node_a = get_parent().get_node_or_null("Player")
		node_b = get_parent().get_node_or_null("ManSprite")
		if not (is_instance_valid(node_a) and is_instance_valid(node_b)):
			clear_points()
			add_point(Vector2.ZERO)
			add_point(Vector2.ZERO)
