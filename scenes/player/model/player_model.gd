class_name PlayerModel
extends Node3D

@onready var animation_tree: AnimationTree = %AnimationTree

func equip_gun(gun: Gun) -> void:
    var gun_models := %GunPosition.get_children()

    for gun_model in gun_models:
        gun_model.queue_free()

    if gun != null:
        %GunPosition.add_child(gun.model_scene.instantiate())

func fire() -> void:
    animation_tree.set("parameters/ShootOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func reload() -> void:
    animation_tree.set("parameters/ReloadOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func look_up_or_down(value: float) -> void:
    value = clamp(value, -1.0, 1.0)

    animation_tree.set("parameters/IdleBlendSpace1D/blend_position", value)

func stand_still_or_jog(value: float) -> void:
    value = clamp(value, -1.0, 1.0)

    animation_tree.set("parameters/AddIdleJog/add_amount", value)
