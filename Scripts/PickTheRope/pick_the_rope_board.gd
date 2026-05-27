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
const ROPE_TINT_OFFSETS: Array[float] = [-0.03, 0.02, -0.01, 0.04]
const PLAYER_COLLAR_COLOR: Color = Color(0.28, 0.74, 0.4)
const TARGET_KNOT_OFFSETS := [
	Vector2(-16.0, -10.0),
	Vector2(16.0, 8.0),
	Vector2(-12.0, 12.0),
	Vector2(18.0, -8.0),
]
const KNOT_VARIANTS := [
	[
		Vector2(706.0, 198.0),
		Vector2(604.0, 260.0),
		Vector2(700.0, 340.0),
		Vector2(598.0, 416.0),
	],
	[
		Vector2(686.0, 214.0),
		Vector2(584.0, 242.0),
		Vector2(714.0, 368.0),
		Vector2(592.0, 388.0),
	],
	[
		Vector2(724.0, 204.0),
		Vector2(616.0, 276.0),
		Vector2(678.0, 316.0),
		Vector2(606.0, 436.0),
	],
]
const SPREAD_VARIANTS := [
	[
		Vector2(472.0, 188.0),
		Vector2(420.0, 276.0),
		Vector2(476.0, 376.0),
		Vector2(420.0, 478.0),
	],
	[
		Vector2(490.0, 202.0),
		Vector2(432.0, 262.0),
		Vector2(484.0, 386.0),
		Vector2(430.0, 464.0),
	],
	[
		Vector2(458.0, 182.0),
		Vector2(414.0, 286.0),
		Vector2(464.0, 362.0),
		Vector2(414.0, 490.0),
	],
]

@export var rope_count: int = 4:
	set(value):
		rope_count = clampi(value, 1, MAX_ROPES)
		if is_node_ready():
			_sync_hook_layout()
			_sync_rope_visuals()
			_sync_dog_visuals()
@export var rope_color: Color = Color(0.9, 0.37, 0.39):
	set(value):
		rope_color = value
		if is_node_ready():
			_sync_rope_visuals()
@export var correct_color: Color = Color(0.28, 0.77, 0.39):
	set(value):
		correct_color = value
		if is_node_ready():
			_sync_rope_visuals()
@export var wrong_color: Color = Color(0.88, 0.26, 0.23):
	set(value):
		wrong_color = value
		if is_node_ready():
			_sync_rope_visuals()
@export var rope_shadow_color: Color = Color(0.09, 0.08, 0.07, 0.24):
	set(value):
		rope_shadow_color = value
		if is_node_ready():
			_sync_rope_visuals()
@export var dog_neck_offset: Vector2 = Vector2(0.0, -30.0)

@export_group("Fallback Positions")
@export var hook_positions: PackedVector2Array = PackedVector2Array([
	Vector2(916.0, 182.0),
	Vector2(916.0, 248.0),
	Vector2(916.0, 314.0),
	Vector2(916.0, 380.0),
])
@export var dog_slot_positions: PackedVector2Array = PackedVector2Array([
	Vector2(196.0, 344.0),
	Vector2(314.0, 396.0),
	Vector2(196.0, 452.0),
	Vector2(314.0, 504.0),
])
@export_group("")

