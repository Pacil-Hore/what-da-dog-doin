extends Node2D

# === Microgame contract ===
signal game_won
signal game_lost

@export var objective_text: String = "Attach the leash!"
@export var win_label_text: String = "Got it!"
@export var lose_label_text: String = "Missed clip!"
@export var time_limit: float = 15.0
@export var control_icon: Texture2D

# === Rope settings ===
@export var rope_length_normal: float = 150.0     # panjang tali pas idle
@export var rope_length_extended: float = 600.0   # panjang tali pas dilempar
@export var swing_speed: float = 2.0              # kecepatan swing otomatis (radians/sec)
@export var swing_amplitude: float = PI / 2       # 90 derajat (total 180° kiri-kanan)
@export var arrow_influence: float = 3.0          # seberapa kuat arrow key push swing
@export var extend_duration: float = 0.3          # durasi extend tali (lempar)
@onready var collar: Area2D = dog.get_node_or_null("Collar")

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
var active_tween: Tween = null

func _ready():
	current_rope_length = rope_length_normal
	
	if hook:
		hook.area_entered.connect(_on_hook_area_entered)
	
	if not _has_main_game_manager():
		_start_standalone_timer()

# Pindah ke _physics_process biar sync sama collision detection
func _physics_process(delta):
	if is_finished:
		return
	
	_update_swing(delta)
	_update_hook_position()
	_update_rope_visual()

func _input(event):
	if is_finished:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_extend_rope()

func _update_swing(_delta: float):
	if not anchor:
		return
		
	# Point and click: Tali mengikuti posisi mouse
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - anchor.global_position).normalized()
	
	# angle 0 berarti lurus ke atas (0, -1)
	swing_angle = atan2(dir.x, -dir.y)
	swing_angle = clamp(swing_angle, -swing_amplitude, swing_amplitude)

func _update_hook_position():
	if not anchor or not hook:
		return
	
	var anchor_pos = anchor.global_position
	var end_pos = anchor_pos + Vector2(sin(swing_angle), -cos(swing_angle)) * current_rope_length
	hook.global_position = end_pos
	hook.rotation = swing_angle

func _update_rope_visual():
	if not anchor or not rope:
		return
	
	var anchor_pos = anchor.global_position
	var end_pos = anchor_pos + Vector2(sin(swing_angle), -cos(swing_angle)) * current_rope_length
	
	rope.clear_points()
	rope.add_point(rope.to_local(anchor_pos))
	rope.add_point(rope.to_local(end_pos))

func _extend_rope():
	if is_extending:
		return
	is_extending = true
	
	# Animate tali extend & retract
	active_tween = create_tween()
	active_tween.tween_property(self, "current_rope_length", rope_length_extended, extend_duration)
	active_tween.tween_property(self, "current_rope_length", rope_length_normal, extend_duration)
	active_tween.tween_callback(func(): is_extending = false)

func _on_hook_area_entered(area: Area2D):
	if area.name == "Collar":
		_on_won()

func _on_won():
	if is_finished:
		return
	is_finished = true
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	_freeze_scene()
	emit_signal("game_won")
	print("[Attach] WIN!")
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _on_lost():
	if is_finished:
		return
	is_finished = true
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	_freeze_scene()
	emit_signal("game_lost")
	print("[Attach] LOSE!")
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _freeze_scene():
	if dog:
		dog.set_physics_process(false)
		dog.set_process(false)
		if "velocity" in dog:
			dog.velocity = Vector2.ZERO

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
