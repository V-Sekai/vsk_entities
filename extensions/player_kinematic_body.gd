extends "res://addons/extended_kinematic_body/extended_kinematic_body.gd"

signal touched_by_body(p_body)


func touched_by_body(p_body):
	emit_signal("touched_by_body", p_body)
