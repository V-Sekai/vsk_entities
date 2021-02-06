extends RigidBody

const vr_constants_const = preload("res://addons/vr_manager/vr_constants.gd")

var owner_entity: Spatial = null

signal touched_by_body_with_network_id(p_network_id)
signal touched_by_body(p_body)

signal pick_up(p_pickup_controller, p_hand_id)
signal drop(p_pickup_controller, p_hand_id)


func touched_by_body_with_network_id(p_network_id: int) -> void:
	emit_signal("touched_by_body_with_network_id", p_network_id)


func touched_by_body(p_body) -> void:
	emit_signal("touched_by_body", p_body)
	

func get_entity_ref() -> Reference:
	return owner_entity.get_entity_ref()


func is_pickup_valid(p_pickup_controller: Node, p_hand_id: int) -> bool:
	return false


func is_drop_valid(p_pickup_controller: Node, p_hand_id: int) -> bool:
	return false


func pick_up(p_pickup_controller: Node, p_hand_id: int) -> void:
	return


func drop(p_pickup_controller: Node, p_hand_id: int) -> void:
	return
