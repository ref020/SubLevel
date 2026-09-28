extends Node
## Main-scene wiring; the generator does not know its environmental consumers.

@export var systems: Node3D
@export var inventory: PlayerInventory
@export var elias: ConversationParticipant
@export var shell: Node3D


func _ready() -> void:
	var state: FacilityPower = systems.get_node("State")
	elias.facility_power = state
	systems.get_node("BatteryUnit/Cover").inventory = inventory
	systems.get_node("BatteryUnit/Cover").opened.connect(func() -> void:
		var collision: CollisionShape3D = systems.get_node("BatteryUnit/Battery/Body/Collision")
		collision.set_deferred("disabled", false))
	systems.get_node("CassetteWorkstation").configure(state, inventory)
	systems.get_node("Generator/Startup").configure(state)
	state.coolant_bypass_opened.connect(_bypass_opened)
	var response: Node = systems.get_node("PowerResponse")
	for path: String in ["CentralHub/WestFixtureLight", "CentralHub/EastFixtureLight", "Archive/RecordsFixtureLight", "Generator/ControlFixtureLight"]:
		response.lights.append(shell.get_node(path))
	response.powered_visuals.assign([systems.get_node("HubMainsFixture/Light"), systems.get_node("HubMainsFixture/Diffuser"), systems.get_node("SecurityStandby")])
	response.status_label = shell.get_node("CentralHub/StatusPanel/Text")
	response.configure(state)


func _bypass_opened() -> void:
	var valve: Node3D = systems.get_node("Bypass/Valve")
	valve.create_tween().tween_property(valve, "rotation_degrees:z", 90.0, 0.6)
	systems.get_node("Generator/BypassLamp").show()
