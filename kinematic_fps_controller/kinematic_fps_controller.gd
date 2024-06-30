extends CharacterBody3D
class_name KinematicFpsController

# TODO: combine all audio code into one bit

@export var underwater_env: Environment

@export_group("Audio")

@export var material_audios: Array[MaterialAudio]

@export var water_material_audio: MaterialAudio

@export_group("FOV")

## Speed at which the FOV changes
@export var fov_change_speed := 4

## FOV to be multiplied when active the sprint
@export var sprint_fov_multiplier := 1.1

## FOV to be multiplied when active the crouch
@export var crouch_fov_multiplier := 0.95

## FOV to be multiplied when active the swim
@export var swim_fov_multiplier := 1.0


@export_group("Mouse")

## Mouse Sensitivity
@export var mouse_sensitivity := 2.0

## Maximum vertical angle the head can aim
@export var vertical_angle_limit := TAU / 4.0


@export_group("Head Bob - Steps")

## Enables bob for made steps
@export var step_bob_enabled := true

## Difference of step bob movement between vertical and horizontal angle
@export var vertical_horizontal_ratio = 2

@export var head_bob_curve : Curve

@export var head_bob_curve_multiplier := Vector2(2,2)

## Maximum range value of headbob
@export var head_bob_range := Vector2(0.07, 0.07)

@export_group("Head Bob - Jump")

## Enables bob for made jumps
@export var jump_bob_enabled := true

@export_group("Head Bob - Rotation When Move (Quake Like)")

## Enables camera angle for the direction the character controller moves
@export var rotation_to_move := true

## Speed at which the camera angle moves
@export var speed_rotation := 4.0

## Rotation angle limit per move
@export var angle_limit_for_rotation := 0.1


@export_group("Movement")

## Controller Gravity Multiplier
## The higher the number, the faster the controller will fall to the ground and 
## your jump will be shorter.
@export var gravity_multiplier := 3.0

## Controller base speed
## Note: this speed is used as a basis for abilities to multiply their 
## respective values, changing it will have consequences on [b]all abilities[/b]
## that use velocity.
@export var speed := 10.0

## Time for the character to reach full speed
@export var acceleration := 8.0

## Time for the character to stop walking
@export var deceleration := 10.0

## Sets control in the air
@export var air_control := 0.3


@export_group("Sprint")

## Speed to be multiplied when active the ability
@export var sprint_speed_multiplier := 1.6


@export_group("Footsteps")

## Maximum counter value to be computed one step
@export var step_lengthen := 0.7

## Value to be added to compute a step, each frame that the character is walking this value 
## is added to a counter
@export var step_interval := 6.0


@export_group("Crouch")

## Collider height when crouch actived
@export var height_in_crouch := 1.0

## Speed multiplier when crouch is actived
@export var crouch_speed_multiplier := 0.7


@export_group("Jump")

## Jump/Impulse height
@export var jump_height := 10.0


@export_group("Fly")

## Speed multiplier when fly mode is actived
@export var fly_mode_speed_modifier := 2.0


@export_group("Swim")

## Minimum height for [CharacterController3D] to be completely submerged in water.
@export var submerged_height := 0.36

## Minimum height for [CharacterController3D] to be float in water.
@export var floating_height := 0.75

## Speed multiplier when floating water
@export var on_water_speed_multiplier := 0.75

## Speed multiplier when submerged water
@export var submerged_speed_multiplier := 0.5

var _step_cycle := 0.0
var _next_step := 0.0
var _initial_capsule_height: float
var _is_flying := false
var _last_is_on_water := false
var _last_is_floating := false
var _last_is_submerged := false
var _last_is_on_floor := false
var _initial_head_position: Vector3
var _initial_head_rotation: Quaternion
var _head_bob_cycle_position := Vector2.ZERO
var _aim_rotation := Vector3()

## [HeadMovement3D] reference, where the rotation of the camera sight is calculated
@onready var head: Node3D = $Head

