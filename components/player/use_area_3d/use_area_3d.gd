class_name UseArea3D
extends Area3D

signal gun_entered_range(weapon: WeaponLocation)
signal gun_left_range(weapon: WeaponLocation)

var detected_gun: WeaponLocation = null

var player: Player = null
var network_node: NetworkNode = null
var player_input: PlayerInput = null
var gun_synchronizer: GunSynchronizer = null
var gun_model_loader: GunModelLoader = null

var last_timestamp: float = 0.0

func _ready() -> void:
    player = get_parent()
    assert(player != null)

    network_node = player.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    player_input = player.get_node_or_null("PlayerInput")
    assert(player_input != null, "PlayerInput not found")

    gun_synchronizer = player.get_node_or_null("GunSynchronizer")
    assert(gun_synchronizer != null, "GunSynchronizer not found")

    gun_model_loader = player.get_node_or_null("GunModelLoader")
    assert(gun_model_loader != null, "GunModelLeader not found")

    if network_node.mode != NetworkNode.Modes.SERVER:
        set_physics_process(false)


func _physics_process(_delta: float) -> void:
    var inputs: Array[Dictionary] = player_input.get_inputs(last_timestamp, Connection.clock_synchronizer.get_time())
    if inputs.is_empty():
        return

    for input: Dictionary in inputs:
        if input["us"] and detected_gun != null:
            var picked_up_gun: Gun = detected_gun.pick_up()

            if picked_up_gun == null:
                continue

            gun_synchronizer.equip_gun(picked_up_gun)

            gun_model_loader.equip_gun(picked_up_gun)

    last_timestamp = inputs[-1]["ts"]


func _on_area_shape_entered(_area_rid: RID, area: Area3D, _area_shape_index: int, _local_shape_index: int) -> void:
    if not area is WeaponLocation:
        return

    if detected_gun != null:
        return

    detected_gun = area

    gun_entered_range.emit(detected_gun)


func _on_area_shape_exited(_area_rid: RID, area: Area3D, _area_shape_index: int, _local_shape_index: int) -> void:
    if area != detected_gun:
        return

    detected_gun = null

    gun_left_range.emit(detected_gun)
