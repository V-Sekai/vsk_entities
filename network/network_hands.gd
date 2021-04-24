extends NetworkLogic

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

var hand_controller_node: Node = null
export (NodePath) var hand_controller_node_path = NodePath()

# Degrees
const FINGER_BASE_MIN_PITCH = -90
const FINGER_BASE_MAX_PITCH = 90
const FINGER_BASE_MIN_YAW = -20
const FINGER_BASE_MAX_YAW = 20

const DIGIT_CHAIN_MIN_PITCH = 0
const DIGIT_CHAIN_MAX_PITCH = 90

# Three bits for each gesture id
var hand_pose_id: int = 0

func _update_hand_pose() -> void:
	if hand_controller_node:
		hand_controller_node.left_hand_gesture_id = (hand_pose_id) & 0x07
		hand_controller_node.right_hand_gesture_id = (hand_pose_id >> 3) & 0x07
		hand_controller_node.update_driver()

func on_serialize(p_writer: network_writer_const, _p_initial_state: bool) -> network_writer_const:	
	hand_pose_id = (
		hand_controller_node.left_hand_gesture_id & 0x7 |
		(hand_controller_node.right_hand_gesture_id & 0x7) << 3
	)
	
	p_writer.put_8(hand_pose_id)

	return p_writer


func on_deserialize(p_reader: network_reader_const, _p_initial_state: bool) -> network_reader_const:
	received_data = true
	
	hand_pose_id = p_reader.get_8()
	
	_update_hand_pose()
	
	return p_reader


func _entity_ready() -> void:
	._entity_ready()
	if ! Engine.is_editor_hint():
		hand_controller_node = get_node_or_null(hand_controller_node_path)
		if received_data:
			_update_hand_pose()
