extends Node
## Single local-player input owner. Presentation uses an isolated 3D world.

signal inspection_started(item: Inspectable)
signal inspection_ended

@export var input_session: PlayerModalInput
@export var inventory: PlayerInventory

var active_item: Inspectable
var inspecting: bool = false
var distance: float = 1.4
var _minimum: float
var _maximum: float
var _dragging: bool = false
var _visual_was_visible: bool
var _return_owner: Node

@onready var overlay: CanvasLayer = $Overlay
@onready var pivot: Node3D = $Overlay/ViewportContainer/Viewport/Stage/Pivot


func _ready() -> void:
	add_to_group("inspection_presenter")
	overlay.hide()


func inspect(item: Inspectable, return_owner: Node = null) -> void:
	if inspecting or not is_instance_valid(item.visual_root):
		return
	if is_instance_valid(input_session.active_owner) and input_session.active_owner != return_owner:
		return
	var copy: Node3D = _copy_meshes(item.visual_root)
	pivot.add_child(copy)
	# The visual root defines object-local axes; ignore its world placement.
	copy.transform = Transform3D.IDENTITY
	var bounds: AABB = _mesh_bounds(copy)
	var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if longest <= 0.0001:
		pivot.remove_child(copy)
		copy.queue_free()
		push_warning("Inspectable has no non-empty static mesh visuals.")
		return
	var fit_scale: float = 0.8 / longest
	copy.scale = Vector3.ONE * fit_scale
	copy.position = -bounds.get_center() * fit_scale
	var acquired: bool = input_session.transfer(return_owner, self) if return_owner != null else input_session.acquire(self)
	if not acquired:
		pivot.remove_child(copy)
		copy.queue_free()
		return
	active_item = item
	_return_owner = return_owner
	inspecting = true
	_visual_was_visible = item.visual_root.visible
	item.visual_root.hide()
	item.tree_exiting.connect(_on_item_exiting, CONNECT_ONE_SHOT)
	_minimum = maxf(0.85, item.minimum_distance)
	_maximum = maxf(_minimum, item.maximum_distance)
	distance = clampf(item.inspection_distance, _minimum, _maximum)
	pivot.position = Vector3(0, 0, -distance)
	pivot.rotation_degrees = item.initial_inspection_rotation
	$Overlay/Hints.text = "Drag LMB — Rotate    |    Mouse Wheel — Zoom\nRMB / Esc — Return"
	if item is PickupItem and return_owner == null:
		$Overlay/Hints.text += "    |    [F] Take"
	overlay.show()
	inspection_started.emit(item)


func finish_inspection(restore_mouse: bool = true) -> void:
	if not inspecting:
		return
	if is_instance_valid(active_item):
		if is_instance_valid(active_item.visual_root):
			active_item.visual_root.visible = _visual_was_visible
		if active_item.tree_exiting.is_connected(_on_item_exiting):
			active_item.tree_exiting.disconnect(_on_item_exiting)
	active_item = null
	inspecting = false
	_dragging = false
	for child: Node in pivot.get_children():
		pivot.remove_child(child)
		child.queue_free()
	overlay.hide()
	var previous: Node = _return_owner
	_return_owner = null
	if is_instance_valid(previous) and not previous.is_queued_for_deletion():
		input_session.transfer(self, previous)
		previous.inspection_returned(restore_mouse)
	else:
		input_session.release(self, restore_mouse)
	inspection_ended.emit()


func _input(event: InputEvent) -> void:
	if not inspecting:
		return
	# Consume the exit event before normal Escape handling can see it.
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_mouse_capture"):
		finish_inspection()
	elif event.is_action_pressed("take_item") and not event.is_echo():
		take_item()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					finish_inspection()
			MOUSE_BUTTON_LEFT:
				_dragging = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					zoom(-0.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					zoom(0.1)
	elif event is InputEventMouseMotion and _dragging:
		rotate_object(event.relative)


func rotate_object(motion: Vector2) -> void:
	if inspecting and is_instance_valid(active_item):
		var sensitivity: float = deg_to_rad(active_item.rotation_sensitivity)
		# Camera-space axes allow tumbling freely, including the underside/back.
		pivot.basis = (Basis(Vector3.UP, motion.x * sensitivity)
			* Basis(Vector3.RIGHT, motion.y * sensitivity) * pivot.basis).orthonormalized()


func zoom(amount: float) -> void:
	if inspecting:
		distance = clampf(distance + amount, _minimum, _maximum)
		pivot.position.z = -distance


func take_item() -> bool:
	if not inspecting or not active_item is PickupItem or _return_owner != null:
		return false
	var pickup: PickupItem = active_item as PickupItem
	if pickup.collected or inventory == null or inventory.has_item(pickup.item_id):
		return false
	var data: InventoryItem = InventoryItem.new()
	data.item_id = pickup.item_id
	data.display_name = pickup.display_name
	data.description = pickup.description
	data.unlocks.assign(pickup.unlocks)
	data.initial_rotation = pickup.initial_inspection_rotation
	data.inspection_distance = pickup.inspection_distance
	data.minimum_distance = pickup.minimum_distance
	data.maximum_distance = pickup.maximum_distance
	data.rotation_sensitivity = pickup.rotation_sensitivity
	# Snapshot only static meshes/materials; never retain a world body or script.
	var visual: Node3D = _copy_meshes(pickup.visual_root)
	visual.visible = true
	visual.transform = Transform3D.IDENTITY
	_set_visual_owner(visual, visual)
	data.visual_scene = PackedScene.new()
	var packed: Error = data.visual_scene.pack(visual)
	visual.free()
	if packed != OK or not inventory.add_item(data):
		return false
	finish_inspection()
	pickup.remove_from_world()
	return true


func _set_visual_owner(node: Node, root: Node) -> void:
	for child: Node in node.get_children():
		child.owner = root
		_set_visual_owner(child, root)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and inspecting:
		finish_inspection(false)


func _on_item_exiting() -> void:
	finish_inspection()


func _exit_tree() -> void:
	if inspecting:
		finish_inspection(false)


func _copy_meshes(source: Node3D) -> Node3D:
	var copy: Node3D = Node3D.new()
	if source is MeshInstance3D:
		var mesh_copy: MeshInstance3D = MeshInstance3D.new()
		mesh_copy.mesh = source.mesh
		mesh_copy.material_override = source.material_override
		mesh_copy.material_overlay = source.material_overlay
		if source.mesh != null:
			for index: int in source.mesh.get_surface_count():
				mesh_copy.set_surface_override_material(index, source.get_surface_override_material(index))
		copy.free()
		copy = mesh_copy
	copy.transform = source.transform
	copy.visible = source.visible
	for child: Node in source.get_children():
		if child is Node3D:
			copy.add_child(_copy_meshes(child))
	return copy


func _mesh_bounds(root: Node3D) -> AABB:
	var bounds: AABB
	var found: bool = false
	var nodes: Array[Node] = [root]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children())
		if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
			var local_transform: Transform3D = root.global_transform.affine_inverse() * node.global_transform
			var mesh_bounds: AABB = local_transform * node.get_aabb()
			bounds = bounds.merge(mesh_bounds) if found else mesh_bounds
			found = true
	return bounds
