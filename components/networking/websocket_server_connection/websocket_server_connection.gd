class_name WebsocketServerConnection
extends Node

# Node storing all the users
var users: Node = null

func _ready() -> void:
    users = Node.new()
    users.name = "Users"
    add_child(users)

func new() -> bool:
    return true