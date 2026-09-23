extends Node
## Local auxiliary circuit only. All references are supplied by the room scene.

signal auxiliary_power_activated
@export var inventory: PlayerInventory
@export var grate: Openable
@export var breaker: Interactable
@export var intercom: Interactable
@export var standby_light: Light3D
@export var standby_screen: MeshInstance3D
var auxiliary_power_active: bool = false


func _ready() -> void:
	for screw: Node in grate.get_node("Fasteners").get_children():
		screw.inventory = inventory
	grate.opened.connect(breaker.enable_access)
	breaker.activated.connect(activate_power)


func activate_power() -> void:
	if auxiliary_power_active:
		return
	auxiliary_power_active = true
	intercom.set_powered()
	standby_light.show()
	var screen_material: StandardMaterial3D = StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.04, 0.08, 0.05)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.025, 0.09, 0.045)
	standby_screen.material_override = screen_material
	auxiliary_power_activated.emit()
