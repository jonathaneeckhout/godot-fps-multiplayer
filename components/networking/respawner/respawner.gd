class_name Respawner
extends Node

signal respawned(node: Node3D)

@export var respawn_time: float = 5.0

var respawn_timer: Timer = null

var parent: Node3D = null
var network_node: NetworkNode = null
var health_synchronizer: HealthSynchronizer = null

func _ready() -> void:
    parent = get_parent()
    assert(parent != null, "Parent can't be null")

    network_node = parent.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")


    health_synchronizer = parent.get_node_or_null("HealthSynchronizer")
    assert(health_synchronizer != null, "Missing HealthSynchronizer")

    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    health_synchronizer.died.connect(_on_died)

    respawn_timer = Timer.new()
    respawn_timer.name = "RespawnTimer"
    respawn_timer.one_shot = true
    respawn_timer.autostart = false
    respawn_timer.timeout.connect(_on_respawn_timer_timeout)
    add_child(respawn_timer)


func _on_died() -> void:
    print("LALA")
    respawn_timer.start(respawn_time)


func _on_respawn_timer_timeout() -> void:
    respawned.emit(parent)

    if network_node.mode == NetworkNode.Modes.SERVER:
        health_synchronizer.restore()

        #TODO: remove all guns
