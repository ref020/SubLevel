class_name CredentialEncoder
extends Interactable

signal changed
@export var profile: CredentialProfile
@export_range(0.1, 5.0, 0.1) var encoding_seconds: float = 1.2
var power: FacilityPower
var employee: String = ""
var clearance: int = 1
var verification: String = ""
var status: String = "NO POWER"
var _remaining: float = 0.0
var _writing_card: InventoryItem
@onready var socket: ItemSocket = $Socket
@onready var readout: TextMesh = $Visual/Readout.mesh
var writing: bool:
	get: return _remaining > 0.0
var powered: bool:
	get: return power != null and power.main_power_online


func _ready() -> void:
	$Visual/Readout.mesh = readout.duplicate()
	readout = $Visual/Readout.mesh
	for bank: int in range(2):
		for digit: int in range(4):
			var mesh: MeshInstance3D = get_node("Visual/DigitText%d%d" % [bank, digit])
			mesh.mesh = mesh.mesh.duplicate()
	socket.item_installed.connect(_inserted)
	socket.item_ejected.connect(_ejected)
	_refresh()


func configure(state: FacilityPower, inventory: PlayerInventory) -> void:
	power = state
	socket.inventory = inventory
	power.main_power_changed.connect(_power_changed)
	_power_changed(power.main_power_online)


func _power_changed(online: bool) -> void:
	if not online:
		_remaining = 0.0
		_writing_card = null
	status = "INSERT CARD" if online else "NO POWER"
	_refresh()


func get_interaction_prompt() -> String:
	return "Operate Card Encoder" if powered else "No Power"


func interact() -> void:
	if not powered:
		feedback("No power.")
		return
	get_tree().call_group("encoder_presenter", "open_encoder", self)


func insert_card() -> void:
	if powered and not writing:
		socket.interact()


func eject_card() -> bool:
	# Mechanical recovery remains possible even during a write or without power.
	if socket.installed_item == null:
		return false
	_remaining = 0.0
	_writing_card = null
	return socket.eject()


func _inserted(item: InventoryItem) -> void:
	status = "CARD REVOKED" if item.credential == null or item.credential.revoked else "CARD ACTIVE"
	_refresh()


func _ejected(_item: InventoryItem) -> void:
	status = "CARD EJECTED" if powered else "NO POWER"
	_refresh()


func set_inputs(id_text: String, class_number: int, hash_text: String) -> void:
	if writing:
		return
	employee = id_text
	clearance = class_number
	verification = hash_text
	_refresh()


func submit() -> bool:
	if not powered or writing:
		return false
	if socket.installed_item == null:
		status = "INSERT CARD"
		_refresh()
		return false
	if profile == null or not profile.matches(socket.installed_item, employee, clearance, verification):
		status = "CREDENTIAL MISMATCH"
		_refresh()
		return false
	_writing_card = socket.installed_item
	_remaining = encoding_seconds
	status = "ENCODING..."
	_refresh()
	return true


func _process(delta: float) -> void:
	if not writing:
		return
	_remaining = maxf(0.0, _remaining - delta)
	if not writing:
		if powered and socket.installed_item == _writing_card and profile.restore(_writing_card):
			status = "CREDENTIAL RESTORED / CLASS " + ["I", "II", "III", "IV"][profile.clearance_class - 1]
			socket.refresh_visual()
		else:
			status = "WRITE INTERRUPTED"
		_writing_card = null
		_refresh()


func _refresh() -> void:
	readout.text = status if powered else ""
	var banks: Array[String] = [employee, verification]
	for bank: int in range(2):
		for digit: int in range(4):
			var mesh: MeshInstance3D = get_node("Visual/DigitText%d%d" % [bank, digit])
			mesh.mesh.text = (banks[bank][digit] if digit < banks[bank].length() else "_") if powered else ""
	$Visual/PowerLamp.visible = powered
	$Visual/WriteLamp.visible = writing
	changed.emit()


func _exit_tree() -> void:
	if is_node_ready() and is_instance_valid(socket.inventory):
		eject_card()
