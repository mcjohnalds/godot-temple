extends CharacterBody3D
class_name KinematicFpsController

# TODO: combine all audio code into one bit

@export var underwater_env: Environment


@export_group("Audio")

@export var material_audios: Array[MaterialAudio]

@export var water_material_audio: MaterialAudio


@export_group("FOV")

## Speed at which the FOV changes
@export var fov_change_speed := 20.0

## FOV to be multiplied when active the crouch
@export var crouch_fov_multiplier := 0.99

## FOV multiplier applied at max speed
@export var max_speed_fov_multiplier := 1.01

@export_group("Mouse")

## Mouse Sensitivity
@export var mouse_sensitivity := 2.0

## Maximum vertical angle the head can aim
@export var vertical_angle_limit := TAU * 0.24


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
@export var quake_camera_tilt_enabled := true

## Speed at which the camera angle moves
@export var quake_camera_tilt_speed := 4.0

## Rotation angle limit per move
@export var quake_camera_tilt_angle_limit := 0.1


@export_group("Movement")

## Controller Gravity Multiplier
## The higher the number, the faster the controller will fall to the ground and 
## your jump will be shorter.
@export var gravity_multiplier := 3.0

## Controller base speed
## Note: this speed is used as a basis for abilities to multiply their 
## respective values, changing it will have consequences on [b]all abilities[/b]
## that use velocity.
@export var base_speed := 10.0

## Time for the character to reach full speed
@export var walk_acceleration := 8.0

## Time for the character to stop walking
@export var walk_deceleration := 10.0

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
var _is_flying := false
var _last_is_on_water := false
var _last_is_floating := false
var _last_is_submerged := false
var _last_is_on_floor := false
var _head_bob_cycle_position := Vector2.ZERO
var _quake_camera_tilt_ratio := 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D =  $Head/Camera3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collision.shape
@onready var _head_ray_cast: RayCast3D = $HeadRayCast
@onready var _step_audio_stream_player: AudioStreamPlayer3D = (
	$StepAudioStreamPlayer
)
@onready var _land_audio_stream_player: AudioStreamPlayer3D = (
	$LandAudioStreamPlayer
)
@onready var _jump_audio_stream_player: AudioStreamPlayer3D = (
	$JumpAudioStreamPlayer
)
@onready var _crouch_audio_stream_player: AudioStreamPlayer3D = (
	$CrouchAudioStreamPlayer
)
@onready var _uncrouch_audio_stream_player: AudioStreamPlayer3D = (
	$UncrouchAudioStreamPlayer
)
@onready var _ground_ray_cast: RayCast3D = $GroundRayCast
@onready var _swim_ray_cast: RayCast3D = $SwimRayCast
@onready var _initial_fov := _camera.fov
@onready var _initial_head_position := _head.position
@onready var _initial_capsule_height = _capsule.height


func _physics_process(delta: float) -> void:
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

	var is_on_water := _swim_ray_cast.is_colliding()

	var depth_on_water := 2.1
	if is_on_water:
		var point := _swim_ray_cast.get_collision_point()
		depth_on_water = -_swim_ray_cast.to_local(point).y

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
		_play_land_audio(is_on_water, is_landed_on_floor_this_frame)

	if is_on_water and !_last_is_on_water:
		_play_land_audio(is_on_water, is_landed_on_floor_this_frame)
	elif !is_on_water and _last_is_on_water:
		_play_jump_audio(is_on_water, is_landed_on_floor_this_frame)

	if is_floating and !_last_is_floating:
		# TODO: play started floating sound
		pass
	elif !is_floating and _last_is_floating:
		# TODO: play stopped floating sound
		pass

	if is_submerged and not _last_is_submerged:
		_camera.environment = underwater_env
	if not is_submerged and _last_is_submerged:
		_camera.environment = null

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
	if _is_flying:
		multiplier *= fly_mode_speed_modifier
	if is_submerged:
		multiplier *= submerged_speed_multiplier
	elif is_floating:
		multiplier *= on_water_speed_multiplier

	var move_speed := base_speed * multiplier

	var input_direction := _get_input_direction(
		input_horizontal, input_vertical, is_floating
	)
	_do_walking(is_walking, input_direction, move_speed, delta)
	_do_crouching(is_crouching, delta)
	_do_swimming(input_direction, is_floating, depth_on_water, move_speed)
	_do_flying(input_direction, move_speed)
	if is_jumping:
		velocity.y = jump_height
		_play_jump_audio(is_on_water, is_landed_on_floor_this_frame)
		_head_bob_cycle_position = Vector2.ZERO

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

	var is_shuffling_feet := absf(horizontal_velocity.length()) < 0.1
	var is_stepping := (
		not _is_flying
		and not is_floating
		and not is_submerged
		and not is_shuffling_feet
	)

	if is_stepping:
		_step_cycle += (horizontal_velocity.length() + step_lengthen) * delta

	var is_step_cycle_complete := _step_cycle > _next_step

	if is_landed_on_floor_this_frame or is_step_cycle_complete:
		_next_step = _step_cycle + step_interval
		_play_step_audio(is_on_water, is_landed_on_floor_this_frame)

	var max_locomotion_speed := (
		base_speed * maxf(sprint_speed_multiplier, fly_mode_speed_modifier)
	)

	# FOV adjust
	var a := velocity.length() / max_locomotion_speed
	var b := max_speed_fov_multiplier - 1.0
	var target_fov := _initial_fov * (1.0 + a * b)
	if is_crouching:
		target_fov *= crouch_fov_multiplier
	_camera.set_fov(lerp(_camera.fov, target_fov, delta * fov_change_speed))

	if quake_camera_tilt_enabled:
		var target := input_horizontal.x
		var direction := signf(target - _quake_camera_tilt_ratio)
		var new_ratio := (
			_quake_camera_tilt_ratio + quake_camera_tilt_speed * direction
		)
		var new_direction := signf(target - new_ratio)
		if new_direction != direction:
			_quake_camera_tilt_ratio = target
		else:
			_quake_camera_tilt_ratio += quake_camera_tilt_speed * direction
		_camera.rotation.z = lerp(
			-quake_camera_tilt_angle_limit,
			quake_camera_tilt_angle_limit,
			smoothstep(-1.0, 1.0, -_quake_camera_tilt_ratio)
		)

	_do_head_bobbing(horizontal_velocity, delta)

	_last_is_on_water = is_on_water
	_last_is_floating = is_floating
	_last_is_submerged = is_submerged
	_last_is_on_floor = is_on_floor()
	move_and_slide()


