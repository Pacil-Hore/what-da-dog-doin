extends CharacterBody2D

@export var move_action: String = "ui_left"
@export var step_distance: float = 162.0
@export var hop_duration: float = 0.15

# Offset untuk rope attachment
@export var hand_offset_idle: Vector2 = Vector2(0, -10)
@export var hand_offset_forward: Vector2 = Vector2(0, -15)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# State
var is_moving: bool = false
var current_platform = null
var is_on_safe_area: bool = false
var is_alive: bool = true

# Variable buat rope offset (di-tween bareng hop)
var rope_offset: Vector2 = Vector2(0, -10)

signal fell_in_water

func _ready():
	rope_offset = hand_offset_idle

func _input(event):
	if not is_alive or is_moving:
		return
	if event.is_action_pressed(move_action):
		try_hop_forward()

func try_hop_forward():
	var target_pos = global_position
	target_pos.y -= step_distance
	
	if current_platform:
		current_platform.remove_occupant(self)
		current_platform = null
	
	# Play animasi (gak perlu await — biarin jalan parallel)
	if anim and anim.sprite_frames.has_animation("jump"):
		anim.play("jump")
	
	hop_to(target_pos)

func _process(_delta):
	print("rope_offset: ", rope_offset, " | is_moving: ", is_moving)
	
func hop_to(target: Vector2):
	is_moving = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Tween position
	tween.tween_property(self, "global_position", target, hop_duration)
	
	# Tween rope_offset (idle → forward → idle)
	tween.tween_property(self, "rope_offset", hand_offset_forward, hop_duration / 2)
	tween.chain().tween_property(self, "rope_offset", hand_offset_idle, hop_duration / 2)
	
	tween.chain().tween_callback(_on_hop_finished)

func _on_hop_finished():
	is_moving = false
	
	# Balik ke animation idle (kalau ada)
	if anim and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	
	await get_tree().process_frame
	if current_platform == null and not is_on_safe_area:
		fall_in_water()

func fall_in_water():
	if not is_alive:
		return
	is_alive = false
	fell_in_water.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 0.5)
