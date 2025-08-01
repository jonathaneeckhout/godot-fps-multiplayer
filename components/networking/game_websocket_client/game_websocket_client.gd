class_name GameWebsocketClient
extends Node

signal connected()
signal disconnected()

var peer: WebSocketMultiplayerPeer = null

func create_client(url: String) -> bool:
    assert(url != "", "url can not be empty, example: ws://localhost:9080")

    peer = WebSocketMultiplayerPeer.new()

    # TODO: implement TLS
    var tls_server_options: TLSOptions = null

    var error: int = peer.create_client(url, tls_server_options)
    if error != OK:
        print("Can't create new client on url: {}".format(url))

        peer = null

        return false

    multiplayer.multiplayer_peer = peer

    multiplayer.connected_to_server.connect(_on_connection_succeeded)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

    return true

func cleanup() -> void:
    multiplayer.connected_to_server.disconnect(_on_connection_succeeded)
    multiplayer.connection_failed.disconnect(_on_connection_failed)
    multiplayer.server_disconnected.disconnect(_on_server_disconnected)

    multiplayer.multiplayer_peer = null

func _on_connection_succeeded() -> void:
    connected.emit()

func _on_connection_failed() -> void:
    disconnected.emit()

func _on_server_disconnected() -> void:
    disconnected.emit()