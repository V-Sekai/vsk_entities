extends "res://addons/network_manager/network_rpc_table.gd"

signal avatar_path_updated(p_path)
signal did_teleport()

puppetsync func did_teleport():
	emit_signal("did_teleport")

puppetsync func set_avatar_path(p_path):
	emit_signal("avatar_path_updated")
