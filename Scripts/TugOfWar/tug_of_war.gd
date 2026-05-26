extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Pull!"
@export var control_hint: String = "Space"
@export var control_icon_path: String = "res://assets/generated/mouse_icon.png" # Fallback icon
@export var time_limit: float = 5.0

# Node references
@onready var human: TugOfWarHuman = $Human
@onready var dog: TugOfWarDog = $Dog
@onready var leash: Line2D = $LeashLine
@onready var win_meter: ProgressBar = $HUD/CenterContainer/VBoxContainer/WinMeter
@onready var warning_label: Label = $HUD/WarningLabel
@onready var time_limit_timer: Timer = get_node_or_null("TimeLimit")

# Game parameters
@export var player_pull_strength := 0.06
@export var dog_base_drain_rate := 0.16
@export var dog_yank_strength := 0.09

# Simulation state
var gauge_value := 0.5 # starts in the middle (0.5). 1.0 is full human, 0.0 is full dog
var time_left := 5.0
var is_finished := false
var game_started := true

# Dog AI state
var next_yank_timer := 0.8
var yank_duration_timer := 0.0
var is_yanking := false

func _ready() -> void:
	time_left = time_limit
	gauge_value = 0.5
	is_finished = false
	is_yanking = false
	game_started = true
	next_yank_timer = randf_range(0.8, 1.4)
	
	warning_label.visible = false
	win_meter.value = gauge_value * 100.0
	
	# Position setup
	_update_positions()

func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		return
		
	# Debug keys for testing
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W or event.physical_keycode == KEY_W:
			game_started = true
			get_viewport().set_input_as_handled()
			_trigger_win()
			return
		elif event.keycode == KEY_L or event.physical_keycode == KEY_L:
			game_started = true
			get_viewport().set_input_as_handled()
			_trigger_loss()
			return
			
	var is_pull_input = false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_pull_input = true
	elif event is InputEventKey:
		if event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE):
			is_pull_input = true
			
	if is_pull_input:
		game_started = true
		get_viewport().set_input_as_handled()
		gauge_value = minf(gauge_value + player_pull_strength, 1.0)
		human.play_pull_wiggle()
		
		if gauge_value >= 1.0:
			_trigger_win()

func _process(delta: float) -> void:
	if is_finished:
		return
		
	if not game_started:
		_update_positions()
		return
		
	# 1. Update Timer
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_trigger_loss()
		return
			
	# 3. Dog AI Logic (Pulling back)
	_update_dog_ai(delta)
	
	# Check for loss (gauge falls to 0.0)
	if gauge_value <= 0.0:
		_trigger_loss()
		return
		
	# 4. Update visuals (leashes, rotations, gauge)
	_update_positions()
	win_meter.value = gauge_value * 100.0

func _update_dog_ai(delta: float) -> void:
	# Constant drain rate (higher time_scale increases speed naturally)
	var active_drain = dog_base_drain_rate * delta
	
	# Handles yanking duration and AI timers
	if is_yanking:
		yank_duration_timer -= delta
		active_drain += dog_base_drain_rate * 0.5 * delta # Pull harder during yank
		if yank_duration_timer <= 0.0:
			is_yanking = false
			dog.set_yank(false)
			warning_label.visible = false
	else:
		next_yank_timer -= delta
		if next_yank_timer <= 0.0:
			# Trigger a yank!
			is_yanking = true
			yank_duration_timer = 0.4 # Yank lasts 0.4 seconds
			gauge_value = maxf(gauge_value - dog_yank_strength, 0.0)
			dog.set_yank(true)
			warning_label.visible = true
			next_yank_timer = randf_range(0.9, 1.5)
			
	# Apply final drain
	gauge_value = maxf(gauge_value - active_drain, 0.0)

func _update_positions() -> void:
	# Calculate lean/tension
	human.set_tension(1.0 - gauge_value) # Tensions lean more as they get pulled
	dog.set_tension(gauge_value)
	
	# Slide dog and human horizontally depending on the gauge
	# If gauge_value -> 1.0, both get pulled toward the human.
	# If gauge_value -> 0.0, both get pulled toward the dog.
	var center_shift = (0.5 - gauge_value) * 200.0
	
	human.position.x = 260.0 + center_shift
	dog.position.x = 890.0 + center_shift
	
	# Get hand position from human shoulder and lean calculation
	# Human shoulder is at shoulder_pos. Hand is shoulder_pos + offset.
	# We can simplify this: Hand is roughly local Vector2(40, 20) under Human.
	var human_hand_global = human.global_position + Vector2(50, 42).rotated(human.rotation)
	
	# Dog collar is local Vector2(30, 20) on the left side of the dog's center.
	# Since scaled by -1, this is Vector2(-30, 20) globally.
	var dog_collar_global = dog.global_position + Vector2(-38, 26)
	
	# Draw leash line
	leash.clear_points()
	leash.add_point(leash.to_local(human_hand_global))
	leash.add_point(leash.to_local(dog_collar_global))

func _trigger_win() -> void:
	if is_finished:
		return
	is_finished = true
	win_meter.value = 100.0
	_update_positions()
	
	# Play victory lean
	human.set_tension(0.0)
	dog.set_tension(1.0)
	
	await get_tree().create_timer(0.4, false).timeout
	emit_signal("game_won")

func _trigger_loss() -> void:
	if is_finished:
		return
	is_finished = true
	
	# Play loss lean
	human.set_tension(1.0)
	dog.set_tension(0.0)
	
	await get_tree().create_timer(0.4, false).timeout
	emit_signal("game_lost")
