extends Interactable
## A scene connection handles powered_interaction; no NPC content lives here.

signal powered_interaction
@export var starts_powered: bool = false
var powered: bool = false


func _ready() -> void:
	if starts_powered:
		set_powered()


func set_powered() -> void:
	powered = true
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.8, 0.4)
	material.emission_enabled = true
	material.emission = Color(0.15, 0.65, 0.3)
	$Indicator.material_override = material
	$ReadyLight.show()


func interact() -> void:
	if not powered:
		feedback("No power.")
	else:
		feedback("The intercom is active.")
		powered_interaction.emit()