## First Person Camera3D reference
@onready var first_person_camera_reference: Node3D = (
	$Head/FirstPersonCameraReference
)

## Third Person Camera3D reference
@onready var third_person_camera_reference: Node3D = (
	$Head/ThirdPersonCameraReference
)

## Collision of character controller.
@onready var collision: CollisionShape3D = $Collision

## Above head collision checker, used for crouching and jumping.
@onready var _head_ray_cast: RayCast3D = $HeadRayCast

## Stores normal speed
@onready var _normal_speed := speed

@onready var step_audio_stream_player: AudioStreamPlayer3D = (
	$StepAudioStreamPlayer
)
@onready var land_audio_stream_player: AudioStreamPlayer3D = (
	$LandAudioStreamPlayer
)
@onready var jump_audio_stream_player: AudioStreamPlayer3D = (
	$JumpAudioStreamPlayer
)
@onready var crouch_audio_stream_player: AudioStreamPlayer3D = (
	$CrouchAudioStreamPlayer
)
@onready var uncrouch_audio_stream_player: AudioStreamPlayer3D = (
	$UncrouchAudioStreamPlayer
)
@onready var ground_ray_cast: RayCast3D = $GroundRayCast
@onready var swim_ray_cast: RayCast3D = $SwimRayCast


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_initial_capsule_height = collision.shape.height
	_initial_head_position = first_person_camera_reference.position
	_initial_head_rotation = first_person_camera_reference.quaternion
	_aim_rotation.y = rotation.y


func _physics_process(delta):
	var input_horizontal := Vector2.ZERO
	var input_vertical := 0.0
	var input_jump := false
	var input_crouch := false
	var input_sprint := false
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_just_pressed("move_fly_mode"):
			_is_flying = not _is_flying
		input_horizontal = Input.get_vector(
			"move_left", "move_right", "move_backward", "move_forward"
		)
		input_vertical = Input.get_axis("move_crouch", "move_jump")
		input_jump = Input.is_action_just_pressed("move_jump")
		input_crouch = Input.is_action_pressed("move_crouch")
		input_sprint = Input.is_action_pressed("move_sprint")

	var is_on_water := swim_ray_cast.is_colliding()

	var depth_on_water := 2.1
	if is_on_water:
		var point := swim_ray_cast.get_collision_point()
		depth_on_water = -swim_ray_cast.to_local(point).y

	var is_jumping := (
		input_jump and is_on_floor() and not _head_ray_cast.is_colliding()
	)

	var is_submerged := (
		depth_on_water < submerged_height and is_on_water and !_is_flying
	)

	var is_floating := (
		depth_on_water < floating_height and is_on_water and !_is_flying
	)

	var is_gravity_applied := (
		not is_jumping
		and not _is_flying
		and not is_submerged
		and not is_floating
	)
	if is_gravity_applied:
		velocity.y -= Util.get_default_gravity() * gravity_multiplier * delta

	var is_landed_on_floor_this_frame := (
		not is_floating and is_on_floor() and not _last_is_on_floor
	)

	if is_landed_on_floor_this_frame:
		land_audio_stream_player.stream = _get_current_material_audio(
			is_on_water, is_landed_on_floor_this_frame
		).landed_audio_stream
		land_audio_stream_player.play()
		_reset_step()

	if is_on_water and !_last_is_on_water:
		land_audio_stream_player.stream = _get_current_material_audio(is_on_water, is_landed_on_floor_this_frame).landed_audio_stream
		land_audio_stream_player.play()
	elif !is_on_water and _last_is_on_water:
		jump_audio_stream_player.stream = _get_current_material_audio(is_on_water, is_landed_on_floor_this_frame).jump_audio_stream
		jump_audio_stream_player.play()

	if is_floating and !_last_is_floating:
		# TODO: play started floating sound
		pass
	elif !is_floating and _last_is_floating:
		# TODO: play stopped floating sound
		pass

	if is_submerged and not _last_is_submerged:
		get_viewport().get_camera_3d().environment = underwater_env
	if not is_submerged and _last_is_submerged:
		get_viewport().get_camera_3d().environment = null

	if is_jumping:
		jump_audio_stream_player.stream = _get_current_material_audio(is_on_water, is_landed_on_floor_this_frame).jump_audio_stream
		jump_audio_stream_player.play()
		_head_bob_cycle_position = Vector2.ZERO

	var is_walking := not _is_flying and not is_floating

	var is_crouching := (
		input_crouch
		and is_on_floor()
		and not is_floating
		and not is_submerged
		and not _is_flying
	)

	var is_sprinting := (
		input_sprint
		and is_on_floor()
		and  input_horizontal.y >= 0.5
		and !is_crouching
		and not _is_flying
		and not is_floating
		and not is_submerged
	)

	var multiplier := 1.0
	if is_crouching:
		multiplier *= crouch_speed_multiplier
	if is_sprinting:
		multiplier *= sprint_speed_multiplier

	if is_submerged:
		multiplier *= submerged_speed_multiplier
	elif is_floating:
		multiplier *= on_water_speed_multiplier

	speed = _normal_speed * multiplier

	var input_direction := _get_input_direction(
		input_horizontal, input_vertical, is_floating
	)
	_do_walking(is_walking, input_direction, delta)
	_do_crouching(is_crouching, delta)
	_do_swimming(input_direction, is_floating, depth_on_water)
	_do_flying(input_direction)
	if is_jumping:
		velocity.y = jump_height

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	if not _is_flying and not is_floating and not is_submerged:
		if _is_step(horizontal_velocity.length(), delta):
			_reset_step()
			if(is_on_floor()):
				step_audio_stream_player.stream = (
					_get_current_material_audio(is_on_water, is_landed_on_floor_this_frame)
						.step_audio_streams.pick_random()
				)
				step_audio_stream_player.play()
