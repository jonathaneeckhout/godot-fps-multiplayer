class_name RandomSpawnLocationPicker
extends SpawnLocationPicker

func _ready() -> void:
    assert(get_child_count() > 0, "This node should at least have some children to pick random positions")

func get_spawn_location() -> Vector3:
    return get_random_free_spawn_location()

func get_random_free_spawn_location() -> Vector3:
    var children: Array[Node] = get_children()

    var free_locations: Array[SpawnLocation] = []

    # Collect all free spawn locations
    for child in children:
        if child is SpawnLocation and child.is_free():
            free_locations.append(child)

    # If no free locations, return a default or error
    if free_locations.size() == 0:
        push_error("No free spawn locations available!")
        return Vector3.ZERO

    # Pick a random free location
    var random_free_child: SpawnLocation = free_locations[randi() % free_locations.size()]
    return random_free_child.position