@onready var hook_nodes: Array[PickTheRopeHook] = [$HookA as PickTheRopeHook, $HookB as PickTheRopeHook, $HookC as PickTheRopeHook, $HookD as PickTheRopeHook]
@onready var rope_nodes: Array[Line2D] = [$Ropes/RopeA as Line2D, $Ropes/RopeB as Line2D, $Ropes/RopeC as Line2D, $Ropes/RopeD as Line2D]
@onready var rope_shadow_nodes: Array[Line2D] = [$RopeShadows/RopeShadowA as Line2D, $RopeShadows/RopeShadowB as Line2D, $RopeShadows/RopeShadowC as Line2D, $RopeShadows/RopeShadowD as Line2D]
@onready var dog_slot_nodes: Array[Node2D] = [$DogSlots/DogSlotA as Node2D, $DogSlots/DogSlotB as Node2D, $DogSlots/DogSlotC as Node2D, $DogSlots/DogSlotD as Node2D]
@onready var dog_visual_nodes: Array[Node2D] = [$DogSlots/DogSlotA/Visuals as Node2D, $DogSlots/DogSlotB/Visuals as Node2D, $DogSlots/DogSlotC/Visuals as Node2D, $DogSlots/DogSlotD/Visuals as Node2D]
@onready var dog_glow_nodes: Array[Sprite2D] = [$DogSlots/DogSlotA/Glow as Sprite2D, $DogSlots/DogSlotB/Glow as Sprite2D, $DogSlots/DogSlotC/Glow as Sprite2D, $DogSlots/DogSlotD/Glow as Sprite2D]

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
	current_pattern_index = rng.randi_range(0, KNOT_VARIANTS.size() - 1)
	_shuffle_assignments()
	_build_rope_paths()
	_reset_feedback_visuals()


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

	_sync_rope_visuals()


func get_correct_hook_index() -> int:
	return correct_hook_index


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

	var knot_points: Array = KNOT_VARIANTS[current_pattern_index]
	for hook_index in range(rope_count):
		var dog_slot_index: int = dog_slot_for_hook[hook_index]
		var knot_point: Vector2 = knot_points[hook_index] + TARGET_KNOT_OFFSETS[dog_slot_index]
		rope_paths.append(_build_rope_path(hook_index, dog_slot_index, knot_point))
		rope_states.append(FeedbackState.NEUTRAL)

	for index in range(rope_count, MAX_ROPES):
		rope_states.append(FeedbackState.NEUTRAL)


