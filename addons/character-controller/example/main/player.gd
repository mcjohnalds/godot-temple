extends CharacterBody3D
class_name Player

@export var input_back_action_name := "move_backward"
@export var input_forward_action_name := "move_forward"
@export var input_left_action_name := "move_left"
@export var input_right_action_name := "move_right"
@export var input_sprint_action_name := "move_sprint"
@export var input_jump_action_name := "move_jump"
@export var input_crouch_action_name := "move_crouch"
@export var input_fly_mode_action_name := "move_fly_mode"

@export var underwater_env: Environment

@export_group("Audio")

## Default audio interact used
@export var audio_interact : Resource

## List of [PhysicsMaterial] synchronized with the [AudioInteract] list
@export var physic_materials : Array[PhysicsMaterial]

## List of [AudioInteract] synchronized with the [PhysicsMaterial] list
@export var audio_interacts : Array[Resource]

## Specific case of audio interact that occurs when we are in the water
@export var water_audio_interact : Resource

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
@export var head_bob_range = Vector2(0.07, 0.07)

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
@export var gravity_multiplier : float = 3.0

## Controller base speed
## Note: this speed is used as a basis for abilities to multiply their 
## respective values, changing it will have consequences on [b]all abilities[/b]
## that use velocity.
@export var speed : float = 10.0

## Time for the character to reach full speed
@export var acceleration : float = 8.0

## Time for the character to stop walking
@export var deceleration : float = 10.0

## Sets control in the air
@export var air_control : float = 0.3


@export_group("Sprint")

## Speed to be multiplied when active the ability
@export var sprint_speed_multiplier : float = 1.6


@export_group("Footsteps")

## Maximum counter value to be computed one step
@export var step_lengthen : float = 0.7

## Value to be added to compute a step, each frame that the character is walking this value 
## is added to a counter
@export var step_interval : float = 6.0


@export_group("Crouch")

## Collider height when crouch actived
@export var height_in_crouch : float = 1.0

## Speed multiplier when crouch is actived
@export var crouch_speed_multiplier : float = 0.7


@export_group("Jump")

## Jump/Impulse height
@export var jump_height : float = 10.0


@export_group("Fly")

## Speed multiplier when fly mode is actived
@export var fly_mode_speed_modifier : float = 2.0


@export_group("Swim")

## Minimum height for [CharacterController3D] to be completely submerged in water.
@export var submerged_height : float = 0.36

## Minimum height for [CharacterController3D] to be float in water.
@export var floating_height : float = 0.75

## Speed multiplier when floating water
@export var on_water_speed_multiplier : float = 0.75

## Speed multiplier when submerged water
@export var submerged_speed_multiplier : float = 0.5

## Result direction of inputs sent to [b]move()[/b].
var _direction := Vector3()

## Current counter used to calculate next step.
var _step_cycle : float = 0

## Maximum value for _step_cycle to compute a step.
var _next_step : float = 0

## Character controller horizontal speed.
var _horizontal_velocity : Vector3

## Base transform node to direct player movement
## Used to differentiate fly mode/swim moves from regular character movement.
var _direction_base_node : Node3D

## True if in the last frame it was on the ground
var _last_is_on_floor := false

## Default controller height, affects collider
var _default_height : float

var _is_on_water := false
var _is_floating := false
var _was_is_on_water := false
var _was_is_floating := false
var _was_is_submerged := false
var _depth_on_water := 0.0

var _is_flying := false

var _is_jumping := false

## Store original position of head for headbob reference
var original_head_position : Vector3

## Store original rotation of head for headbob reference
var original_head_rotation : Quaternion

## Actual cycle x of step headbob
var head_bob_cycle_position_x: float = 0

## Actual cycle x of step headbob
var head_bob_cycle_position_y: float = 0

## Actual rotation of movement
var actual_head_rotation := Vector3()

