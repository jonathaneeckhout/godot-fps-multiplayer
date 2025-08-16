class_name ShotSynchronizer
extends Node

signal fired(target: Node3D)

## Point in space which will use as origin for hitscan bullet detection
@export var aim_point: Node3D = null

var player: Player = null
var network_node: NetworkNode = null
var player_input: PlayerInput = null
var transform_synchronizer: TransformSynchronizer = null

var last_timestamp: float = 0.0

var hit_buffer: Array[Dictionary] = []

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    transform_synchronizer = player.get_node_or_null("TransformSynchronizer")
    assert(transform_synchronizer != null, "TransformSynchronizer not found")

    assert(aim_point != null, "Please set aim point")

func _physics_process(delta: float) -> void:
    match network_node.mode:
        NetworkNode.Modes.SERVER:
            server_physics_process(delta)
        NetworkNode.Modes.LOCAL:
            local_client_physics_process(delta)
        NetworkNode.Modes.OTHER:
            other_client_physics_process(delta)

func server_physics_process(_delta: float) -> void:
    for hit: Dictionary in hit_buffer:
        var target: Player = Connection.get_network_node(hit["ni"])
        if target == null:
            continue

        var target_transform_synchronizer: TransformSynchronizer = target.get_node_or_null("TransformSynchronizer")
        assert(target_transform_synchronizer, "TransformSynchronizer not found")

        var player_transform: Transform3D = player.transform

        player.transform = transform_synchronizer.get_closest_transform(hit["ts"])["tf"]

        transform_synchronizer.update_physics()

        var target_transform: Transform3D = target.transform

        target.transform = target_transform_synchronizer.get_closest_transform(hit["ts"])["tf"]

        target_transform_synchronizer.update_physics()

        var is_hit: Dictionary = detect_hit()

        # Make sure to reset transform
        player.transform = player_transform
        target.transform = target_transform

        if is_hit.is_empty():
            continue

        if is_hit.collider.get("network_id") == hit["ni"]:
            hit_comfirmed.rpc_id(hit["id"], hit["ts"], hit["ni"])


    hit_buffer.clear()


func local_client_physics_process(_delta: float) -> void:
    if not player_input.fire:
        return

    var hit: Dictionary = detect_hit()
    if hit.is_empty():
        fired.emit(null)
        return

    var target: Node3D = hit["collider"]

    fired.emit(target)

    var target_network_node: NetworkNode = target.get_node_or_null("NetworkNode")
    # Only detect hits for network objects
    if target_network_node == null:
        return

    hit_detected.rpc_id(1, Connection.clock_synchronizer.get_time(), target_network_node.network_id)

    print("Detected hit on: {0}".format([target_network_node.network_id]))


func other_client_physics_process(_delta: float) -> void:
    pass

func fire() -> void:
    var hit: Dictionary = detect_hit()

    var target: Node3D = null

    if not hit.is_empty():
        target = hit.collider

    fired.emit(target)


func detect_hit() -> Dictionary:
    var space := aim_point.get_world_3d().direct_space_state

    var origin_xform: Transform3D = aim_point.global_transform

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)

@rpc("call_remote", "any_peer", "reliable")
func hit_detected(timestamp: float, network_id: int) -> void:
    # This code should only run on server
    if not multiplayer.is_server():
        return

    # This code is only allowed by the owner of this player
    var peer_id = multiplayer.get_remote_sender_id()
    if network_node.peer_id != peer_id:
        return

    hit_buffer.append({"ts": timestamp, "id": peer_id, "ni": network_id})

@rpc("call_remote", "authority", "reliable")
func hit_comfirmed(_timestamp: float, network_id: int) -> void:
    print("Confirmed hit on: {0}".format([network_id]))
