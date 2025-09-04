class_name MapSpawner
extends Node

signal player_map_loaded(peer_id: int)

# Node where the map will be put as a child
@export var map_location: Node3D = null

@export var map_scenes: Dictionary[String, PackedScene] = {}

var _current_map: String = ""

func _ready() -> void:
    Connection.map_spawner = self

    assert(map_location != null, "Please set map location")

    assert(Connection.game_server != null)
    Connection.game_server.user_connected.connect(_on_user_connected)


func load_map(map: String) -> void:
    assert(map_scenes.has(map), "Missing {0} in map_scenes".format([map]))

    var map_scene: PackedScene = map_scenes[map]

    var new_map: Node3D = map_scene.instantiate()
    new_map.name = map

    map_location.add_child(new_map)

    _current_map = map


func _on_user_connected(peer_id: int, _username: String) -> void:
    _load_map.rpc_id(peer_id, _current_map)
 

@rpc("call_remote", "authority", "reliable")
func _load_map(map: String) -> void:
    load_map(map)

    _map_loaded.rpc_id(1, map)


@rpc("call_remote", "any_peer", "reliable")
func _map_loaded(map: String) -> void:
    if not multiplayer.is_server():
        return

    if _current_map != map:
        return

    var peer_id = multiplayer.get_remote_sender_id()

    player_map_loaded.emit(peer_id)
