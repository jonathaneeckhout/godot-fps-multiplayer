extends Node3D

func _ready() -> void:
    if "--server" in OS.get_cmdline_args():
        start_server()
    
    if "--client" in OS.get_cmdline_args():
        await get_tree().create_timer(1).timeout
        start_client()


func start_server() -> void:
    get_window().title = "GFM (Server)"

    Engine.set_physics_ticks_per_second(10)

    Connection.game_server.create_server()

func start_client() -> void:
    get_window().title = "GFM (Client)"

    Connection.game_client.create_client()

    await Connection.game_client.connected

    Connection.game_client.authenticate("test", "test")

    await Connection.game_client.authenticated

    print("Authenticated")
