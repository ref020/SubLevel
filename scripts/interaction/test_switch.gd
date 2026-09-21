extends Interactable

var switched_on: bool = false

@onready var handle: MeshInstance3D = $Handle


func interact() -> void:
	switched_on = not switched_on
	handle.rotation.z = deg_to_rad(-35.0 if switched_on else 35.0)