#	TODO Make in exemple this
#	if not _is_flying and not is_floating and not is_submerged
#		camera.set_fov(lerp(camera.fov, normal_fov, delta * fov_change_speed))

	_do_head_bobbing(horizontal_velocity, input_horizontal, is_sprinting, delta)

	_last_is_on_water = is_on_water
	_last_is_floating = is_floating
	_last_is_submerged = is_submerged
	_last_is_on_floor = is_on_floor()
	move_and_slide()


func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_axis: Vector2 = event.relative
		# Horizontal mouse look.
		_aim_rotation.y -= mouse_axis.x * (mouse_sensitivity/1000)
		# Vertical mouse look.
		_aim_rotation.x = clamp(_aim_rotation.x - mouse_axis.y * (mouse_sensitivity/1000), -vertical_angle_limit, vertical_angle_limit)
		
		rotation.y = _aim_rotation.y
		head.rotation.x = _aim_rotation.x
	elif event.is_action_pressed("move_crouch"):
		crouch_audio_stream_player.play()
	elif event.is_action_released("move_crouch"):
		uncrouch_audio_stream_player.play()


func _do_walking(is_walking: bool, input_direction: Vector3, delta: float):
	if not is_walking:
		return

	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0

	var temp_accel: float
	var target: Vector3 = input_direction * speed

	if input_direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration

	if not is_on_floor():
		temp_accel *= air_control

	temp_vel = temp_vel.lerp(target, temp_accel * delta)

	velocity.x = temp_vel.x
	velocity.z = temp_vel.z


func _do_crouching(is_crouching: bool, delta: float) -> void:
	if is_crouching:
		collision.shape.height -= delta * 8
	elif not _head_ray_cast.is_colliding():
		collision.shape.height += delta * 8
	collision.shape.height = clamp(collision.shape.height , height_in_crouch, _initial_capsule_height)
	# var crouch_factor = (_initial_capsule_height - height_in_crouch) - (collision.shape.height - height_in_crouch)/ (_initial_capsule_height - height_in_crouch)


func _do_swimming(input_direction: Vector3, is_floating: bool, depth_on_water: float) -> void:
	if not is_floating:
		return
	var depth := floating_height - depth_on_water
	velocity = input_direction * speed
