extends Openable
## Body origin is the hinge. Mesh and shape are offset to one side of it.

@export_range(-170.0, 170.0, 1.0) var open_angle: float = 100.0


func get_open_transform(closed_transform: Transform3D) -> Transform3D:
	return closed_transform.rotated_local(Vector3.UP, deg_to_rad(open_angle))


func get_object_label() -> String:
	return "Door"
