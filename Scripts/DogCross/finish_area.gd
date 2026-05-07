# FinishArea.gd
extends SafeArea
class_name FinishArea

signal level_completed

var entities_arrived: Array[CharacterBody2D] = []

func _on_body_entered(body):
	super._on_body_entered(body)
	if body is CharacterBody2D and body not in entities_arrived:
		entities_arrived.append(body)
		# Menang kalau player & dog dua-duanya udah sampe
		if entities_arrived.size() >= 2:
			level_completed.emit()
