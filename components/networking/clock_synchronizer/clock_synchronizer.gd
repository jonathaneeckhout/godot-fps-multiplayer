class_name ClockSynchronizer
extends Node

const LATENCY_BUFFER_SIZE = 9
const LATENCY_BUFFER_MID_POINT = int(LATENCY_BUFFER_SIZE / float(2))
const LATENCY_MINIMUM_THRESHOLD = 20

## Time of the delay between clock sync calls on the client side
@export var client_clock_sync_time: float = 0.5

## The current synced clock, this value should be used on the client side
var clock: float = 0.0

var latency: float = 0.0

var _latency_buffer = []

var _delta_latency: float = 0.0

# Timer used to call the clock syncs
var _client_clock_sync_timer: Timer = null


func _ready() -> void:
    Connection.clock_synchronizer = self

    set_physics_process(false)

    _client_clock_sync_timer = Timer.new()
    _client_clock_sync_timer.name = "ClientClockSyncTimer"
    _client_clock_sync_timer.wait_time = client_clock_sync_time
    _client_clock_sync_timer.autostart = false
    _client_clock_sync_timer.timeout.connect(_on_client_clock_sync_timer_timeout)
    add_child(_client_clock_sync_timer)


func _physics_process(delta) -> void:
    clock += delta + _delta_latency
    _delta_latency = 0


func get_time() -> float:
    if multiplayer.is_server():
        return Time.get_unix_time_from_system()
    else:
        return clock


func start_sync_clock() -> void:
    fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())

    _client_clock_sync_timer.start()

    set_physics_process(true)


func stop_sync_clock() -> void:
    set_physics_process(false)

    _client_clock_sync_timer.stop()


func _on_client_clock_sync_timer_timeout() -> void:
    # If the connection is still up, call the get latency rpc
    if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
        get_latency.rpc_id(1, Time.get_unix_time_from_system())


@rpc("call_remote", "any_peer", "reliable")
func fetch_server_time(client_time: float) -> void:
    if not multiplayer.is_server():
        return

    var id = multiplayer.get_remote_sender_id()
    return_server_time.rpc_id(id, Time.get_unix_time_from_system(), client_time)


@rpc("call_remote", "authority", "reliable")
func return_server_time(server_time: float, client_time: float) -> void:
    latency = (Time.get_unix_time_from_system() - client_time) / 2
    clock = server_time + latency


@rpc("call_remote", "any_peer", "reliable")
func get_latency(client_time: float) -> void:
    if not multiplayer.is_server():
        return

    var id = multiplayer.get_remote_sender_id()
    return_latency.rpc_id(id, client_time)


@rpc("call_remote", "authority", "reliable")
func return_latency(client_time: float) -> void:
    _latency_buffer.append((Time.get_unix_time_from_system() - client_time) / 2)
    if _latency_buffer.size() == LATENCY_BUFFER_SIZE:
        var total_latency = 0
        var total_counted = 0

        _latency_buffer.sort()

        var mid_point_threshold = _latency_buffer[LATENCY_BUFFER_MID_POINT] * 2

        for i in range(LATENCY_BUFFER_SIZE - 1):
            if (
                _latency_buffer[i] < mid_point_threshold
                or _latency_buffer[i] < LATENCY_MINIMUM_THRESHOLD
            ):
                total_latency += _latency_buffer[i]
                total_counted += 1

        var average_latency = total_latency / total_counted
        _delta_latency = average_latency - latency
        latency = average_latency

        _latency_buffer.clear()
