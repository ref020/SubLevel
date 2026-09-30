class_name AccessCredential
extends Resource
## Mutable session credential, duplicated from the pickup template on collection.

@export var identity: StringName
@export var active: bool = false
@export var revoked: bool = true
@export_range(0, 4) var clearance_class: int = 0
@export var compatible_access_systems: Array[StringName] = []


func permits(system: StringName, minimum_class: int) -> bool:
	return active and not revoked and clearance_class >= minimum_class and compatible_access_systems.has(system)
