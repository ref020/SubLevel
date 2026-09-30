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
	player.velocity = Vector3.ZERO
	await physics_frame
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


func _fits(prop: Node, width: float, height: float) -> void:
	for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh is TextMesh: continue
		var bounds: AABB = mesh.mesh.get_aabb()
		_check(absf(mesh.position.x) + bounds.size.x * 0.5 < width * 0.5 - 0.008, "Text horizontal margin: " + str(mesh.get_path()))
		_check(absf(mesh.position.y) + bounds.size.y * 0.5 < height * 0.5 - 0.005, "Text vertical margin: " + str(mesh.get_path()))


func _run() -> void:
	root.size = Vector2i(1152, 648)
	for order: int in range(3):
		var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
		root.add_child(level)
		await physics_frame
		await physics_frame
		player = level.get_node("Player")
		camera = player.get_node("Head/Camera3D")
		ray = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		ray.add_exception(player)
		var office: Node3D = level.get_node("DirectorOffice")
		var state: FacilityDirector = office.get_node("State")
		var terminal: AuthorizationTerminal = office.get_node("Terminal")
		var power: FacilityPower = level.get_node("FacilitySystems/State")
		var entrance: Openable = level.get_node("SecurityAccess/DirectorDoor")
		var door: Openable = office.get_node("Cabinet/Door")
		var lock: SymbolLock = office.get_node("Cabinet/Door/Body/Lock")
		var module: PickupItem = office.get_node("Cabinet/Module")
		var inspector: Node = camera.get_node("Inspection")
		var inventory: PlayerInventory = player.get_node("Inventory")
		var ui: CanvasLayer = player.get_node("SymbolLockUI")
		_check(entrance.is_locked and not state.director_primary_authorized and not state.director_authorization_valid, "Fresh session gates")
		_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(26, 0.03, 8)), Vector3(0, 0, 1.6)), "Director threshold physically sealed")
		terminal.interact()
		_check(not inspector.inspecting and terminal.readout.text.is_empty(), "Terminal dead without mains")
		_check(not terminal.socket.install(null), "Socket cannot operate without mains")
		if order == 0:
			await _use(office.get_node("IncidentRegister"), Vector3(16.15, 0.03, 10))
			_check(inspector.inspecting, "Archive document discoverable before office")
			_key(KEY_ESCAPE)
		power.restore_main_power()
		# Security credential progression itself is exercised by security_access_smoke.
		level.get_node("SecurityAccess/State").establish_access()
		_check(not entrance.is_locked, "Security grants office access")
		await _use(entrance, Vector3(26, 0.03, 7.8))
		await create_timer(1.0).timeout
		_check(not player.test_move(Transform3D(Basis.IDENTITY, Vector3(26, 0.03, 8)), Vector3(0, 0, 1.6)), "Open Director threshold traversable")
		if order != 2:
			await _use(office.get_node("Map"), Vector3(24.85, 0.03, 11.65))
			_check(inspector.inspecting, "Map inspectable")
			_key(KEY_ESCAPE)
			if order == 1:
				await _use(office.get_node("IncidentRegister"), Vector3(16.15, 0.03, 10))
				_check(inspector.inspecting, "Map-first then Archive allowed")
				_key(KEY_ESCAPE)
		var departments: Array[String] = ["ADMINISTRATION", "ARCHIVE", "CONTAINMENT", "LABORATORY", "MAINTENANCE"]
		var symbols: Array[String] = ["□", "+", "◇", "○", "△"]
		for index: int in range(5):
			_check(office.get_node("Map/Visual/Department" + str(index)).mesh.text == departments[index], "Canonical map department")
			_check(office.get_node("Map/Visual/Symbol" + str(index)).mesh.text == symbols[index], "Canonical map symbol")
		_fits(office.get_node("Map"), 1.12, 0.82)
		_fits(office.get_node("IncidentRegister"), 0.36, 0.46)
		for glyph: String in SymbolLock.GLYPHS:
			_check(preload("res://assets/fonts/halcyon_symbols.ttf").has_char(glyph.unicode_at(0)), "Font renders symbol " + glyph)
		for segment: Array in [[Vector3(26, 0.03, 9.6), Vector3(-1.15, 0, 2.05)], [Vector3(24.85, 0.03, 11.65), Vector3(2.7, 0, 0)], [Vector3(27.55, 0.03, 11.65), Vector3(-0.5, 0, -0.2)]]:
			_check(not player.test_move(Transform3D(Basis.IDENTITY, segment[0]), segment[1]), "Office clue-to-cabinet aisle clear")
		var incident: String = _text(office.get_node("IncidentRegister"))
		for line: String in ["1. CONTAINMENT", "2. LABORATORY", "3. ARCHIVE", "4. MAINTENANCE", "5. ADMINISTRATION"]:
			_check(incident.contains(line), "Canonical incident priority: " + line)
		_check(module.get_node("Body/Collision").disabled, "Module cannot be targeted through closed cabinet")
		await _use(lock, Vector3(27.55, 0.03, 11.75))
		await process_frame
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.get_node("Backdrop/Center/Panel").get_global_rect()), "Symbol UI fits viewport")
		_check(ui.visible and player.get_node("ModalInput").active_owner == ui, "Symbol modal owns gameplay")
		inspector.inspect(office.get_node("Map"))
		_check(not inspector.inspecting, "Inspection cannot steal lock modal")
		for index: int in range(5): await _click(ui.symbol_buttons[0])
		_key(KEY_ENTER)
		_check(door.is_locked and ui.status.text == "SEQUENCE REJECTED" and ui.entered.is_empty(), "Wrong sequence safely retryable")
		for index: int in [3, 0, 4, 1, 2]: await _click(ui.symbol_buttons[index])
		_key(KEY_ENTER)
		_check(not door.is_locked and door.state == Openable.State.CLOSED, "Canonical sequence unlocks without opening, no knowledge flags")
		_check(module.get_node("Body/Collision").disabled, "Unlock alone does not expose module")
		_key(KEY_ESCAPE)
		_check(not ui.visible and player.get_node("ModalInput").active_owner == null, "Escape restores gameplay")
		await _use(door, Vector3(27.55, 0.03, 11.75))
		await create_timer(1.0).timeout
		_check(not module.get_node("Body/Collision").disabled, "Open cabinet exposes module")
		await _use(module, Vector3(27.55, 0.03, 11.75))
		_check(inspector.inspecting, "Module physically inspectable")
		_key(KEY_F)
		var owned: InventoryItem = inventory.get_item(&"director_authorization_module")
		_check(owned != null, "Module collectible")
		if owned == null:
			quit(1)
			return
		_check(owned.display_name == "Director Authorization Module" and owned.description == "A hardware authorization token issued for the facility director's emergency terminal.", "Exact module metadata")
		await _use(terminal, Vector3(27.05, 0.03, 11.45))
		_check(inspector.inspecting and terminal.readout.text.contains("AWAITING PRIMARY"), "Powered terminal establishes primary requirement")
		_key(KEY_ESCAPE)
		await _use(terminal.socket, Vector3(26.46, 0.03, 11.45))
		_check(terminal.socket.installed_item == owned and not inventory.has_item(owned.item_id), "Deliberate installation retains same item outside carried inventory")
		_check(terminal.socket.get_node("Installed").get_child_count() == 1 and not state.director_primary_authorized, "Physical token visible during validation")
		await create_timer(1.2).timeout
		_check(state.director_primary_authorized and not state.director_authorization_valid, "Primary accepted only; full authorization incomplete")
		await _use(terminal, Vector3(27.05, 0.03, 11.45))
		_check(inspector.inspecting and _text(inspector.pivot).contains("SERVICE CONTROL M-4") and _text(inspector.pivot).contains("NETWORK LINK: OFFLINE"), "Inspection reveals secondary M-4 requirement")
		_key(KEY_ESCAPE)
		var status: String = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text
		_check(status.contains("DIRECTOR AUTHORIZATION REQUIRED") and status.contains("EXIT SEALED"), "Hub remains sealed with third objective incomplete")
		_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(31, 0.03, -12.3)), Vector3(1.5, 0, 0)), "M-4 service side remains blocked")
		_check(office.get_node("M4Designation").find_children("*", "Interactable", true, false).is_empty(), "M-4 has no controls")
		level.queue_free()
		await process_frame
		await create_timer(0.2).timeout
	print("Director office smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
