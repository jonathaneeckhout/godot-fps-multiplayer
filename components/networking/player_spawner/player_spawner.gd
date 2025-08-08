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
    player.peer_id = peer_id
    player.position = spawn_location_picker.get_spawn_location()
    players_node.add_child(player)

    _add_player.rpc(peer_id, username, player.position)

# Removing player on server side
func remove_player(peer_id: int, username: String) -> void:
    pass

@rpc("call_remote", "authority", "reliable")
func _add_player(peer_id: int, username: String, position: Vector3) -> void:
    if multiplayer.is_server():
        return

    var player: Player = player_scene.instantiate()
    player.name = username
    player.username = username
    player.peer_id = peer_id
    player.position = position
    players_node.add_child(player)


@rpc("call_remote", "authority", "reliable")
func _remove_player(peer_id: int, username: String) -> void:
    pass