## [HeadMovement3D] reference, where the rotation of the camera sight is calculated
@onready var head: Node3D = get_node(NodePath("Head"))

## First Person Camera3D reference
@onready var first_person_camera_reference : Marker3D = get_node(NodePath("Head/FirstPersonCameraReference"))

## Third Person Camera3D reference
@onready var third_person_camera_reference : Marker3D = get_node(NodePath("Head/ThirdPersonCameraReference"))

## Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier)

## Collision of character controller.
@onready var collision: CollisionShape3D = get_node(NodePath("Collision"))

## Above head collision checker, used for crouching and jumping.
@onready var head_check: RayCast3D = get_node(NodePath("Head Check"))

## Stores normal speed
@onready var _normal_speed : float = speed

@onready var step_stream: AudioStreamPlayer3D = get_node(NodePath("Player Audios/Step"))
@onready var land_stream: AudioStreamPlayer3D = get_node(NodePath("Player Audios/Land"))
@onready var jump_stream: AudioStreamPlayer3D = get_node(NodePath("Player Audios/Jump"))
@onready var crouch_stream: AudioStreamPlayer3D = get_node(NodePath("Player Audios/Crouch"))
@onready var uncrouch_stream: AudioStreamPlayer3D = get_node(NodePath("Player Audios/Uncrouch"))
@onready var ground_ray_cast: RayCast3D = get_node(NodePath("Player Audios/Detect Ground"))
@onready var swim_ray_cast: RayCast3D = $SwimRayCast


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_direction_base_node = self
	_default_height = collision.shape.height
	original_head_position = first_person_camera_reference.position
	original_head_rotation = first_person_camera_reference.quaternion
	actual_head_rotation.y = rotation.y


func _physics_process(delta):
	var is_valid_input := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	if is_valid_input:
		if Input.is_action_just_pressed(input_fly_mode_action_name):
			_is_flying = not _is_flying
		var input_axis = Input.get_vector(input_left_action_name, input_right_action_name, input_back_action_name, input_forward_action_name)
		var input_jump = Input.is_action_just_pressed(input_jump_action_name)
		var input_crouch = Input.is_action_pressed(input_crouch_action_name)
		var input_sprint = Input.is_action_pressed(input_sprint_action_name)
		var input_swim_down = Input.is_action_pressed(input_crouch_action_name)
		var input_swim_up = Input.is_action_pressed(input_jump_action_name)
		move(delta, input_axis, input_jump, input_crouch, input_sprint, input_swim_down, input_swim_up)
	else:
		# NOTE: It is important to always call move() even if we have no inputs 
		## to process, as we still need to calculate gravity and collisions.
		move(delta)


func _input(event: InputEvent) -> void:
	# Mouse look (only if the mouse is captured).
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_axis: Vector2 = event.relative
		# Horizontal mouse look.
		actual_head_rotation.y -= mouse_axis.x * (mouse_sensitivity/1000)
		# Vertical mouse look.
		actual_head_rotation.x = clamp(actual_head_rotation.x - mouse_axis.y * (mouse_sensitivity/1000), -vertical_angle_limit, vertical_angle_limit)
		
		rotation.y = actual_head_rotation.y
		head.rotation.x = actual_head_rotation.x
	elif event.is_action_pressed("move_crouch"):
		crouch_stream.play()
	elif event.is_action_released("move_crouch"):
		uncrouch_stream.play()


