extends CanvasLayer
class_name DistractionManager

## Fired when a distraction starts, can be used for SFX.
signal distraction_triggered(type: String)

@export var enabled := true
@export var min_interval := 1.5
@export var max_interval := 3.0

@onready var timer: Timer = Timer.new()

enum DistractionType {
	POPUP,
	OVERLAY,
	CURSOR_SHAKE
}

func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	
	if enabled:
		_schedule_next()

func start() -> void:
	enabled = true
	_schedule_next()

func stop() -> void:
	enabled = false
	timer.stop()

func _schedule_next() -> void:
	if not enabled: return
	timer.start(randf_range(min_interval, max_interval))

func _on_timer_timeout() -> void:
	if not enabled: return
	
	_trigger_random_distraction()
	_schedule_next()

func _trigger_random_distraction() -> void:
	var type = DistractionType.values().pick_random()
	
	match type:
		DistractionType.POPUP:
			_show_fake_popup()
		DistractionType.OVERLAY:
			_show_passing_dog()
		DistractionType.CURSOR_SHAKE:
			_shake_screen()
	
	distraction_triggered.emit(str(type))

func _show_fake_popup() -> void:
	var popup = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1) # White window
	style.set_border_width_all(2)
	style.border_color = Color(0, 0, 0.8) # Classic blue border
	popup.add_theme_stylebox_override("panel", style)
	
	popup.custom_minimum_size = Vector2(300, 120)
	popup.position = Vector2(randf_range(100, 500), randf_range(100, 300))
	popup.pivot_offset = popup.custom_minimum_size / 2
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	popup.add_child(vbox)
	
	# Title Bar with [X] on Right
	var title_bar = PanelContainer.new()
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color(0, 0, 0.8)
	title_bar.add_theme_stylebox_override("panel", title_style)
	vbox.add_child(title_bar)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	title_bar.add_child(title_hbox)
	
	var title_label = Label.new()
	title_label.text = " HOT DOG EXPLOSION!"
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title_label)
	
	var close_label = Label.new()
	close_label.text = "[X] "
	close_label.add_theme_font_size_override("font_size", 12)
	title_hbox.add_child(close_label)
	
	# Content
	var content = MarginContainer.new()
	content.add_theme_constant_override("margin_top", 10)
	content.add_theme_constant_override("margin_bottom", 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 5)
	content.add_child(content_vbox)
	
	var main_text = Label.new()
	main_text.text = "LIMITED OFFER: BUY 1 GET 3!!\nVISIT DOG-CITY.COM"
	main_text.add_theme_color_override("font_color", Color.BLACK)
	main_text.add_theme_font_size_override("font_size", 13)
	main_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(main_text)
	
	var buy_btn = Label.new()
	buy_btn.text = "[ CLICK HERE TO CLAIM ]"
	buy_btn.add_theme_color_override("font_color", Color.RED)
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(buy_btn)
	
	# Footer
	var footer = Label.new()
	footer.text = "Ads by DoggoNetwork  "
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	footer.add_theme_font_size_override("font_size", 9)
	vbox.add_child(footer)
	
	add_child(popup)
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.3).from(Vector2.ZERO)
	tween.tween_interval(2.2)
	tween.tween_property(popup, "modulate:a", 0.0, 0.2)
	tween.tween_callback(popup.queue_free)

func _show_passing_dog() -> void:
	var dog = TextureRect.new()
	dog.texture = load("res://Assets/Sprites/SpotTheDifference/dog_icon_progress.png")
	dog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dog.modulate = Color(0, 0, 0, 0.6) # Silhouette
	dog.size = Vector2(200, 200)
	dog.position = Vector2(-300, randf_range(100, 400))
	
	add_child(dog)
	
	var tween = create_tween()
	# Rotate slightly while moving
	tween.set_parallel(true)
	tween.tween_property(dog, "position:x", 1300, 1.2).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(dog, "rotation_degrees", 360.0, 1.2)
	tween.chain().tween_callback(dog.queue_free)

func _shake_screen() -> void:
	# We can't easily shake the camera from here without reference,
	# but we can emit a signal or find the camera.
	var cam = get_viewport().get_camera_2d()
	if cam:
		var original_pos = cam.offset
		var tween = create_tween()
		for i in range(5):
			tween.tween_property(cam, "offset", original_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.05)
		tween.tween_property(cam, "offset", original_pos, 0.05)
