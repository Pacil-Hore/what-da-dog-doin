@tool
extends Node2D
class_name TugOfWarHuman

@export var texture: Texture2D = preload("res://Assets/generated/player_placeholder.png"):
	set(value):
		texture = value
		queue_redraw()

# Animation variables
var pull_tension := 0.0 # From 0.0 to 1.0
var wiggle_offset := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	# Reduce wiggle slowly
	wiggle_offset = move_toward(wiggle_offset, 0.0, delta * 30.0)
	
	# Apply visual rotation and wiggle based on tension and mashing input
	rotation = -0.15 - pull_tension * 0.35 # Lean back
	# Add wiggle offset to rotation
	rotation += sin(wiggle_offset * 1.5) * wiggle_offset * 0.015

func play_pull_wiggle() -> void:
	wiggle_offset = 12.0
	queue_redraw()

func set_tension(tension: float) -> void:
	pull_tension = clampf(tension, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	# Draw shadow
	draw_circle(Vector2(0, 92), 32.0, Color(0, 0, 0, 0.18))
	
	if texture:
		var draw_size = Vector2(120, 120)
		var draw_pos = Vector2(-60, -60)
		draw_texture_rect(texture, Rect2(draw_pos, draw_size), false)
