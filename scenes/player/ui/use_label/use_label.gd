class_name UseLabel
extends Label

@export var use_area: UseArea3D = null

func _ready() -> void:
    assert(use_area != null, "Please set UseArea3D")

    use_area.gun_entered_range.connect(_on_gun_entered_range)
    use_area.gun_left_range.connect(_on_gun_left_range)

    # By default this label should be hidden
    hide()

func _on_gun_entered_range(_gun: WeaponLocation) -> void:
    show()

func _on_gun_left_range(_gun: WeaponLocation) -> void:
    hide()
