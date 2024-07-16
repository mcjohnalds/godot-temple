extends Node3D
class_name Grabbable

enum Type { AMMO, GRENADE, BANDAGES, KEY }

@export var _type := Type.AMMO
var grabbed := false
@onready var _initial_transform := transform
@onready var _initial_position := position


func _process(delta: float) -> void:
	if _type == Type.KEY and not grabbed:
		rotation.y += delta * 2.0
		position.y = (
			_initial_position.y + 0.05 * sin(Util.get_ticks_sec() * TAU / 2.0)
		)


func get_type() -> Type:
	return _type


func reset() -> void:
	transform = _initial_transform
	process_mode = PROCESS_MODE_INHERIT
	visible = true


func disable() -> void:
	process_mode = PROCESS_MODE_DISABLED
	visible = false
