class_name ShotSynchronizer
extends Node

signal fired(target: Node3D)

## Point in space which will use as origin for hitscan bullet detection
@export var aim_point: Node3D = null

var player: Player = null
var player_input: PlayerInput = null

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    assert(aim_point != null, "Please set aim point")

func _physics_process(delta: float) -> void:
    match player.mode:
        Player.Modes.SERVER:
            server_physics_process(delta)
        Player.Modes.LOCAL:
            local_client_physics_process(delta)
        Player.Modes.OTHER:
            other_client_physics_process(delta)

func server_physics_process(_delta: float) -> void:
    if player_input.shot_buffer.is_empty():
        return
    
    for input in player_input.shot_buffer:
        if input["fi"]:
            fire()

    player_input.shot_buffer.clear()

func local_client_physics_process(_delta: float) -> void:
    if player_input.fire:
        fire()

    player_input.shot_buffer.clear()

func other_client_physics_process(_delta: float) -> void:
    pass

func fire() -> void:
    var hit: Dictionary = detect_hit()

    var target: Node3D = null

    if not hit.is_empty():
        target = hit.collider

    fired.emit(target)

    print("{0} side hit: {1}".format([multiplayer.get_unique_id(), target]))


func detect_hit() -> Dictionary:
    var space := aim_point.get_world_3d().direct_space_state

    var origin_xform: Transform3D = aim_point.global_transform

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        origin_xform.origin,
        origin_xform.origin + origin_xform.basis.z * 1024.
    )

    return space.intersect_ray(query)