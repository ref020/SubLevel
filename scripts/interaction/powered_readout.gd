class_name PoweredReadout
extends Inspectable
## Mains-powered instrument using the existing inspection presenter.

@export var display_mesh: MeshInstance3D
@export_multiline var standby_text: String
@export var analyzes_recording: bool = false
var power: FacilityPower
var tape_slot: ItemSocket
var powered: bool = false
var _text: TextMesh


func _ready() -> void:
	_text = display_mesh.mesh.duplicate() as TextMesh
	_text.material = _text.material.duplicate()
	display_mesh.mesh = _text
	_refresh(false)


func configure(state: FacilityPower, slot: ItemSocket = null) -> void:
	power = state
	tape_slot = slot
	power.main_power_changed.connect(_refresh)
	_refresh(power.main_power_online)


func _refresh(online: bool) -> void:
	powered = online
	_text.text = standby_text if powered else ""
	var phosphor: StandardMaterial3D = _text.material as StandardMaterial3D
	phosphor.emission_enabled = powered


func get_interaction_prompt() -> String:
	return interaction_prompt if powered else "No Power"


func interact() -> void:
	if not powered:
		feedback("No power.")
		return
	if analyzes_recording:
		var tape: InventoryItem = tape_slot.installed_item if is_instance_valid(tape_slot) else null
		if tape == null:
			feedback("The cassette well is empty.")
			return
		if tape.recording == null or tape.recording.channel_amplitudes.is_empty():
			feedback("No analysis signal.")
			return
		var lines: PackedStringArray = ["SIGNAL ANALYSIS", "CHANNEL    AMPLITUDE"]
		for channel: String in tape.recording.channel_amplitudes:
			lines.append("%s          %s" % [channel, tape.recording.channel_amplitudes[channel]])
		_text.text = "\n".join(lines)
	super.interact()


func refresh_report() -> void:
	_refresh(powered)
