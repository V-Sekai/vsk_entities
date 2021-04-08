extends Node

var strong_dependent_link: StrongExclusiveEntityDependencyHandle = null
var target_entity_ref: Reference = null
var is_interactable: bool = true

export (int, LAYERS_3D_PHYSICS) var interaction_collision: int = 0
export (float) var interaction_distance = 2.0

export (NodePath) var _camera_controller_node_path: NodePath = NodePath()
onready var _camera_controller_node: Spatial = get_node_or_null(_camera_controller_node_path)

export (NodePath) var _player_pickup_controller_node_path: NodePath = NodePath()
onready var _player_pickup_controller_node: Node = get_node_or_null(_player_pickup_controller_node_path)

onready var dss: PhysicsDirectSpaceState = null

static func get_camera_interaction_entity() -> Entity:
	return null

const INTERACTABLE_ENTITY_TYPES: Array = ["InteractableProp"]
var hand_id: int

func _ready():
	if !Engine.is_editor_hint():
		dss = _camera_controller_node.get_world().get_direct_space_state()
		hand_id = _player_pickup_controller_node.RIGHT_HAND_ID

func cast_camera_interaction_ray() -> Dictionary:
	var camera_global_transform = _camera_controller_node.camera.global_transform
	
	var start: Vector3 = camera_global_transform.origin
	var end: Vector3 = (
		camera_global_transform.origin
		+ camera_global_transform.basis.xform(Vector3(0.0, 0.0, -interaction_distance))
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
	
	if !p_result.empty():
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


func update(p_entity: Entity, _delta: float) -> void:
	var result: Dictionary = cast_camera_interaction_ray()
	var new_entity_ref: Reference = get_collider_entity_ref(result)
	
	var current_hand_entity_ref: EntityRef = _player_pickup_controller_node.get_hand_entity_reference(hand_id)
	
	if current_hand_entity_ref:
		if InputManager.is_ingame_action_just_pressed("grab"):
			p_entity.send_entity_message(current_hand_entity_ref,
			"attempting_drop",
			{
				"grabber_entity_ref":p_entity.get_entity_ref(),
			})
	
	if new_entity_ref != target_entity_ref:
		if target_entity_ref and is_interactable:
			strong_dependent_link = null
			target_entity_ref = new_entity_ref
		if new_entity_ref:
			is_interactable = is_interactable_entity_type(new_entity_ref)
			if is_interactable:
				strong_dependent_link = p_entity.create_strong_exclusive_dependency_for(new_entity_ref)
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
						"grabber_network_id":get_network_master(),
						"grabber_transform":p_entity.get_attachment_node(0).global_transform,
						"grabber_attachment_id":hand_id
					})
