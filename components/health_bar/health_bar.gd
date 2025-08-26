class_name HealthBar
extends ProgressBar


@export var health_synchronizer: HealthSynchronizer = null

func _ready():
    assert(health_synchronizer != null, "HealthSynchronizer not set")

    value = health_synchronizer.health
    max_value = health_synchronizer.max_health

    health_synchronizer.health_changed.connect(_on_health_changed)

func _on_health_changed(hp: int, _amount: int) -> void:
    value = hp
