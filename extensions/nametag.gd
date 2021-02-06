extends "res://addons/canvas_plane/canvas_plane_v2.gd"
tool

export(NodePath) var nametag_label_nodepath: NodePath = NodePath()
export(String) var nametag: String = "" setget set_nametag

func set_nametag(p_name: String) -> void:
	nametag = p_name
	var nametag_label: Label = get_node_or_null(nametag_label_nodepath)
	if nametag_label:
		nametag_label.set_text(nametag)
		nametag_label.set_size(Vector2())
		set_dirty_flag()
