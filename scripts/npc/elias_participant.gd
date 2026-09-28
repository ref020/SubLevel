extends ConversationParticipant
## Concrete physical action implementation; state remains owned by the facility.

var facility_power: FacilityPower


func can_request_action(action_id: String) -> bool:
	if action_id == "open_coolant_bypass":
		return contacted and facility_power != null and not facility_power.coolant_bypass_open and super.can_request_action(action_id)
	return super.can_request_action(action_id)


func _perform_action(action_id: String) -> bool:
	if action_id == "open_coolant_bypass":
		return facility_power.open_coolant_bypass()
	return super._perform_action(action_id)
