class_name Connection
extends Node

var game_server: GameServer = null
var game_client: GameClient = null

func _ready() -> void:
    game_server = get_node_or_null("GameServer")
    assert(game_server, "GameServer is missing")

    game_client = get_node_or_null("GameClient")
    assert(game_client != null, "GameClient is missing")

    game_server.user_connected.connect(_on_user_connected)
    game_server.user_connected.connect(_on_user_disconnected)

func _on_user_connected(peer_id: int, username: String) -> void:
    get_tree().call_group("player_spawners", "add_player", peer_id, username)

func _on_user_disconnected(peer_id: int, username: String) -> void:
    get_tree().call_group("player_spawners", "remove_player", peer_id, username)