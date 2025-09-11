class_name NetworkNodesSpawner
extends Node3D

## Nodes which should be moved towards to target
@export var network_nodes_sources: Array[Node3D] = []
@export var player_scene: PackedScene = null

var spawn_location_picker: SpawnLocationPicker = null


func _ready() -> void:
    assert(player_scene != null, "Please select a scene for the players")

    spawn_location_picker = SpawnLocationPicker.find_spawn_location_picker(get_parent())
    assert(spawn_location_picker != null)

    if multiplayer.is_server():
        assert(Connection.game_server != null)
        Connection.game_server.user_connected.connect(_on_user_connected)
        Connection.game_server.user_disconnected.connect(_on_user_disconnected)

        Connection.map_spawner.player_map_loaded.connect(_on_player_map_loaded)

        child_entered_tree.connect(_on_child_entered)
        child_exiting_tree.connect(_on_child_exited)

        copy_network_nodes()

        remove_all_nodes()
    else:
        # On the client all the nodes should be removed as they should be synced from the server to the client.
        remove_all_nodes()

func _on_user_connected(peer_id: int, username: String) -> void:
    add_node(peer_id, -1, username, spawn_location_picker.get_spawn_location(), player_scene.resource_path)


func _on_user_disconnected(_peer_id: int, username: String) -> void:
    remove_node(username)


func _on_player_map_loaded(peer_id: int):
    for child in get_children():
        var network_node: NetworkNode = child.get_node_or_null("NetworkNode")
        assert(network_node != null, "Missing NetworkNode")

        _add_network_node.rpc_id(peer_id, network_node.peer_id, network_node.network_id, child.name, child.position, child.scene_file_path)


func add_node(peer_id: int, network_id: int, node_name: String, node_position: Vector3, scene_path: String) -> void:
    var node_scene: PackedScene = load(scene_path)

    var node: Node3D = node_scene.instantiate()
    node.name = node_name
    node.position = node_position

    var network_node: NetworkNode = node.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    network_node.peer_id = peer_id

    var respawner: Respawner = node.get_node_or_null("Respawner")
    if respawner != null:
        respawner.respawned.connect(_on_node_respawned)

    if network_id >= 0:
        network_node.network_id = network_id

    add_child(node)


func remove_node(node_name: String) -> void:
    var node = get_node_or_null(node_name)
    if node == null:
        return

    remove_child(node)


func copy_network_nodes() -> void:
    for parent_node: Node3D in network_nodes_sources:
        var children := parent_node.get_children()
        for child in children:
            parent_node.remove_child(child)

            add_child(child)


func remove_all_nodes() -> void:
    for node: Node3D in network_nodes_sources:
        node.queue_free()

func _on_child_entered(child: Node) -> void:
    assert(child is Node3D, "Wrong type of child entered network nodes")

    var network_node: NetworkNode = child.get_node_or_null("NetworkNode")
    assert(network_node != null, "Missing NetworkNode")

    _add_network_node.rpc(network_node.peer_id, network_node.network_id, child.name, child.position, child.scene_file_path)


func _on_child_exited(child: Node) -> void:
    _remove_network_node.rpc(child.name)


func _on_node_respawned(node: Node3D) -> void:
    node.position = spawn_location_picker.get_spawn_location()


@rpc("call_remote", "authority", "reliable")
func _add_network_node(peer_id: int, network_id: int, node_name: String, node_position: Vector3, scene_path: String) -> void:
    # Prevent doubles
    if get_node_or_null(node_name) != null:
        return

    add_node(peer_id, network_id, node_name, node_position, scene_path)


@rpc("call_remote", "authority", "reliable")
func _remove_network_node(node_name: String) -> void:
    remove_node(node_name)
