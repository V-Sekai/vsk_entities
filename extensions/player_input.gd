extends Node

const controller_helpers_const = preload("res://addons/actor/controller_helpers.gd")

const SNAP_INTERPOLATION_RATE: float = 10.0
const ROTATION_SCALE: float = 1.0

export (NodePath) var _camera_controller_node_path: NodePath = NodePath()
onready var _camera_controller_node: Spatial = get_node_or_null(_camera_controller_node_path)

export (bool) var use_head_accumulator: bool = true
export (float) var camera_height: float = 1.8

var vr_locomotion_component: Node = null

var lock_pitch: bool = false

var input_direction: Vector3 = Vector3()
var input_magnitude: float = 0.0

var snap_turns: int = 0
# Used to provide representation interpolation for snapping
var rotation_yaw_snap_offset: float = 0.0 # radians

# Head offset
var xr_camera: ARVRCamera = null
var head_offset_accumulator: Vector3 = Vector3()
var xr_camera_previous: Vector3 = Vector3()
var xr_camera_current: Vector3 = Vector3()

func _ready():
	if !Engine.is_editor_hint() and is_network_master():
		if VRManager.xr_origin:
			vr_locomotion_component = VRManager.xr_origin.get_component_by_name("LocomotionComponent")
		else:
			printerr("Could not access xr_origin!")

func update_movement_input(p_target_basis: Basis) -> void:
	var horizontal_movement: float = 0.0
	var vertical_movement: float = 0.0
	if ! (
		VRManager.is_xr_active()
		and ! VRManager.vr_user_preferences.movement_type == VRManager.vr_user_preferences.movement_type_enum.MOVEMENT_TYPE_LOCOMOTION
	):
		horizontal_movement = clamp(
			InputManager.axes_values["move_horizontal"], -1.0, 1.0
		)
		vertical_movement = clamp(
			InputManager.axes_values["move_vertical"], -1.0, 1.0
		)
		
	input_direction = p_target_basis.x * horizontal_movement + p_target_basis.z * vertical_movement
	input_magnitude = clamp(Vector2(horizontal_movement, vertical_movement).length_squared(), 0.0, 1.0)


func update_vr_camera_state():
	if VRManager.is_xr_active():
		lock_pitch = true
	else:
		lock_pitch = false
	_camera_controller_node.camera_height = camera_height


func reset_offset() -> void:
	ARVRServer.center_on_hmd(ARVRServer.RESET_BUT_KEEP_TILT, true)
	if VRManager.xr_origin:
		VRManager.xr_origin.transform.origin = Vector3()
	xr_camera_previous = Vector3()
	xr_camera_current = Vector3()


# Return the origin offset translated by the entity orientation
func transform_origin_offset(p_offset: Vector3) -> Vector3:
	var camera_yaw_basis: Basis = Basis(
		Vector3(0.0, _camera_controller_node.transform.basis.get_euler().y, 0.0)
	)
	var offset_accumulator_transformed: Vector3 = (
		(camera_yaw_basis.z * Vector3(p_offset.z, 0.0, p_offset.z))
		+ (camera_yaw_basis.x * Vector3(p_offset.x, 0.0, p_offset.x))
	)

	return offset_accumulator_transformed


func clear_head_accumulator() -> void:
	head_offset_accumulator = Vector3()


func get_head_accumulator() -> Vector3:
	if use_head_accumulator:
		return head_offset_accumulator
	else:
		return Vector3()


func update_origin(p_offset: Vector3):
	_camera_controller_node.update_origin(p_offset)


func _update_head_accumulation() -> void:
	if VRManager.xr_origin and xr_camera:
		xr_camera_previous = xr_camera_current
		xr_camera_current = xr_camera.transform.origin
		var headset_accumulation: Vector3 = xr_camera_current - xr_camera_previous
		head_offset_accumulator += Vector3(headset_accumulation.x, 0.0, headset_accumulation.z)

func _process_snap_turning() -> void:
	var snap_turning_radians: float = VRManager.snap_turning_radians
	
	var snap_radians: float = snap_turning_radians * snap_turns
	
	_camera_controller_node.rotation_yaw -= snap_radians
	
	rotation_yaw_snap_offset += snap_radians
	
	snap_turns = 0

func update_physics_input() -> void:
	_update_head_accumulation()
	_process_snap_turning()

func update_representation_input(p_delta: float) -> void:
	var x_direction: float = 1.0
	var y_direction: float = 1.0

	if InputManager.invert_look_x:
		x_direction = -1.0
	else:
		x_direction = 1.0

	if InputManager.invert_look_y:
		y_direction = -1.0
	else:
		y_direction = 1.0

	var mouse_turning_vector: Vector2 = (
		Vector2(InputManager.axes_values["mouse_x"], InputManager.axes_values["mouse_y"])
		* InputManager.mouse_sensitivity
	) if InputManager.ingame_input_enabled() else Vector2()
	
	var controller_turning_vector: Vector2 = Vector2(
		InputManager.axes_values["look_horizontal"], InputManager.axes_values["look_vertical"]
	)
	
	var input_x: float = (
		(controller_turning_vector.x + mouse_turning_vector.x)
		* x_direction
	)
	var input_y: float = (
		(controller_turning_vector.y + mouse_turning_vector.y)
		* y_direction
	)

	if _camera_controller_node:
		# Get snap turning mode
		var snap_turning_enabled: bool = false
		if VRManager.is_xr_active():
			if VRManager.vr_user_preferences.turning_mode != VRManager.vr_user_preferences.turning_mode_enum.TURNING_MODE_SMOOTH:
				snap_turning_enabled = true

		var rotation_yaw: float = _camera_controller_node.rotation_yaw
		var rotation_pitch: float = _camera_controller_node.rotation_pitch

		if snap_turning_enabled:
			if InputManager.is_ingame_action_just_pressed("snap_left"):
				snap_turns -= 1
			if InputManager.is_ingame_action_just_pressed("snap_right"):
				snap_turns += 1
		else:
			rotation_yaw -= input_x * p_delta * ROTATION_SCALE

		if ! lock_pitch:
			rotation_pitch -= input_y * p_delta * ROTATION_SCALE
		else:
			rotation_pitch = 0.0

		if rotation_yaw_snap_offset < 0.0:
			rotation_yaw_snap_offset += SNAP_INTERPOLATION_RATE * p_delta
			if rotation_yaw_snap_offset > 0.0:
				rotation_yaw_snap_offset = 0.0
		else:
			rotation_yaw_snap_offset -= SNAP_INTERPOLATION_RATE * p_delta
			if rotation_yaw_snap_offset < 0.0:
				rotation_yaw_snap_offset = 0.0

		_camera_controller_node.rotation_yaw_snap_offset = rotation_yaw_snap_offset
		_camera_controller_node.rotation_yaw = rotation_yaw
		_camera_controller_node.rotation_pitch = rotation_pitch

		_camera_controller_node.update()

	update_vr_camera_state()


func setup_xr_camera():
	if VRManager.xr_origin:
		xr_camera = VRManager.xr_origin.get_node_or_null("ARVRCamera")  # Sometimes missing (???)
	else:
		xr_camera = null

	reset_offset()