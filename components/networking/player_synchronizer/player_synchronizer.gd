class_name PlayerSynchronizer
extends Node

enum Modes {LOCAL, OTHER, SERVER}

var player: Player = null
# Buffer to store all inputs received from the client
var input_buffer: Array[Dictionary] = []

var last_sync_timestamp: float = 0.0
var last_sync_position: Vector3 = Vector3.ZERO
var last_sync_rotation: Vector3 = Vector3.ZERO

var mode: Modes = Modes.SERVER

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    if multiplayer.is_server():
        mode = Modes.SERVER
        return
    else:
        if player.peer_id == multiplayer.get_unique_id():
            mode = Modes.LOCAL

            last_sync_timestamp = Connection.clock_synchronizer.get_time()
            last_sync_position = player.position
            last_sync_rotation = player.rotation
        else:
            mode = Modes.OTHER

            # Don't process input for other players
            set_process_input(false)


func _input(event):
    if event is InputEventMouseMotion:
        # Rotate the player around the axis.
        player.rotate_y(deg_to_rad(-event.relative.x * player.mouse_sensitivity))

        # Look up and down.
        player.local_model.rotate_x(deg_to_rad(-event.relative.y * player.mouse_sensitivity))

        # Ensure not to look too far.
        player.local_model.rotation.x = clamp(player.local_model.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
    match mode:
        Modes.SERVER:
            server_physics_process(delta)
        Modes.LOCAL:
            local_client_physics_process(delta)
        Modes.OTHER:
            other_client_physics_process(delta)

func server_physics_process(delta: float) -> void:
    var last_timestamp: float = 0.0
    
    for input in input_buffer:
        player.velocity.x = input["di"].x * player.movement_speed
        player.velocity.z = input["di"].y * player.movement_speed

        player.rotation.y = input["ro"].y

        if player.is_on_floor() and input["ju"]:
            player.velocity.y = player.jump_force
        else:
            player.velocity += player.get_gravity() * delta

        perform_physics_step(delta / input["dt"])

        last_timestamp = input["ts"]

    input_buffer.clear()

    _sync_trans.rpc(last_timestamp, player.position, player.rotation)


func local_client_physics_process(delta: float) -> void:
    var timestamp: float = Connection.clock_synchronizer.get_time()

    var direction: Vector2 = Input.get_vector("strafe_left", "strafe_right", "move_up", "move_down")

    var transform_direction: Vector3 = (player.transform.basis * Vector3(direction.x, 0, direction.y)).normalized()

    # Calculate the direction compared to the current player's transform basis.
    direction.x = transform_direction.x
    direction.y = transform_direction.z

    var jump: bool = Input.is_action_just_pressed("jump")

    input_buffer.append({"ts": timestamp, "di": direction, "ju": jump, "dt": delta})

    var rotation: Vector3 = player.rotation
    rotation.x = player.local_model.rotation.x

    _sync_input.rpc_id(1, timestamp, direction, rotation, jump, delta)

    local_client_sync_translation()

    local_client_process_input(delta)

func local_client_sync_translation() -> void:
    player.position.x = last_sync_position.x
    player.position.z = last_sync_position.z

    # player.rotation = last_sync_rotation

func local_client_process_input(delta: float) -> void:
    while input_buffer.size() > 0 and input_buffer[0]["ts"] <= last_sync_timestamp:
        input_buffer.remove_at(0)

    for input in input_buffer:
        player.velocity.x = input["di"].x * player.movement_speed
        player.velocity.z = input["di"].y * player.movement_speed

        if player.is_on_floor() and input["ju"]:
            player.velocity.y = player.jump_force
        else:
            player.velocity += player.get_gravity() * delta

        player.move_and_slide()

func other_client_physics_process(_delta: float) -> void:
    player.position = last_sync_position
    player.rotation = last_sync_rotation

func perform_physics_step(fraction: float):
    player.velocity /= fraction
    # Perform the actual move and collision checking
    player.move_and_slide()

    player.velocity *= fraction

@rpc("call_remote", "any_peer", "reliable")
func _sync_input(timestamp: float, direction: Vector2, rotation: Vector3, jump: bool, delta: float) -> void:
    if not multiplayer.is_server():
        return

    input_buffer.append({"ts": timestamp, "di": direction, "ro": rotation, "ju": jump, "dt": delta})


@rpc("call_remote", "authority", "unreliable")
func _sync_trans(timestamp: float, position: Vector3, rotation: Vector3) -> void:
    # Ignore older updates
    if timestamp < last_sync_timestamp:
        return

    last_sync_timestamp = timestamp
    last_sync_position = position
    last_sync_rotation = rotation
