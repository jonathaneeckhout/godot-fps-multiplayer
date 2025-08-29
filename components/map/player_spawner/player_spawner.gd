class_name PlayerSpawner
extends Node

@export var players_node: Node3D = null
@export var player_scene: PackedScene = null

var spawn_location_picker: SpawnLocationPicker = null

func _ready() -> void:
    add_to_group("player_spawners")

    assert(players_node != null, "Please select a node where the players will be spawned")
    assert(player_scene != null, "Please select a scene for the players")

    spawn_location_picker = SpawnLocationPicker.find_spawn_location_picker(get_parent())
    assert(spawn_location_picker != null)

    assert(Connection.game_server != null)
    Connection.game_server.user_connected.connect(_on_user_connected)
    Connection.game_server.user_connected.connect(_on_user_disconnected)

# Server side
func _on_user_connected(peer_id: int, username: String) -> void:
    add_player(peer_id, username)

# Server side
func _on_user_disconnected(peer_id: int, username: String) -> void:
    remove_player(peer_id, username)


# Adding player on server side
func add_player(peer_id: int, username: String) -> void:
    var player: Player = player_scene.instantiate()
    player.name = username
    player.position = spawn_location_picker.get_spawn_location()

    var network_node: NetworkNode = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    network_node.peer_id = peer_id

    players_node.add_child(player)

    # Connection.add_network_node(player.network_id, player)

# Removing player on server side
func remove_player(_peer_id: int, _username: String) -> void:
    pass
