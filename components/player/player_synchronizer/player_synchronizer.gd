class_name PlayerSynchronizer
extends Node

@export var head: Node3D = null

var player: Player = null
var player_input: PlayerInput = null

var last_timestamp: float = 0.0

var last_sync_timestamp: float = 0.0
var last_sync_transform: Transform3D

var transform_buffer: Array[Dictionary] = []
var transform_buffer_size: int = 20

var interpolation_offset: float = 0.1

var gravity = ProjectSettings.get_setting(&"physics/3d/default_gravity") * 2

var position_buffer: Array[Dictionary] = []

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    assert(head != null, "Please set head")

    last_sync_timestamp = Connection.clock_synchronizer.get_time()
    last_sync_transform = player.transform


func _physics_process(delta: float) -> void:
    match player.mode:
        Player.Modes.SERVER:
            server_physics_process(delta)
        Player.Modes.LOCAL:
            local_client_physics_process(delta)
        Player.Modes.OTHER:
            other_client_physics_process(delta)


func server_physics_process(delta: float) -> void:
    if player_input.input_buffer.is_empty():
        return

    for input in player_input.input_buffer:
        player.rotate_object_local(Vector3(0, 1, 0), input["la"].x)

        head.rotate_object_local(Vector3(1, 0, 0), input["la"].y)

        head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
        head.rotation.z = 0
        head.rotation.y = 0

        _force_update_is_on_floor()

        if player.is_on_floor():
            var input_dir: Vector2 = input["di"]

            var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

            player.velocity.x = direction.x * player.movement_speed
            player.velocity.z = direction.z * player.movement_speed

            if input["ju"]:
                player.velocity.y = player.jump_force
        else:
            player.velocity.y -= gravity * delta

        player.move_and_slide()

    last_timestamp = player_input.input_buffer[-1]["ts"]

    player_input.input_buffer.clear()

    _sync_trans.rpc(last_timestamp, player.transform)


func local_client_physics_process(delta: float) -> void:
    local_client_sync_translation()

    local_client_process_input(delta)


func local_client_sync_translation() -> void:
    if position_buffer.is_empty():
        return

    while position_buffer.size() > 1 and position_buffer[0]["ts"] < last_sync_timestamp:
        position_buffer.remove_at(0)

    if position_buffer[0]["ts"] == last_sync_timestamp:
        if position_buffer[0]["tr"] != last_sync_transform:
            player.transform = last_sync_transform

            #TODO: reapply inputs
        else:
            player_input.input_buffer.clear()


func local_client_process_input(delta: float) -> void:
    player.rotate_object_local(Vector3(0, 1, 0), player_input.look_angle.x)

    head.rotate_object_local(Vector3(1, 0, 0), player_input.look_angle.y)

    head.rotation.x = clamp(head.rotation.x, -1.57, 1.57)
    head.rotation.z = 0
    head.rotation.y = 0

    if player.is_on_floor():
        var input_dir: Vector2 = player_input.direction

        var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

        player.velocity.x = direction.x * player.movement_speed
        player.velocity.z = direction.z * player.movement_speed

        if player_input.jump:
            player.velocity.y = player.jump_force
    else:
        player.velocity.y -= gravity * delta

    player.move_and_slide()

    player_input.input_buffer.clear()

    position_buffer.append({"ts": player_input.timestamp, "tr": player.transform})


func other_client_physics_process(_delta: float) -> void:
    if transform_buffer.size() < 2:
        player.transform = last_sync_transform
    else:
        var current_time: float = Connection.clock_synchronizer.get_time()
        var render_time: float = current_time - interpolation_offset

        for i in range(transform_buffer.size() - 1):
            if transform_buffer[i]["ts"] <= render_time and transform_buffer[i + 1]["ts"] >= render_time:
                var t: float = (render_time - transform_buffer[i]["ts"]) / (transform_buffer[i + 1]["ts"] - transform_buffer[i]["ts"])
                player.transform = transform_buffer[i]["tr"].interpolate_with(transform_buffer[i + 1]["tr"], t)

                break


func perform_physics_step(fraction: float):
    player.velocity /= fraction
    # Perform the actual move and collision checking
    player.move_and_slide()

    player.velocity *= fraction


@rpc("call_remote", "authority", "unreliable")
func _sync_trans(timestamp: float, transform: Transform3D) -> void:
    # Ignore older updates
    if timestamp < last_sync_timestamp:
        return

    last_sync_timestamp = timestamp
    last_sync_transform = transform

    if player.mode == Player.Modes.OTHER:
        transform_buffer.append({"ts": timestamp, "tr": transform})

        if transform_buffer.size() > transform_buffer_size:
            transform_buffer.remove_at(0)


func _force_update_is_on_floor():
    var old_velocity = player.velocity
    player.velocity = Vector3.ZERO
    player.move_and_slide()
    player.velocity = old_velocity