func _input(event: InputEvent) -> void:
	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var e: InputEventMouseMotion = event
		var s := mouse_sensitivity / 1000.0
		rotation.y -= e.relative.x * s
		_head.rotation.x = clamp(
			_head.rotation.x - e.relative.y * s,
			-vertical_angle_limit,
			vertical_angle_limit
		)
	elif event.is_action_pressed("move_crouch"):
		_crouch_audio_stream_player.play()
	elif event.is_action_released("move_crouch"):
		_uncrouch_audio_stream_player.play()


func _do_walking(
	is_walking: bool, input_direction: Vector3, move_speed: float, delta: float
):
	if not is_walking:
		return

	var horizontal_velocity := velocity
	horizontal_velocity.y = 0.0

	var is_accelerating := input_direction.dot(horizontal_velocity) > 0.0

	var a := walk_acceleration if is_accelerating else walk_deceleration
	if not is_on_floor():
		a *= air_control

	var target := input_direction * move_speed
	var w := horizontal_velocity.lerp(target, a * delta)

	velocity.x = w.x
	velocity.z = w.z


func _do_crouching(is_crouching: bool, delta: float) -> void:
	if is_crouching:
		_capsule.height -= delta * 8
	elif not _head_ray_cast.is_colliding():
		_capsule.height += delta * 8
	_capsule.height = clamp(
		_capsule.height , height_in_crouch, _initial_capsule_height
	)
	# var crouch_factor = (_initial_capsule_height - height_in_crouch) - (_capsule.height - height_in_crouch)/ (_initial_capsule_height - height_in_crouch)


func _do_swimming(
	input_direction: Vector3,
	is_floating: bool,
	depth_on_water: float,
	move_speed: float
) -> void:
	if not is_floating:
		return
	var depth := floating_height - depth_on_water
	velocity = input_direction * move_speed
#	if depth < 0.1: && !_is_flying:
	if depth < 0.1:
		# Prevent free sea movement from exceeding the water surface
		velocity.y = min(velocity.y,0)


func _do_flying(input_direction: Vector3, move_speed: float) -> void:
	if not _is_flying:
		return
	velocity = input_direction * move_speed


func _do_head_bobbing(horizontal_velocity: Vector3, delta: float):
	var new_position := _initial_head_position
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

	_camera.position = new_position


func _get_input_direction(
	input_horizontal: Vector2, input_vertical: float, is_floating: bool
) -> Vector3:
	var allow_vertical := _is_flying or is_floating
	var aim := _head if allow_vertical else self
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


func _get_material_audio_for_object(object: Object) -> MaterialAudio:
	if object.get("physics_material_override") is PhysicsMaterial:
		var material: PhysicsMaterial = object.physics_material_override
		for m in material_audios:
			if m.physics_material == material:
				return m
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
	if _ground_ray_cast.get_collider():
		return _get_material_audio_for_object(_ground_ray_cast.get_collider())
	return null


func _play_jump_audio(
	is_on_water: bool,
	is_landed_on_floor_this_frame: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		is_on_water, is_landed_on_floor_this_frame
	)
	if not material_audio:
		return
	_jump_audio_stream_player.stream = material_audio.jump_audio_stream
	_jump_audio_stream_player.play()


func _play_land_audio(
	is_on_water: bool,
	is_landed_on_floor_this_frame: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		is_on_water, is_landed_on_floor_this_frame
	)
	if not material_audio:
		return
	_land_audio_stream_player.stream = material_audio.landed_audio_stream
	_land_audio_stream_player.play()


func _play_step_audio(
	is_on_water: bool,
	is_landed_on_floor_this_frame: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		is_on_water, is_landed_on_floor_this_frame
	)
	if not material_audio:
		return
	_step_audio_stream_player.stream = (
		material_audio.step_audio_streams.pick_random()
	)
	_step_audio_stream_player.play()
