class_name PlayerInput
extends Node

var direction: Vector2 = Vector2.ZERO
var jump: bool = false
var timestamp: float = 0.0

# Buffer to store all inputs received from the client
var input_buffer: Array[Dictionary] = []

var player: Player = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    if player.peer_id != multiplayer.get_unique_id():
        set_physics_process(false)


func _physics_process(delta):
    timestamp = Connection.clock_synchronizer.get_time()

    direction = Input.get_vector("strafe_left", "strafe_right", "move_up", "move_down")

    var transform_direction: Vector3 = (player.transform.basis * Vector3(direction.x, 0, direction.y)).normalized()

    # Calculate the direction compared to the current player's transform basis.
    direction.x = transform_direction.x
    direction.y = transform_direction.z

    jump = Input.is_action_just_pressed("jump")

    input_buffer.append({"ts": timestamp, "di": direction, "ju": jump, "dt": delta})

    var rotation: Vector3 = player.rotation
    rotation.x = player.local_model.rotation.x

    _sync_input.rpc_id(1, timestamp, direction, rotation, jump, delta)


@rpc("call_remote", "any_peer", "reliable")
func _sync_input(ts: float, dir: Vector2, rotation: Vector3, ju: bool, delta: float) -> void:
    if not multiplayer.is_server():
        return

    var peer_id = multiplayer.get_remote_sender_id()
    if player.peer_id != peer_id:
        return

    input_buffer.append({"ts": ts, "di": dir, "ro": rotation, "ju": ju, "dt": delta})
