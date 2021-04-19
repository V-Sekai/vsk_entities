extends RigidBody

const vr_constants_const = preload("res://addons/vr_manager/vr_constants.gd")

var owner_entity: Spatial = null

signal touched_by_body_with_network_id(p_network_id)
signal touched_by_body(p_body)


func touched_by_body_with_network_id(p_network_id: int) -> void:
	emit_signal("touched_by_body_with_network_id", p_network_id)


func touched_by_body(p_body) -> void:
	emit_signal("touched_by_body", p_body)
	

func get_entity_ref() -> Reference:
	return owner_entity.get_entity_ref()


func is_pickup_valid(_pickup_controller: Node, _hand_id: int) -> bool:
	return false


func is_drop_valid(_pickup_controller: Node, _hand_id: int) -> bool:
	return false


func pick_up(_pickup_controller: Node, _hand_id: int) -> void:
	return


func drop(_pickup_controller: Node, _hand_id: int) -> void:
	return

func _integrate_forces(state):
	pass
