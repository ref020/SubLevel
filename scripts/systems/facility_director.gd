class_name FacilityDirector
extends Node
## Primary token acceptance is not the complete Director macro condition.

signal primary_authorization_changed(authorized: bool)
var _primary: bool = false
var director_primary_authorized: bool:
	get: return _primary
var director_authorization_valid: bool:
	get: return false # Secondary authorization has no implementation in 12A.


func accept_primary() -> void:
	if _primary:
		return
	_primary = true
	primary_authorization_changed.emit(true)