#	if depth < 0.1: && !_is_flying:
	if depth < 0.1:
		# Prevent free sea movement from exceeding the water surface
		velocity.y = min(velocity.y,0)


func _do_flying(input_direction: Vector3) -> void:
	if not _is_flying:
		return
	velocity = input_direction * speed


func _do_head_bobbing(
	horizontal_velocity: Vector3,
	input_horizontal: Vector2,
	is_sprinting: bool,
	delta: float
):
	var new_position := _initial_head_position
	var new_rotation := _initial_head_rotation
	if step_bob_enabled:
		var x_pos := (
			head_bob_curve.sample(_head_bob_cycle_position.x)
			* head_bob_curve_multiplier.x
			* head_bob_range.x
		)
		var y_pos := (
			head_bob_curve.sample(_head_bob_cycle_position.y)
			* head_bob_curve_multiplier.y
			* head_bob_range.y
		)

		var head_bob_interval := 2.0 * step_interval
		var tick_speed = (horizontal_velocity.length() * delta) / head_bob_interval
		_head_bob_cycle_position.x += tick_speed
		_head_bob_cycle_position.y += tick_speed * vertical_horizontal_ratio

		if _head_bob_cycle_position.x > 1.0:
			_head_bob_cycle_position.x -= 1.0
		if _head_bob_cycle_position.y > 1.0:
			_head_bob_cycle_position.y -= 1.0

		if is_on_floor():
			new_position += Vector3(x_pos, y_pos, 0.0)

	if is_sprinting:
		input_horizontal *= 2.0
	if rotation_to_move:
		var target_rotation : Quaternion
		# target_rotation.from_euler(Vector3(input_horizontal.y * angle_limit_for_rotation, 0.0, -input_horizontal.x * angle_limit_for_rotation))
		new_rotation += lerp(first_person_camera_reference.quaternion, target_rotation, speed_rotation * delta)

	first_person_camera_reference.position = new_position
	first_person_camera_reference.quaternion = new_rotation


## Returns the speed of character controller
func get_speed() -> float:
	return speed


func _reset_step():
	_next_step = _step_cycle + step_interval


func _get_input_direction(
	input_horizontal: Vector2, input_vertical: float, is_floating: bool
) -> Vector3:
	var allow_vertical := _is_flying or is_floating
	var aim := head if allow_vertical else self
	var input_direction := Vector3.ZERO
	if input_horizontal.y >= 0.5:
		input_direction -= aim.global_basis.z
	if input_horizontal.y <= -0.5:
		input_direction += aim.global_basis.z
	if input_horizontal.x <= -0.5:
		input_direction -= aim.global_basis.x
	if input_horizontal.x >= 0.5:
		input_direction += aim.global_basis.x
	if allow_vertical:
		input_direction.y += input_vertical
	return input_direction.normalized()


func _is_step(velocity:float, delta:float) -> bool:
	if(abs(velocity) < 0.1):
		return false
	_step_cycle = _step_cycle + ((velocity + step_lengthen) * delta)
	if(_step_cycle <= _next_step):
		return false
	return true


func _get_material_audio_for_material(
	material: PhysicsMaterial
) -> MaterialAudio:
	for m in material_audios:
		if m.physics_material == material:
			return m
	return null


func _get_material_audio_for_object(object: Object) -> MaterialAudio:
	if object.get("physics_material_override") is PhysicsMaterial:
		var mat: PhysicsMaterial = object.physics_material_override
		return _get_material_audio_for_material(mat)
	return null


func _get_current_material_audio(
	is_on_water: bool,
	is_landed_on_floor_this_frame: bool
) -> MaterialAudio:
	if is_on_water:
		return water_material_audio
	if is_landed_on_floor_this_frame:
		var k_col = get_last_slide_collision()
		return _get_material_audio_for_object(k_col.get_collider(0))
	if ground_ray_cast.get_collider():
		return _get_material_audio_for_object(ground_ray_cast.get_collider())
	return material_audios[0]
