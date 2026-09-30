class_name AuthorizationTerminal
extends Inspectable

const WAITING: String = "HALCYON EMERGENCY AUTHORIZATION\n\nPRIMARY TOKEN: NOT PRESENT\n\nSECONDARY: UNAVAILABLE\nAWAITING PRIMARY"
const ACCEPTED: String = "HALCYON EMERGENCY AUTHORIZATION\n\nPRIMARY AUTHORIZATION: ACCEPTED\nSECONDARY AUTHORIZATION: REQUIRED\n\nSECONDARY TERMINAL:\nSERVICE CONTROL M-4\n\nNETWORK LINK: OFFLINE"
@export_range(0.1, 5.0, 0.1) var validation_seconds: float = 1.0
var power: FacilityPower
var director: FacilityDirector
var _remaining: float = 0.0
@onready var socket: PoweredItemSocket = $Socket
@onready var readout: TextMesh = $Visual/Readout.mesh


func _ready() -> void:
	$Visual/Readout.mesh = readout.duplicate()
	readout = $Visual/Readout.mesh
	socket.item_installed.connect(_installed)
	$Control.activated.connect(_operate)
	_refresh()


func configure(supply: FacilityPower, state: FacilityDirector, inventory: PlayerInventory) -> void:
	power = supply
	director = state
	socket.power = supply
	socket.inventory = inventory
	power.main_power_changed.connect(_power_changed)
	director.primary_authorization_changed.connect(_primary_changed)
	director.changed.connect(_refresh)
	_refresh()


func _power_changed(online: bool) -> void:
	if not online:
		_remaining = 0.0
	elif socket.installed_item != null and not director.director_primary_authorized:
		_remaining = validation_seconds
	_refresh()


func _installed(_item: InventoryItem) -> void:
	_remaining = validation_seconds
	_refresh()


func _primary_changed(_accepted: bool) -> void:
	_refresh()


func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining == 0.0:
		if power.main_power_online and socket.installed_item != null:
			director.accept_primary()
		_refresh()


func get_interaction_prompt() -> String:
	return "Read Authorization Terminal" if power != null and power.main_power_online else "No Power"


func interact() -> void:
	if power == null or not power.main_power_online:
		feedback("No power.")
		return
	if _remaining > 0.0:
		feedback("Validating primary token.")
		return # Inspection snapshots are static; do not strand a stale validating view.
	super.interact()


func _refresh() -> void:
	var online: bool = power != null and power.main_power_online
	$Visual/PowerLamp.visible = online
	if not online:
		readout.text = ""
	elif _remaining > 0.0:
		readout.text = "PRIMARY TOKEN\nVALIDATING..."
	else:
		readout.text = ACCEPTED if director != null and director.director_primary_authorized else WAITING
		if director != null and director.director_primary_authorized:
			if director.director_authorization_valid:
				readout.text = "EMERGENCY AUTHORIZATION\nCOMPLETE\n\nPRIMARY: VALID\nSECONDARY M-4: VALID"
			elif director.director_secondary_ready:
				readout.text = "PRIMARY AUTHORIZATION: ACCEPTED\n\nSECONDARY STATION M-4: READY\n\nFINALIZE AUTHORIZATION\nPRESS SESSION / CONFIRM"
			elif director.director_secondary_session_active:
				readout.text = "SECONDARY SESSION / M-4\n\nPHASE 2\nLOAD 6\nCIRCUIT B\n\nAWAITING STATION RESPONSE"
			elif director.link_available():
				readout.text = "PRIMARY AUTHORIZATION: ACCEPTED\nSECONDARY AUTHORIZATION: REQUIRED\nSERVICE CONTROL M-4\nVOICE LINK: CONNECTED\n\nPRESS SESSION / CONFIRM"


func _operate() -> void:
	if power == null or not power.main_power_online or director == null or _remaining > 0.0:
		feedback("Terminal unavailable.")
		return
	if director.director_secondary_ready:
		if director.finalize(): feedback("Emergency authorization complete.")
	elif director.begin_secondary():
		feedback("Secondary session active. Read the terminal.")
	else:
		feedback("Authorization prerequisites unavailable.")
