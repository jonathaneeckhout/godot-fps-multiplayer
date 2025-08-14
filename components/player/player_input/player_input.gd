class_name PlayerInput
extends Node

@export var mouse_sensitivity: float = 0.4

## The amount of inputs buffered
@export var input_buffer_size: int = 64

var direction: Vector2 = Vector2.ZERO
var look_angle: Vector2 = Vector2.ZERO
var jump: bool = false
var fire: bool = false
var next_weapon: bool = false
var previous_weapon: bool = false
var timestamp: float = 0.0

var _override_mouse: bool = true
var _mouse_rotation: Vector2 = Vector2.ZERO
var _wheel_up: bool = false
var _wheel_down: bool = false

# Buffer to store all inputs received from the client
var input_buffer: Array[Dictionary] = []


var player: Player = null
var network_node: NetworkNode = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    if network_node.mode != NetworkNode.Modes.LOCAL:
        set_physics_process(false)
        set_process_input(false)
        return

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

    add_input(timestamp, direction, look_angle, jump, fire)

    _sync_input.rpc_id(1, timestamp, direction, look_angle, jump, fire)

func add_input(ts: float, di: Vector2, la: Vector2, ju: bool, fi: bool) -> void:
    input_buffer.append({"ts": ts, "di": di, "la": la, "ju": ju, "fi": fi})

    if input_buffer.size() > input_buffer_size:
        input_buffer.remove_at(0)

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
    if network_node.peer_id != peer_id:
        return

    add_input(ts, di, la, ju, fi)
