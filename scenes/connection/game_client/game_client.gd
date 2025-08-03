class_name GameClient
extends Node

signal connected()
signal disconnected()

signal authenticated(result: bool)


@export var mode: Modes = Modes.WEBSOCKET
@export var game_server_url: String = "ws://localhost:9080"

enum Modes {WEBSOCKET}

var game_websocket_client: GameWebsocketClient = null
var game_client_authenticator: GameClientAuthenticator = null

func _ready() -> void:
    game_client_authenticator = get_node_or_null("GameClientAuthenticator")
    assert(game_client_authenticator != null, "Missing GameClientAuthenticator")

    game_client_authenticator.authenticated.connect(_on_authenticated)

func create_client() -> bool:
    match mode:
        Modes.WEBSOCKET:
            assert(game_server_url != "", "Invalid server url")

            game_websocket_client = get_node_or_null("GameWebsocketClient")
            assert(game_websocket_client != null, "Missing GameWebsocketClient component")

            game_websocket_client.connected.connect(_on_connected)
            game_websocket_client.disconnected.connect(_on_disconnected)

            var created: bool = game_websocket_client.create_client(game_server_url)
            if not created:
                return false

            return true
        _:
            print("Unsupported game server mode")
            return false

func cleanup() -> void:
    if game_websocket_client != null:
        if game_websocket_client.connected.is_connected(_on_connected):
            game_websocket_client.connected.disconnect(_on_connected)
        
        if game_websocket_client.disconnected.is_connected(_on_disconnected):
            game_websocket_client.disconnected.disconnect(_on_disconnected)

func authenticate(username: String, key: String) -> bool:
    return game_client_authenticator.authenticate(username, key)

func _on_connected() -> void:
    connected.emit()

func _on_disconnected() -> void:
    disconnected.emit()

func _on_authenticated(result: bool) -> void:
    authenticated.emit(result)