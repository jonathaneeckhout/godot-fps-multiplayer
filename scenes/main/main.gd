extends Node3D


func _ready() -> void:
    if "--server" in OS.get_cmdline_args():
        start_server()
    
    if "--client" in OS.get_cmdline_args():
        await get_tree().create_timer(1).timeout
        start_client()


func start_server() -> void:
    get_window().title = "GFM (Server)"

    %MapSpawner.load_map("Game")

    Engine.set_physics_ticks_per_second(30)

    Connection.game_server.create_server()

    get_tree().root.mode = Window.MODE_MINIMIZED


func start_client() -> void:
    get_window().title = "GFM (Client)"

    Engine.set_physics_ticks_per_second(30)

    Connection.game_client.create_client()

    await Connection.game_client.connected

    Connection.game_client.authenticate("test_{0}".format([multiplayer.get_unique_id()]), "test")

    await Connection.game_client.authenticated

    print("Authenticated")
