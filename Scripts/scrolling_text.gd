extends Control

@onready var background: ColorRect = $Background

@export_group("Labels")
@export var label_texts: Array[String] = [
	"WOOF WOOF",
	"ARF",
	"BARK",
	"GUK GUK",
	"MEEEEP",
	"GOOOOOO",
]
@export var label_count: int = 12         # berapa banyak label di layar
@export var font_size: int = 48
@export var min_opacity: float = 0.15
@export var max_opacity: float = 0.4

@export_group("Movement")
@export var min_speed: float = 40.0
@export var max_speed: float = 100.0

@export_group("Variation")
@export var min_scale: float = 0.7
@export var max_scale: float = 1.3

var _viewport_size: Vector2
var _labels: Array = []  # array of {label, speed}

func _ready():
	_viewport_size = get_viewport_rect().size
	_spawn_labels()

func _spawn_labels():
	for i in range(label_count):
		var label = Label.new()
		label.text = label_texts.pick_random()
		label.add_theme_font_size_override("font_size", font_size)
		add_child(label)
		
		# Wait 1 frame biar Label hitung size-nya
		await get_tree().process_frame
		
		label.pivot_offset = label.size / 2
		label.rotation_degrees = rotation_degrees
		
		# Random properties
		var scale_val = randf_range(min_scale, max_scale)
		label.scale = Vector2(scale_val, scale_val)
		
		var opacity = randf_range(min_opacity, max_opacity)
		label.modulate.a = opacity
		
		var speed = randf_range(min_speed, max_speed)
		
		# Random posisi awal
		_randomize_label_position(label, true)
		
		_labels.append({"node": label, "speed": speed})

func _randomize_label_position(label: Label, initial_spawn: bool = false):
	# X random di sepanjang lebar layar
	var x_pos = randf_range(0, _viewport_size.x - label.size.y)
	
	# Y: kalau initial spawn, random di sepanjang layar (biar gak kosong di awal)
	# Kalau respawn (udah lewat atas), spawn dari bawah
	var y_pos: float
	if initial_spawn:
		y_pos = randf_range(0, _viewport_size.y * 2)  # spread di & bawah layar
	else:
		y_pos = _viewport_size.y + randf_range(0, 200)  # spawn dari bawah
	
	label.position = Vector2(x_pos, y_pos)

func _process(delta):
	for entry in _labels:
		var label = entry["node"]
		var speed = entry["speed"]
		
		# Gerak ke atas
		label.position.y -= speed * delta
		
		# Cek udah lewat atas layar
		# Setelah rotate 90°, panjang visual = label.size.x * scale
		var visual_length = label.size.x * label.scale.x
		if label.position.y + visual_length < -100:
			# Reset ke bawah dengan posisi & teks baru
			label.text = label_texts.pick_random()
			await get_tree().process_frame  # tunggu size update
			label.pivot_offset = label.size / 2
			
			# Random opacity & speed baru
			label.modulate.a = randf_range(min_opacity, max_opacity)
			entry["speed"] = randf_range(min_speed, max_speed)
			
			# Random scale baru
			var new_scale = randf_range(min_scale, max_scale)
			label.scale = Vector2(new_scale, new_scale)
			
			_randomize_label_position(label, false)
