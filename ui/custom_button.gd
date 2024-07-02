@tool
extends Control
class_name CustomButton

signal button_down


@export var text := "":
	set(value):
		text = value
		_update()


@onready var _label: Label = %Label


func _ready() -> void:
	_update()


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.pressed:
			button_down.emit()


func _update() -> void:
	if not is_node_ready():
		await ready
	_label.text = text
