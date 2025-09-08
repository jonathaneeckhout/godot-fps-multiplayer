class_name UseArea3D
extends Area3D

signal gun_entered_range(weapon: WeaponLocation)
signal gun_left_range(weapon: WeaponLocation)

var detected_gun: WeaponLocation = null


func _on_area_shape_entered(_area_rid: RID, area: Area3D, _area_shape_index: int, _local_shape_index: int) -> void:
    if not area is WeaponLocation:
        return
    
    if detected_gun != null:
        return
    
    detected_gun = area

    gun_entered_range.emit(detected_gun)


func _on_area_shape_exited(_area_rid: RID, area: Area3D, _area_shape_index: int, _local_shape_index: int) -> void:
    if area != detected_gun:
        return

    detected_gun = null

    gun_left_range.emit(detected_gun)
