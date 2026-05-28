@tool
extends Node2D

enum FitMode {
	COVER,
	CONTAIN,
	STRETCH,
	ORIGINAL,
}

@export var background_texture: Texture2D:
	set(value):
		background_texture = value
		queue_redraw()

@export var stage_size: Vector2 = Vector2(1152.0, 645.0):
	set(value):
		stage_size = value
		queue_redraw()

@export_enum("Cover", "Contain", "Stretch", "Original") var fit_mode: int = FitMode.COVER:
	set(value):
		fit_mode = value
		queue_redraw()

@export var texture_offset: Vector2 = Vector2.ZERO:
	set(value):
		texture_offset = value
		queue_redraw()

@export var texture_scale: Vector2 = Vector2.ONE:
	set(value):
		texture_scale = value
		queue_redraw()

@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()


func _draw() -> void:
	if background_texture == null:
		return

	var texture_size: Vector2 = background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return

	var safe_scale: Vector2 = Vector2(maxf(texture_scale.x, 0.001), maxf(texture_scale.y, 0.001))
	var draw_size: Vector2 = _get_draw_size(texture_size) * safe_scale
	var draw_position: Vector2 = (stage_size - draw_size) * 0.5 + texture_offset
	draw_texture_rect(background_texture, Rect2(draw_position, draw_size), false, tint)


func _get_draw_size(texture_size: Vector2) -> Vector2:
	match fit_mode:
		FitMode.CONTAIN:
			return texture_size * minf(stage_size.x / texture_size.x, stage_size.y / texture_size.y)
		FitMode.STRETCH:
			return stage_size
		FitMode.ORIGINAL:
			return texture_size
		_:
			return texture_size * maxf(stage_size.x / texture_size.x, stage_size.y / texture_size.y)
