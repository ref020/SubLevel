extends Interactable

var pressed: bool = false

@onready var button_cap: MeshInstance3D = $ButtonCap


func interact() -> void:
	pressed = not pressed
	button_cap.position.z = 0.08 if pressed else 0.24
	button_cap.scale = Vector3(0.75, 0.75, 1.0) if pressed else Vector3.ONE
