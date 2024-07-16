extends Node3D
class_name Melee

enum State { IDLE, PREPARE, EXTEND, RETRACT }

signal hit(collision: Dictionary)
@export var attack_time := 0.4
@export var attack_range := 2.0
var allowed := true
var _state := State.IDLE
var _attack_time_remaining := 0.0


func _physics_process(delta: float) -> void:
	_attack_time_remaining -= delta
	match _state:
		State.PREPARE:
			if _attack_time_remaining <= attack_time * 0.825:
				_state = State.EXTEND
				_ray_cast()
		State.EXTEND:
			if _attack_time_remaining <= attack_time * 0.5:
				_state = State.RETRACT
		State.RETRACT:
			if _attack_time_remaining <= 0.0:
				_state = State.IDLE


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("melee") and allowed and _state == State.IDLE:
		_attack_time_remaining = attack_time
		_state = State.PREPARE


func get_state() -> State:
	return _state


func _ray_cast() -> void:
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = Global.PhysicsLayer.DEFAULT
	query.from = global_position
	var dir := global_basis.z
	query.to = global_position + dir * attack_range
	query.exclude = [Util.get_parent_collision_object_3d(self).get_rid()]
	var collision := get_world_3d().direct_space_state.intersect_ray(query)
	hit.emit(collision)
