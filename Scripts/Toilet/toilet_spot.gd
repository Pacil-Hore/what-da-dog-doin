@tool
extends "res://Scripts/Interaction/pickable_object.gd"
class_name ToiletSpot

signal spot_selected(spot: ToiletSpot)

enum SpotType {
	BILLBOARD,
	GRASS_PATCH,
	POLE_AREA,
	CAR,
}

@export_enum("Billboard", "Grass Patch", "Pole Area", "Car") var spot_type: int = SpotType.BILLBOARD:
	set(value):
		spot_type = value
		queue_redraw()

@export var is_correct := false:
	set(value):
		is_correct = value
		queue_redraw()

@export var blocked_variant := false:
	set(value):
		blocked_variant = value
		queue_redraw()

var feedback_color: Color = Color.TRANSPARENT
var is_revealed: bool = false
var feedback_tween: Tween
var feedback_intensity := 0.0:
	set(value):
		feedback_intensity = value
		queue_redraw()


func _ready() -> void:
	super()
	if not picked.is_connected(_on_picked):
		picked.connect(_on_picked)
	queue_redraw()


func configure_round(correct: bool, blocked: bool) -> void:
	is_correct = correct
	blocked_variant = blocked
	clear_feedback()
	set_pick_enabled(true)


func clear_feedback() -> void:
	if feedback_tween != null:
		feedback_tween.kill()
		feedback_tween = null

	feedback_color = Color.TRANSPARENT
	feedback_intensity = 0.0
	is_revealed = false
	scale = default_scale
	queue_redraw()


func show_success_feedback() -> void:
	_play_feedback(Color(0.21, 0.73, 0.33), 0.42)


func show_failure_feedback() -> void:
	_play_feedback(Color(0.86, 0.21, 0.19), 0.35)


func reveal_as_correct() -> void:
	_play_feedback(Color(0.28, 0.76, 0.37), 0.26)


func _play_feedback(color: Color, settled_intensity: float) -> void:
	if feedback_tween != null:
		feedback_tween.kill()

	feedback_color = color
	is_revealed = true
	feedback_intensity = 0.0
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "feedback_intensity", 1.0, 0.12)
	feedback_tween.tween_property(self, "feedback_intensity", settled_intensity, 0.18)
	feedback_tween.finished.connect(_on_feedback_finished)


func _draw() -> void:
	match spot_type:
		SpotType.BILLBOARD:
			_draw_billboard()
		SpotType.GRASS_PATCH:
			_draw_grass_patch()
		SpotType.POLE_AREA:
			_draw_pole_area()
		SpotType.CAR:
			_draw_car()

	_draw_feedback_overlay()


func _draw_billboard() -> void:
	var frame_rect := Rect2(Vector2(-78.0, -44.0), Vector2(156.0, 88.0))
	draw_rect(frame_rect, Color(0.92, 0.9, 0.82), true)
	draw_rect(frame_rect, Color(0.31, 0.25, 0.19), false, 6.0)
	draw_line(Vector2(-48.0, 44.0), Vector2(-48.0, 94.0), Color(0.36, 0.29, 0.21), 7.0)
	draw_line(Vector2(48.0, 44.0), Vector2(48.0, 94.0), Color(0.36, 0.29, 0.21), 7.0)
	draw_rect(Rect2(Vector2(-58.0, -24.0), Vector2(116.0, 48.0)), Color(0.53, 0.68, 0.89), true)
	draw_circle(Vector2(-26.0, -4.0), 9.0, Color(0.95, 0.84, 0.62))
	draw_rect(Rect2(Vector2(-34.0, 6.0), Vector2(18.0, 18.0)), Color(0.82, 0.35, 0.29), true)
	draw_circle(Vector2(18.0, 2.0), 10.0, Color(0.94, 0.88, 0.8))
	draw_rect(Rect2(Vector2(6.0, 10.0), Vector2(24.0, 10.0)), Color(0.51, 0.42, 0.27), true)
	draw_line(Vector2(-52.0, 30.0), Vector2(52.0, -18.0), Color(0.82, 0.23, 0.21), 6.0)
	draw_arc(Vector2(54.0, 28.0), 16.0, 0.0, TAU, 24, Color(0.82, 0.23, 0.21), 5.0)


func _draw_grass_patch() -> void:
	draw_circle(Vector2(0.0, 42.0), 56.0, Color(0.44, 0.66, 0.33, 0.28))
	draw_circle(Vector2(-32.0, 22.0), 42.0, Color(0.31, 0.57, 0.23))
	draw_circle(Vector2(8.0, 6.0), 50.0, Color(0.35, 0.63, 0.28))
	draw_circle(Vector2(48.0, 24.0), 38.0, Color(0.27, 0.51, 0.21))
	draw_rect(Rect2(Vector2(-84.0, 38.0), Vector2(168.0, 22.0)), Color(0.58, 0.42, 0.23), true)

	if blocked_variant:
		draw_line(Vector2(-62.0, -18.0), Vector2(-62.0, 46.0), Color(0.47, 0.31, 0.18), 4.0)
		draw_line(Vector2(62.0, -18.0), Vector2(62.0, 46.0), Color(0.47, 0.31, 0.18), 4.0)
		draw_line(Vector2(-62.0, -8.0), Vector2(62.0, -8.0), Color(0.7, 0.19, 0.2), 5.0)
		draw_line(Vector2(-62.0, 14.0), Vector2(62.0, 14.0), Color(0.95, 0.87, 0.56), 5.0)
		for index in range(3):
			var flower_x := -34.0 + float(index) * 30.0
			draw_line(Vector2(flower_x, 14.0), Vector2(flower_x, 40.0), Color(0.22, 0.45, 0.18), 3.0)
			draw_circle(Vector2(flower_x - 5.0, 12.0), 5.0, Color(0.95, 0.42, 0.55))
			draw_circle(Vector2(flower_x + 5.0, 12.0), 5.0, Color(0.96, 0.81, 0.35))
	else:
		draw_circle(Vector2(-18.0, 10.0), 6.0, Color(0.94, 0.96, 0.76))
		draw_circle(Vector2(20.0, -2.0), 5.0, Color(0.94, 0.96, 0.76))
		draw_circle(Vector2(42.0, 8.0), 4.0, Color(0.94, 0.96, 0.76))


