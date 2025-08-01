class_name GameWebsocketServer
extends Node

signal new_connection(peer_id: int)
signal connection_disconnected(peer_id: int)

signal user_connected(user: String)
signal user_disconnected(user: String)


# Node for storing all new connections
var new_connections: Node = null

# Node storing all the users
var users: Node = null

var peer: WebSocketMultiplayerPeer = null

func create_server(port: int, bind_anddress: String) -> bool:
    new_connections = Node.new()
    new_connections.name = " NewConnections"
    add_child(new_connections)

    users = Node.new()
    users.name = "Users"
    add_child(users)

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

    new_connections.queue_free()
    users.queue_free()

    multiplayer.multiplayer_peer = null

func _on_peer_connected(id: int) -> void:
    print("Peer {0} connected".format([id]))

    var new_user: User = User.new()
    new_user.name = "user_{0}".format([id])
    new_connections.add_child(new_user)

    new_connection.emit(id)

func _on_peer_disconnected(id: int) -> void:
    print("Peer {0} disconnected".format([id]))

    var connection: Node = new_connections.get_node_or_null("user_{0}".format([id]))
    if connection != null:
        connection.queue_free()
        connection_disconnected.emit(id)
        return

    # Todo: lookup user by id and remove it
