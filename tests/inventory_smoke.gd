extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _key(code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	event.pressed = false
	root.push_input(event)


func _run() -> void:
	root.size = Vector2i(1152, 900)
	for production: bool in [false, true]:
		var level: Node3D = load("res://scenes/levels/observation_room.tscn" if production else "res://scenes/levels/inventory_test.tscn").instantiate()
		root.add_child(level)
		var player: CharacterBody3D = level.get_node("Player")
		var inventory: PlayerInventory = player.get_node("Inventory")
		var ui: CanvasLayer = player.get_node("InventoryUI")
		var camera: Camera3D = player.get_node("Head/Camera3D")
		var ray: RayCast3D = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		var inspection: Node = camera.get_node("Inspection")
		var modal: PlayerModalInput = player.get_node("ModalInput")
		var keypad_ui: CanvasLayer = player.get_node("KeypadUI")
		await physics_frame
		await physics_frame
		_check(inventory.get_items().is_empty(), "Inventory starts empty")
		_key(KEY_TAB)
		_check(ui.visible and ui.details.text == "Inventory is empty.", "Tab opens empty inventory")
		_check(not player.is_physics_processing() and not ray.gameplay_enabled and not player.get_node("InteractionHUD").visible, "Inventory suspends gameplay")
		var pose: Transform3D = player.transform
		Input.action_press("move_forward")
		Input.action_press("jump")
		await physics_frame
		await physics_frame
		_check(player.transform.is_equal_approx(pose), "Movement and jump remain suspended")
		Input.action_release("move_forward")
		Input.action_release("jump")
		_key(KEY_TAB)
		_check(not ui.visible and player.is_physics_processing(), "Tab restores gameplay")
		var photo: Inspectable = level.get_node("Furniture/Desk/Photograph" if production else "Photograph")
		inspection.inspect(photo)
		_key(KEY_TAB)
		_check(not ui.visible and inspection.inspecting, "Inventory cannot steal world inspection")
		_check(not inspection.take_item(), "Noncollectible cannot be taken")
		inspection.finish_inspection()
		var prefix: String = "PuzzleProps/Cabinet/Contents/" if production else ""
		if production:
			var keypad: Keypad = level.get_node("PuzzleProps/Cabinet/Keypad")
			keypad_ui.open_keypad(keypad)
			_key(KEY_TAB)
			_check(not ui.visible and keypad_ui.visible, "Inventory cannot steal keypad ownership")
			keypad_ui.close_keypad()
			keypad.submit_code("4371")
			var door: Openable = level.get_node("PuzzleProps/Cabinet/Door")
			door.animation_duration = 0.1
			door.interact()
			await create_timer(0.2).timeout
		var names: Array[String] = ["Screwdriver", "Cassette"]
		if production:
			names.append("Note")
		for item_name: String in names:
			var pickup: PickupItem = level.get_node(prefix + item_name)
			var id: StringName = pickup.item_id
			var description: String = pickup.description
			player.position = Vector3(-2.9, 0.03, 1.0) if production else Vector3(pickup.position.x, 0.03, 2)
			camera.look_at(pickup.global_position)
			await physics_frame
			ray.refresh_target()
			_check(ray.current_target == pickup, "Reachable pickup: " + item_name)
			if ray.current_target != pickup:
				print("Hit instead: ", ray.get_collider())
			_key(KEY_E)
			_check(inspection.active_item == pickup, "E inspects before collection")
			_key(KEY_F)
			_check(inventory.has_item(id) and not inspection.inspecting, "F collects and closes inspection")
			_check(not pickup.is_inside_tree(), "World item and physics immediately detached")
			await process_frame
			await process_frame
			_check(not is_instance_valid(pickup), "World item freed")
			var data: InventoryItem = inventory.get_item(id)
			if data == null:
				continue
			_check(data.description == description and data.visual_scene != null, "Metadata and inspection representation retained")
			_check(not inventory.add_item(data), "Duplicate unique item rejected")
			ray.refresh_target()
			_check(not ray.current_target is PickupItem or ray.current_target.item_id != id, "Collected collider no longer targeted")
		_check(inventory.has_item(&"screwdriver") and inventory.has_item(&"cassette_tape"), "Required tool and cassette IDs")
		if production:
			_check(inventory.has_item(&"cabinet_note"), "Required note ID")
		_key(KEY_TAB)
		inventory.select_item(&"cassette_tape")
		_check(ui.details.text.contains("An unlabeled audio cassette."), "Selection displays description")
		ui.inspect_button.pressed.emit()
		_check(inspection.inspecting and not ui.visible and modal.active_owner == inspection, "Inventory hands off to existing inspector")
		_check(not player.is_physics_processing() and not ray.gameplay_enabled, "No gameplay gap during handoff")
		var orientation: Basis = inspection.pivot.basis
		inspection.rotate_object(Vector2(80, 40))
		inspection.zoom(-0.1)
		_check(not inspection.pivot.basis.is_equal_approx(orientation), "Owned item rotates")
		_check(not inspection.take_item(), "Owned item cannot be taken twice")
		_key(KEY_ESCAPE)
		_check(ui.visible and modal.active_owner == ui and not player.is_physics_processing(), "Escape returns to inventory, not gameplay")
		_key(KEY_ESCAPE)
		_check(not ui.visible and modal.active_owner == null and player.is_physics_processing(), "Second Escape restores gameplay")
		_key(KEY_TAB)
		ui.inspect_selected()
		inspection._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(not inspection.inspecting and not ui.visible and modal.active_owner == null, "Focus loss safely unwinds nested inventory inspection")
		_check(inventory.remove_item(&"cassette_tape") and not inventory.has_item(&"cassette_tape") and inventory.selected_item_id == &"", "Removal clears selection")
		_check(not inventory.remove_item(&"missing") and not inventory.select_item(&"missing"), "Unknown IDs handled safely")
		_key(KEY_TAB)
		inventory.select_item(&"screwdriver")
		ui.inspect_selected()
		_check(inspection.inspecting, "Nested inspection active before scene teardown")
		level.queue_free()
		await process_frame
		await process_frame
	print("Inventory smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
