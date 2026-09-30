class_name FacilityDirector
extends Node
## Scene-owned physical progression, independent of dialogue knowledge flags.

signal primary_authorization_changed(authorized: bool)
signal changed
signal authorization_completed
signal m4_attempted(accepted: bool)
var power: FacilityPower
var security: FacilitySecurity
var _primary: bool = false
var _line: String = ""
var _contact: bool = false
var _session: bool = false
var _ready: bool = false
var _valid: bool = false
var director_primary_authorized: bool:
	get: return _primary
var communications_line_connected: String:
	get: return _line
var participants_connected: bool:
	get: return _contact
var director_secondary_session_active: bool:
	get: return _session
var director_secondary_ready: bool:
	get: return _ready
var director_authorization_valid: bool:
	get: return _valid


func powered() -> bool:
	return power != null and power.main_power_online


func accept_primary() -> void:
	if _primary: return
	_primary = true
	primary_authorization_changed.emit(true)
	changed.emit()


func connect_line(line: String) -> bool:
	if not powered() or line not in ["A", "B", "C", "D", "E", "F"]: return false
	if _line != line:
		_contact = false
	_line = line
	changed.emit()
	return true


func establish_contact() -> bool:
	if not powered() or _line != "D": return false
	_contact = true
	changed.emit()
	return true


func link_available() -> bool:
	return powered() and _line == "D" and _contact


func begin_secondary() -> bool:
	if not _primary or not link_available() or _valid: return false
	_session = true
	changed.emit()
	return true


func configure_m4(direction: String, color: String, circuit: String) -> bool:
	if not _session or not link_available() or _ready or _valid: return false
	var accepted: bool = direction == "EAST" and color == "AMBER" and circuit == "B"
	if accepted: _ready = true
	m4_attempted.emit(accepted)
	changed.emit()
	return accepted


func finalize() -> bool:
	if not powered() or not _primary or not _session or not _ready or _valid: return false
	if security == null or not security.security_clearance_valid: return false
	_valid = true
	changed.emit()
	authorization_completed.emit()
	return true