func _build_rope_path(hook_index: int, dog_slot_index: int, knot_point: Vector2) -> PackedVector2Array:
	var spread_points: Array = SPREAD_VARIANTS[current_pattern_index]
	var end: Vector2 = _get_dog_neck_anchor(dog_slot_index)
	var spread_point: Vector2 = spread_points[dog_slot_index] + Vector2(float(hook_index - dog_slot_index) * 4.0, float(hook_index - dog_slot_index) * 4.0)
	var hook_position: Vector2 = _get_hook_position(hook_index)
	var start: Vector2 = hook_position + Vector2(-22.0, 0.0)
	var hook_exit: Vector2 = start + Vector2(-34.0, clampf((end.y - start.y) * 0.04, -7.0, 7.0))
	var pole_clear: Vector2 = Vector2(
		hook_position.x - (94.0 + float(current_pattern_index) * 8.0),
		start.y + float(hook_index - 1) * 4.0
	)
	var lane_point: Vector2 = Vector2(
		756.0 - float(current_pattern_index) * 12.0,
		lerpf(start.y, end.y, 0.18) + float(hook_index - dog_slot_index) * 10.0
	)
	var rope_points: PackedVector2Array = PackedVector2Array()

	_append_bezier_segment(rope_points, start, start + Vector2(-14.0, 0.0), hook_exit + Vector2(10.0, 0.0), hook_exit, 5)
	_append_bezier_segment(rope_points, hook_exit, hook_exit + Vector2(-18.0, 0.0), pole_clear + Vector2(18.0, clampf((hook_exit.y - pole_clear.y) * 0.16, -10.0, 10.0)), pole_clear, 6)
	_append_bezier_segment(rope_points, pole_clear, pole_clear + Vector2(-28.0, 0.0), lane_point + Vector2(34.0, clampf((pole_clear.y - lane_point.y) * 0.18, -16.0, 16.0)), lane_point, 6)

	var knot_dx: float = knot_point.x - lane_point.x
	_append_bezier_segment(
		rope_points,
		lane_point,
		lane_point + Vector2(clampf(knot_dx * 0.2, -22.0, 16.0), clampf((knot_point.y - lane_point.y) * 0.24, -24.0, 24.0)),
		knot_point + Vector2(clampf(-knot_dx * 0.18, -48.0, 52.0), clampf((lane_point.y - knot_point.y) * 0.22, -28.0, 28.0)),
		knot_point,
		10
	)

	var spread_dx: float = spread_point.x - knot_point.x
	_append_bezier_segment(
		rope_points,
		knot_point,
		knot_point + Vector2(spread_dx * 0.22, clampf((spread_point.y - knot_point.y) * 0.34, -40.0, 40.0)),
		spread_point + Vector2(-spread_dx * 0.18, clampf((knot_point.y - spread_point.y) * 0.2, -28.0, 28.0)),
		spread_point,
		10
	)

	var end_dx: float = end.x - spread_point.x
	_append_bezier_segment(
		rope_points,
		spread_point,
		spread_point + Vector2(end_dx * 0.22, clampf((end.y - spread_point.y) * 0.24, -24.0, 24.0)),
		end + Vector2(clampf(-end_dx * 0.08, -26.0, 30.0), clampf((spread_point.y - end.y) * 0.2, -32.0, 32.0)),
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


func _reset_feedback_visuals() -> void:
	_clear_feedback_tween()
	player_dog_glow = 0.0
	player_dog_bounce = 0.0

	for index in range(hook_nodes.size()):
		var hook: PickTheRopeHook = hook_nodes[index]
		hook.visible = index < rope_count
		hook.reset_hook(index, _get_neutral_rope_color(index))

	for index in range(rope_states.size()):
		rope_states[index] = FeedbackState.NEUTRAL

	_sync_hook_layout()
	_sync_rope_visuals()
	_sync_dog_visuals()


func _sync_hook_layout() -> void:
	if hook_nodes.is_empty():
		return

	for index in range(hook_nodes.size()):
		var hook: PickTheRopeHook = hook_nodes[index]
		hook.visible = index < rope_count
		if index >= rope_count:
			hook.set_pick_enabled(false)


func _sync_rope_visuals() -> void:
	for index in range(MAX_ROPES):
		var has_path: bool = index < rope_paths.size() and index < rope_count
		var path: PackedVector2Array = rope_paths[index] if has_path else PackedVector2Array()
		var rope_state: int = rope_states[index] if index < rope_states.size() else FeedbackState.NEUTRAL

		var rope_line: Line2D = rope_nodes[index]
		rope_line.visible = has_path
		rope_line.points = path
		rope_line.default_color = _get_rope_color_for_state(index, rope_state)

		var shadow_line: Line2D = rope_shadow_nodes[index]
		shadow_line.visible = has_path
		shadow_line.points = path
		shadow_line.default_color = _get_rope_shadow_for_state(rope_state)


func _sync_dog_visuals() -> void:
	for index in range(dog_slot_nodes.size()):
		var is_active: bool = index < rope_count
		var is_player_dog: bool = index == player_dog_slot_index
		dog_slot_nodes[index].visible = is_active
		var visual_y: float = -player_dog_bounce if is_player_dog else 0.0
		dog_visual_nodes[index].position = Vector2(0.0, visual_y)

		var glow: Sprite2D = dog_glow_nodes[index]
		glow.visible = is_active and is_player_dog
		var glow_color: Color = PLAYER_COLLAR_COLOR
		glow_color.a = 0.18 + player_dog_glow * 0.18
		glow.modulate = glow_color
		glow.scale = Vector2.ONE * (1.35 + player_dog_glow * 0.18)


func _get_hook_position(index: int) -> Vector2:
	if index < hook_nodes.size() and is_instance_valid(hook_nodes[index]):
		return hook_nodes[index].position
	if index < hook_positions.size():
		return hook_positions[index]
	return Vector2.ZERO


func _get_dog_slot_position(index: int) -> Vector2:
	if index < dog_slot_nodes.size() and is_instance_valid(dog_slot_nodes[index]):
		return dog_slot_nodes[index].position
	if index < dog_slot_positions.size():
		return dog_slot_positions[index]
	return Vector2.ZERO


func _get_dog_neck_anchor(slot_index: int) -> Vector2:
	return _get_dog_slot_position(slot_index) + dog_neck_offset


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
	_sync_dog_visuals()


func _set_player_dog_bounce(value: float) -> void:
	player_dog_bounce = value
	_sync_dog_visuals()


func _on_feedback_finished() -> void:
	feedback_tween = null


func _on_hook_pressed(hook_index: int) -> void:
	hook_selected.emit(hook_index)
