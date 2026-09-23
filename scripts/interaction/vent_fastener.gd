class_name VentFastener
extends RequiredItemInteractable

signal removed

@export_range(0.5, 1.0) var removal_duration: float = 0.75
var is_removed: bool = false
var removing: bool = false


func get_interaction_prompt() -> String:
	return "Removing..." if removing else super.get_interaction_prompt()


func interact() -> void:
	if is_removed or removing or not check_requirement():
		return
	removing = true
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property($Visual, "rotation:z", TAU * 3.0, removal_duration)
	tween.tween_property($Visual, "position:z", -0.12, removal_duration)
	tween.chain().tween_callback(_finish_removal)


func _finish_removal() -> void:
	is_removed = true
	removing = false
	hide()
	$Body/Collision.disabled = true
	removed.emit()
