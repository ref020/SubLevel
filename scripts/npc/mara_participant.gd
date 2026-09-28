extends ConversationParticipant
## Physical circuit availability is separate from clue discovery.

var facility_power: FacilityPower


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
	if action_id == "inspect_phase_chart" and (facility_power == null or not facility_power.main_power_online):
		return false
	return super.can_request_action(action_id)
