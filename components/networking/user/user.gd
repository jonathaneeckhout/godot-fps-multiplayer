class_name User
extends Node

@export var authentication_deadline_time: float = 10.0

var username: String = ""

var peer_id: int = 0

var logged_in: bool = false

var connection_time: float = 0.0

var authentication_timer: Timer = null

func _ready() -> void:
    connection_time = Time.get_unix_time_from_system()

    authentication_timer = Timer.new()
    authentication_timer.name = "AuthenticationTimer"
    authentication_timer.autostart = true
    authentication_timer.wait_time = authentication_deadline_time
    authentication_timer.timeout.connect(_on_authentication_timer_timeout)
    add_child(authentication_timer)

# Disconnect user when not authenticated in time
func _on_authentication_timer_timeout() -> void:
    if not logged_in:
        multiplayer.multiplayer_peer.disconnect_peer(peer_id)

        queue_free()