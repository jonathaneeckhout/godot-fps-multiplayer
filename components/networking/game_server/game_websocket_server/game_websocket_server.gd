class_name GameWebsocketServer
extends Node

var game_server: GameServer = null
var peer: WebSocketMultiplayerPeer = null

func _ready() -> void:
    game_server = get_parent()
    assert(game_server != null)

func create_server(port: int, bind_anddress: String) -> bool:
    peer = WebSocketMultiplayerPeer.new()

    # TODO: implement TLS
    var tls_server_options: TLSOptions = null

    var error: int = peer.create_server(port, bind_anddress, tls_server_options)
    if error != OK:
        print("Can't create new server on {}:{}".format([bind_anddress, port]))

        peer = null

        return false

    if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
        print("Failed to start websocket server, disconnected state")

        peer = null

        return false

    multiplayer.multiplayer_peer = peer

    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    return true

func cleanup() -> void:
    multiplayer.peer_connected.disconnect(_on_peer_connected)
    multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)

    multiplayer.multiplayer_peer = null

func _on_peer_connected(peer_id: int) -> void:
    print("Peer {0} connected".format([peer_id]))

    game_server.add_connection(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
    print("Peer {0} disconnected".format([peer_id]))

    game_server.remove_connection(peer_id)
