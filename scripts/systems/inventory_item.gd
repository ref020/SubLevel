class_name InventoryItem
extends Resource
## Owned item data, independent of the collectible world node.

@export var item_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var unlocks: Array[StringName] = []
@export var visual_scene: PackedScene
@export var initial_rotation: Vector3 = Vector3.ZERO
@export var inspection_distance: float = 1.4
@export var minimum_distance: float = 0.85
@export var maximum_distance: float = 2.5
@export var rotation_sensitivity: float = 0.3
