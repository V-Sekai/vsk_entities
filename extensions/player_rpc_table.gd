extends "res://addons/network_manager/network_rpc_table.gd"

signal avatar_path_updated(p_path)
signal did_teleport()

@rpc(authority) func send_did_teleport() -> void:
	emit_signal("did_teleport")

@rpc(authority) func send_set_avatar_path(p_path: String) -> void:
	emit_signal("avatar_path_updated", p_path)
