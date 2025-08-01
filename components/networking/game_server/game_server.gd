class_name GameServer
extends Node

@export var mode: Modes = Modes.Websocket
@export var bind_address: String = "*"
@export var port: int = 9080

enum Modes {Websocket}


var game_websocket_server: GameWebsocketServer = null

func create_server() -> bool:
    match mode:
        Modes.Websocket:
            assert(bind_address != "", "Invalid bind address")
            assert(port > 0, "Invalid port")

            game_websocket_server = get_node_or_null("GameWebsocketServer")
            assert(game_websocket_server != null, "Missing GameWebsocketServer component")
            
            return game_websocket_server.create_server(port, bind_address)

        _:
            print("Unsupported game server mode")
            return false
