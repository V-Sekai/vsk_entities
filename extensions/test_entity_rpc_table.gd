extends "res://addons/network_manager/network_rpc_table.gd"

signal session_master_spawn(p_requester_id, p_entity_callback_id)
signal session_puppet_spawn(p_entity_callback_id)

@rpc(any_peer) func spawn_ball(p_entity_callback_id) -> void:
	if VSKNetworkManager.is_session_master():
		emit_signal("session_master_spawn", get_remote_sender_id(), p_entity_callback_id)
	else:
		if get_remote_sender_id() == VSKNetworkManager.get_current_peer_id():
			emit_signal("session_puppet_spawn", p_entity_callback_id)
