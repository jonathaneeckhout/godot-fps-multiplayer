extends PathFollow3D


func _ready()-> void:
    if not multiplayer.is_server():
        set_physics_process(false)

func _physics_process(delta: float)-> void:
    progress += delta * 5