extends Node

var strong_dependent_link: StrongExclusiveEntityDependencyHandle = null
var target_entity_ref: RefCounted = null
var is_interactable: bool = true

@export  var interaction_collision: int # (int, LAYERS_3D_PHYSICS) = 0
@export  var interaction_distance : float = 2.0

@export  var _camera_controller_node_path: NodePath # (NodePath) = NodePath()
# @onready var _camera_controller_node: Node3D = get_node_or_null(_camera_controller_node_path)
var _camera_controller_node: Node3D = null

@export  var _player_pickup_controller_node_path: NodePath # (NodePath) = NodePath()
@onready var _player_pickup_controller_node: Node = get_node_or_null(_player_pickup_controller_node_path)

@onready var dss: PhysicsDirectSpaceState3D = null

static func get_camera_interaction_entity() -> Entity:
	return null

const INTERACTABLE_ENTITY_TYPES: Array = ["InteractableProp"]
var hand_id: int = -1

func _ready():
	print("My path " + str(get_path()) + " camera_con " + str(  _camera_controller_node_path))
	_camera_controller_node = get_node_or_null(_camera_controller_node_path)
	print("Got a cam controller " + str(_camera_controller_node))
	if !Engine.is_editor_hint():
		dss = _camera_controller_node.get_world_3d().get_direct_space_state()
		hand_id = _player_pickup_controller_node.RIGHT_HAND_ID

func cast_flat_interaction_ray() -> Dictionary:
	var source_global_transform = Transform3D()
	
	if _camera_controller_node.camera_mode == _camera_controller_node.CAMERA_FIRST_PERSON:
		source_global_transform = _camera_controller_node.camera.global_transform
	else:
		source_global_transform =_player_pickup_controller_node.get_head_forward_transform()
	
	var start: Vector3 = source_global_transform.origin
	var end: Vector3 = (
		source_global_transform.origin
		+ source_global_transform.basis*(Vector3(0.0, 0.0, -interaction_distance))
	)
	
	var result: Dictionary = dss.intersect_ray(start, end, [], interaction_collision)
	return result

func is_interactable_entity_type(p_entity_ref: EntityRef) -> bool:
	var type_name: String = p_entity_ref.get_entity_type()
	if INTERACTABLE_ENTITY_TYPES.has(type_name):
		return true
	else:
		return false

static func get_collider_entity_ref(p_result: Dictionary) -> EntityRef:
	var new_entity_ref: EntityRef = null
	
	if !p_result.is_empty():
		var collider: Object = p_result["collider"]
		if collider.has_method("get_entity_ref"):
			new_entity_ref = collider.call("get_entity_ref")
			
	return new_entity_ref
			

func _on_entity_message(p_message, p_args) -> void:
	match p_message:
		"pickup_grab_callback":
			if p_args["entity_ref"]:
				_player_pickup_controller_node.set_hand_entity_reference(hand_id, p_args["entity_ref"])
		"pickup_drop_callback":
			if p_args["entity_ref"]:
				_player_pickup_controller_node.set_hand_entity_reference(hand_id, null)


func _update_current_hand_ref(p_entity: Entity, current_hand_entity_ref: EntityRef):
	if InputManager.is_ingame_action_just_pressed("grab"):
		p_entity.send_entity_message(current_hand_entity_ref,
		"attempting_drop",
		{
			"grabber_entity_ref":p_entity.get_entity_ref(),
		})

func update(p_entity: Entity, _delta: float) -> void:	
	var current_hand_entity_ref: EntityRef = _player_pickup_controller_node.get_hand_entity_reference(hand_id)
	
	if current_hand_entity_ref:
		_update_current_hand_ref(p_entity, current_hand_entity_ref)
	else:
		var result: Dictionary = cast_flat_interaction_ray()
		var new_entity_ref: RefCounted = get_collider_entity_ref(result)
		
		if new_entity_ref != target_entity_ref:
			if target_entity_ref and is_interactable:
				strong_dependent_link = null
				target_entity_ref = new_entity_ref
			if new_entity_ref:
				is_interactable = is_interactable_entity_type(new_entity_ref)
				if is_interactable:
					# FIXME: Cast GDScript to StrongExclusiveEntityDependencyHandle
					var tmp: Variant = p_entity.create_strong_exclusive_dependency_for(new_entity_ref)
					strong_dependent_link = tmp
					target_entity_ref = new_entity_ref
		else:
			# This assumes we now have a dependency created from the previous frame
			# so we can now interact with this object 
			if target_entity_ref and is_interactable:
				# Is my hand empty?
				if ! _player_pickup_controller_node.get_hand_entity_reference(hand_id):
					var attempting_grab: bool = InputManager.is_ingame_action_just_pressed("grab")
					if attempting_grab:
						p_entity.send_entity_message(target_entity_ref,
						"attempting_grab",
						{
							"grabber_entity_ref":p_entity.get_entity_ref(),
							"grabber_network_id":get_multiplayer_authority(),
							"grabber_transform":p_entity.get_attachment_node(0).global_transform,
							"grabber_attachment_id":hand_id
						})
