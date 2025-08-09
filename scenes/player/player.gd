class_name Player
extends CharacterBody3D

enum Modes {LOCAL, OTHER, SERVER}

var username: String = ""
var peer_id: int = 0
var mode: Modes = Modes.SERVER

@export var movement_speed: float = 8.0
@export var jump_force: float = 8.0
@export var mouse_sensitivity: float = 0.4

@onready var head: Node3D = %Head
@onready var model: Node3D = %Model
@onready var camera: Camera3D =  %Camera

func _ready() -> void:
    if multiplayer.is_server():
        mode = Modes.SERVER

        head.hide()
    else:
        if multiplayer.get_unique_id() == peer_id:
            mode = Modes.LOCAL
    
            camera.current = true     

            model.queue_free()
        else:
            mode = Modes.OTHER

            head.hide()
