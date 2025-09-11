class_name GunModelLoader
extends Node

@export var local_gun_location: Node3D = null
@export var player_model: PlayerModel = null

var player: Player = null
var network_node: NetworkNode = null

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    assert(local_gun_location != null, "Local Gun Location not set")
    assert(player_model != null, "Player Model not set")


func equip_gun(gun: Gun) -> void:
    var gun_models := local_gun_location.get_children()

    for gun_model in gun_models:
        gun_model.queue_free()

    if network_node.mode == NetworkNode.Modes.LOCAL:
        if gun != null:
            local_gun_location.add_child(gun.model_scene.instantiate())
    else:
        player_model.equip_gun(gun)

    if network_node.mode == NetworkNode.Modes.SERVER:
        _equip_gun.rpc(gun.scene_file_path)

@rpc("call_remote", "authority", "reliable")
func _equip_gun(gun_scene_path: String) -> void:
    var gun_scene: PackedScene = load(gun_scene_path)

    var gun: Gun = gun_scene.instantiate()

    equip_gun(gun)
