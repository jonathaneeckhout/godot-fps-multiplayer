extends Node


var game_server: GameServer = null
var game_client: GameClient = null

var clock_synchronizer: ClockSynchronizer = null

var _id_counter: int = 0
var _network_nodes: Dictionary[int, Node3D] = {}


func get_unique_network_id() -> int:
    if not multiplayer.is_server():
        return -1

    _id_counter += 1

    return _id_counter

func add_network_node(network_id: int, node: Node3D) -> void:
    _network_nodes[network_id] = node

func get_network_node(network_id: int) -> Node3D:
    return _network_nodes.get(network_id)