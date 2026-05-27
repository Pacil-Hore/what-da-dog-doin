@tool
extends Node2D

@export var has_clue := false:
	set(value):
		has_clue = value
		queue_redraw()
@export var dog_texture: Texture2D = preload("res://Assets/Sprites/Pick The Rope/dog_front.png"):
	set(value):
		dog_texture = value
		queue_redraw()
@export var dog_frame := 0:
	set(value):
		dog_frame = value
		queue_redraw()

var prepared_dog_texture: Texture2D


func _ready() -> void:
	prepared_dog_texture = _make_black_transparent(dog_texture)


func _draw() -> void:
	if has_clue:
		var visible_dog_texture := prepared_dog_texture if prepared_dog_texture else dog_texture
		if visible_dog_texture:
			var frame_size := Vector2(48.0, 48.0)
			var draw_size := Vector2(118.0, 118.0)
			var source := Rect2(Vector2(frame_size.x * dog_frame, 0.0), frame_size)
			draw_texture_rect_region(visible_dog_texture, Rect2(-draw_size * 0.5 + Vector2(0.0, -50.0), draw_size), source)
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


func _make_black_transparent(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null

	var image := texture.get_image()
	if image == null:
		return texture

	var size := image.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var color := image.get_pixel(x, y)
			if color.r < 0.05 and color.g < 0.05 and color.b < 0.05:
				color.a = 0.0
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
