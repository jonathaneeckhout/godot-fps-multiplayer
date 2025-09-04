class_name NetworkNode
extends Node

# Make sure to set this node on top of the scene!

enum Modes {LOCAL, OTHER, SERVER}

var parent: Node3D = null

var peer_id: int = 1
var network_id: int = 0
var mode: Modes = Modes.SERVER


func _init() -> void:
    network_id = Connection.get_unique_network_id()

func _enter_tree() -> void:
    parent = get_parent()
    assert(parent != null, "Missing parent")

    Connection.add_network_node(network_id, parent)


func _exit_tree() -> void:
    Connection.remove_network_node(network_id)


func _ready() -> void:
    parent = get_parent()
    assert(parent != null, "Missing parent")

    if multiplayer.is_server():
        mode = Modes.SERVER
    else:
        if multiplayer.get_unique_id() == peer_id:
            mode = Modes.LOCAL
        else:
            mode = Modes.OTHER
