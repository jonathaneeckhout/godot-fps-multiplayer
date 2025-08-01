class_name GameClientAuthenticator
extends Node

signal authenticated
signal authentication_error()

func _validate_username(username: String) -> bool:
    if username == null:
        return false

    if username == "":
        return false

    return true

func _validate_key(key: String) -> bool:
    if key == null:
        return false

    if key == "":
        return false

    return true

func authenticate(username: String, key: String) -> bool:
    if not _validate_username(username):
        return false

    if not _validate_key(key):
        return false

    if multiplayer.is_server():
        return false

    _authenticate.rpc_id(1, username, key)

    return true

@rpc("call_remote", "any_peer", "reliable")
func _authenticate(username: String, key: String) -> void:
    if not multiplayer.is_server():
        return

    var peer_id: int = multiplayer.get_remote_sender_id()

    var result: bool = false

    #TODO: authenticate via the server
    var game_server_authenticator: GameServerAuthenticator = get_node_or_null("../../GameServer/GameServerAuthenticator")
    assert(game_server_authenticator != null, "GameServerAuthenticator missing")

    game_server_authenticator.authenticate(peer_id, username, key)

    _authentication_response.rpc_id(peer_id, result)


@rpc("call_remote", "authority", "reliable")
func _authentication_response(result: bool) -> void:
    if result:
        authenticated.emit()
    else:
        authentication_error.emit()