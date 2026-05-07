extends Node2D
class_name PickTheRopeBoard

signal hook_selected(hook_index: int)

enum FeedbackState {
	NEUTRAL,
	CORRECT,
	WRONG,
	DIMMED,
}

const MAX_ROPES: int = 4
const PLAYER_FUR_COLOR: Color = Color(0.94, 0.89, 0.8)
const PLAYER_SPOT_COLOR: Color = Color(0.83, 0.66, 0.44)
const PLAYER_COLLAR_COLOR: Color = Color(0.28, 0.74, 0.4)
const NPC_FUR_COLORS: Array[Color] = [
	Color(0.91, 0.86, 0.77),
	Color(0.89, 0.83, 0.74),
	Color(0.87, 0.81, 0.71),
]
const NPC_COLLAR_COLORS: Array[Color] = [
	Color(0.73, 0.42, 0.86),
	Color(0.94, 0.63, 0.22),
	Color(0.33, 0.62, 0.9),
]
const ROPE_TINT_OFFSETS: Array[float] = [-0.03, 0.02, -0.01, 0.04]
const TARGET_KNOT_OFFSETS := [
	Vector2(-34.0, 22.0),
	Vector2(28.0, -18.0),
	Vector2(-18.0, 20.0),
	Vector2(34.0, -24.0),
]
const HOOK_ENTRY_VARIANTS := [
	[
		Vector2(576.0, 164.0),
		Vector2(576.0, 232.0),
		Vector2(576.0, 300.0),
		Vector2(576.0, 368.0),
	],
	[
		Vector2(562.0, 176.0),
		Vector2(590.0, 244.0),
		Vector2(564.0, 312.0),
		Vector2(588.0, 380.0),
	],
	[
		Vector2(590.0, 170.0),
		Vector2(562.0, 238.0),
		Vector2(590.0, 306.0),
		Vector2(560.0, 374.0),
	],
]
const KNOT_VARIANTS := [
	[
		Vector2(452.0, 238.0),
		Vector2(690.0, 226.0),
		Vector2(500.0, 354.0),
		Vector2(734.0, 330.0),
	],
	[
		Vector2(420.0, 256.0),
		Vector2(664.0, 214.0),
		Vector2(488.0, 338.0),
		Vector2(760.0, 354.0),
	],
	[
		Vector2(444.0, 222.0),
		Vector2(706.0, 248.0),
		Vector2(512.0, 370.0),
		Vector2(716.0, 318.0),
	],
]
const FAN_SWAY_VARIANTS := [
	[-18.0, -6.0, 8.0, 20.0],
	[12.0, -18.0, 18.0, -10.0],
	[-10.0, 16.0, -14.0, 12.0],
]

@export var rope_count: int = 4:
	set(value):
		rope_count = clampi(value, 1, MAX_ROPES)
		_sync_hook_layout()
		queue_redraw()
@export var hook_positions: PackedVector2Array = PackedVector2Array([
	Vector2(576.0, 126.0),
	Vector2(576.0, 194.0),
	Vector2(576.0, 262.0),
	Vector2(576.0, 330.0),
])
@export var dog_slot_positions: PackedVector2Array = PackedVector2Array([
	Vector2(160.0, 510.0),
	Vector2(416.0, 508.0),
	Vector2(736.0, 508.0),
	Vector2(992.0, 510.0),
])
@export var rope_color: Color = Color(0.9, 0.37, 0.39)
@export var correct_color: Color = Color(0.28, 0.77, 0.39)
@export var wrong_color: Color = Color(0.88, 0.26, 0.23)
@export var rope_shadow_color: Color = Color(0.09, 0.08, 0.07, 0.24)
@export var rope_width: float = 6.0
@export var rope_shadow_width: float = 11.0
@export var player_label_offset: Vector2 = Vector2(0.0, -106.0)

@onready var hook_nodes: Array[PickTheRopeHook] = [$HookA, $HookB, $HookC, $HookD]
@onready var player_dog_label: Label = $PlayerDogLabel

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var dog_slot_for_hook: Array[int] = []
var rope_paths: Array[PackedVector2Array] = []
var rope_states: Array[int] = []
var correct_hook_index: int = -1
var player_dog_slot_index: int = 0
var current_pattern_index: int = 0
var feedback_tween: Tween
var player_dog_glow: float = 0.0
var player_dog_bounce: float = 0.0


func _ready() -> void:
	rng.randomize()
	for index in range(hook_nodes.size()):
		var hook: PickTheRopeHook = hook_nodes[index]
		hook.hook_index = index
		if not hook.hook_pressed.is_connected(_on_hook_pressed):
			hook.hook_pressed.connect(_on_hook_pressed)

	_sync_hook_layout()
	_reset_feedback_visuals()


