class_name GunSynchronizer
extends Node

signal fired()

@export var gun: Gun = null

## Point in space which will use as origin for hitscan bullet detection
@export var aim_point: Node3D = null

var player: Player = null
var network_node: NetworkNode = null
var player_input: PlayerInput = null

var last_timestamp: float = 0.0


func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")


func _physics_process(delta: float) -> void:
    match network_node.mode:
        NetworkNode.Modes.SERVER:
            server_physics_process(delta)
        NetworkNode.Modes.LOCAL:
            local_client_physics_process(delta)


func server_physics_process(_delta: float) -> void:
    var inputs: Array[Dictionary] = player_input.get_inputs(last_timestamp, Connection.clock_synchronizer.get_time())
    if inputs.is_empty():
        return

    for input in inputs:
        if not input["fi"]:
            continue

        if gun == null:
            continue

        if not gun.fire():
            continue

        # TODO: verify hit (copy code from shot_synchronizer)

        fired.emit()

    last_timestamp = inputs[-1]["ts"]


func local_client_physics_process(_delta: float) -> void:
    if not player_input.fire:
        return

    if gun == null:
        return

    if not gun.fire():
        return

    fired.emit()


func equip_gun(new_gun: Gun) -> Gun:
    var old_gun: Gun = gun

    if old_gun != null:
        remove_child(old_gun)

    gun = new_gun

    add_child(new_gun)

    if network_node.mode == NetworkNode.Modes.SERVER:
        pass

    return old_gun

func lag_compensate() -> void:
    # Lag compensation should only work on the server
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    for other_node: Node3D in Connection.get_network_nodes():
        var other_network_node: NetworkNode = other_node.get_node_or_null("NetworkNode")
        assert(other_network_node != null, "Missing NetworkNode in other network node")

        # Don't handle own node
        if other_network_node.peer_id == network_node.peer_id:
            continue
        
        
func detect_hit() -> Dictionary:
    var space := aim_point.get_world_3d().direct_space_state

    var origin_xform: Transform3D = aim_point.global_transform

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)