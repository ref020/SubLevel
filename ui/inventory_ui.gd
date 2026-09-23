extends CanvasLayer

@export var inventory: PlayerInventory
@export var input_session: PlayerModalInput
@export var inspection: Node

var _proxy: Inspectable
var _ids: Array[StringName] = []

@onready var item_list: ItemList = $Backdrop/Center/Panel/Margin/Content/Items
@onready var details: Label = $Backdrop/Center/Panel/Margin/Content/Details
@onready var inspect_button: Button = $Backdrop/Center/Panel/Margin/Content/Inspect


func _ready() -> void:
	hide()
	inventory.changed.connect(_refresh)
	inventory.selection_changed.connect(_show_selection)
	item_list.item_selected.connect(_select_index)
	inspect_button.pressed.connect(inspect_selected)
	$Backdrop/Center/Panel/Margin/Content/Return.pressed.connect(close_inventory)
	_refresh()


func open_inventory() -> void:
	if not input_session.acquire(self):
		return
	_refresh()
	show()


func close_inventory(restore_mouse: bool = true) -> void:
	if input_session.active_owner != self:
		return
	hide()
	input_session.release(self, restore_mouse)


func _refresh() -> void:
	item_list.clear()
	_ids.clear()
	for item: InventoryItem in inventory.get_items():
		_ids.append(item.item_id)
		item_list.add_item(item.display_name)
	_show_selection(inventory.selected_item_id)


func _select_index(index: int) -> void:
	if index >= 0 and index < _ids.size():
		inventory.select_item(_ids[index])


func _show_selection(item_id: StringName) -> void:
	var item: InventoryItem = inventory.get_item(item_id)
	if item == null:
		item_list.deselect_all()
		details.text = "Inventory is empty." if _ids.is_empty() else "Select an item."
		inspect_button.disabled = true
	else:
		item_list.select(_ids.find(item_id))
		details.text = item.display_name + "\n\n" + item.description
		inspect_button.disabled = item.visual_scene == null


func inspect_selected() -> void:
	if input_session.active_owner != self:
		return
	var item: InventoryItem = inventory.get_item(inventory.selected_item_id)
	if item == null or item.visual_scene == null:
		return
	_proxy = Inspectable.new()
	var visual: Node3D = item.visual_scene.instantiate() as Node3D
	_proxy.add_child(visual)
	_proxy.visual_root = visual
	_proxy.initial_inspection_rotation = item.initial_rotation
	_proxy.inspection_distance = item.inspection_distance
	_proxy.minimum_distance = item.minimum_distance
	_proxy.maximum_distance = item.maximum_distance
	_proxy.rotation_sensitivity = item.rotation_sensitivity
	add_child(_proxy)
	inspection.inspect(_proxy, self)
	if inspection.active_item == _proxy:
		hide()
	else:
		_dispose_proxy()


func inspection_returned(restore_mouse: bool) -> void:
	_dispose_proxy()
	if not restore_mouse:
		close_inventory(false)
		return
	_refresh()
	show()


func _dispose_proxy() -> void:
	if is_instance_valid(_proxy):
		# The proxy has no physics; defer deletion safely even during tree exit.
		_proxy.hide()
		_proxy.queue_free()
	_proxy = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not event.is_echo():
		if input_session.active_owner == self:
			get_viewport().set_input_as_handled()
			close_inventory()
		elif not is_instance_valid(input_session.active_owner):
			get_viewport().set_input_as_handled()
			open_inventory()
	elif input_session.active_owner == self and event is InputEventKey:
		if event.is_action_pressed("toggle_mouse_capture"):
			get_viewport().set_input_as_handled()
			close_inventory()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and input_session.active_owner == self:
		close_inventory(false)


func _exit_tree() -> void:
	if is_node_ready():
		if is_instance_valid(_proxy) and inspection.active_item == _proxy:
			inspection.finish_inspection(false)
		close_inventory(false)