func reset_round() -> void:
	current_pattern_index = rng.randi_range(0, HOOK_ENTRY_VARIANTS.size() - 1)
	_shuffle_assignments()
	_build_rope_paths()
	_reset_feedback_visuals()
	_sync_hook_layout()
	_update_player_label()
	queue_redraw()


func set_pick_enabled(value: bool) -> void:
	for index in range(hook_nodes.size()):
		hook_nodes[index].set_pick_enabled(value and index < rope_count)


func reveal_result(selected_hook_index: int, correct_hook_index_value: int) -> void:
	correct_hook_index = correct_hook_index_value
	_clear_feedback_tween()
	_set_player_dog_glow(0.0)
	_set_player_dog_bounce(0.0)

	for index in range(rope_states.size()):
		rope_states[index] = FeedbackState.DIMMED

	for index in range(hook_nodes.size()):
		if index >= rope_count:
			hook_nodes[index].visible = false
			continue

		hook_nodes[index].visible = true
		hook_nodes[index].set_pick_enabled(false)
		hook_nodes[index].set_feedback_state(FeedbackState.DIMMED)

	if correct_hook_index >= 0 and correct_hook_index < rope_count:
		rope_states[correct_hook_index] = FeedbackState.CORRECT
		hook_nodes[correct_hook_index].set_feedback_state(FeedbackState.CORRECT)

	if selected_hook_index >= 0 and selected_hook_index < rope_count and selected_hook_index != correct_hook_index:
		rope_states[selected_hook_index] = FeedbackState.WRONG
		hook_nodes[selected_hook_index].set_feedback_state(FeedbackState.WRONG)

	if selected_hook_index == correct_hook_index and correct_hook_index >= 0:
		_play_player_success_feedback()

	queue_redraw()


func get_correct_hook_index() -> int:
	return correct_hook_index


func _draw() -> void:
	_draw_tangle_shadow()
	_draw_ropes()
	_draw_dogs()


