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


func _click(button: Button) -> void:
	await process_frame
	await process_frame
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	root.push_input(motion, true)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)


func _use(target: Node3D, approach: Vector3) -> void:
	player.position = approach
	camera.look_at(target.get_node("Body/Panel").global_position if target is Openable else target.global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == target, "Physical ray/E target: " + str(target.name))
	_key(KEY_E)


func _text(node: Node) -> String:
	var text: String = ""
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is TextMesh: text += mesh.mesh.text + "\n"
	return text


func _run() -> void:
	root.size = Vector2i(1152, 648)
	for recovery_first: bool in [true, false]:
		var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
		root.add_child(level)
		await physics_frame
		await physics_frame
		player = level.get_node("Player")
		camera = player.get_node("Head/Camera3D")
		ray = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		ray.add_exception(player)
		var inventory: PlayerInventory = player.get_node("Inventory")
		var inspector: Node = camera.get_node("Inspection")
		var ui: CanvasLayer = player.get_node("EncoderUI")
		var modal: PlayerModalInput = player.get_node("ModalInput")
		var power: FacilityPower = level.get_node("FacilitySystems/State")
		var security: FacilitySecurity = level.get_node("SecurityAccess/State")
		var encoder: CredentialEncoder = level.get_node("SecurityAccess/Encoder")
		var door: CredentialDoor = level.get_node("SecurityAccess/InnerDoor")
		var director: Openable = level.get_node("SecurityAccess/DirectorDoor")
		var card: PickupItem = level.get_node("SecurityInvestigation/ValeCard")
		var workstation: Vector3 = Vector3(24.2, 0.03, 6.65)
		_check(not power.main_power_online and not security.security_clearance_valid and door.is_locked and director.is_locked, "Fresh scene/session gates")
		_check(card.credential.revoked and not card.credential.active and card.credential.clearance_class == 0, "World card starts revoked on every session")
		await _use(encoder, workstation)
		_check(not ui.visible and not encoder.powered and encoder.readout.text.is_empty(), "Unpowered encoder dead and unavailable")
		await _use(card, Vector3(15.28, 0.03, 10.8))
		_key(KEY_F)
		var owned: InventoryItem = inventory.get_item(&"vale_access_card")
		_check(owned != null and owned.credential != null, "Pickup preserves independent credential metadata")
		var credential: AccessCredential = owned.credential
		encoder.insert_card()
		_check(encoder.socket.installed_item == null, "No power: no insertion")
		# Even an otherwise valid credential cannot energize an unpowered reader.
		credential.active = true
		credential.revoked = false
		credential.clearance_class = 4
		await _use(door, Vector3(27.4, 0.03, 4.9))
		_check(door.is_locked and not security.security_clearance_valid, "Power gate independent of card validity")
		credential.active = false
		credential.revoked = true
		credential.clearance_class = 0
		# Main Power's full legal gameplay path remains covered by main_power_smoke.
		power.restore_main_power()
		await _use(door, Vector3(27.4, 0.03, 4.9))
		_check(door.is_locked and not security.security_clearance_valid, "Possessing revoked card never grants access")
		for height: float in [0.03, 0.9]:
			for z: float in [4.5, 5.0, 5.3, 6.1, 7.8]:
				_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(27.9, height, z)), Vector3(1.4, 0, 0)), "Closed threshold has no capsule bypass")
		await _use(encoder, workstation)
		_check(ui.visible and modal.active_owner == ui and not player.is_physics_processing() and not ray.gameplay_enabled, "Encoder owns modal input")
		_check(not player.is_processing_unhandled_input() and not player.get_node("InteractionHUD").visible, "Mouse look/HUD suspended")
		await process_frame
		await process_frame
		var panel: Control = ui.get_node("Backdrop").get_child(0).get_child(0)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.get_global_rect()), "Hardware panel fits 1152x648 viewport")
		player.get_node("InventoryUI").open_inventory()
		inspector.inspect(level.get_node("FacilityInvestigation/ValeRecord"))
		_check(not inspector.inspecting and not player.get_node("InventoryUI").visible, "Other modals cannot steal encoder")
		await _click(ui.insert_button)
		_check(encoder.socket.installed_item == owned and not inventory.has_item(owned.item_id), "Explicit insertion moves same item out of inventory")
		_check(encoder.socket.get_node("Installed").get_child_count() == 1 and encoder.status == "CARD REVOKED", "Inserted card visible and revoked")
		if recovery_first:
			encoder.set_inputs("0614", 4, "3142")
			await _click(ui.write_button)
			_check(encoder.status == "CREDENTIAL MISMATCH" and credential.revoked, "Failed rewrite preserves card")
			_key(KEY_ESCAPE)
			_check(not ui.visible and modal.active_owner == null and player.is_physics_processing(), "Escape restores gameplay")
			_check(encoder.socket.installed_item == owned and not inventory.has_item(owned.item_id), "Exit retains recoverable physical card")
			await _use(encoder, workstation)
			await _click(ui.eject_button)
			_check(inventory.get_item(owned.item_id) == owned and credential.revoked and encoder.socket.installed_item == null, "Unsuccessful card recovery")
			await _click(ui.insert_button)
			for wrong: Array in [["614", 4, "4321"], ["0615", 4, "4321"], ["0614", 3, "4321"], ["0614", 4, "3142"], ["0614", 4, "CADB"], ["0614", 4, "1073"], ["0614", 4, "432"], ["", 4, "4321"]]:
				encoder.set_inputs(wrong[0], wrong[1], wrong[2])
				_check(not encoder.submit() and encoder.status == "CREDENTIAL MISMATCH" and not encoder.writing, "Uniform immediate retry for wrong or partial credentials")
				_check(encoder.socket.installed_item == owned and credential.revoked, "Failure never destroys/restores card")
			encoder.set_inputs("0614", 4, "4321")
			_check(encoder.submit(), "Valid write begins")
			await _click(ui.eject_button)
			_check(not encoder.writing and credential.revoked and inventory.get_item(owned.item_id) == owned, "Eject during write cancels safely")
			await _click(ui.insert_button)
		# Real panel controls, no visits to investigation clue props or knowledge flags.
		encoder.set_inputs("", 1, "")
		await _click(ui.digit_buttons[0]) # First wheel starts at zero, not implicit zero-padding.
		for digit: int in [6, 1, 4]: _key(KEY_0 + digit)
		await _click(ui.class_buttons[3])
		_key(KEY_TAB)
		for digit: int in [4, 3, 2, 1]: _key(KEY_0 + digit)
		_check(encoder.employee == "0614" and encoder.clearance == 4 and encoder.verification == "4321", "Visible wheels and class buttons accept exact input")
		_check(encoder.get_node("Visual/DigitText00").mesh.text == "0", "Physical encoder display retains leading zero")
		_key(KEY_ENTER)
		_check(encoder.writing and credential.revoked and not security.security_clearance_valid, "Encoding delay precedes state mutation")
		_key(KEY_ESCAPE)
		await create_timer(1.35).timeout
		_check(owned.credential == credential and credential.active and not credential.revoked and credential.clearance_class == 4, "Same card/state restored after physical write")
		_check(encoder.socket.installed_item == owned and encoder.status == "CREDENTIAL RESTORED / CLASS IV", "Successful card remains in writer for explicit retrieval")
		_check(not security.security_clearance_valid and director.is_locked and door.is_locked, "Writing alone never completes Security")
		await _use(door, Vector3(27.4, 0.03, 4.9))
		_check(door.is_locked, "Unretrieved active card cannot open reader remotely")
		await _use(encoder, workstation)
		await _click(ui.eject_button)
		_check(inventory.get_item(owned.item_id) == owned and encoder.socket.installed_item == null, "Explicit eject retains same active inventory item")
		_key(KEY_ESCAPE)
		_check(owned.description == "An active Class IV access credential issued to Facility Director Warren Vale.", "Updated active description")
		var inv_ui: CanvasLayer = player.get_node("InventoryUI")
		inv_ui.open_inventory()
		inventory.select_item(owned.item_id)
		inv_ui.inspect_selected()
		_check(inspector.inspecting and _text(inspector.pivot).contains("ACTIVE / CLASS IV") and not _text(inspector.pivot).contains("ACCESS REVOKED"), "Inventory reinspection uses updated card visual")
		_key(KEY_ESCAPE)
		_key(KEY_ESCAPE)
		# Validity, class, and compatible reader are independently required.
		credential.clearance_class = 3
		_check(not door.has_compatible_key(), "Insufficient clearance rejected")
		credential.clearance_class = 4
		credential.compatible_access_systems.assign([&"other_system"])
		_check(not door.has_compatible_key(), "Wrong reader compatibility rejected")
		credential.compatible_access_systems.assign([&"security_inner"])
		var count: Array[int] = [0]
		security.security_clearance_changed.connect(func(_valid: bool) -> void: count[0] += 1)
		await _use(door, Vector3(27.4, 0.03, 4.9))
		_check(not door.is_locked and door.state == Openable.State.CLOSED, "First valid credential interaction unlocks without opening")
		_check(security.security_clearance_valid and count[0] == 1 and not director.is_locked, "Acceptance completes Security and releases Director threshold")
		_check(inventory.get_item(owned.item_id) == owned, "Reader does not consume credential")
		var status: String = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text
		for line: String in ["MAIN POWER             ONLINE", "SECURITY CLEARANCE     VALID", "DIRECTOR AUTHORIZATION REQUIRED", "EXIT SEALED"]:
			_check(status.contains(line), "Hub completion status: " + line)
		_check(door.get_node("Body/AcceptedLamp").visible and director.get_node("Body/AcceptedLamp").visible, "Restrained local access confirmation")
		_key(KEY_E)
		await create_timer(0.9).timeout
		_check(door.state == Openable.State.OPEN, "Second interaction physically opens Security")
		player.set_physics_process(false)
		for point: Vector3 in [Vector3(29.6, 0.03, 4.9), Vector3(30.5, 0.03, 6), Vector3(29.6, 0.03, 4.9), Vector3(27.4, 0.03, 4.9)]:
			_check(player.move_and_collide(point - player.position) == null and player.position.distance_to(point) < 0.01, "Enter inner room and return through real doorway")
		await _use(director, Vector3(26, 0.03, 7.4))
		await create_timer(0.9).timeout
		_check(director.state == Openable.State.OPEN, "Released Director threshold opens manually")
		var threshold: Vector3 = Vector3(26, 0.03, 9.6)
		_check(player.move_and_collide(threshold - player.position) == null and player.position.distance_to(threshold) < 0.01, "Director threshold physically enterable")
		_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(18.5, 0.03, -2.3)), Vector3(0, 0, -2)), "Emergency egress remains sealed")
		security.establish_access()
		_check(count[0] == 1, "Security completion is idempotent")
		# No Director puzzle interactables/content have been introduced.
		_check(level.get_node("Architecture/Facility/DirectorThreshold").find_children("*", "Interactable", true, false).is_empty(), "Director architectural shell stays separate from active props")
		await _use(encoder, workstation)
		await _click(ui.insert_button)
		ui._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(modal.active_owner == null and not ui.visible and encoder.socket.installed_item == owned, "Focus loss leaves safely recoverable card")
		ui.open_encoder(encoder)
		encoder.queue_free()
		await process_frame
		await process_frame
		_check(modal.active_owner == null and not ui.visible and inventory.get_item(owned.item_id) == owned, "Device deletion releases modal and returns retained card")
		level.queue_free()
		await process_frame
		await create_timer(0.2).timeout
	print("Security access smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
