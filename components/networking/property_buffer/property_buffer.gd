class_name PropertyBuffer
extends Node

@export var property_paths: Array[String] = []
@export var buffer_size: int = 64

var parent: Node3D = null
var network_node: NetworkNode = null
var buffer: Dictionary[String, Array] = {}

func _ready() -> void:
    parent = get_parent()
    assert(parent != null, "Parent can't be null")

    network_node = parent.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    # This node is only valid on the server (for now)
    if network_node.mode != NetworkNode.Modes.SERVER:
        set_physics_process(false)
        return

    init_buffer()

func init_buffer() -> void:
    for property_path in property_paths:
        buffer[property_path] = []

func _physics_process(_delta: float) -> void:
    var timestamp: float = Connection.clock_synchronizer.get_time()

    for property_path in buffer:
        buffer_property(timestamp, property_path)


func buffer_property(timestamp: float, property_path: String) -> void:
    var property_buffer: Array = buffer[property_path]

    var property_values = parent.get_node_and_resource(property_path)

    var property_node: Node = property_values[0]
    assert(property_node != null, "Can't find [0]".format([property_path]))

    var property_value = property_node.get_indexed(property_values[2])

    property_buffer.append({"ts": timestamp, "pv": property_value})

    if property_buffer.size() > buffer_size:
        property_buffer.remove_at(0)

func get_closest_value(property_path: String, timestamp: float) -> Variant:
    if not buffer.has(property_path):
        return null

    var property_buffer: Array = buffer[property_path]

    if property_buffer.is_empty():
        return null

    var closest_entry = property_buffer[0]
    var min_diff = abs(property_buffer[0]["ts"] - timestamp)

    for entry in property_buffer:
        var current_diff = abs(entry["ts"] - timestamp)
        if current_diff < min_diff:
            min_diff = current_diff
            closest_entry = entry

    return closest_entry["pv"]

func get_interpolated_transform(property_path: String, timestamp: float) -> Transform3D:
    if not buffer.has(property_path) or buffer[property_path].is_empty():
        return Transform3D.IDENTITY
    var property_buffer = buffer[property_path]
    # Find the two entries to interpolate between
    var lower = property_buffer[0]
    var upper = property_buffer[-1]
    for i in range(property_buffer.size() - 1):
        if property_buffer[i]["ts"] <= timestamp and property_buffer[i + 1]["ts"] >= timestamp:
            lower = property_buffer[i]
            upper = property_buffer[i + 1]
            break
    # Linear interpolation for Transform3D
    var t = (timestamp - lower["ts"]) / (upper["ts"] - lower["ts"])
    return lower["pv"].interpolate_with(upper["pv"], t)

func _get_empty_value() -> Dictionary:
    return {"ts": Connection.clock_synchronizer.get_time(), "pv": null}
