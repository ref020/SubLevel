class_name Inspectable
extends Interactable
## Static mesh visuals are copied safely; scripts and physics are never copied.

@export var visual_root: Node3D
@export_range(0.85, 5.0, 0.05) var inspection_distance: float = 1.4
@export_range(0.85, 5.0, 0.05) var minimum_distance: float = 0.85
@export_range(0.85, 5.0, 0.05) var maximum_distance: float = 2.5
@export_range(0.01, 2.0, 0.01) var rotation_sensitivity: float = 0.3
@export var initial_inspection_rotation: Vector3 = Vector3.ZERO


func interact() -> void:
	# The local player's presenter owns the inspection session, not this item.
	get_tree().call_group("inspection_presenter", "inspect", self)
