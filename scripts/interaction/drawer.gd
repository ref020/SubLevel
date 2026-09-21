extends Openable
## Direction is in the interactable root's local coordinates.

@export var slide_direction: Vector3 = Vector3.FORWARD * -1.0
@export_range(0.05, 3.0, 0.05) var travel_distance: float = 0.65


func get_open_transform(closed_transform: Transform3D) -> Transform3D:
	var result: Transform3D = closed_transform
	var direction: Vector3 = slide_direction.normalized()
	if direction.is_zero_approx():
		push_warning("Drawer slide_direction is zero; using local +Z.")
		direction = Vector3.BACK
	result.origin += direction * travel_distance
	return result


func get_object_label() -> String:
	return "Drawer"
