class_name FacilityEgress
extends Node
## Authoritative session state; macro authorization is read from its owners.

signal changed
signal sector_released(sector: StringName)
signal completed
var power: FacilityPower
var security: FacilitySecurity
var director: FacilityDirector
var _primary: bool = false
var _service: bool = false
var _secondary: bool = false
var _observation: bool = false
var _maintenance: bool = false
var _surface: bool = false
var _completed: bool = false
var egress_authorized: bool:
	get: return power != null and security != null and director != null and power.main_power_online and security.security_clearance_valid and director.director_authorization_valid
var primary_release_open: bool:
	get: return _primary
var service_plate_open: bool:
	get: return _service
var secondary_release_open: bool:
	get: return _secondary
var observation_cells_released: bool:
	get: return _observation
var maintenance_sector_released: bool:
	get: return _maintenance
var surface_access_enabled: bool:
	get: return _surface
var game_completed: bool:
	get: return _completed


func configure(mains: FacilityPower, access: FacilitySecurity, authorization: FacilityDirector) -> void:
	power = mains
	security = access
	director = authorization
	power.main_power_changed.connect(func(_online: bool) -> void: changed.emit())
	security.security_clearance_changed.connect(func(_valid: bool) -> void: changed.emit())
	director.authorization_completed.connect(func() -> void: changed.emit())
	changed.emit()


func open_service_plate() -> void:
	if egress_authorized and _primary:
		_service = true
		changed.emit()


func can_operate(action: StringName) -> bool:
	if not egress_authorized or _completed: return false
	match action:
		&"primary": return not _primary
		&"secondary": return _primary and _service and not _secondary
		&"observation": return _primary and _secondary and not _observation
		&"maintenance": return _primary and _secondary and not _maintenance
		&"surface": return _observation and _maintenance and not _surface
	return false


func operate(action: StringName) -> bool:
	if not can_operate(action): return false
	match action:
		&"primary": _primary = true
		&"secondary": _secondary = true
		&"observation": _observation = true
		&"maintenance": _maintenance = true
		&"surface": _surface = true
	changed.emit()
	if action == &"observation" or action == &"maintenance": sector_released.emit(action)
	return true


## Called only by the physical exit Area3D's player entry, never by a control.
func cross_final_threshold() -> bool:
	if not egress_authorized or not _primary or not _secondary or not _surface or not _observation or not _maintenance or _completed: return false
	_completed = true
	changed.emit()
	completed.emit()
	return true