func _shuffle_assignments() -> void:
	dog_slot_for_hook.clear()
	var slot_order: Array[int] = []
	for index in range(rope_count):
		slot_order.append(index)

	for index in range(slot_order.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: int = slot_order[index]
		slot_order[index] = slot_order[swap_index]
		slot_order[swap_index] = temp

	for slot_index in slot_order:
		dog_slot_for_hook.append(slot_index)

	player_dog_slot_index = rng.randi_range(0, rope_count - 1)
	correct_hook_index = dog_slot_for_hook.find(player_dog_slot_index)


func _build_rope_paths() -> void:
	rope_paths.clear()
	rope_states.clear()

	var entry_points: Array = HOOK_ENTRY_VARIANTS[current_pattern_index]
	var knot_points: Array = KNOT_VARIANTS[current_pattern_index]

	for hook_index in range(rope_count):
		var dog_slot_index: int = dog_slot_for_hook[hook_index]
		var knot_point: Vector2 = knot_points[hook_index] + TARGET_KNOT_OFFSETS[dog_slot_index]
		rope_paths.append(_build_rope_path(hook_index, dog_slot_index, entry_points[hook_index], knot_point))
		rope_states.append(FeedbackState.NEUTRAL)

	for index in range(rope_count, MAX_ROPES):
		rope_states.append(FeedbackState.NEUTRAL)


func _build_rope_path(hook_index: int, dog_slot_index: int, drop_point: Vector2, knot_point: Vector2) -> PackedVector2Array:
	var start: Vector2 = hook_positions[hook_index] + Vector2(0.0, 22.0)
	var fan_sways: Array = FAN_SWAY_VARIANTS[current_pattern_index]
	var fan_point: Vector2 = Vector2(
		576.0 + (float(dog_slot_index) - 1.5) * 132.0 + float(fan_sways[dog_slot_index]),
		396.0 + float(hook_index - dog_slot_index) * 8.0
	)
	var end: Vector2 = _get_dog_neck_anchor(dog_slot_index)
	var rope_points: PackedVector2Array = PackedVector2Array()

	_append_bezier_segment(
		rope_points,
		start,
		start + Vector2(0.0, 28.0),
		drop_point + Vector2(0.0, -22.0),
		drop_point,
		8
	)

	var knot_dx: float = knot_point.x - drop_point.x
	_append_bezier_segment(
		rope_points,
		drop_point,
		drop_point + Vector2(clampf(knot_dx * 0.18, -28.0, 28.0), 42.0),
		knot_point + Vector2(clampf(-knot_dx * 0.24, -76.0, 76.0), -44.0),
		knot_point,
		10
	)

	var fan_dx: float = fan_point.x - knot_point.x
	_append_bezier_segment(
		rope_points,
		knot_point,
		knot_point + Vector2(fan_dx * 0.34, 58.0),
		fan_point + Vector2(-fan_dx * 0.22, -36.0),
		fan_point,
		10
	)

	var end_dx: float = end.x - fan_point.x
	_append_bezier_segment(
		rope_points,
		fan_point,
		fan_point + Vector2(end_dx * 0.3, 30.0),
		end + Vector2(-end_dx * 0.08, -58.0),
		end,
		10
	)

	return rope_points


func _append_bezier_segment(points: PackedVector2Array, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, samples: int) -> void:
	for step in range(samples + 1):
		if points.size() > 0 and step == 0:
			continue

		var t: float = float(step) / float(samples)
		points.append(_cubic_bezier_point(p0, p1, p2, p3, t))


func _cubic_bezier_point(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var inverse_t: float = 1.0 - t
	return (
		inverse_t * inverse_t * inverse_t * p0 +
		3.0 * inverse_t * inverse_t * t * p1 +
		3.0 * inverse_t * t * t * p2 +
		t * t * t * p3
	)


func _draw_tangle_shadow() -> void:
	draw_circle(Vector2(576.0, 316.0), 122.0, Color(0.18, 0.11, 0.1, 0.06))
	draw_circle(Vector2(576.0, 316.0), 86.0, Color(0.18, 0.11, 0.1, 0.08))
	draw_arc(Vector2(576.0, 316.0), 138.0, PI * 0.15, PI * 0.95, 40, Color(1.0, 1.0, 1.0, 0.09), 3.0)


func _draw_ropes() -> void:
	for index in range(rope_paths.size()):
		var path: PackedVector2Array = rope_paths[index]
		var rope_state: int = rope_states[index]
		var shadow_color: Color = _get_rope_shadow_for_state(rope_state)
		var line_color: Color = _get_rope_color_for_state(index, rope_state)

		draw_polyline(path, shadow_color, rope_shadow_width, true)
		draw_polyline(path, line_color, rope_width, true)


func _draw_dogs() -> void:
	for slot_index in range(rope_count):
		_draw_dog(slot_index)


func _draw_dog(slot_index: int) -> void:
	var is_player_dog: bool = slot_index == player_dog_slot_index
	var origin: Vector2 = dog_slot_positions[slot_index]
	if is_player_dog:
		origin.y -= player_dog_bounce

	var fur_color: Color = PLAYER_FUR_COLOR if is_player_dog else NPC_FUR_COLORS[slot_index % NPC_FUR_COLORS.size()]
	var spot_color: Color = PLAYER_SPOT_COLOR if is_player_dog else fur_color.darkened(0.12)
	var collar_color: Color = PLAYER_COLLAR_COLOR if is_player_dog else NPC_COLLAR_COLORS[slot_index % NPC_COLLAR_COLORS.size()]

	if is_player_dog and player_dog_glow > 0.0:
		var aura: Color = correct_color
		aura.a = 0.08 + player_dog_glow * 0.18
		draw_circle(origin + Vector2(0.0, -24.0), 64.0 + player_dog_glow * 8.0, aura)

	draw_circle(origin + Vector2(0.0, 8.0), 34.0, Color(0.15, 0.11, 0.09, 0.12))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-30.0, -58.0),
		origin + Vector2(-46.0, -84.0),
		origin + Vector2(-18.0, -72.0),
	]), fur_color)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(30.0, -58.0),
		origin + Vector2(46.0, -84.0),
		origin + Vector2(18.0, -72.0),
	]), fur_color)
	draw_circle(origin + Vector2(0.0, -48.0), 28.0, fur_color)
	draw_circle(origin + Vector2(-12.0, -54.0), 10.0, spot_color)
	draw_circle(origin + Vector2(0.0, -8.0), 34.0, fur_color)
	draw_rect(Rect2(origin + Vector2(-26.0, -30.0), Vector2(52.0, 10.0)), collar_color, true)
	draw_circle(origin + Vector2(0.0, -25.0), 5.0, collar_color.lightened(0.18))
	draw_circle(origin + Vector2(-9.0, -52.0), 3.0, Color(0.15, 0.12, 0.1))
	draw_circle(origin + Vector2(9.0, -52.0), 3.0, Color(0.15, 0.12, 0.1))
	draw_circle(origin + Vector2(0.0, -42.0), 4.0, Color(0.18, 0.11, 0.1))
	draw_arc(origin + Vector2(0.0, -36.0), 10.0, 0.35, PI - 0.35, 16, Color(0.36, 0.21, 0.16), 3.0)
	draw_rect(Rect2(origin + Vector2(-23.0, 8.0), Vector2(10.0, 28.0)), fur_color.darkened(0.14), true)
	draw_rect(Rect2(origin + Vector2(-5.0, 10.0), Vector2(10.0, 28.0)), fur_color.darkened(0.14), true)
	draw_rect(Rect2(origin + Vector2(13.0, 8.0), Vector2(10.0, 28.0)), fur_color.darkened(0.14), true)
	draw_arc(origin + Vector2(30.0, -2.0), 20.0, -0.7, 0.8, 18, spot_color, 5.0)


