extends Node


var game_server: GameServer = null
var game_client: GameClient = null

var clock_synchronizer: ClockSynchronizer = null

# Node storing all active players (used for hit)
var players: Node3D = null