func _draw_pole_area() -> void:
	draw_circle(Vector2(0.0, 54.0), 50.0, Color(0.43, 0.39, 0.31, 0.2))
	draw_rect(Rect2(Vector2(-10.0, -74.0), Vector2(20.0, 132.0)), Color(0.63, 0.67, 0.74), true)
	draw_rect(Rect2(Vector2(-12.0, -78.0), Vector2(24.0, 140.0)), Color(0.27, 0.31, 0.35), false, 3.0)
	draw_rect(Rect2(Vector2(-5.0, -70.0), Vector2(4.0, 124.0)), Color(0.82, 0.86, 0.92), true)

	if blocked_variant:
		draw_rect(Rect2(Vector2(-44.0, 26.0), Vector2(88.0, 18.0)), Color(0.86, 0.18, 0.2), true)
		draw_line(Vector2(-38.0, 14.0), Vector2(38.0, 14.0), Color(0.96, 0.85, 0.36), 5.0)
		draw_line(Vector2(-38.0, 44.0), Vector2(38.0, 44.0), Color(0.96, 0.85, 0.36), 5.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(36.0, 52.0),
			Vector2(58.0, 52.0),
			Vector2(72.0, 90.0),
			Vector2(22.0, 90.0),
		]), Color(0.95, 0.56, 0.18))
		draw_rect(Rect2(Vector2(39.0, 60.0), Vector2(16.0, 20.0)), Color(0.96, 0.89, 0.72), true)
	else:
		draw_circle(Vector2(0.0, 58.0), 34.0, Color(0.57, 0.43, 0.27))
		draw_circle(Vector2(-24.0, 58.0), 16.0, Color(0.29, 0.56, 0.24))
		draw_circle(Vector2(24.0, 58.0), 14.0, Color(0.29, 0.56, 0.24))


func _draw_car() -> void:
	draw_circle(Vector2(-48.0, 46.0), 18.0, Color(0.18, 0.2, 0.23))
	draw_circle(Vector2(48.0, 46.0), 18.0, Color(0.18, 0.2, 0.23))
	draw_circle(Vector2(-48.0, 46.0), 9.0, Color(0.78, 0.82, 0.86))
	draw_circle(Vector2(48.0, 46.0), 9.0, Color(0.78, 0.82, 0.86))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-88.0, 24.0),
		Vector2(-62.0, -8.0),
		Vector2(24.0, -24.0),
		Vector2(66.0, -8.0),
		Vector2(86.0, 22.0),
		Vector2(88.0, 44.0),
		Vector2(-88.0, 44.0),
	]), Color(0.52, 0.71, 0.94))
	draw_polyline(_closed_points(PackedVector2Array([
		Vector2(-88.0, 24.0),
		Vector2(-62.0, -8.0),
		Vector2(24.0, -24.0),
		Vector2(66.0, -8.0),
		Vector2(86.0, 22.0),
		Vector2(88.0, 44.0),
		Vector2(-88.0, 44.0),
	])), Color(0.19, 0.24, 0.29), 4.0)
	draw_rect(Rect2(Vector2(-50.0, -4.0), Vector2(52.0, 26.0)), Color(0.83, 0.93, 0.98), true)
	draw_rect(Rect2(Vector2(6.0, -10.0), Vector2(42.0, 32.0)), Color(0.83, 0.93, 0.98), true)


func _draw_feedback_overlay() -> void:
	if feedback_intensity <= 0.0:
		return

	var bounds := _get_feedback_bounds().grow(10.0)
	var fill_color := feedback_color
	fill_color.a = 0.08 + feedback_intensity * 0.12
	draw_rect(bounds, fill_color, true)

	var outline_color := feedback_color
	outline_color.a = 0.28 + feedback_intensity * 0.48
	draw_rect(bounds, outline_color, false, 5.0)

	if is_revealed and is_correct:
		draw_circle(Vector2(0.0, -88.0), 8.0 + feedback_intensity * 3.0, outline_color)


func _get_feedback_bounds() -> Rect2:
	match spot_type:
		SpotType.BILLBOARD:
			return Rect2(Vector2(-98.0, -54.0), Vector2(196.0, 164.0))
		SpotType.GRASS_PATCH:
			return Rect2(Vector2(-102.0, -34.0), Vector2(204.0, 102.0))
		SpotType.POLE_AREA:
			return Rect2(Vector2(-76.0, -86.0), Vector2(152.0, 186.0))
		SpotType.CAR:
			return Rect2(Vector2(-102.0, -30.0), Vector2(204.0, 94.0))

	return Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0))


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	return closed


func _on_feedback_finished() -> void:
	feedback_tween = null


func _on_picked(_pickable: Variant) -> void:
	spot_selected.emit(self)
