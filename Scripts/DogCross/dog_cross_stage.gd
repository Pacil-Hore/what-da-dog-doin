extends Node2D

signal game_won
signal game_lost

@export var objective_text: String = "Cross the river!"
@export var control_icon: Texture2D
@export var win_label_text: String = "SAFE SHORE!"
@export var lose_label_text: String = "SWEPT AWAY!"
@export var timeout_wins: bool = false
@export var dog_cross_manager_path: NodePath = ^"GameManager"

var is_finished := false

@onready var dog_cross_manager: Node = get_node_or_null(dog_cross_manager_path)

func _ready() -> void:
	if dog_cross_manager == null:
		push_error("DogCrossStage: dog_cross_manager_path is not assigned.")
		return
	if dog_cross_manager.has_signal("dog_cross_won"):
		dog_cross_manager.dog_cross_won.connect(_on_level_won)
	if dog_cross_manager.has_signal("dog_cross_lost"):
		dog_cross_manager.dog_cross_lost.connect(_on_level_lost)

func _on_level_won() -> void:
	if is_finished:
		return
	is_finished = true
	game_won.emit()

func _on_level_lost() -> void:
	if is_finished:
		return
	is_finished = true
	game_lost.emit()
