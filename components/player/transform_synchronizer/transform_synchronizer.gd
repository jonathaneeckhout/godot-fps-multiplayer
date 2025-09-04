class_name TransformSynchronizer
extends Node

@export var head: Node3D = null

var player: Player = null
var network_node: NetworkNode = null
var player_input: PlayerInput = null

var last_timestamp: float = 0.0

var last_sync_timestamp: float = 0.0
var last_sync_transform: Transform3D
var last_head_rotation: Vector3 = Vector3.ZERO

var interpolation_offset: float = 0.1
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2
var position_buffer: Array[Dictionary] = []

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    assert(head != null, "Please set head")

    last_sync_timestamp = Connection.clock_synchronizer.get_time()
    last_sync_transform = player.transform


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
        apply_head_rotation(input["la"])

        update_physics()

        apply_movement_and_gravity(input["di"], input["ju"])

    last_timestamp = inputs[-1]["ts"]

    _sync_trans.rpc_id(network_node.peer_id, last_timestamp, player.transform, head.rotation)

func local_client_physics_process(_delta: float) -> void:
    local_client_sync_translation()

    apply_head_rotation(player_input.look_angle)

    apply_movement_and_gravity(player_input.direction, player_input.jump)

    position_buffer.append({"ts": player_input.timestamp, "tf": player.transform})

func local_client_sync_translation() -> void:
    if position_buffer.is_empty():
        return

    while position_buffer.size() > 1 and position_buffer[0]["ts"] < last_sync_timestamp:
        position_buffer.remove_at(0)

    if position_buffer[0]["ts"] == last_sync_timestamp:
        if position_buffer[0]["tf"] != last_sync_transform:
            print("Expected {0} but got {1}".format([position_buffer[0]["tf"], last_sync_transform]))
            player.transform = last_sync_transform


func apply_head_rotation(look_angle: Vector2) -> void:
    player.rotate_object_local(Vector3(0, 1, 0), look_angle.x)
    head.rotate_object_local(Vector3(1, 0, 0), look_angle.y)

    head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
    head.rotation.z = 0
    head.rotation.y = 0

func apply_movement_and_gravity(input_dir: Vector2, jump: bool) -> void:
    if player.is_on_floor():
        var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
        player.velocity.x = direction.x * player.movement_speed
        player.velocity.z = direction.z * player.movement_speed
        if jump:
            player.velocity.y = player.jump_force
    else:
        player.velocity.y -= gravity * get_physics_process_delta_time()

    player.move_and_slide()

func perform_physics_step(fraction: float):
    player.velocity /= fraction

    player.move_and_slide()

    player.velocity *= fraction

@rpc("call_remote", "authority", "unreliable")
func _sync_trans(ts: float, tf: Transform3D, hr: Vector3) -> void:
    if ts < last_sync_timestamp:
        return

    last_sync_timestamp = ts
    last_sync_transform = tf
    last_head_rotation = hr


func update_physics():
    var old_velocity = player.velocity
    player.velocity = Vector3.ZERO
    player.move_and_slide()
    player.velocity = old_velocity
