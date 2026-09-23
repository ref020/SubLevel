extends Interactable

signal activated

@export var accessible: bool = true
var is_on: bool = false


func enable_access() -> void:
	accessible = true


func get_interaction_prompt() -> String:
	return "Power On" if is_on else "Activate Breaker"


func interact() -> void:
	if not accessible or is_on:
		return
	is_on = true
	create_tween().tween_property($Lever, "rotation:x", deg_to_rad(-35), 0.35)
	activated.emit()
