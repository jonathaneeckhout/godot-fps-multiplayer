class_name PlayerSynchronizer
extends Node

var player: Player = null
# Buffer to store all inputs received from the client
var input_buffer: Array[Dictionary] = []

var last_sync_frame: float = 0.0

var client_translation_buffer: Array[Dictionary] = []

func _ready() -> void:
    player = get_parent()
    assert(player != null)

func _physics_process(delta: float) -> void:
    if multiplayer.is_server():
        server_physics_process(delta)
    else:
        client_physics_process(delta)

func server_physics_process(delta: float) -> void:
    var last_timestamp: float = 0.0
    
    for input in input_buffer:
        player.velocity.x = input["di"].x * player.movement_speed
        player.velocity.z = input["di"].y * player.movement_speed

        if player.is_on_floor() and input["ju"]:
            player.velocity.y = player.jump_force
        else:
            player.velocity += player.get_gravity() * delta

        perform_physics_step(delta / input["dt"])

        last_timestamp = input["ts"]

    input_buffer.clear()

    _sync_trans.rpc(last_timestamp, player.position, player.rotation)


func client_physics_process(delta: float) -> void:
    var timestamp: float = Connection.clock_synchronizer.get_time()

    var direction: Vector2 = Input.get_vector("strafe_left", "strafe_right", "move_up", "move_down")
    var jump: bool = Input.is_action_just_pressed("jump")

    input_buffer.append({"ts": timestamp, "di": direction, "ju": jump, "dt": delta})

    _sync_input.rpc_id(1, timestamp, direction, jump, delta)

    client_process_input(delta)

func client_process_input(delta: float) -> void:
    if client_translation_buffer.is_empty():
        return

    if client_translation_buffer.size() > 1:
        var last_entity = client_translation_buffer[-1]

        client_translation_buffer.clear()

        client_translation_buffer.append(last_entity)

    # Set the translation to the last known place
    var translation = client_translation_buffer[0]

    player.position = translation["po"]
    player.rotation = translation["ro"]

    while input_buffer.size() > 0 and input_buffer[0]["ts"] <= translation["ts"]:
        input_buffer.remove_at(0)

    for input in input_buffer:
        player.velocity.x = input["di"].x * player.movement_speed
        player.velocity.z = input["di"].y * player.movement_speed

        if player.is_on_floor() and input["ju"]:
            player.velocity.y = player.jump_force
        else:
            player.velocity += player.get_gravity() * delta

        player.move_and_slide()

func perform_physics_step(fraction: float):
    player.velocity /= fraction
    # Perform the actual move and collision checking
    player.move_and_slide()

    player.velocity *= fraction

@rpc("call_remote", "any_peer", "reliable")
func _sync_input(timestamp: float, direction: Vector2, jump: bool, delta: float) -> void:
    if not multiplayer.is_server():
        return

    input_buffer.append({"ts": timestamp, "di": direction, "ju": jump, "dt": delta})


@rpc("call_remote", "authority", "unreliable")
func _sync_trans(timestamp: float, position: Vector3, rotation: Vector3) -> void:
    if timestamp < last_sync_frame:
        return

    last_sync_frame = timestamp

    client_translation_buffer.append({"ts": timestamp, "po": position, "ro": rotation})
