extends ConversationParticipant
## Physical circuit availability is separate from clue discovery.

var facility_power: FacilityPower
var director: FacilityDirector
var relay_response: Dictionary = {}


func configure(state: FacilityPower) -> void:
	facility_power = state
	state.main_power_changed.connect(_power_changed)
	_power_changed(state.main_power_online)


func _power_changed(online: bool) -> void:
	if online:
		flags["main_power_online"] = true
	else:
		flags.erase("main_power_online")


func can_request_action(action_id: String) -> bool:
	if action_id == "route_line": return director != null and director.powered()
	if action_id == "relay_m4": return director != null and director.link_available() and director.director_secondary_session_active and not director.director_secondary_ready and not director.director_authorization_valid

	if action_id == "inspect_phase_chart" and (facility_power == null or not facility_power.main_power_online):
		return false
	return super.can_request_action(action_id)


func _perform_action(action_id: String, parameters: Dictionary = {}) -> bool:
	if action_id == "route_line":
		return director.connect_line(parameters.get("line", ""))
	if action_id == "relay_m4":
		var receiver: ConversationParticipant = conversation_partners.get("elias")
		if not is_instance_valid(receiver): return false
		relay_response = {"direction": dialogue_values.get("direction", ""), "color": dialogue_values.get("color", ""), "circuit": dialogue_values.get("circuit", "")}
		return receiver.receive_m4_response(relay_response)
	return super._perform_action(action_id, parameters)
