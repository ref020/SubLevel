class_name FacilitySecurity
extends Node
## Separate from mains power and card possession/restoration. Session-only.

signal security_clearance_changed(valid: bool)
var _valid: bool = false
var security_clearance_valid: bool:
	get: return _valid


func establish_access() -> void:
	if _valid:
		return
	_valid = true
	security_clearance_changed.emit(true)
