class_name ItemSocket
extends Interactable
## Retains the real InventoryItem while installed, rather than destroying it.

signal item_installed(item: InventoryItem)
signal item_ejected(item: InventoryItem)
@export var accepts_tag: StringName
@export var socket_label: String = "Slot"
var inventory: PlayerInventory
var installed_item: InventoryItem


func get_interaction_prompt() -> String:
	return socket_label + (" — Installed" if installed_item != null else " — Insert")


func interact() -> void:
	if installed_item != null:
		feedback("Already fitted.")
		return
	if inventory != null:
		for item: InventoryItem in inventory.get_items():
			if item.installation_tags.has(accepts_tag):
				install(item)
				return
	feedback("Nothing I have fits this connection.")


func install(item: InventoryItem) -> bool:
	if installed_item != null or item == null or inventory == null or not item.installation_tags.has(accepts_tag):
		return false
	if inventory.get_item(item.item_id) != item or item.visual_scene == null:
		return false
	var visual: Node3D = item.visual_scene.instantiate()
	# Claim before inventory signals can re-enter this socket.
	installed_item = item
	if not inventory.remove_item(item.item_id):
		installed_item = null
		visual.free()
		return false
	$Installed.add_child(visual)
	item_installed.emit(item)
	return true


func eject() -> bool:
	if installed_item == null or not is_instance_valid(inventory) or inventory.has_item(installed_item.item_id):
		return false
	var item: InventoryItem = installed_item
	installed_item = null
	if not inventory.add_item(item):
		installed_item = item
		return false
	for child: Node in $Installed.get_children():
		$Installed.remove_child(child)
		child.queue_free()
	item_ejected.emit(item)
	return true


func refresh_visual() -> void:
	for child: Node in $Installed.get_children():
		$Installed.remove_child(child)
		child.queue_free()
	if installed_item != null and installed_item.visual_scene != null:
		$Installed.add_child(installed_item.visual_scene.instantiate())
