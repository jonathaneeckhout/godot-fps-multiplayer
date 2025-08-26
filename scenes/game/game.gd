class_name Game
extends Node3D

func _ready() -> void:
    if multiplayer.is_server():
        var moving_target: MovingTarget = load("res://scenes/moving_target/moving_target.tscn").instantiate()
        moving_target.move = true
        %NetworkNodes.add_child(moving_target)

        moving_target = load("res://scenes/moving_target/moving_target.tscn").instantiate()
        moving_target.move = false
        moving_target.position = Vector3(0,0,1)
        %NetworkNodes.add_child(moving_target)