extends Interactable
## Prototype test fixture only; no key or puzzle rules.

@export var target: Openable


func get_interaction_prompt() -> String:
	return "Unlock Test Lock" if is_instance_valid(target) and target.is_locked else "Test Lock Unlocked"


func interact() -> void:
	if is_instance_valid(target):
		target.unlock()
