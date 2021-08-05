@tool
extends "res://addons/entity_manager/node_3d_simulation_logic.gd"

# const interactable_prop_const = preload("res://addons/vsk_entities/vsk_interactable_prop.tscn")
var interactable_prop_const = load("res://addons/vsk_entities/vsk_interactable_prop.tscn")

var spawned_balls: Array = []

@export  var spawn_model: PackedScene # (PackedScene) = null
@export  var rpc_table: NodePath # (NodePath) = NodePath()

var spawn_key_pressed_last_frame: bool = false

func spawn_ball_master(p_requester_id, _entity_callback_id: int) -> void:
	print("Spawn ball master")
	
	var requester_player_entity: RefCounted = VSKNetworkManager.get_player_instance_ref(p_requester_id) # EntityRef
	
	if requester_player_entity:
		if EntityManager.spawn_entity(\
		interactable_prop_const,\
		{\
		"transform":requester_player_entity.get_last_transform(),
		"model_scene":spawn_model\
		}, "NetEntity", p_requester_id) == null:
			printerr("Could not spawn ball!")

func spawn_ball_puppet(_entity_callback_id: int) -> void:
	print("Spawn ball puppet")


func spawn_ball() -> void:
	get_node(rpc_table).nm_rpc_id(0, "spawn_ball", [0])


func test_spawning() -> void:
	if InputManager.ingame_input_enabled():
		var spawn_key_pressed_this_frame: bool = Input.is_key_pressed(KEY_P)
		if !spawn_key_pressed_last_frame:
			if spawn_key_pressed_this_frame:
				spawn_ball()
				
		spawn_key_pressed_last_frame = spawn_key_pressed_this_frame


func _entity_physics_process(_delta: float):
	test_spawning()


func _entity_ready() -> void:
	assert(get_node(rpc_table).connect("session_master_spawn", self.spawn_ball_master) == OK)
	assert(get_node(rpc_table).connect("session_puppet_spawn", self.spawn_ball_puppet) == OK)
