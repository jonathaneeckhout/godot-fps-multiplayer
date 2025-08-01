extends Node3D

func _ready() -> void:
    if "--server" in OS.get_cmdline_args():
        start_server()
    
    if "--client" in OS.get_cmdline_args():
        await get_tree().create_timer(1).timeout
        start_client()


func start_server() -> void:
    get_window().title = "GFM (Server)"

    %GameServer.create_server()

func start_client() -> void:
    get_window().title = "GFM (Client)"

    %GameClient.create_client()
