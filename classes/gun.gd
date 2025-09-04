class_name Gun
extends Node

@export var damage: int = 10
@export var mag_size: int = 20
@export var max_bullets = 80
@export var automatic: bool = false
@export var shots_per_second: float = 3.0
@export var reload_time: float = 1.5

## The scene which will be used as part of the player's model
@export var model_scene: PackedScene = null

## The scene which will be used as a drop item
@export var drop_scene: PackedScene = null

var magazine: int = mag_size
var spare_bullets: int = max_bullets
var last_fire: float = 0.0
var time_between_shots: float = 1 / shots_per_second
var is_reloading: bool = false

func _ready() -> void:
    magazine = mag_size

    spare_bullets = max_bullets

    time_between_shots = 1 / shots_per_second


func fire() -> bool:
    if is_mag_empty() or is_reloading:
        return false

    var current_time: float = Connection.clock_synchronizer.get_time()

    if automatic and (current_time - last_fire <= time_between_shots):
        return false

    magazine -= 1

    last_fire = current_time

    return true


func reload() -> bool:
    if is_out_of_ammo() or is_reloading:
        return false

    if magazine == mag_size:
        return false

    is_reloading = true

    await get_tree().create_timer(reload_time).timeout

    var bullets_needed: int = mag_size - magazine
    var bullets_to_reload: int = min(bullets_needed, spare_bullets)

    magazine += bullets_to_reload
    spare_bullets -= bullets_to_reload
    is_reloading = false

    return true


func is_mag_empty() -> bool:
    return magazine == 0


func is_out_of_ammo() -> bool:
    return is_mag_empty() and spare_bullets == 0


func get_magazine() -> int:
    return magazine


func get_spare_bullets() -> int:
    return spare_bullets


func get_damage() -> int:
    return damage