## Call to move the character.
## First it is defined what the direction of movement will be, whether it is vertically or not 
## based on whether swim or fly mode is active.
## Afterwards, the [b]move()[/b] of the base class [CharacterMovement3D] is called
## It is then called functions responsible for head bob if necessary.
func move(delta: float, input_axis := Vector2.ZERO, input_jump := false, input_crouch := false, input_sprint := false, input_swim_down := false, input_swim_up := false):
	if _is_flying or _is_floating:
		_direction_base_node = head
	else:
		_direction_base_node = self

	var direction = _direction_input(input_axis, input_swim_down, input_swim_up, _direction_base_node)
	if not _is_floating:
		_check_landed()
	_is_on_water = swim_ray_cast.is_colliding()

	if _is_on_water:
		_depth_on_water = -swim_ray_cast.to_local(swim_ray_cast.get_collision_point()).y
	else:
		_depth_on_water = 2.1

	var is_submerged := _depth_on_water < submerged_height and _is_on_water and !_is_flying
	if not _is_jumping and not _is_flying and not is_submerged and not _is_floating:
		velocity.y -= gravity * delta

	_is_floating = _depth_on_water < floating_height and _is_on_water and !_is_flying

	if _is_on_water and !_was_is_on_water:
		audio_interact = water_audio_interact
		land_stream.stream = audio_interact.landed_audio
		land_stream.play()
	elif !_is_on_water and _was_is_on_water:
		jump_stream.stream = audio_interact.jump_audio
		jump_stream.play()

	if _is_floating and !_was_is_floating:
		# TODO: play started floating sound
		pass
	elif !_is_floating and _was_is_floating:
		# TODO: play stopped floating sound
		pass

	if is_submerged and not _was_is_submerged:
		get_viewport().get_camera_3d().environment = underwater_env
	if not is_submerged and _was_is_submerged:
		get_viewport().get_camera_3d().environment = null

	_was_is_on_water = _is_on_water
	_was_is_floating = _is_floating
	_was_is_submerged = is_submerged

	if input_jump:
		jump_stream.stream = audio_interact.jump_audio
		jump_stream.play()
		head_bob_cycle_position_x = 0
		head_bob_cycle_position_y = 0

	_is_jumping = input_jump and is_on_floor() and not head_check.is_colliding()
	var is_walking := not _is_flying and not _is_floating
	var is_crouching := input_crouch and is_on_floor() and not _is_floating and not is_submerged and not _is_flying
	var is_sprinting := input_sprint and is_on_floor() and  input_axis.y >= 0.5 and !is_crouching and not _is_flying and not _is_floating and not is_submerged

	var multiplier = 1.0
	if is_crouching:
		multiplier *= crouch_speed_multiplier
	if is_sprinting:
		multiplier *= sprint_speed_multiplier

	if is_submerged:
		multiplier *= submerged_speed_multiplier
	elif _is_floating:
		multiplier *= on_water_speed_multiplier

	speed = _normal_speed * multiplier

	_do_walking(is_walking, direction, delta)
	_do_crouching(is_crouching, delta)
	_do_swimming(direction)
	_do_flying(direction)
	_do_jumping()

	move_and_slide()
	_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)

	if not _is_flying and not _is_floating and not is_submerged:
		_check_step(delta)
#	TODO Make in exemple this
#	if not _is_flying and not _is_floating and not is_submerged
#		camera.set_fov(lerp(camera.fov, normal_fov, delta * fov_change_speed))

	_do_head_bobbing(_horizontal_velocity, input_axis, is_sprinting, delta)


func _do_walking(is_walking: bool, direction: Vector3, delta: float):
	if not is_walking:
		return

	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0

	var temp_accel: float
	var target: Vector3 = direction * speed

	if direction.dot(temp_vel) > 0:
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
	elif not head_check.is_colliding():
		collision.shape.height += delta * 8
	collision.shape.height = clamp(collision.shape.height , height_in_crouch, _default_height)
	# var crouch_factor = (_default_height - height_in_crouch) - (collision.shape.height - height_in_crouch)/ (_default_height - height_in_crouch)


func _do_swimming(direction: Vector3) -> void:
	if not _is_floating:
		return
	var depth = floating_height - _depth_on_water
	velocity = direction * speed
#	if depth < 0.1: && !_is_flying:
	if depth < 0.1:
		# Prevent free sea movement from exceeding the water surface
		velocity.y = min(velocity.y,0)


func _do_flying(direction: Vector3) -> void:
	if not _is_flying:
		return
	velocity = direction * speed


