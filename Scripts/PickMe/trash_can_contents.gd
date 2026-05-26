@tool
extends Node2D

@export var has_clue := false:
	set(value):
		has_clue = value
		queue_redraw()
@export var dog_texture: Texture2D = preload("res://Assets/Sprites/dog_top.png"):
	set(value):
		dog_texture = value
		queue_redraw()


func _draw() -> void:
	if has_clue:
		if dog_texture:
			var draw_size := Vector2(76.0, 76.0)
			draw_texture_rect(dog_texture, Rect2(-draw_size * 0.5 + Vector2(0.0, -6.0), draw_size), false)
		else:
			draw_circle(Vector2(-24.0, 16.0), 15.0, Color(1.0, 0.88, 0.28))
			draw_circle(Vector2(18.0, 8.0), 11.0, Color(0.2, 0.85, 0.46))
			draw_rect(Rect2(Vector2(-8.0, -12.0), Vector2(36.0, 26.0)), Color(0.96, 0.92, 0.58), true)
			draw_rect(Rect2(Vector2(-8.0, -12.0), Vector2(36.0, 26.0)), Color(0.2, 0.18, 0.08), false, 2.0)
	else:
		draw_circle(Vector2(-24.0, 14.0), 14.0, Color(0.43, 0.28, 0.18))
		draw_rect(Rect2(Vector2(0.0, -10.0), Vector2(34.0, 26.0)), Color(0.2, 0.55, 0.45), true)
		draw_rect(Rect2(Vector2(0.0, -10.0), Vector2(34.0, 26.0)), Color(0.08, 0.18, 0.15), false, 2.0)
		draw_circle(Vector2(28.0, 18.0), 10.0, Color(0.55, 0.16, 0.14))
