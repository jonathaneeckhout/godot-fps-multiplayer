class_name Player
extends CharacterBody3D

enum Modes {LOCAL, OTHER, SERVER}

var username: String = ""

@export var movement_speed: float = 8.0
@export var jump_force: float = 8.0
@export var mouse_sensitivity: float = 0.4

@onready var hud: CanvasLayer = %HUDCanvasLayer
@onready var head: Node3D = %Head
@onready var player_model: PlayerModel = %PlayerModel
@onready var camera: Camera3D = %Camera

var network_node: NetworkNode = null
var gun_synchronizer: GunSynchronizer = null

func _ready() -> void:
    network_node = get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    gun_synchronizer = get_node_or_null("GunSynchronizer")
    assert(gun_synchronizer != null, "Missing GunSynchronizer")

    match network_node.mode:
        network_node.Modes.SERVER:
            head.hide()

            hud.queue_free()
        network_node.Modes.LOCAL:
            player_model.queue_free()

            camera.current = true

        network_node.Modes.OTHER:
            head.hide()

            hud.queue_free()

    # Todo: remove debug lines
    # var gun: Gun = load("res://scenes/guns/pistol/Pistol.tscn").instantiate()

    var gun: Gun = load("res://scenes/guns/rifle/Rifle.tscn").instantiate()

    gun_synchronizer.equip_gun(gun)
