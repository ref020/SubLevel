class_name PlayerInventory
extends Node

signal changed
signal selection_changed(item_id: StringName)

var selected_item_id: StringName = &""
var _items: Dictionary = {}


func add_item(item: InventoryItem) -> bool:
	if item == null or item.item_id == &"" or has_item(item.item_id):
		return false
	_items[item.item_id] = item
	changed.emit()
	return true


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func get_item(item_id: StringName) -> InventoryItem:
	return _items.get(item_id) as InventoryItem


func get_items() -> Array[InventoryItem]:
	var items: Array[InventoryItem] = []
	for item: InventoryItem in _items.values():
		items.append(item)
	return items


func select_item(item_id: StringName) -> bool:
	if item_id != &"" and not has_item(item_id):
		return false
	selected_item_id = item_id
	selection_changed.emit(item_id)
	return true


func remove_item(item_id: StringName) -> bool:
	if not _items.erase(item_id):
		return false
	if selected_item_id == item_id:
		select_item(&"")
	changed.emit()
	return true
