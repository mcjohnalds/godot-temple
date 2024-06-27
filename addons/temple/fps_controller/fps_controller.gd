@tool
class_name FpsController
extends RigidBody3D


@export var ground_clearance: float = 0.3:
	set(value):
		ground_clearance = value
		if not is_node_ready():
			return
		_update()


@export var height: float = 1.7:
	set(value):
		height = value
		if not is_node_ready():
			return
		_update()


@export var radius: float = 0.6:
	set(value):
		radius = value
		if not is_node_ready():
			return
		_update()


var _last_force_error: float
var _last_upright_torque_error: Vector3
var _last_yaw_torque_error: Vector3
@onready var collision_shape: CollisionShape3D = $CollisionShape
@onready var debug_capsule: MeshInstance3D = $DebugCapsule
@onready var camera: Camera3D = $Camera3D
@onready var camera_anchor: Node3D = $CameraAnchor


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	await get_tree().create_timer(0.1).timeout


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var is_on_ground := _physics_process_force_pid(delta)
	_physics_process_walking(is_on_ground)
	_physics_process_upright_torque_pid(delta)
	_physics_process_yaw_torque_pid(delta)
	camera.global_position = camera_anchor.global_position


func _physics_process_force_pid(delta: float) -> bool:
	var query := PhysicsRayQueryParameters3D.new()
	var offset := 0.1
	query.from = global_position + Vector3(0.0, ground_clearance + offset, 0.0)
	query.to = global_position - 10.0 * Vector3(0.0, ground_clearance, 0.0)
	query.exclude = [self.get_rid()]
	var collision := get_world_3d().direct_space_state.intersect_ray(query)

	var distance := 10.0
	if collision:
		var point: Vector3 = collision.position
		distance = query.from.distance_to(point) - offset

	var error := ground_clearance - distance
	var error_delta := (error - _last_force_error) / delta
	var kp := 8000.0
	var max_force := 8000.0
	var td := 0.1
	var up_force := minf(kp * (error + td * error_delta), max_force)
	var is_on_ground := error > 0.0
	if is_on_ground:
		apply_central_force(Vector3.UP * up_force)
	_last_force_error = error
	return is_on_ground


func _physics_process_walking(is_on_ground: bool) -> void:
	if not is_on_ground:
		return

	var camera_space_input := Input.get_vector(
		"move_right",
		"move_left",
		"move_backward",
		"move_forward"
	)

	var global_space_input := (
		Vector3(camera_space_input.x, 0.0, camera_space_input.y)
			.rotated(Vector3.UP, camera.rotation.y + TAU / 2.0)
	)

	var global_space_friction := -Vector3(
		linear_velocity.x, 0.0, linear_velocity.z
	) * 1600.0

	var is_walking := camera_space_input.length() > 0.0
	var force: Vector3
	if is_walking:
		var walk_space := Basis.looking_at(
			global_space_input, Vector3.UP, true
		)
		var walk_space_vel := walk_space.transposed() * linear_velocity
		var walk_space_friction := (
			walk_space.transposed() * global_space_friction
		)
		var walk_force := (
			global_space_input.length() * 3000.0 if walk_space_vel.z < 6.0
			else walk_space_friction.z * 0.1
		)
		var walk_space_force := Vector3(
			walk_space_friction.x,
			0.0,
			maxf(walk_space_friction.z, walk_force)
		)
		force = walk_space * walk_space_force
	else:
		force = global_space_friction

	apply_central_force(force)


func _physics_process_upright_torque_pid(delta: float) -> void:
	var target := Vector3.MODEL_TOP
	var current := global_basis.y
	var error := current.cross(target)
	var kp := 1000.0
	var td := 0.2
	var error_delta := (error - _last_upright_torque_error) / delta
	var torque := kp * (error + td * error_delta)
	apply_torque(torque)
	_last_upright_torque_error = error


func _physics_process_yaw_torque_pid(delta: float) -> void:
	var target := -Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z).normalized()
	var current := Vector3(global_basis.z.x, 0.0, global_basis.z.z).normalized()
	var error := current.cross(target)
	var kp := 1000.0
	var td := 0.5
	var error_delta := (error - _last_yaw_torque_error) / delta
	var torque := kp * (error + td * error_delta)
	apply_torque(torque)
	_last_yaw_torque_error = error


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion 
	if motion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_sensitivity := 0.002
		var m := 0.9 * TAU / 4.0
		var rx := camera.rotation.x - motion.relative.y * mouse_sensitivity
		var ry := camera.rotation.y - motion.relative.x * mouse_sensitivity
		camera.rotation.x = clamp(rx, -m, m)
		camera.rotation.y = ry


func _update() -> void:
	var capsule: CapsuleShape3D = collision_shape.shape
	capsule.radius = radius
	capsule.height = height - ground_clearance
	collision_shape.position = Vector3(
		0.0, ground_clearance + capsule.height / 2.0, 0.0
	)
	debug_capsule.position = collision_shape.position
	var capsule_mesh: CapsuleMesh = debug_capsule.mesh
	capsule_mesh.radius = radius
	capsule_mesh.height = capsule.height
	debug_capsule.position = collision_shape.position
