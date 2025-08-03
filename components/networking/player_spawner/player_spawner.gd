class_name PlayerSpawner
extends Node

@export var players_node: Node3D = null
@export var player_scene: PackedScene = null

func _ready() -> void:
    add_to_group("player_spawners")

    assert(players_node != null, "Please select a node where the players will be spawned")
    assert(player_scene != null, "Please select a scene for the players on the server side")

# Adding player on server side
func add_player(peer_id: int, username: String) -> void:
    var player: CharacterBody3D = player_scene.instantiate()
    player.name = username

    # TODO: spawn at position

    players_node.add_child(player)



    _add_player.rpc(peer_id, username, player.position)

# Removing player on server side
func remove_player(peer_id: int, username: String) -> void:
    pass

@rpc("call_remote", "authority", "reliable")
func _add_player(peer_id: int, username: String, position: Vector3) -> void:
    print("HIER")

@rpc("call_remote", "authority", "reliable")
func _remove_player(peer_id: int, username: String) -> void:
    pass