extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _mouse_button(index: MouseButton, pressed: bool = true) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	return event


func _run() -> void:
	var level: Node3D = load("res://scenes/levels/inspection_test.tscn").instantiate()
	root.add_child(level)
	var player: CharacterBody3D = level.get_node("Player")
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	var inspection: Node = camera.get_node("Inspection")
	var hud: CanvasLayer = player.get_node("InteractionHUD")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	await physics_frame
	await physics_frame
	for node_name: String in ["Photograph", "Block", "TestItem"]:
		var item: Inspectable = level.get_node(node_name)
		var world_transform: Transform3D = item.global_transform
		var visual_transform: Transform3D = item.visual_root.transform
		var body: StaticBody3D = item.get_node("Body")
		var layer: int = body.collision_layer
		var mask: int = body.collision_mask
		player.position = Vector3(item.position.x, 0, 2)
		player.velocity = Vector3.ZERO
		camera.look_at(item.global_position)
		for cycle: int in range(3):
			ray.refresh_target()
			_check(ray.current_target == item, node_name + ": ray targets item")
			ray._unhandled_input(press)
			_check(inspection.inspecting, node_name + ": E enters inspection")
			_check(not player.is_physics_processing() and not player.is_processing_unhandled_input(), "Movement and look are suspended")
			_check(not hud.visible and not item.visual_root.visible, "Normal HUD and original visuals hidden")
			_check(inspection.pivot.get_child_count() == 1, "One visual copy only")
			var nodes: Array[Node] = [inspection.pivot]
			while not nodes.is_empty():
				var node: Node = nodes.pop_back()
				_check(not node is CollisionObject3D and node.get_script() == null, "Presentation contains no physics or scripts")
				nodes.append_array(node.get_children())
			_check(inspection.pivot.get_world_3d() != item.get_world_3d(), "Inspection world is isolated")
			ray._unhandled_input(press)
			_check(ray.current_target == null and not ray.gameplay_enabled, "World interaction remains disabled even on E")
			var player_transform: Transform3D = player.transform
			var camera_transform: Transform3D = camera.transform
			Input.action_press("move_forward")
			Input.action_press("jump")
			var motion: InputEventMouseMotion = InputEventMouseMotion.new()
			motion.relative = Vector2(70, 30)
			motion.screen_relative = motion.relative
			var orientation: Basis = inspection.pivot.basis
			root.push_input(motion)
			_check(inspection.pivot.basis.is_equal_approx(orientation), "No drag means no rotation")
			root.push_input(_mouse_button(MOUSE_BUTTON_LEFT))
			root.push_input(motion)
			root.push_input(_mouse_button(MOUSE_BUTTON_LEFT, false))
			_check(not inspection.pivot.basis.is_equal_approx(orientation), "LMB drag rotates copy")
			_check(camera.transform.is_equal_approx(camera_transform), "Mouse drag does not change camera look")
			await physics_frame
			await physics_frame
			_check(player.transform.is_equal_approx(player_transform), "WASD/jump cannot move player")
			Input.action_release("move_forward")
			Input.action_release("jump")
			var before_zoom: float = inspection.distance
			root.push_input(_mouse_button(MOUSE_BUTTON_WHEEL_UP))
			_check(inspection.distance < before_zoom, "Wheel zooms closer")
			inspection.zoom(-100)
			_check(is_equal_approx(inspection.distance, item.minimum_distance), "Minimum zoom clamp")
			inspection.zoom(100)
			_check(is_equal_approx(inspection.distance, item.maximum_distance), "Maximum zoom clamp")
			_check(body.collision_layer == layer and body.collision_mask == mask, "Original collision remains unchanged")
			if cycle % 2 == 0:
				var escape: InputEventKey = InputEventKey.new()
				escape.physical_keycode = KEY_ESCAPE
				escape.pressed = true
				root.push_input(escape)
			else:
				root.push_input(_mouse_button(MOUSE_BUTTON_RIGHT))
			_check(not inspection.inspecting and not inspection.overlay.visible, "RMB/Escape exits inspection")
			_check(player.is_physics_processing() and player.is_processing_unhandled_input(), "Movement/look processing restored")
			_check(hud.visible and item.visual_root.visible, "World visuals/HUD restored")
			_check(inspection.pivot.get_child_count() == 0, "No leftover inspection copy")
			_check(item.global_transform.is_equal_approx(world_transform) and item.visual_root.transform.is_equal_approx(visual_transform), "No world transform drift")
			ray.refresh_target()
			_check(ray.current_target == item, "Original collision is targetable after exit")
	_check(not level.get_node("Photograph") is PickupItem and not level.get_node("Block") is PickupItem, "Inspect-only objects are not pickup-capable")
	var pickup: PickupItem = level.get_node("TestItem")
	_check(pickup.item_id == &"test_item" and pickup.display_name == "Test Item" and pickup.description == "Used to validate future inventory support.", "Pickup metadata accessible")
	inspection.inspect(pickup)
	inspection._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not inspection.inspecting and pickup.visual_root.visible, "Focus loss safely ends inspection")
	inspection.inspect(pickup)
	pickup.queue_free()
	await process_frame
	await process_frame
	_check(not inspection.inspecting and player.is_physics_processing(), "Deleting inspected item restores input")
	print("Inspection smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
