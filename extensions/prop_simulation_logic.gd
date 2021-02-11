extends "model_simulation_logic.gd"
tool

const vr_constants_const = preload("res://addons/vr_manager/vr_constants.gd")

export (AudioStreamSample) var hit_sample = null
export (float) var hit_velocity = 0.25
export (PhysicsMaterial) var physics_material = null

export (float) var mass = 1.0
export (int, LAYERS_3D_PHYSICS) var collison_layers: int = 1
export (int, LAYERS_3D_PHYSICS) var collison_mask: int = 1

export (NodePath) var _render_smooth_path: NodePath = NodePath()
export (NodePath) var _target_path: NodePath = NodePath()
var _render_smooth: Spatial = null
var _target: Spatial = null

var physics_node_root: RigidBody = null

var throw_offset = Vector3(0.0, 0.0, 0.0)
var throw_velocity = Vector3(0.0, 0.0, 0.0)

var prev_linear_velocity_length: float = 0.0


func _network_transform_update(p_transform: Transform) -> void:
	._network_transform_update(p_transform)

	_target.transform = get_transform()


# Overloaded set_global_origin function which also sets the global transform of the physics node
func set_global_origin(p_origin: Vector3, _p_update_physics: bool = false) -> void:
	.set_global_origin(p_origin, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_global_transform(get_global_transform())


# Overloaded set_transform function which also updates the global transform of the physics node
func set_transform(p_transform: Transform, _p_update_physics: bool = false) -> void:
	.set_transform(p_transform, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_transform(get_transform())


# Overloaded set_global_transform function which also sets the global transform of the physics node
func set_global_transform(p_global_transform: Transform, _p_update_physics: bool = false) -> void:
	.set_global_transform(p_global_transform, _p_update_physics)
	if _p_update_physics:
		if physics_node_root:
			physics_node_root.set_global_transform(get_global_transform())


# Change the properties of the rigid body based on whether or not it is parented
func _update_parented_node_state():
	if get_entity_node().hierarchy_component_node.get_entity_parent():
		physics_node_root.mode = RigidBody.MODE_STATIC
		physics_node_root.collision_layer = collison_layers
		physics_node_root.collision_mask = 0
		if ! Engine.is_editor_hint():
			physics_node_root.set_as_toplevel(false)
			physics_node_root.set_transform(Transform())

			_render_smooth.set_as_toplevel(false)
			_render_smooth.set_enabled(false)
			_render_smooth.set_transform(Transform())

			_target.set_as_toplevel(false)
			_target.transform = Transform()
	else:
		physics_node_root.mode = RigidBody.MODE_RIGID
		physics_node_root.collision_layer = collison_layers
		physics_node_root.collision_mask = collison_mask
		if ! Engine.is_editor_hint():
			physics_node_root.set_as_toplevel(true)

			# Reset velocity
			physics_node_root.linear_velocity = Vector3()
			physics_node_root.angular_velocity = Vector3()

			physics_node_root.apply_impulse(throw_offset, throw_velocity)
			throw_velocity = Vector3()
			throw_offset = Vector3()

			_render_smooth.set_as_toplevel(true)
			_render_smooth.set_enabled(true)

			_target.set_as_toplevel(true)
			if is_inside_tree():
				_target.transform = get_global_transform().orthonormalized()
			else:
				_target.transform = get_transform().orthonormalized()

	# Saracen: Todo fix: weird glitches
	#physics_node_root.transform = Transform()
	#_target.transform = Transform()
	#_render_smooth.transform = Transform()


# Delete the previous physics node and disconnect associated signals
func _delete_previous_physics_nodes() -> void:
	if physics_node_root:
		physics_node_root.disconnect("touched_by_body", self, "_on_touched_by_body")
		physics_node_root.disconnect(
			"touched_by_body_with_network_id", self, "_on_touched_by_body_with_network_id"
		)
		physics_node_root.queue_free()
		if physics_node_root.is_inside_tree():
			physics_node_root.get_parent().remove_child(physics_node_root)
	physics_node_root = null


# Create a new physics node
func _setup_physics_nodes() -> void:
	physics_node_root = model_rigid_body_const.new()
	physics_node_root.mass = mass
	physics_node_root.contact_monitor = true
	physics_node_root.contacts_reported = 3
	physics_node_root.owner_entity = get_entity_node()
	physics_node_root.physics_material_override = physics_material

	physics_node_root.set_name("Physics")
	if physics_node_root.connect("body_entered", self, "_on_body_entered") != OK:
		printerr("Could not connect signal body_entered")
	if physics_node_root.connect("touched_by_body", self, "_on_touched_by_body"):
		printerr("Could not connect signal touched_by_body")
	if physics_node_root.connect(
		"touched_by_body_with_network_id", self, "_on_touched_by_body_with_network_id"
	):
		printerr("Could not connect signal touched_by_body_with_network_id")
	if physics_node_root.connect("pick_up", self, "_pick_up"):
		printerr("Could not connect signal attempt_pick_up")
	if physics_node_root.connect("drop", self, "_drop"):
		printerr("Could not connect signal attempt_drop")
	for node in physics_nodes:
		physics_node_root.add_child(node)

	get_entity_node().add_child(physics_node_root)

	_update_parented_node_state()


func _setup_model_nodes() -> bool:
	if ._setup_model_nodes():
		if ! Engine.is_editor_hint():
			_delete_previous_physics_nodes()
			_setup_physics_nodes()
		return true
	return false


func _on_touched_by_body(p_body) -> void:
	if p_body.has_method("touched_by_body_with_network_id"):
		p_body.touched_by_body_with_network_id(get_network_master())


func _on_touched_by_body_with_network_id(p_network_id: int) -> void:
	if NetworkManager.get_current_peer_id() == p_network_id:
		get_entity_node().request_to_become_master()


func is_pickup_valid(p_attempting_pickup_controller: Node, p_id: int) -> bool:
	return false


func is_drop_valid(p_attempting_pickup_controller: Node, p_id: int) -> bool:
	return false


func is_grabbable() -> bool:
	return true


func is_interactable() -> bool:
	return true


func _pick_up(p_attempting_pickup_controller: Node, p_id: int) -> void:
	return


func _drop(p_attempting_pickup_controller: Node, p_id: int, p_velocity = Vector3(0.0, 0.0, 0.0)) -> void:
	return


func _entity_parent_changed() -> void:
	._entity_parent_changed()

	_update_parented_node_state()


func _on_body_entered(p_body):
	if p_body is KinematicBody or p_body is RigidBody:
		if p_body != physics_node_root:
			if p_body.has_method("touched_by_body"):
				p_body.touched_by_body(physics_node_root)


func can_request_master_from_peer(_id: int) -> bool:
	return true


func can_transfer_master_from_session_master(_id: int) -> bool:
	return true


func cache_nodes() -> void:
	.cache_nodes()
	_target = get_node_or_null(_target_path)
	_render_smooth = get_node_or_null(_render_smooth_path)


func _entity_physics_process(p_delta: float) -> void:
	._entity_physics_process(p_delta)
	if physics_node_root:
		var linear_velocity: Vector3 = physics_node_root.linear_velocity
		var linear_velocity_length: float = linear_velocity.length()

		var colliding_bodies: Array = physics_node_root.get_colliding_bodies()
		if colliding_bodies.size() > 0:
			if hit_sample:
				if prev_linear_velocity_length - linear_velocity_length >= hit_velocity:
					VSKAudioManager.play_oneshot_audio_stream_3d(
						hit_sample,\
						VSKAudioManager.GAME_SFX_OUTPUT_BUS_NAME,\
						get_global_transform()
					)

		prev_linear_velocity_length = linear_velocity_length

		entity_node.network_logic_node.set_dirty(true)


func _entity_representation_process(p_delta: float) -> void:
	._entity_representation_process(p_delta)
	if physics_node_root and get_entity_node().hierarchy_component_node.get_entity_parent() == null:
		set_transform(physics_node_root.transform)
		if _target:
			_target.transform = physics_node_root.transform
	else:
		if _target:
			_target.transform = Transform()


func _entity_ready() -> void:
	._entity_ready()
	if ! Engine.is_editor_hint():
		if _target:
			_target.set_as_toplevel(true)
			_target.global_transform = get_entity_node().global_transform

		if _render_smooth:
			_render_smooth.set_as_toplevel(true)
			_render_smooth.set_target(_render_smooth.get_path_to(_target))
			_render_smooth.teleport()
			
		entity_node.hierarchy_component_node.connect("entity_parent_changed", self, "_entity_parent_changed")
			
