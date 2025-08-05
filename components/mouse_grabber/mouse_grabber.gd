class_name MouseGrabber
extends Node

@export var grab_mouse_key: String = "grab_mouse"

var _player: Player = null

func _ready():
    _player = get_parent()
    assert(_player != null)

    if _player.peer_id == multiplayer.get_unique_id():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    else:
        set_process_input(false)
        queue_free()

func _input(event):
    if event.is_action_pressed(grab_mouse_key):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)