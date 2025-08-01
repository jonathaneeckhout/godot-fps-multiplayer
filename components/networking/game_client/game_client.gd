class_name GameClient
extends Node

@export var mode: Modes = Modes.Websocket
@export var game_server_url: String = "ws://localhost:9080"

enum Modes {Websocket}

var game_websocket_client: GameWebsocketClient = null

func create_client() -> bool:
    match mode:
        Modes.Websocket:
            assert(game_server_url != "", "Invalid server url")

            game_websocket_client = get_node_or_null("GameWebsocketClient")
            assert(game_websocket_client != null, "Missing GameWebsocketClient component")
            
            return game_websocket_client.create_client(game_server_url)
        _:
            print("Unsupported game server mode")
            return false
