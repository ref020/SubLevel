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


func _text(visual: Node) -> String:
	var result: String = ""
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		if node.mesh is TextMesh:
			result += node.mesh.text + "\n"
	return result


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	var player: CharacterBody3D = level.get_node("Player")
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	ray.add_exception(player)
	var radio: TunableRadio = level.get_node("FacilityInvestigation/M2")
	var elias: ConversationParticipant = level.get_node("FacilityInvestigation/Elias")
	var ui: CanvasLayer = player.get_node("RadioUI")
	var dialogue: CanvasLayer = player.get_node("DialogueUI")
	var modal: PlayerModalInput = player.get_node("ModalInput")
	var inventory_ui: CanvasLayer = player.get_node("InventoryUI")
	var inspector: Node = camera.get_node("Inspection")
	var log_record: Inspectable = level.get_node("FacilityInvestigation/CalibrationLog")
	var vale: Inspectable = level.get_node("FacilityInvestigation/ValeRecord")
	var note: PickupItem = level.get_node("PuzzleProps/Cabinet/Contents/Note")
	_check(_text(note.visual_root).strip_edges() == "M-2 is still three tenths out.\nVale refuses to change the card.", "Canonical note physically readable")
	_check(_text(log_record.visual_root).contains("M-2            -0.3") and _text(log_record.visual_root).contains("A-4            +0.1") and _text(log_record.visual_root).contains("C-7            +0.2"), "Calibration entries preserved equally")
	_check(_text(vale.visual_root).contains("107.6 MHz") and _text(vale.visual_root).contains("DR. WARREN VALE") and not _text(vale.visual_root).contains("107.3"), "Vale card supplies only its canonical frequency")
	_check(not log_record is PickupItem and not vale is PickupItem, "Environmental records remain in place")
	for document: Inspectable in [note, log_record, vale]:
		var paper: MeshInstance3D = document.visual_root.get_node("Paper")
		var bounds: AABB = paper.get_aabb()
		for mesh: MeshInstance3D in document.visual_root.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh is TextMesh:
				for corner: int in range(8):
					var point: Vector3 = paper.to_local(mesh.to_global(mesh.get_aabb().get_endpoint(corner)))
					_check(point.x > bounds.position.x and point.x < bounds.end.x and point.y > bounds.position.y and point.y < bounds.end.y, "Document lettering stays on paper: " + str(document.name))
	_check(radio.global_position.is_equal_approx(level.get_node("Architecture/Facility/Maintenance/ReservedRadioM2").global_position), "M-2 uses reserved Maintenance position")
	_check(elias.npc_id == &"elias" and not elias.contacted and elias.flags.is_empty(), "Fresh Elias session")
	_check(not elias.request_action("open_coolant_bypass"), "Unimplemented bypass action refused")
	# Actual world ray and E path; no clue inspections or knowledge flags yet.
	player.position = Vector3(24.8, 0.03, 0.9)
	camera.look_at(radio.global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == radio, "M-2 reachable from standing position")
	var mouse_before: Input.MouseMode = Input.mouse_mode
	_key(KEY_E)
	_check(ui.visible and modal.active_owner == ui, "E enters exclusive radio modal")
	_check(not player.is_physics_processing() and not ray.gameplay_enabled and not player.get_node("InteractionHUD").visible, "Tuning suppresses movement, targeting, HUD")
	var before: Transform3D = player.transform
	var look: Transform3D = camera.transform
	Input.action_press("move_forward")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.screen_relative = Vector2(100, 50)
	root.push_input(motion)
	inventory_ui.open_inventory()
	inspector.inspect(log_record)
	player.get_node("KeypadUI").open_keypad(level.get_node("PuzzleProps/Cabinet/Keypad"))
	_check(not dialogue.open_dialogue(elias), "Dialogue cannot steal tuning modal")
	await physics_frame
	Input.action_release("move_forward")
	_check(player.transform.is_equal_approx(before) and camera.transform.is_equal_approx(look), "Tuning blocks walk and mouse look")
	_check(not inventory_ui.visible and not inspector.inspecting and not player.get_node("KeypadUI").visible, "Competing modals refused")
	var initial: float = radio.frequency
	_key(KEY_RIGHT)
	_check(is_equal_approx(radio.frequency, initial + 0.1), "Keyboard tunes exactly one tenth")
	_key(KEY_LEFT)
	_check(is_equal_approx(radio.frequency, initial), "Reverse tuning returns exactly")
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	_check(is_equal_approx(radio.frequency, initial + 0.1), "Mouse wheel tunes one step")
	_key(KEY_LEFT)
	_check((radio.get_node("Visual/Frequency").mesh as TextMesh).text == "99.5 MHz", "Physical frequency display tracks dial")
	await process_frame
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.get_node("Backdrop/Center/Panel").get_global_rect()), "Radio controls fit normal viewport")
	await create_timer(1.0).timeout
	_check(not elias.contacted and ui.visible, "Incorrect frequency remains static")
	_key(KEY_ESCAPE)
	_check(not ui.visible and modal.active_owner == null and player.is_physics_processing() and Input.mouse_mode == mouse_before, "Escape restores prior gameplay state")
	inventory_ui.open_inventory()
	radio.interact()
	_check(not ui.visible and modal.active_owner == inventory_ui, "Inventory blocks tuning")
	inventory_ui.close_inventory()
	_key(KEY_E)
	for step: int in range(77):
		_key(KEY_RIGHT)
	_check(is_equal_approx(radio.frequency, 107.2), "Dial advances without snapping to station")
	_key(KEY_RIGHT)
	await create_timer(0.25).timeout
	_check(not elias.contacted, "Passing target briefly does not force conversation")
	_key(KEY_RIGHT)
	await create_timer(1.0).timeout
	_check(not elias.contacted, "Adjacent 107.4 has no transmission")
	_key(KEY_LEFT)
	await create_timer(1.05).timeout
	_check(dialogue.visible and not ui.visible and modal.active_owner == dialogue and elias.contacted, "Stable 107.3 hands modal to Elias without prerequisite clues")
	_check(dialogue.conversation.node_id == "first" and dialogue.speaker_label.text == "ELIAS", "First contact starts at introduction")
	_check(not player.is_physics_processing() and not ray.gameplay_enabled and not ui.noise.playing, "Handoff retains suppression and silences static")
	for line: int in range(7):
		if dialogue.conversation.node_id != "menu":
			_key(KEY_ENTER)
	_check(elias.flags.get("generator_problem_established", false) and dialogue.conversation.node_id == "menu", "Concise first contact establishes cooperative problem")
	_check(dialogue.conversation.choices.size() == 2, "Only reminder and end choices; no fake bypass action")
	_key(KEY_ESCAPE)
	_check(modal.active_owner == null and player.is_physics_processing() and Input.mouse_mode == mouse_before, "Dialogue exit restores original gameplay snapshot")
	_key(KEY_E)
	await create_timer(1.05).timeout
	_check(dialogue.conversation.node_id == "menu", "Retained frequency gives repeat contact without introduction")
	_key(KEY_1)
	_check(dialogue.conversation.node_id == "reminder", "Repeat context remains accessible")
	_key(KEY_ESCAPE)
	# Both records are targetable at their physical surfaces and fully inspectable.
	for entry: Array in [[log_record, Vector3(13.1, 0.03, -10.7)], [vale, Vector3(14.9, 0.03, 10.7)]]:
		player.position = entry[1]
		camera.look_at(entry[0].global_position)
		await physics_frame
		ray.refresh_target()
		_check(ray.current_target == entry[0], "Record physically reachable: " + str(entry[0].name))
		_key(KEY_E)
		_check(inspector.active_item == entry[0], "E inspects record")
		_check(not inspector.take_item(), "Record cannot be collected")
		_check(_text(inspector.pivot).contains("107.6" if entry[0] == vale else "-0.3"), "Inspection retains clue meshes")
		_key(KEY_ESCAPE)
	# Existing cabinet suite covers its lock; here verify note snapshot/re-reading.
	note.interact()
	_key(KEY_F)
	var inventory: PlayerInventory = player.get_node("Inventory")
	_check(inventory.has_item(&"cabinet_note"), "Note uses established inspect/F take flow")
	_check(inventory.get_item(&"cabinet_note").description == "M-2 is still three tenths out.\nVale refuses to change the card.", "Inventory preserves canonical note description")
	inventory.select_item(&"cabinet_note")
	inventory_ui.open_inventory()
	inventory_ui.inspect_selected()
	_check(_text(inspector.pivot).contains("Vale refuses to change the card."), "Note can be read again from inventory inspection")
	_key(KEY_ESCAPE)
	inventory_ui.close_inventory()
	# Focus loss and target deletion restore input safely.
	radio.interact()
	ui._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(modal.active_owner == null and not ui.noise.playing, "Focus loss cleans tuning")
	radio.interact()
	for step: int in range(300):
		radio.tune(-1)
	_check(is_equal_approx(radio.frequency, 87.5), "Lower frequency clamp")
	for step: int in range(300):
		radio.tune(1)
	_check(is_equal_approx(radio.frequency, 108.0), "Upper frequency clamp")
	radio.queue_free()
	await process_frame
	await process_frame
	_check(modal.active_owner == null and not ui.visible, "Deleting radio cleans tuning")
	level.queue_free()
	await process_frame
	# Let the audio server retire its last stopped playback before process exit.
	await create_timer(0.15).timeout
	print("Radio smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)

