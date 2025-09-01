class_name GunSynchronizer
extends Node

signal fired()
signal reloaded()

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

    for input: Dictionary in inputs:
        handle_fire(input["ts"], input["fi"])

        handle_reload(input["re"])

    last_timestamp = inputs[-1]["ts"]


func local_client_physics_process(_delta: float) -> void:
    handle_fire(Connection.clock_synchronizer.get_time(), player_input.fire)

    handle_reload(player_input.reload)


func handle_fire(timestamp: float, fire: bool) -> void:
    if not fire:
        return

    if gun == null:
        return

    if not gun.fire():
        return

    if network_node.mode == NetworkNode.Modes.SERVER:
        lag_compensate_shot(timestamp)

    fired.emit()

func handle_reload(reload: bool) -> void:
    if not reload:
        return

    if gun == null:
        return

    if not gun.reload():
        return

    reloaded.emit()

func equip_gun(new_gun: Gun) -> Gun:
    var old_gun: Gun = gun

    if old_gun != null:
        remove_child(old_gun)

    gun = new_gun

    add_child(new_gun)

    if network_node.mode == NetworkNode.Modes.SERVER:
        pass

    return old_gun

func lag_compensate_shot(timestamp: float) -> void:
    # Gun should not be null
    if gun == null:
        return

    # Lag compensation should only work on the server
    if network_node.mode != NetworkNode.Modes.SERVER:
        return

    var network_nodes: Array[Node3D] = Connection.get_network_nodes()

    # The player sees other nodes in the past so substract the interpolation offset
    var interpolated_timestamp: float = timestamp - 0.1

    var old_transforms: Dictionary[int, Transform3D] = {}

    # Set the other nodes transform to the time the shot was fired
    for other_node: Node3D in network_nodes:
        var other_network_node: NetworkNode = other_node.get_node_or_null("NetworkNode")
        assert(other_network_node != null, "Missing NetworkNode in other network node")

        # Don't handle own node
        if other_network_node.network_id == network_node.network_id:
            continue

        var other_property_buffer: PropertyBuffer = other_node.get_node_or_null("PropertyBuffer")
        assert(other_property_buffer, "PropertyBuffer not found")

        old_transforms[other_network_node.network_id] = other_node.transform

        other_node.transform = other_property_buffer.get_interpolated_transform(":transform", interpolated_timestamp)

        other_node.force_update_transform()

    var hit: Dictionary = detect_hit()

    # Restore the transforms of the other network nodes
    for other_node: Node3D in network_nodes:
        var other_network_node: NetworkNode = other_node.get_node_or_null("NetworkNode")
        assert(other_network_node != null, "Missing NetworkNode in other network node")

        # Don't handle own node
        if other_network_node.network_id == network_node.network_id:
            continue

        other_node.transform = old_transforms[other_network_node.network_id]

        other_node.force_update_transform()

    # Didn't hit anything, return
    if hit.is_empty():
        return

    var collider: Node3D = hit.collider as Node3D

    var collider_network_node: NetworkNode = collider.get_node_or_null("NetworkNode")
    if collider_network_node == null:
        return

    var collider_health_synchronizer: HealthSynchronizer = collider.get_node_or_null("HealthSynchronizer")
    if collider_health_synchronizer != null:
        collider_health_synchronizer.hurt(gun.get_damage())


func detect_hit() -> Dictionary:
    var space := aim_point.get_world_3d().direct_space_state

    var origin_xform: Transform3D = aim_point.global_transform

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)

func get_gun() -> Gun:
    return gun