extends Area2D

signal bubble_expired(bubble)
signal bubble_satisfied(bubble)
signal bubble_wrong_item(bubble, dropped_item_type: String)

const ICON_COLORS := {
	"Bone": Color(0.82, 0.72, 0.56, 1.0),
	"Ball": Color(0.86, 0.22, 0.22, 1.0),
	"Food": Color(0.92, 0.52, 0.18, 1.0),
	"Toy": Color(0.58, 0.30, 0.82, 1.0),
	"Water": Color(0.24, 0.52, 0.90, 1.0),
}

@export var timer_duration: float = 4.0
@export var bubble_size: Vector2 = Vector2(180.0, 136.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bubble_sprite: Sprite2D = $BubbleSprite
@onready var item_icon: Sprite2D = $ItemIcon
@onready var timer_bar: ProgressBar = $TimerBar
@onready var seconds_label: Label = $SecondsLabel

var item_type: String = ""
var time_left: float = 0.0
var is_active: bool = false


func _ready() -> void:
	_configure_bubble_visuals()
	timer_bar.max_value = timer_duration
	timer_bar.value = timer_duration
	_update_timer_display()


func _process(delta: float) -> void:
	if not is_active:
		return

	time_left = maxf(time_left - delta, 0.0)
	_update_timer_display()
	if time_left <= 0.0:
		is_active = false
		bubble_expired.emit(self)


func set_item(type: String) -> void:
	item_type = type
	item_icon.texture = _make_placeholder_texture(ICON_COLORS.get(type, Color.WHITE), Vector2i(48, 48))


func start_timer(duration: float) -> void:
	timer_duration = duration
	time_left = duration
	is_active = true
	timer_bar.max_value = maxf(timer_duration, 0.01)
	_update_timer_display()


func try_satisfy(dropped_item_type: String) -> void:
	if not is_active:
		return

	if dropped_item_type == item_type:
		is_active = false
		bubble_satisfied.emit(self)
		return

	bubble_wrong_item.emit(self, dropped_item_type)


func stop_bubble() -> void:
	is_active = false


func contains_global_point(global_point: Vector2) -> bool:
	var half_size := bubble_size * 0.5
	var bubble_rect := Rect2(global_position - half_size, bubble_size)
	return bubble_rect.has_point(global_point)


func _configure_bubble_visuals() -> void:
	bubble_sprite.texture = _make_placeholder_texture(Color(0.96, 0.96, 0.96, 1.0), Vector2i(int(bubble_size.x), int(bubble_size.y)))
	bubble_sprite.centered = true
	item_icon.centered = true
	item_icon.position = Vector2(0.0, -18.0)
	timer_bar.position = Vector2(-68.0, 34.0)
	timer_bar.size = Vector2(136.0, 18.0)
	seconds_label.position = Vector2(-42.0, 56.0)
	seconds_label.size = Vector2(84.0, 24.0)


func _update_timer_display() -> void:
	timer_bar.value = time_left
	seconds_label.text = "%.1f s" % time_left


func _make_placeholder_texture(fill_color: Color, texture_size: Vector2i) -> ImageTexture:
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(fill_color)
	return ImageTexture.create_from_image(image)
