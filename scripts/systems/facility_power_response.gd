extends Node
## Optional consumer component. Future consumers can subscribe directly too.

var lights: Array[Light3D] = []
var powered_visuals: Array[Node3D] = []
var status_label: Label3D
var _base_energies: Array[float] = []
var _offline_status: String


func configure(state: FacilityPower) -> void:
	for light: Light3D in lights:
		_base_energies.append(light.light_energy)
	if status_label != null:
		_offline_status = status_label.text
	state.main_power_changed.connect(_apply)
	_apply(state.main_power_online)


func _apply(online: bool) -> void:
	for index: int in lights.size():
		lights[index].light_energy = _base_energies[index] * (1.65 if online else 1.0)
	for visual: Node3D in powered_visuals:
		visual.visible = online
	if status_label != null:
		status_label.text = _offline_status.replace("MAIN POWER             OFF", "MAIN POWER             ONLINE") if online else _offline_status
