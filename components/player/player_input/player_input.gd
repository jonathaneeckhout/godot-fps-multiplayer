class_name PlayerInput
extends Node

@export var mouse_sensitivity: float = 0.4

## The amount of inputs buffered
@export var inputs_buffered: int = 64

var direction: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var jump: bool = false
var fire: bool = false
var next_weapon: bool = false
var previous_weapon: bool = false
var timestamp: float = 0.0

var _override_mouse: bool = false
var _mouse_rotation: Vector2 = Vector2.ZERO
var _wheel_up: bool = false
var _wheel_down: bool = false

# Buffer to store all inputs received from the client
var input_buffer: Array[Dictionary] = []

# TODO: optimize this, don't use 2 different buffers
var shot_buffer: Array[Dictionary] = []

var player: Player = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    if player.peer_id != multiplayer.get_unique_id():
        set_physics_process(false)
        set_process_input(false)
        return

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _mouse_rotation.y = event.relative.x * mouse_sensitivity
        _mouse_rotation.x = - event.relative.y * mouse_sensitivity

    if event.is_action_pressed("escape"):
        _override_mouse = !_override_mouse

        if _override_mouse:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if event is InputEventMouseButton:
        if event.is_pressed():
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                _wheel_up = true
            elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                _wheel_down = true

func _physics_process(delta):
    timestamp = Connection.clock_synchronizer.get_time()

    direction = Input.get_vector("strafe_right", "strafe_left", "move_down", "move_up")

    jump = Input.is_action_just_pressed("jump")

    fire = Input.is_action_just_pressed("fire")

    if _override_mouse:
        look_angle = Vector2.ZERO
    else:
        look_angle = Vector2(-_mouse_rotation.y * delta, -_mouse_rotation.x * delta)

    _mouse_rotation = Vector2.ZERO

    next_weapon = _wheel_up
    previous_weapon = _wheel_down

    _wheel_up = false
    _wheel_down = false

    input_buffer.append({"ts": timestamp, "di": direction, "la": look_angle, "ju": jump, "fi": fire})

    shot_buffer.append({"ts": timestamp, "fi": fire})

    _sync_input.rpc_id(1, timestamp, direction, look_angle, jump, fire)

func get_inputs(from: float, to: float) -> Array[Dictionary]:
    var filtered_inputs: Array[Dictionary] = []

    for input in input_buffer:
        var ts: float = input["ts"]
        # Don't take the from field as it would result in too many inputs (thus no ts >= from but ts > from)
        if ts > from and ts <= to:
            filtered_inputs.append(input)

    return filtered_inputs

@rpc("call_remote", "any_peer", "reliable")
func _sync_input(ts: float, di: Vector2, la: Vector2, ju: bool, fi: bool) -> void:
    if not multiplayer.is_server():
        return

    var peer_id = multiplayer.get_remote_sender_id()
    if player.peer_id != peer_id:
        return

    input_buffer.append({"ts": ts, "di": di, "la": la, "ju": ju, "fi": fi})

    shot_buffer.append({"ts": ts, "fi": fi})

    if input_buffer.size() > inputs_buffered:
        input_buffer.remove_at(0)
