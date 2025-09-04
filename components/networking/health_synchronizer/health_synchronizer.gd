class_name HealthSynchronizer
extends Node

signal health_changed(hp: int, amount: int)

@export var health: int = 100

var max_health: int = health

var parent: Node3D = null
var network_node: NetworkNode = null


var last_synced_health: int = health

func _ready() -> void:
    parent = get_parent()
    assert(parent != null, "Parent can't be null")

    network_node = parent.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    if network_node.mode != NetworkNode.Modes.SERVER:
        _get_health.rpc_id(1)


func _physics_process(_delta: float) -> void:
    if last_synced_health != health:
        health_changed.emit(health, last_synced_health - health)

        last_synced_health = health

        if network_node.mode == NetworkNode.Modes.SERVER:
            _update_health.rpc(health)


func hurt(amount: int) -> void:
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    health = clamp(0, health - amount, max_health)


func heal(amount: int) -> void:
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    health = clamp(0, health + amount, max_health)


@rpc("call_remote", "authority", "reliable")
func _update_health(value: int) -> void:
    health = value


@rpc("call_remote", "any_peer", "reliable")
func _get_health() -> void:
    if not multiplayer.is_server():
        return

    var peer_id = multiplayer.get_remote_sender_id()

    _return_health.rpc_id(peer_id, health)


@rpc("call_remote", "authority", "reliable")
func _return_health(value: int) -> void:
    health = value
    last_synced_health = health