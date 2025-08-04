class_name UsernameAuthenticator
extends Node

func _validate_username(username: String) -> bool:
    if username == null:
        return false

    if username == "":
        return false

    return true

func authenticate(username: String) -> bool:
    return _validate_username(username)