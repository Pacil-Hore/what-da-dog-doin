extends Node2D

# === Microgame contract ===
signal game_won
signal game_lost

@export var objective_text: String = "Attach the leash!"
@export var win_label_text: String = "Got it!"
@export var lose_label_text: String = "Too late..."
@export var time_limit: float = 15.0
@export var control_icon_path: String = "res://assets/generated/mouse_icon.png"

# === Rope settings ===
@export var rope_length_normal: float = 200.0
@export var rope_length_extended: float = 500.0
@export var swing_speed: float = 2.0
@export var swing_amplitude: float = PI / 2
@export var extend_duration: float = 0.3

# === References ===
@export var anchor: Marker2D
@export var rope: Line2D
@export var hook: Area2D
@export var dog: CharacterBody2D

# === State ===
var swing_angle: float = 0.0
var swing_phase: float = 0.0
var current_rope_length: float = 200.0
var is_extending: bool = false
var is_finished: bool = false

func _ready():
	current_rope_length = rope_length_normal
	
	if hook:
		hook.area_entered.connect(_on_hook_area_entered)
	
	if not _has_main_game_manager():
		_start_standalone_timer()

func _process(delta):
	if is_finished:
		return
	
	_update_swing(delta)
	_update_rope_visual()
	_update_hook_position()

func _input(event):
	if is_finished:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_extend_rope()

func _update_swing(delta: float):
	swing_phase += swing_speed * delta
	swing_angle = sin(swing_phase) * swing_amplitude

func _update_rope_visual():
	if not anchor or not rope:
		return
	
	var anchor_pos = anchor.global_position
	var end_pos = anchor_pos + Vector2(sin(swing_angle), -cos(swing_angle)) * current_rope_length
	
	rope.clear_points()
	rope.add_point(rope.to_local(anchor_pos))
	rope.add_point(rope.to_local(end_pos))

func _update_hook_position():
	if not anchor or not hook:
		return
	
	var anchor_pos = anchor.global_position
	var end_pos = anchor_pos + Vector2(sin(swing_angle), -cos(swing_angle)) * current_rope_length
	hook.global_position = end_pos
	hook.rotation = swing_angle

func _extend_rope():
	if is_extending:
		return
	is_extending = true
	
	var tween = create_tween()
	tween.tween_property(self, "current_rope_length", rope_length_extended, extend_duration)
	tween.tween_property(self, "current_rope_length", rope_length_normal, extend_duration)
	tween.tween_callback(func(): is_extending = false)

func _on_hook_area_entered(area: Area2D):
	if area.name == "Collar":
		_on_won()

func _on_won():
	if is_finished:
		return
	is_finished = true
	_freeze_scene()
	emit_signal("game_won")
	print("[Attach] WIN!")

func _on_lost():
	if is_finished:
		return
	is_finished = true
	_freeze_scene()
	emit_signal("game_lost")
	print("[Attach] LOSE!")

func _freeze_scene():
	# Stop anjing
	if dog:
		dog.set_physics_process(false)
		dog.set_process(false)
		if dog.has_method("set_velocity"):
			dog.velocity = Vector2.ZERO
	
	# Hentikan tween yang lagi jalan (extend rope)
	# Tween auto-stop kalau target node-nya pause/disabled,
	# tapi kita explicit aja: skip _process di Attach itu sendiri
	# (udah ke-handle di guard is_finished di awal _process)

func _has_main_game_manager() -> bool:
	var node = get_parent()
	while node:
		if "lives" in node and node.has_method("_load_interstitial"):
			return true
		node = node.get_parent()
	return false

func _start_standalone_timer():
	var t = Timer.new()
	t.wait_time = time_limit
	t.one_shot = true
	t.timeout.connect(_on_lost)
	add_child(t)
	t.start()