func _get_dog_neck_anchor(slot_index: int) -> Vector2:
	return dog_slot_positions[slot_index] + Vector2(0.0, -30.0)


func _get_neutral_rope_color(index: int) -> Color:
	var shift: float = ROPE_TINT_OFFSETS[index % ROPE_TINT_OFFSETS.size()]
	if shift >= 0.0:
		return rope_color.lightened(shift)
	return rope_color.darkened(-shift)


func _get_rope_color_for_state(index: int, rope_state: int) -> Color:
	match rope_state:
		FeedbackState.CORRECT:
			return correct_color
		FeedbackState.WRONG:
			return wrong_color
		FeedbackState.DIMMED:
			var dimmed: Color = rope_color.darkened(0.18)
			dimmed.a = 0.22
			return dimmed
		_:
			return _get_neutral_rope_color(index)


func _get_rope_shadow_for_state(rope_state: int) -> Color:
	match rope_state:
		FeedbackState.CORRECT:
			var success_shadow: Color = correct_color.darkened(0.56)
			success_shadow.a = 0.3
			return success_shadow
		FeedbackState.WRONG:
			var failure_shadow: Color = wrong_color.darkened(0.58)
			failure_shadow.a = 0.3
			return failure_shadow
		FeedbackState.DIMMED:
			var dim_shadow: Color = rope_shadow_color
			dim_shadow.a = 0.08
			return dim_shadow
		_:
			return rope_shadow_color


func _reset_feedback_visuals() -> void:
	_clear_feedback_tween()
	_set_player_dog_glow(0.0)
	_set_player_dog_bounce(0.0)

	for index in range(hook_nodes.size()):
		var hook: PickTheRopeHook = hook_nodes[index]
		hook.position = hook_positions[index]
		hook.visible = index < rope_count
		hook.reset_hook(index, _get_neutral_rope_color(index))

	for index in range(rope_states.size()):
		rope_states[index] = FeedbackState.NEUTRAL


func _sync_hook_layout() -> void:
	if not is_node_ready() or hook_nodes.is_empty():
		return

	for index in range(hook_nodes.size()):
		var hook: PickTheRopeHook = hook_nodes[index]
		hook.position = hook_positions[index]
		hook.visible = index < rope_count
		if index >= rope_count:
			hook.set_pick_enabled(false)


func _update_player_label() -> void:
	if player_dog_label == null:
		return

	player_dog_label.position = dog_slot_positions[player_dog_slot_index] + player_label_offset + Vector2(-60.0, -player_dog_bounce)
	player_dog_label.modulate = Color(0.19, 0.3, 0.16).lerp(Color(0.23, 0.54, 0.25), player_dog_glow)


func _play_player_success_feedback() -> void:
	feedback_tween = create_tween()
	feedback_tween.tween_method(_set_player_dog_glow, 0.0, 1.0, 0.12)
	feedback_tween.parallel().tween_method(_set_player_dog_bounce, 0.0, 14.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_method(_set_player_dog_glow, 1.0, 0.34, 0.24)
	feedback_tween.parallel().tween_method(_set_player_dog_bounce, 14.0, 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	feedback_tween.finished.connect(_on_feedback_finished)


func _clear_feedback_tween() -> void:
	if feedback_tween != null:
		feedback_tween.kill()
		feedback_tween = null


func _set_player_dog_glow(value: float) -> void:
	player_dog_glow = value
	_update_player_label()
	queue_redraw()


func _set_player_dog_bounce(value: float) -> void:
	player_dog_bounce = value
	_update_player_label()
	queue_redraw()


func _on_feedback_finished() -> void:
	feedback_tween = null


func _on_hook_pressed(hook_index: int) -> void:
	hook_selected.emit(hook_index)
