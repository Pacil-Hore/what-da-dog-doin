@tool
extends Node2D

## Represents the central hydrant/post object that the leash wraps around.
## The HydrantSprite child is the editable placeholder for final art.

signal state_changed(state_index: int)

@export var hydrant_texture: Texture2D = preload("res://Assets/generated/placeholder_icon.png"):
	set(value):
		hydrant_texture = value
		_refresh_sprite()

@export var state_textures: Array[Texture2D] = [
	preload("res://Assets/Sprites/untangle/hydrant_tangled.png"),
	preload("res://Assets/Sprites/untangle/hydrant_half_tangled.png"),
	preload("res://Assets/Sprites/untangle/hydrant_untangled.png"),
]
@export var state_sprite_scale := Vector2(3.0, 3.0)

@export var current_state_index := 0:
	set(value):
		current_state_index = clampi(value, 0, max(get_state_count() - 1, 0))
		_sync_state()

@export var completed_state_index := 2
@export var state_labels: Array[String] = ["A", "B", "C"]:
	set(value):
		state_labels = value
		_sync_state()
@export var visual_container_path := NodePath("Visuals")
@export var state_label_path := NodePath("StateLabel")

var _sprite: Sprite2D
var _is_ready_done := false


func _ready() -> void:
	_ensure_sprite()
	if is_instance_valid(_sprite):
		_sprite.visible = false
	_prepare_state_sprite_textures()
	_sync_state()
	_is_ready_done = true


func set_state_index(value: int) -> void:
	current_state_index = value


func advance_state() -> void:
	set_state_index(current_state_index + 1)


func is_completed() -> bool:
	return current_state_index >= completed_state_index


func get_state_count() -> int:
	var visual_container: Node = get_node_or_null(visual_container_path)
	if visual_container != null:
		return visual_container.get_child_count()
	return max(state_labels.size(), completed_state_index + 1)


func _ensure_sprite() -> void:
	_sprite = get_node_or_null("HydrantSprite") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "HydrantSprite"
		_sprite.z_index = -1
		add_child(_sprite)
		if Engine.is_editor_hint():
			_sprite.owner = get_tree().edited_scene_root


func _refresh_sprite() -> void:
	if not is_inside_tree():
		return
	_ensure_sprite()
	if is_instance_valid(_sprite):
		if hydrant_texture != null:
			_sprite.texture = hydrant_texture
		if _sprite.texture:
			var target_size := 120.0
			var tex_size := _sprite.texture.get_size()
			var s := target_size / maxf(tex_size.x, tex_size.y)
			_sprite.scale = Vector2(s, s)


func _sync_state() -> void:
	if not is_inside_tree():
		return

	_sync_visuals()
	_sync_label()
	state_changed.emit(current_state_index)


func _sync_visuals() -> void:
	var visual_container: Node = get_node_or_null(visual_container_path)
	if visual_container == null:
		return

	for index in range(visual_container.get_child_count()):
		var visual: Node = visual_container.get_child(index)
		if visual is CanvasItem:
			var was_visible = visual.visible
			visual.visible = index == current_state_index
			
			# Pop animation when state becomes active
			if _is_ready_done and not was_visible and visual.visible and not Engine.is_editor_hint():
				var state_sprite = visual.get_node_or_null("StateSprite") as Sprite2D
				if state_sprite != null:
					state_sprite.scale = state_sprite_scale * 0.85
					var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tween.tween_property(state_sprite, "scale", state_sprite_scale, 0.2)


func _prepare_state_sprite_textures() -> void:
	var visual_container: Node = get_node_or_null(visual_container_path)
	if visual_container == null:
		return

	for index in range(visual_container.get_child_count()):
		var visual := visual_container.get_child(index)
		var state_sprite := visual.get_node_or_null("StateSprite") as Sprite2D
		if state_sprite == null:
			continue

		if index < state_textures.size() and state_textures[index] != null:
			state_sprite.texture = state_textures[index]
		if state_sprite.texture == null:
			continue
		# state_sprite.texture = _make_black_transparent(state_sprite.texture)
		state_sprite.centered = true
		state_sprite.modulate = Color.WHITE
		state_sprite.scale = state_sprite_scale


func _make_black_transparent(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture

	var size := image.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var color := image.get_pixel(x, y)
			if color.r < 0.05 and color.g < 0.05 and color.b < 0.05:
				color.a = 0.0
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _sync_label() -> void:
	var state_label := get_node_or_null(state_label_path) as Label
	if state_label == null:
		return
	if current_state_index >= 0 and current_state_index < state_labels.size():
		state_label.text = state_labels[current_state_index]
	else:
		state_label.text = str(current_state_index)
