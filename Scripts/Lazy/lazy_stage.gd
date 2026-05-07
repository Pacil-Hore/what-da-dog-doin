extends Node2D

signal game_finished(did_win: bool)

const ALL_ITEMS := ["Bone", "Ball", "Food", "Toy", "Water"]
const ITEM_COLORS := {
	"Bone": Color(0.82, 0.72, 0.56, 1.0),
	"Ball": Color(0.86, 0.22, 0.22, 1.0),
	"Food": Color(0.92, 0.52, 0.18, 1.0),
	"Toy": Color(0.58, 0.30, 0.82, 1.0),
	"Water": Color(0.24, 0.52, 0.90, 1.0),
}

@export var survive_duration: float = 5.0
@export var spawn_interval_min: float = 0.5
@export var spawn_interval_max: float = 1.0
@export var max_bubbles: int = 3
@export var bubble_timer_min: float = 1.5
@export var bubble_timer_max: float = 2.0
@export var initial_spawn_buffer: float = 0.5
@export var bubble_spawn_range: Vector2 = Vector2(150.0, 90.0)
@export var dog_protection_radius: float = 125.0
@export var bubble_scene: PackedScene

@onready var dog: AnimatedSprite2D = $Dog
@onready var bubble_container: Node2D = $BubbleContainer
@onready var card_tray: HBoxContainer = $CardTray
@onready var survive_timer_label: Label = $SurviveTimer
@onready var result_overlay: ColorRect = $ResultOverlay/Backdrop
@onready var result_label: Label = $ResultOverlay/Backdrop/ResultLabel

var active_items: Array[String] = []
var active_bubbles: Array = []
var survive_time_left: float = 0.0
var game_over: bool = false
var spawn_timer: float = 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	add_to_group("lazy_stage")
	_setup_dog_placeholder()
	_pick_active_items()
	_build_card_tray()
	survive_time_left = survive_duration
	spawn_timer = initial_spawn_buffer
	result_overlay.visible = false
	if dog.sprite_frames != null:
		dog.play("idle")
	_update_survive_label()


func _process(delta: float) -> void:
	if game_over:
		return

	survive_time_left = maxf(survive_time_left - delta, 0.0)
	_update_survive_label()
	if survive_time_left <= 0.0:
		_show_result(true)
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		if active_bubbles.size() < max_bubbles:
			_spawn_bubble()
		spawn_timer = _get_spawn_interval()

func handle_item_drop(item_type: String, drop_position: Vector2) -> bool:
	if game_over:
		return false

	for bubble in active_bubbles:
		if bubble.contains_global_point(drop_position):
			bubble.try_satisfy(item_type)
			return true

	return false


func _pick_active_items() -> void:
	var item_pool: Array[String] = []
	for item in ALL_ITEMS:
		item_pool.append(item)
	active_items.clear()
	while active_items.size() < 3 and not item_pool.is_empty():
		var pick_index := rng.randi_range(0, item_pool.size() - 1)
		active_items.append(item_pool[pick_index])
		item_pool.remove_at(pick_index)


func _build_card_tray() -> void:
	for child in card_tray.get_children():
		child.queue_free()

	for item_type in active_items:
		var card := ColorRect.new()
		card.custom_minimum_size = Vector2(120.0, 120.0)
		card.color = Color(0.92, 0.92, 0.92, 1.0)
		card.mouse_filter = Control.MOUSE_FILTER_STOP

		var item_sprite: Node = Sprite2D.new()
		item_sprite.set("position", Vector2(60.0, 60.0))
		item_sprite.script = load("res://Scripts/Lazy/draggable_item.gd")
		card.add_child(item_sprite)

		card_tray.add_child(card)
		item_sprite.call("setup", item_type, _make_item_texture(item_type), self)
		card.gui_input.connect(func(event: InputEvent) -> void:
			_on_card_gui_input(event, item_sprite)
		)


func _spawn_bubble() -> void:
	if bubble_scene == null:
		return

	var bubble = bubble_scene.instantiate()
	var bubble_item := active_items[rng.randi_range(0, active_items.size() - 1)]
	var bubble_offset := _get_valid_bubble_offset()

	bubble.set("position", dog.position + bubble_offset)
	bubble_container.add_child(bubble)
	bubble.call("set_item", bubble_item)
	bubble.call("start_timer", _get_bubble_timer_duration())
	bubble.connect("bubble_expired", Callable(self, "_on_lose"))
	bubble.connect("bubble_wrong_item", Callable(self, "_on_bubble_wrong_item"))
	bubble.connect("bubble_satisfied", Callable(self, "_on_bubble_satisfied"))
	active_bubbles.append(bubble)


func _on_bubble_satisfied(bubble) -> void:
	if active_bubbles.has(bubble):
		active_bubbles.erase(bubble)
	bubble.queue_free()


func _on_bubble_wrong_item(_bubble, _dropped_item_type: String) -> void:
	_on_lose()


func _on_lose(_bubble = null) -> void:
	if game_over:
		return

	_show_result(false)


func _show_result(did_win: bool) -> void:
	if game_over:
		return

	game_over = true
	for bubble in active_bubbles:
		bubble.stop_bubble()
	result_label.text = "WIN" if did_win else "LOSE"
	result_overlay.visible = true
	game_finished.emit(did_win)


func _update_survive_label() -> void:
	survive_timer_label.text = "Survive: %.1f" % survive_time_left


func _on_card_gui_input(event: InputEvent, item_sprite: Node) -> void:
	if game_over:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		item_sprite.call("start_drag")


func _get_valid_bubble_offset() -> Vector2:
	var offset := Vector2.ZERO
	for _attempt in range(12):
		offset = Vector2(
			rng.randf_range(-bubble_spawn_range.x, bubble_spawn_range.x),
			rng.randf_range(-bubble_spawn_range.y, bubble_spawn_range.y)
		)
		if offset.length() >= dog_protection_radius:
			return offset

	if offset == Vector2.ZERO:
		offset = Vector2(dog_protection_radius, 0.0)
	return offset.normalized() * dog_protection_radius


func _get_bubble_timer_duration() -> float:
	var min_duration := minf(bubble_timer_min, bubble_timer_max)
	var max_duration := maxf(bubble_timer_min, bubble_timer_max)
	return rng.randf_range(min_duration, max_duration)


func _get_spawn_interval() -> float:
	var min_interval := minf(spawn_interval_min, spawn_interval_max)
	var max_interval := maxf(spawn_interval_min, spawn_interval_max)
	return rng.randf_range(min_interval, max_interval)


func _setup_dog_placeholder() -> void:
	if dog.sprite_frames == null:
		dog.sprite_frames = SpriteFrames.new()
	if not dog.sprite_frames.has_animation("idle"):
		dog.sprite_frames.add_animation("idle")
	var dog_texture := _make_solid_texture(Color(0.68, 0.56, 0.44, 1.0), Vector2i(120, 80))
	dog.sprite_frames.clear("idle")
	dog.sprite_frames.add_frame("idle", dog_texture)
	dog.animation = "idle"
	dog.centered = true


func _make_item_texture(item_type: String) -> ImageTexture:
	return _make_solid_texture(ITEM_COLORS.get(item_type, Color.WHITE), Vector2i(48, 48))


func _make_solid_texture(fill_color: Color, texture_size: Vector2i) -> ImageTexture:
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(fill_color)
	return ImageTexture.create_from_image(image)
