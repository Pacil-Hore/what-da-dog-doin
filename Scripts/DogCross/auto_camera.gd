extends Camera2D

@export var scroll_speed: float = 30.0  # pixel per detik, ke atas
@export var auto_scroll: bool = true

# Kalau mau pakai mode follow + auto-scroll combined:
@export var follow_target: Node2D  # entity terdepan (player atau dog)
@export var follow_offset: Vector2 = Vector2(0, -200)  # offset dari target
@export var follow_smoothness: float = 5.0

# Track posisi terjauh (kamera gak pernah mundur)
var furthest_y: float

# Reference ke entity buat detect "ketinggalan"
@export var entity_a: CharacterBody2D
@export var entity_b: CharacterBody2D
@export var bottom_kill_offset: float = 500.0  # jarak dari bottom screen sebelum mati

func _ready():
	furthest_y = global_position.y

func _process(delta):
	if not auto_scroll:
		return
	
	# Auto-scroll ke atas (Y berkurang)
	global_position.y -= scroll_speed * delta
	furthest_y = global_position.y
	
	# Optional: kalau ada follow_target dan dia maju lebih jauh, kamera ikut maju
	if follow_target:
		var target_y = follow_target.global_position.y + follow_offset.y
		if target_y < furthest_y:
			# Smooth catch up
			global_position.y = lerp(global_position.y, target_y, follow_smoothness * delta)
			furthest_y = global_position.y
	
	# Cek entity ketinggalan (di luar bawah kamera)
	_check_entity_left_behind()

func _check_entity_left_behind():
	var bottom_threshold = global_position.y + bottom_kill_offset
	
	if entity_a and entity_a.is_alive:
		if entity_a.global_position.y > bottom_threshold:
			entity_a.fall_in_water()
	
	if entity_b and entity_b.is_alive:
		if entity_b.global_position.y > bottom_threshold:
			entity_b.fall_in_water()
