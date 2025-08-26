extends Sprite3D

@onready var progress_bar: TextureProgressBar = $SubViewport/ProgressBar

const bar_green: Resource = preload("res://assets/healthbar/scaled/GreenBar.png")
const bar_yellow: Resource = preload("res://assets/healthbar/scaled/YellowBar.png")
const bar_red: Resource = preload("res://assets/healthbar/scaled/RedBar.png")

var parent: Node3D = null
var health_synchronizer: HealthSynchronizer = null

func _ready():
    parent = get_parent()
    assert(parent != null, "Parent can't be null")

    health_synchronizer = parent.get_node_or_null("HealthSynchronizer")
    assert(health_synchronizer != null, "Can't find HealthSynchronizer")

    health_synchronizer.health_changed.connect(_on_health_changed)


func update():
    progress_bar.texture_progress = bar_green
    if health_synchronizer.health < 0.75 * health_synchronizer.max_health:
        progress_bar.texture_progress = bar_yellow
    if health_synchronizer.health < 0.45 * health_synchronizer.max_health:
        progress_bar.texture_progress = bar_red

    progress_bar.value = health_synchronizer.health


func _on_health_changed(_hp: int, _amount: int):
    update();
