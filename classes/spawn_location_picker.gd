class_name SpawnLocationPicker
extends Node3D

static func find_spawn_location_picker(object: Node) -> SpawnLocationPicker:
    for child in object.get_children():
        if child is SpawnLocationPicker:
            return child

    return null

func get_spawn_location() -> Vector3:
    return Vector3.ZERO