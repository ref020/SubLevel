class_name TunableRadio
extends Interactable
## Integer dial positions avoid accumulated floating-point tuning error.

signal frequency_changed(frequency: float)
signal transmission_found

@export var minimum_frequency: float = 87.5
@export var maximum_frequency: float = 108.0
@export_range(0.1, 1.0, 0.1) var tuning_step: float = 0.1
@export var starting_frequency: float = 99.5
@export var target_frequency: float = 107.3
@export_range(0.1, 3.0, 0.1) var stable_seconds: float = 0.9
@export var designation: String = "RADIO"

var _tick: int = 0
var _stable: float = 0.0
var _received: bool = false
var _listening: bool = false

var frequency: float:
	get:
		return minimum_frequency + _tick * tuning_step


func _ready() -> void:
	_tick = clampi(roundi((starting_frequency - minimum_frequency) / tuning_step), 0, _maximum_tick())
	# Each instance owns its changing display mesh.
	$Visual/Frequency.mesh = $Visual/Frequency.mesh.duplicate()
	$Visual/Designation.mesh = $Visual/Designation.mesh.duplicate()
	$Visual/Designation.mesh.text = designation
	_update_display()


func get_interaction_prompt() -> String:
	return "Tune " + designation


func interact() -> void:
	get_tree().call_group("radio_presenter", "open_radio", self)


func begin_listening() -> void:
	_listening = true
	_stable = 0.0
	_received = false


func end_listening() -> void:
	_listening = false
	_stable = 0.0


func tune(direction: int) -> void:
	if not _listening:
		return
	var next: int = clampi(_tick + signi(direction), 0, _maximum_tick())
	if next == _tick:
		return
	_tick = next
	_stable = 0.0
	_received = false
	_update_display()
	frequency_changed.emit(frequency)


func _maximum_tick() -> int:
	return maxi(0, floori((maximum_frequency - minimum_frequency) / tuning_step + 0.00001))


func _update_display() -> void:
	$Visual/Frequency.mesh.text = "%.1f MHz" % frequency
	$Visual/Dial.rotation.z = -float(_tick) * 0.12


func _process(delta: float) -> void:
	if not _listening or _received:
		return
	if not is_equal_approx(frequency, target_frequency):
		_stable = 0.0
		return
	_stable += delta
	if _stable >= stable_seconds:
		_received = true
		transmission_found.emit()
