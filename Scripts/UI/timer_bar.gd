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
	# Don't hide yet, show frozen state until GameManager hides it

func _process(delta: float):
	if not active:
		return
	
	time_left -= delta
	progress_bar.value = time_left
	progress_bar.modulate = _get_timer_color()
	
	if time_left <= 0:
		time_left = 0
		active = false
		emit_signal("timeout")

func _get_timer_color() -> Color:
	var ratio = time_left / total_time
	if ratio > 0.5:
		return Color.GREEN
	elif ratio > 0.2:
		return Color.YELLOW
	else:
		return Color.RED
