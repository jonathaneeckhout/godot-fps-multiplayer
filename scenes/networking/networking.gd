class_name Networking
extends Node

var game_server: GameServer = null
var game_client: GameClient = null
var clock_synchronizer: ClockSynchronizer = null

func _ready() -> void:
    game_server = get_node_or_null("GameServer")
    assert(game_server, "GameServer is missing")

    game_client = get_node_or_null("GameClient")
    assert(game_client != null, "GameClient is missing")

    clock_synchronizer = get_node_or_null("ClockSynchronizer")
    assert(clock_synchronizer != null, "ClockSynchronizer is missing")


    game_client.connected.connect(_on_client_connected)
    game_client.disconnected.connect(_on_client_disconnected)

func _on_client_connected() -> void:
    clock_synchronizer.start_sync_clock()

func _on_client_disconnected() -> void:
    clock_synchronizer.stop_sync_clock()