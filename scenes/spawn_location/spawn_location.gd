class_name SpawnLocation
extends Node3D


func is_free() -> bool:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

    var shape_rid = PhysicsServer3D.sphere_shape_create()
    var radius = 2.0
    PhysicsServer3D.shape_set_data(shape_rid, radius)

    var params = PhysicsShapeQueryParameters3D.new()
    params.shape_rid = shape_rid
    params.transform = global_transform

    var results := space.intersect_shape(params)

    if results.is_empty():
        return true

    for result in results:
        if result.collider is Player:
            return false

    PhysicsServer3D.free_rid(shape_rid)

    return true
