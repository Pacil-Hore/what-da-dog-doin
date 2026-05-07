extends Control

@export var cutscene_title: String = "Cutscene"
@export var cutscene_body: String = "..."

@onready var title_label: Label = $VBox/TitleLabel
@onready var body_label: Label = $VBox/BodyLabel

func _ready():
	title_label.text = cutscene_title
	body_label.text = cutscene_body
	$VBox/ContinueButton.pressed.connect(_on_continue)

func _on_continue():
	AppManager.story_cutscene_done()
