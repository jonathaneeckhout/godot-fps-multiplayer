class_name Player
extends CharacterBody3D

var username: String = ""
var peer_id: int = 0

@export var movement_speed: float = 5.0
@export var jump_force: float = 10.0

@onready var local_camera: Camera3D = %LocalCamera
@onready var other_model: Node3D = %OtherModel

func _ready() -> void:
    if multiplayer.is_server():
        local_camera.queue_free()
    else:
        if multiplayer.get_unique_id() == peer_id:
            local_camera.current = true

            other_model.queue_free()
        else:
            local_camera.current = false
