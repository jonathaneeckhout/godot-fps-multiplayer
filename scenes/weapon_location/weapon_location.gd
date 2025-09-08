class_name WeaponLocation
extends Area3D

@export var gun_scene: PackedScene = null
@export var respawn_time: float = 30.0
@export var rotation_speed: float = 0.5

@onready var gun_location: Node3D = %GunLocation

var gun: Gun = null

func _ready() -> void:
    if multiplayer.is_server():
        assert(gun_scene != null, "GunScene missing")

        gun = gun_scene.instantiate()

        var gun_model: Node3D = gun.drop_scene.instantiate()

        gun_location.add_child(gun_model)
    else:
        _get_gun.rpc_id(1)


func _process(delta: float) -> void:
    gun_location.rotate_y(rotation_speed * delta)


@rpc("call_remote", "any_peer", "reliable")
func _get_gun() -> void:
    if not multiplayer.is_server():
        return

    var peer_id = multiplayer.get_remote_sender_id()

    _return_gun.rpc_id(peer_id, gun.scene_file_path)


@rpc("call_remote", "authority", "reliable")
func _return_gun(gun_path: String) -> void:
    gun_scene = load(gun_path)
    
    gun = gun_scene.instantiate()

    var gun_model: Node3D = gun.drop_scene.instantiate()

    gun_location.add_child(gun_model)
