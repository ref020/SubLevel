class_name FacilityPower
extends Node
## Authoritative, scene-owned session state. Observation auxiliary is separate.

signal main_power_changed(online: bool)
signal coolant_bypass_opened

var _online: bool = false
var _bypass_open: bool = false
var main_power_online: bool:
	get: return _online
var coolant_bypass_open: bool:
	get: return _bypass_open


func open_coolant_bypass() -> bool:
	if _bypass_open:
		return false
	_bypass_open = true
	coolant_bypass_opened.emit()
	return true


func restore_main_power() -> void:
	if _online:
		return
	_online = true
	main_power_changed.emit(true)
