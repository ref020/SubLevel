class_name PickupItem
extends Inspectable
## Inspect first; the inspection presenter offers the deliberate Take action.

@export var item_id: StringName
@export var display_name: String
@export_multiline var description: String

var collected: bool = false


func get_interaction_prompt() -> String:
	return "Inspect " + display_name


func remove_from_world() -> void:
	collected = true
	hide()
	# Detach immediately so visuals, physics and targeting disappear together.
	get_parent().remove_child(self)
	queue_free()
