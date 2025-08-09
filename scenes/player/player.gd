class_name Player
extends CharacterBody3D

enum Modes {LOCAL, OTHER, SERVER}

var username: String = ""
var peer_id: int = 0
var mode: Modes = Modes.SERVER

@export var movement_speed: float = 8.0
@export var jump_force: float = 8.0
@export var mouse_sensitivity: float = 0.4

@onready var local_camera: Camera3D = %LocalCamera
@onready var other_model: Node3D = %OtherModel
@onready var local_model: Node3D = %LocalModel

func _ready() -> void:
    if multiplayer.is_server():
        mode = Modes.SERVER

        local_camera.hide()
    else:
        if multiplayer.get_unique_id() == peer_id:
            mode = Modes.LOCAL
    
            local_camera.current = true

            other_model.queue_free()
        else:
            mode = Modes.OTHER

            local_model.queue_free()
