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


func _physics_process(_delta: float) -> void:
    if last_synced_health != health:
        health_changed.emit(health, last_synced_health - health)

        last_synced_health = health


func hurt(amount: int) -> void:
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    health = clamp(0, health - amount, max_health)


func heal(amount: int) -> void:
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    health = clamp(0, health + amount, max_health)