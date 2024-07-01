@tool
extends Control
class_name Menu

signal started
signal resumed
signal restarted


@export var start_button_visible := true:
	set(value):
		start_button_visible = value
		if not is_node_ready():
			await ready
		_start_button.visible = value


@export var resume_button_visible := true:
	set(value):
		resume_button_visible = value
		if not is_node_ready():
			await ready
		_resume_button.visible = value


@export var restart_button_visible := true:
	set(value):
		restart_button_visible = value
		if not is_node_ready():
			await ready
		_restart_button.visible = value


@onready var _start_button: Button = %StartButton
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_start_button.button_down.connect(started.emit)
	_resume_button.button_down.connect(resumed.emit)
	_restart_button.button_down.connect(restarted.emit)
	_quit_button.button_down.connect(_on_quit_button_pressed)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
