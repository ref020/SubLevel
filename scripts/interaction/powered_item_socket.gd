class_name PoweredItemSocket
extends ItemSocket

var power: FacilityPower


func get_interaction_prompt() -> String:
	return super.get_interaction_prompt() if power != null and power.main_power_online else "No Power"


func interact() -> void:
	if power == null or not power.main_power_online:
		feedback("No power.")
		return
	super.interact()


func install(item: InventoryItem) -> bool:
	if power == null or not power.main_power_online:
		return false
	return super.install(item)
