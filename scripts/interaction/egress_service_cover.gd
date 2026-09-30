extends "res://scripts/interaction/tool_access_cover.gd"

var egress: FacilityEgress


func interact() -> void:
	if egress == null or not egress.egress_authorized or not egress.primary_release_open:
		feedback("Service interlock engaged.")
		return
	super.interact()
