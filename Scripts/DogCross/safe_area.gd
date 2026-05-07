extends Area2D
class_name SafeArea

func _ready() -> void:
	add_to_group("safe_area")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D:
		body.is_on_safe_area = true

func _on_body_exited(body):
	if body is CharacterBody2D:
		body.is_on_safe_area = false
