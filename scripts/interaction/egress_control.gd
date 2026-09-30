extends Interactable

@export var action: StringName
@export var control_name: String
var egress: FacilityEgress


func get_interaction_prompt() -> String:
	return control_name if egress != null and egress.can_operate(action) else control_name + " - Unavailable"


func interact() -> void:
	if egress == null: return
	if egress.operate(action):
		if action == &"primary": feedback("Primary released. Secondary latch: mechanical fault.")
		elif action == &"secondary": feedback("Secondary latch released.")
		elif action == &"surface": feedback("Surface access unlocked.")
	elif action == &"surface" and not egress.surface_access_enabled:
		feedback("Release both occupied sectors first.")
	else:
		feedback("Control unavailable.")
