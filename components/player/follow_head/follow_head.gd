## This node will make another node follow the head rotation. 
## This is usefull as the head is only visible on the local player thus this component is needed for other players model.
class_name FollowHead
extends Node

@export var head: Node3D = null
@export var replica: Node3D = null

var player: Player = null

func _ready() -> void:
    player = get_parent()
    assert(player != null, "Player not found")

    assert(head != null, "Please set head")
    assert(replica != null, "Please set replica")

    if player.peer_id == multiplayer.get_unique_id():
        set_physics_process(false)
    
func _physics_process(_delta: float) -> void:
    replica.rotation = head.rotation
