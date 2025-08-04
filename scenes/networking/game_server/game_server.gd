class_name GameServer
extends Node

signal new_connection(peer_id: int)
signal connection_disconnected(peer_id: int)

signal user_connected(peer_id: int, username: String)
signal user_disconnected(peer_id: int, username: String)

@export var mode: Modes = Modes.WEBSOCKET
@export var bind_address: String = "*"
@export var port: int = 9080

enum Modes {WEBSOCKET}

# Node for storing all new connections
var connections: Node = null

# Node storing all the users
var users: Node = null

var game_websocket_server: GameWebsocketServer = null

func _ready() -> void:
    Connection.game_server = self

func create_server() -> bool:
    connections = Node.new()
    connections.name = " Connection"
    add_child(connections)

    users = Node.new()
    users.name = "Users"
    add_child(users)

    match mode:
        Modes.WEBSOCKET:
            assert(bind_address != "", "Invalid bind address")
            assert(port > 0, "Invalid port")

            game_websocket_server = get_node_or_null("GameWebsocketServer")
            assert(game_websocket_server != null, "Missing GameWebsocketServer component")
            
            return game_websocket_server.create_server(port, bind_address)

        _:
            print("Unsupported game server mode")
            return false

func cleanup() -> void:
    match mode:
        Modes.WEBSOCKET:
            game_websocket_server.cleanup()
        _:
            pass

    connections.queue_free()
    users.queue_free()

func add_connection(peer_id: int) -> void:
    var new_user: User = User.new()
    new_user.name = "user_{0}".format([peer_id])
    new_user.peer_id = peer_id
    connections.add_child(new_user)

    new_connection.emit(peer_id)

func get_connection(peer_id: int) -> User:
    return connections.get_node_or_null("user_{0}".format([peer_id]))

func remove_connection(peer_id: int) -> void:
    var user: User = get_connection(peer_id)
    if user != null:
        user.queue_free()

        connection_disconnected.emit(peer_id)

        return

    user = get_user_by_peer_id(peer_id)
    if user != null:
        user.queue_free()

        user_disconnected.emit(user.peer_id, user.username)

        return

func move_connection_to_users(user: User) -> void:
    connections.remove_child(user)

    user.name = user.username

    users.add_child(user)

    user_connected.emit(user.peer_id, user.username)

func get_user_by_peer_id(peer_id: int) -> User:
    for user: User in users.get_children():
        if user.peer_id == peer_id:
            return user
    
    return null

func get_user(username: String) -> User:
    return users.get_node_or_null(username)