func _do_jumping() -> void:
	if _is_jumping:
		velocity.y = jump_height


func _do_head_bobbing(horizontal_velocity:Vector3, input_axis:Vector2, is_sprinting:bool, delta:float):
	var new_position = original_head_position
	var new_rotation = original_head_rotation
	if step_bob_enabled:
		var x_pos = (head_bob_curve.sample(head_bob_cycle_position_x) * head_bob_curve_multiplier.x * head_bob_range.x)
		var y_pos = (head_bob_curve.sample(head_bob_cycle_position_y) * head_bob_curve_multiplier.y * head_bob_range.y)

		var head_bob_interval := 2.0 * step_interval
		var tick_speed = (horizontal_velocity.length() * delta) / head_bob_interval
		head_bob_cycle_position_x += tick_speed
		head_bob_cycle_position_y += tick_speed * vertical_horizontal_ratio

		if(head_bob_cycle_position_x > 1):
			head_bob_cycle_position_x -= 1
		if(head_bob_cycle_position_y > 1):
			head_bob_cycle_position_y -= 1

		var headpos = Vector3(x_pos,y_pos,0)
		if is_on_floor():
			new_position += headpos

	if is_sprinting:
		input_axis *= 2
	if rotation_to_move:
		var target_rotation : Quaternion
		# target_rotation.from_euler(Vector3(input_axis.y * angle_limit_for_rotation, 0.0, -input_axis.x * angle_limit_for_rotation))
		new_rotation += lerp(first_person_camera_reference.quaternion, target_rotation, speed_rotation * delta)

	first_person_camera_reference.position = new_position
	first_person_camera_reference.quaternion = new_rotation


## Returns the speed of character controller
func get_speed() -> float:
	return speed


func _reset_step():
	_next_step = _step_cycle + step_interval


func _check_landed():
	if is_on_floor() and not _last_is_on_floor:
		_get_audio_interact()
		land_stream.stream = audio_interact.landed_audio
		land_stream.play()
		_reset_step()
	_last_is_on_floor = is_on_floor()


func _check_step(delta):
	if _is_step(_horizontal_velocity.length(), delta):
		_step()


func _direction_input(input : Vector2, input_down : bool, input_up : bool, aim_node : Node3D) -> Vector3:
	_direction = Vector3()
	var aim = aim_node.get_global_transform().basis
	if input.y >= 0.5:
		_direction -= aim.z
	if input.y <= -0.5:
		_direction += aim.z
	if input.x <= -0.5:
		_direction -= aim.x
	if input.x >= 0.5:
		_direction += aim.x
	# NOTE: For free-flying and swimming movements
	if _is_flying or _is_floating:
		if input_up:
			_direction.y += 1.0
		elif input_down:
			_direction.y -= 1.0
	else:
		_direction.y = 0
	return _direction.normalized()


func _step() -> bool:
	_reset_step()
	if(is_on_floor()):
		var collision = ground_ray_cast.get_collider()
		_get_audio_interact_of_object(collision)
		step_stream.stream = audio_interact.random_step()
		step_stream.play()
		return true
	return false


func _is_step(velocity:float, delta:float) -> bool:
	if(abs(velocity) < 0.1):
		return false
	_step_cycle = _step_cycle + ((velocity + step_lengthen) * delta)
	if(_step_cycle <= _next_step):
		return false
	return true


func _get_audio_interact():
	var k_col = get_last_slide_collision()
	var collision = k_col.get_collider(0)
	_get_audio_interact_of_object(collision)


func _get_audio_interact_of_object(collision):
	if _is_on_water:
		audio_interact = water_audio_interact
		return
	if !collision:
		return
	if not "physics_material_override" in collision:
		return
	var mat = collision.physics_material_override
	if mat:
		var i = physic_materials.rfind(mat)
		if i != -1:
			audio_interact = audio_interacts[i]
