extends Control
class_name CustomHSlider

signal drag_ended


@export var value: float:
	get:
		return _slider.value
	set(value):
		_slider.value = value


@onready var _slider: HSlider = %Slider
@onready var _hover: Control = %Hover


func _ready() -> void:
	_slider.drag_ended.connect(_on_drag_ended)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_drag_ended(_value_changed: bool) -> void:
	drag_ended.emit()


func _on_mouse_entered() -> void:
	_hover.visible = true


func _on_mouse_exited() -> void:
	_hover.visible = false
