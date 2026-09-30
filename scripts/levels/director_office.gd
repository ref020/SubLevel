extends Node
## Main-scene references wire reusable props to scene-owned state and inventory.

@export var office: Node3D
@export var power: FacilityPower
@export var inventory: PlayerInventory
@export var mara: ConversationParticipant
@export var elias: ConversationParticipant
@export var security: FacilitySecurity
@export var shell: Node3D


func _ready() -> void:
	var state: FacilityDirector = office.get_node("State")
	state.power = power
	state.security = security
	mara.director = state
	elias.director = state
	mara.conversation_partners["elias"] = elias
	elias.conversation_partners["mara"] = mara
	state.changed.connect(_director_changed)
	_director_changed()
	office.get_node("Terminal").configure(power, office.get_node("State"), inventory)
	var door: Openable = office.get_node("Cabinet/Door")
	door.opened.connect(_contents_access.bind(true))
	door.closed.connect(_contents_access.bind(false))


func _contents_access(accessible: bool) -> void:
	var collider: CollisionShape3D = office.get_node_or_null("Cabinet/Module/Body/Collision")
	if collider != null:
		collider.set_deferred("disabled", not accessible)


func _director_changed() -> void:
	var state: FacilityDirector = office.get_node("State")
	var projected: Dictionary = {"secondary_session": state.director_secondary_session_active, "secondary_ready": state.director_secondary_ready, "director_valid": state.director_authorization_valid}
	for flag: String in projected:
		if projected[flag]: mara.flags[flag] = true
		else: mara.flags.erase(flag)
	office.get_node("M4Designation/ReadyLamp").visible = state.director_secondary_ready
	office.get_node("M4Designation/ReadyLabel").visible = state.director_secondary_ready
	if state.director_authorization_valid:
		var panel: Label3D = shell.get_node("CentralHub/StatusPanel/Text")
		panel.text = panel.text.replace("DIRECTOR AUTHORIZATION REQUIRED", "DIRECTOR AUTHORIZATION VALID").replace("EXIT SEALED", "READY FOR MANUAL RELEASE")
