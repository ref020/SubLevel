class_name CredentialProfile
extends Resource
## Encoder configuration; neither player nor inventory knows puzzle answers.

@export var identity: StringName
@export var employee_id: String
@export_range(1, 4) var clearance_class: int = 1
@export var verification_hash: String
@export_multiline var active_description: String
@export var revoked_label: String = "ACCESS REVOKED"
@export var active_label: String = "ACCESS ACTIVE"


func matches(item: InventoryItem, employee: String, clearance: int, verification: String) -> bool:
	return item != null and item.credential != null and item.credential.identity == identity \
		and employee.length() == 4 and verification.length() == 4 \
		and employee == employee_id and clearance == clearance_class and verification == verification_hash


func restore(item: InventoryItem) -> bool:
	if item == null or item.credential == null or item.credential.identity != identity or item.visual_scene == null:
		return false
	# Update the same item's static inspection snapshot without mutating shared meshes.
	var visual: Node3D = item.visual_scene.instantiate()
	for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is TextMesh and mesh.mesh.text == revoked_label:
			mesh.mesh = mesh.mesh.duplicate()
			mesh.mesh.text = active_label
	var updated: PackedScene = PackedScene.new()
	var result: Error = updated.pack(visual)
	visual.free()
	if result != OK:
		return false
	item.visual_scene = updated
	item.description = active_description
	item.credential.active = true
	item.credential.revoked = false
	item.credential.clearance_class = clearance_class
	return true
