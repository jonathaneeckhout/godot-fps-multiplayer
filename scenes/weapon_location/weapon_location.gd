class_name WeaponLocation
extends Area3D

@export var gun_scene: PackedScene = null
@export var respawn_time: float = 5.0
@export var rotation_speed: float = 0.5

@onready var gun_location: Node3D = %GunLocation

var gun: Gun = null

var respawn_timer: Timer = null

func _ready() -> void:
    if multiplayer.is_server():
        assert(gun_scene != null, "GunScene missing")

        gun = gun_scene.instantiate()

        var gun_model: Node3D = gun.drop_scene.instantiate()

        gun_location.add_child(gun_model)

        respawn_timer = Timer.new()
        respawn_timer.name = "RespawnTimer"
        respawn_timer.autostart = false
        respawn_timer.one_shot = true
        respawn_timer.timeout.connect(_on_respawn_timer_timeout)
        add_child(respawn_timer)

    else:
        _get_gun.rpc_id(1)


func _process(delta: float) -> void:
    gun_location.rotate_y(rotation_speed * delta)


func pick_up() -> Gun:
    # This function should only be called on the server
    if not multiplayer.is_server():
        return null

    respawn_timer.start(respawn_time)

    hide()

    %CollisionShape3D.disabled = true

    _pick_up.rpc()
    
    return gun_scene.instantiate()


func _on_respawn_timer_timeout() -> void:
    show()

    %CollisionShape3D.disabled = false

    _respawn.rpc()


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

@rpc("call_remote", "authority", "reliable")
func _pick_up() -> void:
    hide()

    %CollisionShape3D.disabled = true

@rpc("call_remote", "authority", "reliable")
func _respawn() -> void:
    show()

    %CollisionShape3D.disabled = false