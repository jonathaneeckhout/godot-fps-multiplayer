class_name MovingTarget
extends StaticBody3D


@export var move: bool = false
@export var move_distance: float = 10.0
@export var move_speed: float = 5.0

var network_node: NetworkNode = null

var start_position: Vector3
var direction: int = 1
var left_target: Vector3
var right_target: Vector3

func _ready() -> void:
    start_position = position

    left_target = start_position - Vector3.RIGHT * move_distance
    right_target = start_position + Vector3.RIGHT * move_distance

    network_node = get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    # This node should only run on the server
    if network_node.mode != NetworkNode.Modes.SERVER:
        set_physics_process(false)
        return


func _physics_process(delta: float) -> void:
    if not move:
        return

    var target_position = right_target if direction == 1 else left_target

    var new_position = position.move_toward(target_position, move_speed * delta)
    position = new_position

    if position.distance_to(target_position) < 0.1:
        direction *= -1
