class_name GameServerAuthenticator
extends Node

@export var mode: Modes = Modes.USERNAME

enum Modes {USERNAME}

var game_server: GameServer = null
var username_authenticator: UsernameAuthenticator = null

func _ready() -> void:
    game_server = get_parent()
    assert(game_server != null)

    username_authenticator = get_node_or_null("UsernameAuthenticator")
    assert(username_authenticator != null, "Missing UsernameAuthenticator")

func authenticate(peer_id: int, username: String, _key: String) -> bool:
    #TODO: handle double authentications
    var user: User = game_server.get_connection(peer_id)
    if user == null:
        return false
    
    var authenticated: bool = false
    match mode:
        Modes.USERNAME:
            authenticated = username_authenticator.authenticate(username)
        _:
            return false

    if not authenticated:
        return false

    user.username = username
    user.logged_in = true

    game_server.move_connection_to_users(user)

    return true
