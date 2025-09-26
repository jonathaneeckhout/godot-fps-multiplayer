# godot-fps-multiplayer
Demostration project of a 3D multiplayer FPS game built with Godot

## Features
This is a server authoritative FPS shooter.

- Server reconciliation
- Lag compensation
- Client prediction
- Client interpolation
- Clock synchronization

## How to run

Setup Godot to run mutliple instances:

- Debug --> Customize Run Instances ... --> Enable Multiple Instances
- Enable 2 or more instances (1 server and 1+ clients)
- Add launch arguments "--server --headless" to once instance
- Add launch arguments "--client" to the others

Run the project and have fun!
