extends Node
## Main-scene references wire reusable props to scene-owned state and inventory.

@export var office: Node3D
@export var power: FacilityPower
@export var inventory: PlayerInventory


func _ready() -> void:
	office.get_node("Terminal").configure(power, office.get_node("State"), inventory)
	var door: Openable = office.get_node("Cabinet/Door")
	door.opened.connect(_contents_access.bind(true))
	door.closed.connect(_contents_access.bind(false))


func _contents_access(accessible: bool) -> void:
	var collider: CollisionShape3D = office.get_node_or_null("Cabinet/Module/Body/Collision")
	if collider != null:
		collider.set_deferred("disabled", not accessible)
