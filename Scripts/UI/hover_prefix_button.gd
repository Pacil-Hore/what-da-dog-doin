@tool
class_name HoverPrefixButton
extends Button

@export var hover_prefix: String = ">"
@export var hover_prefix_separator: String = " "
@onready var menu_move = %MenuMove

var _base_text: String = ""
var _hovered := false


func _ready() -> void:
	_base_text = _strip_prefix(text)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_update_text()


func _get_configuration_warnings() -> PackedStringArray:
	if hover_prefix.is_empty():
		return ["hover_prefix is empty, so the button text will not change on hover."]
	return PackedStringArray()


func _validate_property(property: Dictionary) -> void:
	if property.name == "text":
		_base_text = _strip_prefix(text)
		_update_text()


func _on_mouse_entered() -> void:
	menu_move.play()
	_hovered = true
	_update_text()


func _on_mouse_exited() -> void:
	_hovered = false
	_update_text()


func _on_focus_entered() -> void:
	_hovered = true
	_update_text()


func _on_focus_exited() -> void:
	_hovered = false
	_update_text()


func _update_text() -> void:
	if _hovered:
		text = "%s%s%s" % [hover_prefix, hover_prefix_separator, _base_text]
	else:
		text = _base_text


func _strip_prefix(value: String) -> String:
	var full_prefix := "%s%s" % [hover_prefix, hover_prefix_separator]
	if value.begins_with(full_prefix):
		return value.substr(full_prefix.length())
	return value
