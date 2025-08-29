class_name NetworkInterpolator
extends Node

@export var property_paths: Array[String] = []
@export var buffer_size: int = 16
@export var interpolation_offset: float = 0.1

var last_sync_timestamp: float = 0.0

var parent: Node3D = null
var network_node: NetworkNode = null

var buffer: Dictionary[String, Array] = {}

var interpolation_factor: float = 0.0

func _ready() -> void:
    parent = get_parent()
    assert(parent != null, "Parent can't be null")

    network_node = parent.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    # This node is not valid for local players
    if network_node.mode == NetworkNode.Modes.LOCAL:
        set_physics_process(false)
        return

    if network_node.mode == NetworkNode.Modes.OTHER:
        init_buffer()
        return


func init_buffer() -> void:
    for property_path in property_paths:
        buffer[property_path] = []


func _physics_process(delta: float) -> void:
    match network_node.mode:
        NetworkNode.Modes.SERVER:
            server_physics_process(delta)
        NetworkNode.Modes.OTHER:
            other_client_physics_process(delta)


func server_physics_process(_delta: float) -> void:
    var timestamp: float = Connection.clock_synchronizer.get_time()

    var properties: Dictionary = {}

    for property_path in property_paths:
        var property_values = parent.get_node_and_resource(property_path)

        var property_node: Node = property_values[0]
        assert(property_node != null, "Can't find [0]".format([property_path]))

        var property_value = property_node.get_indexed(property_values[2])

        properties[property_path] = property_value

    _sync_trans.rpc(timestamp, properties)


func other_client_physics_process(_delta: float) -> void:
    var current_time: float = Connection.clock_synchronizer.get_time()
    var render_time: float = current_time - interpolation_offset
    
    for property_path: String in buffer:
        var property_values = buffer[property_path]
        if property_values.size() < 2:
            continue

        for i in range(property_values.size() - 1):
            if property_values[i]["ts"] <= render_time and property_values[i + 1]["ts"] >= render_time:
                var t: float = (render_time - property_values[i]["ts"]) / (property_values[i + 1]["ts"] - property_values[i]["ts"])

                interpolation_factor =  t

                var property_value = property_values[i]["pv"]

                var node_values = parent.get_node_and_resource(property_path)
                assert(node_values[0] != null, "Can't find [0]".format([property_path]))

                match typeof(property_value):
                    TYPE_TRANSFORM3D:
                        var value = property_values[i]["pv"].interpolate_with(property_values[i + 1]["pv"], t)
                        node_values[0].set_indexed(node_values[2], value)
                    _:
                        var value = property_values[i]["pv"].lerp(property_values[i + 1]["pv"], t)
                        node_values[0].set_indexed(node_values[2], value)

                break


func buffer_property(timestamp: float, property_path: String, property_value: Variant) -> void:
    var property_buffer: Array = buffer[property_path]

    property_buffer.append({"ts": timestamp, "pv": property_value})

    if property_buffer.size() > buffer_size:
        property_buffer.remove_at(0)


@rpc("call_remote", "authority", "unreliable")
func _sync_trans(timestamp: float, properties: Dictionary) -> void:
    if network_node.mode != NetworkNode.Modes.OTHER:
        return

    if timestamp < last_sync_timestamp:
        return

    last_sync_timestamp = timestamp

    for property_path in properties:
        buffer_property(timestamp, property_path, properties[property_path])
