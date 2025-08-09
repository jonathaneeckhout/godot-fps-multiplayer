class_name RandomSpawnLocationPicker
extends SpawnLocationPicker

func _ready() -> void:
    assert(get_child_count() > 0, "This node should at least have some children to pick random positions")

func get_spawn_location() -> Vector3:
    return get_random_spawn_location()


func get_random_spawn_location() -> Vector3:
    var children: Array[Node] = get_children()

    var random_child: Node3D = children[randi() % children.size()]

    return random_child.position