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
	_refresh()


func configure(supply: FacilityPower, state: FacilityDirector, inventory: PlayerInventory) -> void:
	power = supply
	director = state
	socket.power = supply
	socket.inventory = inventory
	power.main_power_changed.connect(_power_changed)
	director.primary_authorization_changed.connect(_primary_changed)
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
