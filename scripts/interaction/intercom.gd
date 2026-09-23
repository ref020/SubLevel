extends Interactable
## Future dialogue listens to powered_interaction; no dialogue knowledge here.

signal powered_interaction
var powered: bool = false


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
