extends ConversationParticipant
## Concrete physical action implementation; state remains owned by the facility.

var facility_power: FacilityPower
var director: FacilityDirector
var received_response: Dictionary = {}


func can_request_action(action_id: String) -> bool:
	if action_id == "contact_m4": return director != null and director.powered() and director.communications_line_connected == "D"
	if action_id == "configure_m4": return director != null and director.link_available() and director.director_secondary_session_active and not received_response.is_empty() and not director.director_secondary_ready and not director.director_authorization_valid

	if action_id == "open_coolant_bypass":
		return contacted and facility_power != null and not facility_power.coolant_bypass_open and super.can_request_action(action_id)
	return super.can_request_action(action_id)


func _perform_action(action_id: String, parameters: Dictionary = {}) -> bool:
	if action_id == "contact_m4": return director.establish_contact()
	if action_id == "configure_m4":
		var accepted: bool = director.configure_m4(received_response["direction"], received_response["color"], received_response["circuit"])
		dialogue_values["m4_result"] = "M-4 is holding. The secondary station is ready. Confirm it at your terminal." if accepted else "No. M-4 rejected that combination. I can try another setting."
		received_response.clear()
		return true

	if action_id == "open_coolant_bypass":
		return facility_power.open_coolant_bypass()
	return super._perform_action(action_id, parameters)


func receive_m4_response(response: Dictionary) -> bool:
	if director == null or not director.link_available() or not director.director_secondary_session_active: return false
	if response.get("direction") not in ["NORTH", "EAST", "SOUTH", "WEST"]: return false
	if response.get("color") not in ["WHITE", "BLUE", "AMBER", "RED"]: return false
	if response.get("circuit") not in ["A", "B", "C", "D"]: return false
	received_response = response.duplicate()
	return true
