class_name AnimationSynchronizer
extends Node

@export var head: Node3D = null

var player: Player = null
var gun_synchronizer: GunSynchronizer = null
var network_node: NetworkNode = null
var player_model: PlayerModel = null

var prev_position: Vector3 = Vector3.ZERO

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    gun_synchronizer = player.get_node_or_null("GunSynchronizer")
    assert(gun_synchronizer != null, "GunSynchronizer not found")

    player_model = player.get_node_or_null("PlayerModel")
    assert(player_model != null, "Please set PlayerModel")

    assert(head != null, "Please set head")

    prev_position = player.position

    gun_synchronizer.fired.connect(_on_fired)
    gun_synchronizer.reloaded.connect(_on_reloaded)


func _on_fired() -> void:
    if network_node.mode == network_node.Modes.LOCAL:
        return

    player_model.fire()


func _on_reloaded() -> void:
    if network_node.mode == network_node.Modes.LOCAL:
        return

    player_model.reload()

func _physics_process(_delta: float) -> void:
    if network_node.mode == network_node.Modes.LOCAL:
        return

    # Handle head look up or down
    var normalized_pitch: float = head.rotation.x / (PI / 2)

    normalized_pitch = clamp(normalized_pitch, -1.0, 1.0)

    player_model.look_up_or_down(normalized_pitch)

    # Calculate the movement vector between the current and previous player positions.
    var movement: Vector3 = player.position - prev_position

    # Update the previous position to the current player position.
    prev_position = player.position

    # Check if the player is stationary.
    if movement.is_zero_approx():
        player_model.stand_still_or_jog(0.0)
    else:
        player_model.stand_still_or_jog(1.0)
