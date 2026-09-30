class_name CredentialDoor
extends "res://scripts/interaction/door.gd"

signal credential_accepted(item: InventoryItem)
@export var access_system: StringName
@export_range(1, 4) var minimum_class: int = 4
var power: FacilityPower


func configure(state_source: FacilityPower, carried: PlayerInventory) -> void:
	power = state_source
	inventory = carried


func compatible_card() -> InventoryItem:
	if power == null or not power.main_power_online or not is_instance_valid(inventory):
		return null
	for item: InventoryItem in inventory.get_items():
		if item.credential != null and item.credential.permits(access_system, minimum_class):
			return item
	return null


func has_compatible_key() -> bool:
	return compatible_card() != null


func get_interaction_prompt() -> String:
	if power == null or not power.main_power_online:
		return "No Power"
	return super.get_interaction_prompt()


func interact() -> void:
	if power == null or not power.main_power_online:
		feedback("No power.")
		return
	if is_locked:
		var card: InventoryItem = compatible_card()
		if card == null:
			feedback("ACCESS DENIED")
			return
		unlock()
		feedback("ACCESS ACCEPTED")
		credential_accepted.emit(card)
		return
	super.interact()
