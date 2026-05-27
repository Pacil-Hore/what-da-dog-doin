extends Control

signal timeout

@onready var progress_bar: ProgressBar = $ProgressBar

var total_time := 5.0
var time_left := 5.0
var active := false

func start(duration: float):
	total_time = duration
	time_left = duration
	active = true
	progress_bar.max_value = total_time
	progress_bar.value = total_time
	show()

func stop():
	active = false
	progress_bar.value = time_left
	progress_bar.modulate = _get_timer_color()
	progress_bar.scale = Vector2.ONE
	# Don't hide yet, show frozen state until GameManager hides it

func _process(delta: float):
	if not active:
		return
	
	time_left -= delta
	progress_bar.value = time_left
	progress_bar.modulate = _get_timer_color()
	
	var ratio = time_left / total_time
	if ratio <= 0.25:
		progress_bar.pivot_offset = progress_bar.size / 2
		var pulse = 1.0 + 0.08 * abs(sin(time_left * 12.0))
		progress_bar.scale = Vector2(pulse, pulse)
	else:
		progress_bar.scale = Vector2.ONE
	
	if time_left <= 0:
		time_left = 0
		active = false
		progress_bar.scale = Vector2.ONE
		emit_signal("timeout")

func _get_timer_color() -> Color:
	var ratio = time_left / total_time
	if ratio > 0.5:
		return Color.GREEN
	elif ratio > 0.25:
		return Color.YELLOW
	else:
		var pulse = abs(sin(time_left * 12.0))
		return Color.RED.lerp(Color(1.0, 0.45, 0.45), pulse)
