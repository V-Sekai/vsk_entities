@tool
extends Node

var player_controller: Node = null

var left_hand_strong_dependent_link: StrongExclusiveEntityDependencyHandle = null
var right_hand_strong_dependent_link: StrongExclusiveEntityDependencyHandle = null

var left_hand_object: EntityRef = null
var right_hand_object: EntityRef = null

const LEFT_HAND_ID = 0
const RIGHT_HAND_ID = 1


func get_attachment_id(p_attachment_name: String) -> int:
	match p_attachment_name:
		"LeftHand":
			return LEFT_HAND_ID
		"RightHand":
			return RIGHT_HAND_ID
		_:
			return -1


func get_hand_entity_reference(p_attachment_id: int) -> EntityRef:
	match p_attachment_id:
		LEFT_HAND_ID:
			return left_hand_object
		RIGHT_HAND_ID:
			return right_hand_object
		_:
			return null


func set_hand_entity_reference(p_attachment_id: int, p_entity: EntityRef) -> void:
	match p_attachment_id:
		LEFT_HAND_ID:
			left_hand_object = p_entity
			left_hand_strong_dependent_link = player_controller.entity_node.create_strong_exclusive_dependency_for(left_hand_object)
		RIGHT_HAND_ID:
			right_hand_object = p_entity
			right_hand_strong_dependent_link = player_controller.entity_node.create_strong_exclusive_dependency_for(right_hand_object)


func clear_hand_entity_references_for_entity(p_entity: EntityRef) -> void:
	if p_entity == left_hand_object:
		left_hand_object = null
	if p_entity == right_hand_object:
		right_hand_object = null

func get_head_forward_transform() -> Transform3D:
	return player_controller.get_avatar_display().get_head_forward_transform()

func get_entity_node() -> Node:
	return player_controller.get_entity_node()
	

func cache_nodes() -> void:
	pass
