extends Node
class_name Game

signal restarted

var _paused := false
@onready var _container: Node3D = $Container
@onready var _menu: Menu = $Menu


func _ready() -> void:
	_menu.resumed.connect(_unpause)
	_menu.restarted.connect(restarted.emit)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _paused:
			_unpause()
		else:
			_pause()


func _pause() -> void:
	_paused = true
	_container.process_mode = Node.PROCESS_MODE_DISABLED
	_menu.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unpause() -> void:
	_paused = false
	_container.process_mode = Node.PROCESS_MODE_INHERIT
	_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
