extends CanvasLayer

func setup(objective_text: String):
	$Control/VBoxContainer/ObjectiveLabel.text = objective_text
	
	# Wait for a split second (0.8 scaled seconds)
	await get_tree().create_timer(0.8, false).timeout
	queue_free()
