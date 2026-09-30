extends Node
## Scene wiring/presentation; FacilityEgress owns the progression rules.

@export var assembly: Node3D
@export var power: FacilityPower
@export var security: FacilitySecurity
@export var director: FacilityDirector
@export var inventory: PlayerInventory
@export var player: CharacterBody3D
@export var shell: Node3D
@export var dialogue_ui: Node
@export var ending_ui: Node
@export var mara: ConversationParticipant
@export var elias: ConversationParticipant
@export var facility_hum: AudioStreamPlayer3D
var _hum_volume: float = -20.0
var state: FacilityEgress
var _in_exit: bool = false
var _last_stage: int = 0


func _ready() -> void:
	_hum_volume = facility_hum.volume_db
	state = assembly.get_node("State")
	for path: String in ["Primary", "Service/Linkage", "EvacuationPanel/Observation", "EvacuationPanel/Maintenance", "EvacuationPanel/Surface"]:
		assembly.get_node(path).egress = state
	var cover: RequiredItemInteractable = assembly.get_node("Service/Cover")
	cover.egress = state
	cover.inventory = inventory
	cover.opened.connect(state.open_service_plate)
	for path: String in ["FaultText", "EvacuationPanel/Readout"]:
		var mesh: MeshInstance3D = assembly.get_node(path)
		mesh.mesh = mesh.mesh.duplicate()
	state.changed.connect(_render)
	state.sector_released.connect(_sector_released)
	state.completed.connect(ending_ui.present)
	assembly.get_node("FinalThreshold").body_entered.connect(func(body: Node3D) -> void:
		if body == player: _in_exit = true)
	assembly.get_node("FinalThreshold").body_exited.connect(func(body: Node3D) -> void:
		if body == player: _in_exit = false)
	assembly.get_node("MechanismSound").stream = _clunk()
	state.configure(power, security, director)


func _process(_delta: float) -> void:
	var on_route: bool = player.global_position.x > 17.6 and player.global_position.x < 20.1 and player.global_position.z < -7.3
	facility_hum.volume_db = _hum_volume - (clampf((-player.global_position.z - 7.3) / 6.0, 0.0, 1.0) * 28.0 if on_route else 0.0)
	if _in_exit and player.global_position.z < -14.4:
		state.cross_final_threshold()


func _render() -> void:
	var primary: bool = state.primary_release_open
	var secondary: bool = state.secondary_release_open
	assembly.get_node("AuthorizedLamp").visible = state.egress_authorized
	var status: Label3D = shell.get_node("CentralHub/StatusPanel/Text")
	if state.egress_authorized:
		status.text = status.text.replace("READY FOR MANUAL RELEASE", "MANUAL RELEASE ENABLED").replace("EXIT SEALED", "MANUAL RELEASE ENABLED")
	var fault: TextMesh = assembly.get_node("FaultText").mesh
	fault.text = "PRIMARY: OPEN\nSECONDARY: OPEN" if secondary else ("PRIMARY: OPEN\nSECONDARY: MECHANICAL FAULT" if primary else "PRIMARY: SECURED\nSECONDARY: SECURED")
	assembly.get_node("Service/Linkage/Base/Collision").set_deferred("disabled", not state.service_plate_open)
	if primary and secondary: assembly.get_node("Door").unlock()
	if state.surface_access_enabled: assembly.get_node("SurfaceDoor").unlock()
	var readout: TextMesh = assembly.get_node("EvacuationPanel/Readout").mesh
	readout.text = "EVACUATION CONTROL\nOBSERVATION CELLS   " + ("RELEASED" if state.observation_cells_released else "SECURED")
	readout.text += "\nMAINTENANCE SECTOR  " + ("RELEASED" if state.maintenance_sector_released else "SECURED")
	readout.text += "\nSURFACE ACCESS      " + ("ENABLED" if state.surface_access_enabled else ("READY" if state.observation_cells_released and state.maintenance_sector_released else "LOCKED"))
	for pair: Array in [["Observation", state.observation_cells_released], ["Maintenance", state.maintenance_sector_released], ["Surface", state.surface_access_enabled]]:
		assembly.get_node("EvacuationPanel/" + pair[0] + "/Lever").rotation_degrees.z = 55.0 if pair[1] else 0.0
	var stage: int = int(state.egress_authorized) + int(primary) + int(secondary)
	if stage != _last_stage:
		_last_stage = stage
		assembly.get_node("MechanismSound").play()
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(assembly.get_node("Door/Body/PrimaryLatch"), "position:x", 1.5 if primary else 1.85, 0.4)
		tween.tween_property(assembly.get_node("Door/Body/SecondaryLatch"), "position:x", 1.5 if secondary else (1.79 if primary else 1.85), 0.4)
		tween.tween_property(assembly.get_node("Primary/Lever"), "rotation_degrees:z", 55.0 if primary else 0.0, 0.4)


func _sector_released(sector: StringName) -> void:
	var participant: ConversationParticipant = mara if sector == &"observation" else elias
	dialogue_ui.open_dialogue(participant, assembly.get_node("EvacuationPanel"), null, "EVACUATION / FACILITY VOICE", "sector_released")


func _clunk() -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(6615)
	for i: int in bytes.size():
		var t: float = float(i) / 22050.0
		bytes[i] = roundi((sin(TAU * 73.0 * t) * 55.0 + sin(TAU * 311.0 * t) * 18.0) * exp(-18.0 * t)) & 0xff
	var sound: AudioStreamWAV = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = 22050
	sound.data = bytes
	return sound
