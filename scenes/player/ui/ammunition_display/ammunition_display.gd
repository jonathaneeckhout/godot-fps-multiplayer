class_name AmmunitionDisplay
extends Control

@export var gun_synchronizer: GunSynchronizer = null

func _ready() -> void:
    assert(gun_synchronizer != null, "GunSynchronizer not set")

    gun_synchronizer.fired.connect(_on_fired)
    gun_synchronizer.reloaded.connect(_on_reloaded)

    update_display()


func update_display() -> void:
    var gun: Gun = gun_synchronizer.get_gun()

    if gun == null:
        %AmmoLabel.text = "- / -"

        return

    %AmmoLabel.text = "{0} / {1}".format([gun.get_magazine(), gun.get_spare_bullets()])


func _on_fired() -> void:
    update_display()


func _on_reloaded() -> void:
    update_display()
