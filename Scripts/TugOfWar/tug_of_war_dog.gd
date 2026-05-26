@tool
extends Node2D
class_name TugOfWarDog

@export var texture: Texture2D = preload("res://icon.svg"):
	set(value):
		texture = value
		queue_redraw()

# Animation variables
var pull_tension := 0.0 # From 0.0 to 1.0
var yank_timer := 0.0
var is_yanking := false
var yank_shake_x := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if is_yanking:
		yank_timer += delta * 20.0
		yank_shake_x = sin(yank_timer) * 6.0
		# Tilt the dog's body back and forth during yanking
		rotation = sin(yank_timer) * 0.1
	else:
		yank_shake_x = 0.0
		rotation = 0.0
		
	# Apply leaning/tilt based on tension
	rotation += pull_tension * 0.15
	queue_redraw()

func set_yank(active: bool) -> void:
	is_yanking = active
	if active:
		yank_timer = 0.0
	queue_redraw()

func set_tension(tension: float) -> void:
	pull_tension = clampf(tension, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2(yank_shake_x, 72), 38.0, Color(0, 0, 0, 0.18))
	
	if texture:
		var draw_size = Vector2(100, 100)
		var draw_pos = Vector2(-50 + yank_shake_x, -50)
		draw_texture_rect(texture, Rect2(draw_pos, draw_size), false)
