class_name RequiredItemInteractable
extends Interactable
## The owning level supplies its player's inventory; requirements belong here.

@export var inventory: PlayerInventory
@export var required_item_id: StringName
@export var missing_item_prompt: String = "Examine"
@export var ready_prompt: String = "Use Tool"
@export var missing_item_message: String = "I need something that fits this."


func has_required_item() -> bool:
	return is_instance_valid(inventory) and inventory.has_item(required_item_id)


func get_interaction_prompt() -> String:
	return ready_prompt if has_required_item() else missing_item_prompt


func check_requirement() -> bool:
	if has_required_item():
		return true
	feedback(missing_item_message)
	return false
