extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0
var player: CharacterBody3D
var camera: Camera3D
var ray: RayCast3D


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


func _aim(target: Interactable, position: Vector3, point: Vector3) -> bool:
	player.position = position
	camera.look_at(point)
	await physics_frame
	ray.refresh_target()
	var hit: bool = ray.current_target == target
	_check(hit, "Reachable interaction: " + str(target.get_path()))
	if not hit:
		print("Hit instead: ", ray.get_collider())
	return hit


func _enter_code(code: String) -> void:
	for digit: String in code:
		_key(KEY_0 + int(digit))
	_key(KEY_ENTER)


func _choice(ui: Node, id: String) -> void:
	for index: int in ui.conversation.choices.size():
		if ui.conversation.choices[index]["id"] == id:
			_key(KEY_1 + index)
			return
	_check(false, "Dialogue choice available: " + id)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var room: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(room)
	await physics_frame
	player = room.get_node("Player")
	player.set_physics_process(false)
	camera = player.get_node("Head/Camera3D")
	ray = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	ray.add_exception(player)
	var inspector: Node = camera.get_node("Inspection")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var keypad_ui: Node = player.get_node("KeypadUI")
	var dialogue: Node = player.get_node("DialogueUI")
	var drawer: Openable = room.get_node("Furniture/Desk/LockedDrawer")
	var combination: Keypad = drawer.get_node("Body/Combination")
	var exit_door: Openable = room.get_node("PuzzleProps/ExitDoor")
	var badge: Inspectable = room.get_node("Furniture/UtilityShelf/Badge")
	var exit_key: PickupItem = drawer.get_node("Body/ExitKey")
	_check(not badge is PickupItem, "Badge is inspectable but not collectible")
	var expected: Array[String] = ["7294", "3816", "5042", "9637"]
	var derived: String = ""
	for row: int in range(4):
		for col: int in range(4):
			var mesh: TextMesh = badge.get_node("Visual/Cell" + "ABCD"[col] + str(row + 1)).mesh
			_check(mesh.text == expected[row][col], "Canonical badge grid cell")
	for coordinate: String in ["C3", "A1", "D4", "B2"]:
		derived += (badge.get_node("Visual/Cell" + coordinate).mesh as TextMesh).text
	_check(derived == "4778" and combination.correct_code == derived, "Coordinate order derives drawer code")
	await _aim(badge, Vector3(1.35, 0.03, 1.65), badge.global_position)
	_key(KEY_E)
	_check(inspector.active_item == badge and not inspector.take_item(), "Badge inspection is available before Mara and cannot be taken")
	var copied_texts: Array[String] = []
	var stack: Array[Node] = [inspector.pivot]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D and node.mesh is TextMesh:
			copied_texts.append(node.mesh.text)
	_check(copied_texts.size() == 27 and copied_texts.has("SECURITY VERIFICATION"), "All text meshes survive inspection copy")
	_key(KEY_ESCAPE)
	_check(badge.visual_root.visible, "Badge remains on middle table")
	await _aim(exit_door, Vector3(3.5, 0.03, 1.7), Vector3(4.5, 1.4, 1.7))
	_key(KEY_E)
	_check(exit_door.is_locked and exit_door.state == Openable.State.CLOSED, "Exit refuses missing key")
	var unrelated: InventoryItem = InventoryItem.new()
	unrelated.item_id = &"test_access_item"
	unrelated.unlocks.assign([&"test_lock_a", &"test_lock_b"])
	inventory.add_item(unrelated)
	_key(KEY_E)
	_check(exit_door.is_locked, "Unrelated compatible-lock list cannot unlock exit")
	var other_door: Openable = load("res://scenes/interactables/door.tscn").instantiate()
	other_door.starts_locked = true
	other_door.lock_id = &"test_lock_b"
	other_door.inventory = inventory
	other_door.position = Vector3(20, 0, 0)
	room.add_child(other_door)
	other_door.interact()
	_check(not other_door.is_locked and other_door.state == Openable.State.CLOSED, "Arbitrary second compatible lock works without special door code")
	_check(inventory.has_item(&"test_access_item"), "Generic access item retained")
	inventory.remove_item(&"test_access_item")
	other_door.queue_free()
	# Standing and jumping approaches must not expose the key through the closed drawer.
	for x: float in [-3.8, -3.1, -2.4, -1.25]:
		for z: float in [-2.8, -1.1, -0.5]:
			for height: float in [0.03, 0.9]:
				player.position = Vector3(x, height, z)
				camera.look_at(exit_key.global_position)
				ray.refresh_target()
				_check(ray.current_target != exit_key, "Closed drawer shields key at " + str(player.position))
	var cabinet: Node = room.get_node("PuzzleProps/Cabinet")
	var cabinet_code: Keypad = cabinet.get_node("Keypad")
	var cabinet_door: Openable = cabinet.get_node("Door")
	var intercom: Interactable = room.get_node("PuzzleProps/Intercom")
	var grate: Openable = room.get_node("PuzzleProps/VentilationGrate/Grate")
	var breaker: Interactable = room.get_node("PuzzleProps/VentilationGrate/Breaker")
	intercom.interact()
	_check(not dialogue.visible, "No conversation before power")
	grate.get_node("Fasteners/Screw1").interact()
	_check(not grate.get_node("Fasteners/Screw1").removing, "No fastener removal without tool")
	await _aim(cabinet_code, Vector3(-2.9, 0.03, 0.6), cabinet_code.global_position)
	_key(KEY_E)
	_enter_code("0000")
	_check(cabinet_door.is_locked, "Wrong cabinet code refused")
	await create_timer(0.85).timeout
	_enter_code("4371")
	_check(not cabinet_door.is_locked and cabinet_door.state == Openable.State.CLOSED, "4371 unlocks without opening")
	await create_timer(0.85).timeout
	await _aim(cabinet_door, Vector3(-2.9, 0.03, 0.7), cabinet_door.get_node("Body").to_global(Vector3(0.345, 1.05, 0)))
	_key(KEY_E)
	await create_timer(0.9).timeout
	var tool: PickupItem = cabinet.get_node("Contents/Screwdriver")
	await _aim(tool, Vector3(-2.9, 0.03, 1.0), tool.global_position)
	_key(KEY_E)
	_key(KEY_F)
	_check(inventory.has_item(&"screwdriver"), "Tool collected through E/F")
	for screw: VentFastener in grate.get_node("Fasteners").get_children():
		await _aim(screw, Vector3(screw.global_position.x, 0.03, 1.9), screw.global_position)
		_key(KEY_E)
		await create_timer(0.8).timeout
	await _aim(grate, Vector3(1.6, 0.03, 1.9), breaker.global_position)
	_key(KEY_E)
	await create_timer(0.9).timeout
	await _aim(breaker, Vector3(1.6, 0.03, 1.9), breaker.global_position)
	_key(KEY_E)
	_check(intercom.powered, "Breaker powers intercom")
	await _aim(intercom, Vector3(2.13, 0.03, -1.8), intercom.global_position)
	_key(KEY_E)
	_key(KEY_ENTER)
	_choice(dialogue, "answer")
	_key(KEY_ENTER)
	_choice(dialogue, "trapped")
	_key(KEY_ENTER)
	_key(KEY_ENTER)
	_key(KEY_ENTER)
	_choice(dialogue, "surroundings")
	_key(KEY_ENTER)
	_choice(dialogue, "inspect")
	_key(KEY_ENTER)
	_key(KEY_ENTER)
	_key(KEY_ENTER)
	_check(dialogue.text_label.text == "C3 - A1 - D4 - B2", "Mara supplies exact coordinate sequence")
	_key(KEY_ESCAPE)
	await _aim(combination, Vector3(-1.25, 0.03, -1.2), combination.global_position)
	_key(KEY_E)
	_enter_code("4371")
	_check(drawer.is_locked and keypad_ui.status.text == "INVALID CODE", "Cabinet code does not unlock drawer")
	await create_timer(0.85).timeout
	_enter_code(derived)
	_check(not drawer.is_locked and drawer.state == Openable.State.CLOSED, "4778 unlocks without opening drawer")
	await create_timer(0.85).timeout
	await _aim(drawer, Vector3(-1.25, 0.03, -1.2), Vector3(-3.09, 0.62, -1.445))
	_key(KEY_E)
	await create_timer(0.9).timeout
	_check(drawer.state == Openable.State.OPEN, "Drawer physically opens")
	_check(exit_key.item_id == &"observation_exit_key" and exit_key.display_name == "Observation Room Key" and exit_key.description == 'A heavy key stamped "OBS-06".', "Exact key metadata")
	_check(exit_key.unlocks == [&"observation_room_exit"], "Key declares lock compatibility")
	await _aim(exit_key, Vector3(-2.1, 0.03, -1.05), exit_key.global_position)
	_key(KEY_E)
	_check(inspector.active_item == exit_key, "Key inspectable inside opened drawer")
	_key(KEY_F)
	_check(inventory.has_item(&"observation_exit_key") and not exit_key.is_inside_tree(), "Collection removes key from drawer")
	_check(inventory.get_item(&"observation_exit_key").unlocks == [&"observation_room_exit"], "Compatibility survives collection")
	await _aim(exit_door, Vector3(3.5, 0.03, 1.7), Vector3(4.5, 1.4, 1.7))
	_key(KEY_E)
	_check(not exit_door.is_locked and exit_door.state == Openable.State.CLOSED, "Compatible key unlocks but does not open")
	_check(inventory.has_item(&"observation_exit_key"), "Key is not consumed")
	_key(KEY_E)
	await create_timer(0.9).timeout
	_check(exit_door.state == Openable.State.OPEN, "Second E opens exit")
	_check(not player.test_move(Transform3D(Basis.IDENTITY, Vector3(3.8, 0.03, 1.7)), Vector3(1.2, 0, 0)), "Open threshold allows stepping beyond room")
	_check(not player.test_move(Transform3D(Basis.IDENTITY, Vector3(5.2, 0.03, 1.7)), Vector3(7.8, 0, 0)), "Completed escape reaches Central Hub through service corridor")
	player.position = Vector3(3.8, 0.03, 1.7)
	var transition_collision: KinematicCollision3D = player.move_and_collide(Vector3(9.2, 0, 0))
	_check(transition_collision == null and player.position.x > 12.9, "Player physically moves from completed Observation Room into Hub")
	room.queue_free()
	await process_frame
	print("Escape smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
