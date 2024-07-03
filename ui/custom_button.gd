@tool
extends Control
class_name CustomButton

signal button_down


@export var text := "":
	set(value):
		text = value
		_update()


@export var checkbox := false:
	set(value):
		checkbox = value
		_update()


@export var checked := false:
	set(value):
		checked = value
		_update()


@export var chevron := false:
	set(value):
		chevron = value
		_update()


@onready var _label: Label = %Label
@onready var _checkbox: Control = %Checkbox
@onready var _check: Control = %Check
@onready var _chevron: Control = %Chevron
@onready var _hover: Control = %Hover


func _ready() -> void:
	_update()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.pressed:
			button_down.emit()
			accept_event()


func _update() -> void:
	if not is_node_ready():
		await ready
	_label.text = text
	_checkbox.visible = checkbox
	_check.visible = checked
	_chevron.visible = chevron


func _on_mouse_entered() -> void:
	_hover.visible = true


func _on_mouse_exited() -> void:
	_hover.visible = false
