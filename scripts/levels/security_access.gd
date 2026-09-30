extends Node
## Consumers react to Security acceptance; the encoder only changes a card.

@export var power: FacilityPower
@export var security: FacilitySecurity
@export var encoder: CredentialEncoder
@export var inner_door: CredentialDoor
@export var director_door: Openable
@export var inventory: PlayerInventory
@export var shell: Node3D
@export var terminal: PoweredReadout


func _ready() -> void:
	encoder.configure(power, inventory)
	inner_door.configure(power, inventory)
	inner_door.credential_accepted.connect(_accepted)
	security.security_clearance_changed.connect(_security_changed)
	power.main_power_changed.connect(_power_changed)
	_power_changed(power.main_power_online)


func _accepted(_card: InventoryItem) -> void:
	security.establish_access()


func _power_changed(online: bool) -> void:
	shell.get_node("SecurityInner/InnerFixtureLight").light_energy = 0.8 if online else 0.35


func _security_changed(_valid: bool) -> void:
	director_door.unlock()
	var panel: Label3D = shell.get_node("CentralHub/StatusPanel/Text")
	panel.text = panel.text.replace("SECURITY CLEARANCE     INVALID", "SECURITY CLEARANCE     VALID")
	inner_door.get_node("Body/AcceptedLamp").show()
	director_door.get_node("Body/AcceptedLamp").show()
	terminal.standby_text = terminal.standby_text.replace("CARD STATUS: REVOKED", "CARD STATUS: ACTIVE").replace("CLEARANCE: NONE", "CLEARANCE: IV")
	terminal.refresh_report()
