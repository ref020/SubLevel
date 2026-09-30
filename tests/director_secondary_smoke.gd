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


func _choose(ui: Node, id: String) -> void:
	var found: int = -1
	for index: int in ui.conversation.choices.size():
		if ui.conversation.choices[index]["id"] == id: found = index
	_check(found >= 0, "Choice available: " + id)
	if found >= 0: await _click(ui.buttons.get_child(found))


func _until(ui: Node, id: String) -> void:
	for step: int in range(20):
		if ui.conversation.node_id == id: return
		if not ui.conversation.choices.is_empty(): break
		_key(KEY_ENTER)
	_check(ui.conversation.node_id == id, "Reached " + id + " from " + ui.conversation.node_id)


func _response(ui: Node, direction: String, color: String, circuit: String) -> void:
	await _choose(ui, "communications")
	await _choose(ui, "response")
	_check(ui.conversation.choices.size() == 5, "Four independent direction choices and cancel")
	await _choose(ui, "select_direction_" + direction)
	_key(KEY_ENTER)
	await _choose(ui, "select_color_" + color)
	_key(KEY_ENTER)
	await _choose(ui, "select_circuit_" + circuit)
	_key(KEY_ENTER)
	_check(ui.text_label.text.contains(direction) and ui.text_label.text.contains(color), "Review contains constructed response")
	await _choose(ui, "transmit")
	_check(ui.speaker_label.text == "PLAYER", "Player supplies response")
	_key(KEY_ENTER)
	_check(ui.speaker_label.text == "MARA" and ui.text_label.text.contains(color), "Mara repeats without judging")
	_key(KEY_ENTER)
	_check(ui.text_label.text == "Elias, response is " + direction + ", " + color + ", circuit " + circuit + ".", "Explicit witnessed relay")
	_key(KEY_ENTER)
	_check(ui.speaker_label.text == "ELIAS" and ui.conversation.current_actor.npc_id == &"elias", "Elias's own participant acknowledges")
	_key(KEY_ENTER)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	for inspect_clues: bool in [true, false]:
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
		var security: FacilitySecurity = level.get_node("SecurityAccess/State")
		var mara: ConversationParticipant = level.get_node("PuzzleProps/ObservationWindow/Mara")
		var elias: ConversationParticipant = level.get_node("FacilityInvestigation/Elias")
		var ui: Node = player.get_node("DialogueUI")
		var inspector: Node = camera.get_node("Inspection")
		var intercom: Node3D = level.get_node("PuzzleProps/Intercom")
		var counts: Dictionary = {"configure_m4": 0}
		elias.action_resolved.connect(func(id: String) -> void:
			if id == "configure_m4": counts[id] += 1)
		_check(not state.director_authorization_valid and not state.director_secondary_session_active and state.communications_line_connected.is_empty(), "Fresh state resets")
		_check(not mara.request_action("route_line", {"line": "D"}) and not state.begin_secondary() and not state.finalize(), "Power/progression guards")
		var documents: Array[String] = ["RoutingDocument", "PhaseDocument", "LoadDocument"]
		var approaches: Array[Vector3] = [Vector3(23.8, 0.03, -3.0), Vector3(28.1, 0.03, -2.7), Vector3(14.4, 0.03, 14.4)]
		var rows: Array = [["M-1                 C", "M-2                 F", "M-3                 A", "M-4                 D"], ["PHASE 1 = NORTH", "PHASE 2 = EAST", "PHASE 3 = SOUTH", "PHASE 4 = WEST"], ["LOAD 2 = WHITE", "LOAD 4 = BLUE", "LOAD 6 = AMBER", "LOAD 8 = RED"]]
		for i: int in range(3):
			var prop: Node3D = office.get_node(documents[i])
			for row: String in rows[i]: _check(_text(prop).contains(row), "Canonical document " + row)
			_fits(prop, 0.36, 0.46)
			if inspect_clues:
				await _use(prop, approaches[i])
				_check(inspector.inspecting and not state.director_primary_authorized, "Clue inspectable before primary")
				_key(KEY_ESCAPE)
		level.get_node("AuxiliaryPower").activate_power()
		await _use(intercom, Vector3(2.13, 0.03, -1.8))
		_key(KEY_ENTER)
		await _choose(ui, "answer")
		_key(KEY_ENTER)
		await _choose(ui, "trapped")
		_until(ui, "menu")
		await _choose(ui, "surroundings")
		_key(KEY_ENTER)
		await _choose(ui, "inspect")
		_until(ui, "report")
		_check(ui.text_label.text == "C3 - A1 - D4 - B2", "Original Mara window action preserved")
		_until(ui, "menu")
		_key(KEY_ESCAPE)
		ui.open_dialogue(elias, level.get_node("FacilityInvestigation/M2"))
		_until(ui, "menu")
		await _choose(ui, "problem")
		_check(ui.text_label.text.contains("coolant bypass"), "Earlier Elias reminder preserved")
		_key(KEY_ENTER)
		await _choose(ui, "bypass")
		_until(ui, "menu")
		_check(power.coolant_bypass_open, "Earlier Elias physical action preserved")
		_key(KEY_ESCAPE)
		power.restore_main_power()
		security.establish_access()
		await _use(intercom, Vector3(2.13, 0.03, -1.8))
		await _choose(ui, "communications")
		await _choose(ui, "routing")
		await process_frame
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.get_node("Backdrop/Center/Panel").get_global_rect()), "Routing menu fits viewport")
		_check(ui.conversation.choices.size() == 7, "All six equal-weight lines and return")
		await _choose(ui, "line_A")
		_until(ui, "routing")
		_check(not state.link_available() and not state.begin_secondary(), "Wrong line safe and cannot start session")
		await _choose(ui, "line_D")
		_check(not state.participants_connected, "Selecting line alone is not witnessed contact")
		_key(KEY_ESCAPE)
		await _use(intercom, Vector3(2.13, 0.03, -1.8))
		await _choose(ui, "communications")
		await _choose(ui, "routing")
		await _choose(ui, "line_D")
		_key(KEY_ENTER)
		_check(ui.speaker_label.text == "MARA" and ui.conversation.node_id == "call_elias", "Mara calls maintenance")
		_key(KEY_ENTER)
		_check(ui.speaker_label.text == "ELIAS" and ui.conversation.current_actor == elias, "Real Elias answers Mara")
		_key(KEY_ENTER)
		_check(ui.speaker_label.text == "MARA" and ui.conversation.current_actor == mara, "Mara answers Elias")
		_key(KEY_ENTER)
		_check(ui.speaker_label.text == "ELIAS" and state.participants_connected, "Elias action establishes physical M-4 reach")
		_until(ui, "menu")
		_check(not state.begin_secondary(), "Link alone cannot replace primary")
		_key(KEY_ESCAPE)
		# Prior director_office suite covers physical cabinet/module primary acceptance.
		state.accept_primary()
		await _use(terminal.get_node("Control"), Vector3(27.25, 0.03, 11.45))
		_check(state.director_secondary_session_active and not state.director_secondary_ready, "Deliberate terminal button starts challenge")
		await _use(terminal, Vector3(27.05, 0.03, 11.45))
		_check(inspector.inspecting and terminal.readout.text.contains("PHASE 2\nLOAD 6\nCIRCUIT B"), "Exact inspectable challenge")
		_key(KEY_ESCAPE)
		await _use(intercom, Vector3(2.13, 0.03, -1.8))
		await _response(ui, "NORTH", "WHITE", "A")
		_check(ui.text_label.text == "No. M-4 rejected that combination. I can try another setting." and not state.director_secondary_ready, "Uniform failure without component hints")
		_check(state.link_available(), "Wrong response preserves link")
		# Other partial combinations receive exactly the same station result.
		for response: Array in [["NORTH", "AMBER", "B"], ["EAST", "WHITE", "B"], ["EAST", "AMBER", "A"]]:
			_check(not state.configure_m4(response[0], response[1], response[2]), "Every response component must match")
		_key(KEY_ENTER)
		await _response(ui, "EAST", "AMBER", "B")
		_check(state.director_secondary_ready and not state.director_authorization_valid and counts["configure_m4"] == 2, "Elias action sets readiness, never full authorization")
		_check(office.get_node("M4Designation/ReadyLamp").visible, "Remote readiness indicator")
		_key(KEY_ESCAPE)
		player.position = Vector3(16, 0.03, 0)
		await physics_frame
		_check(not state.director_authorization_valid and terminal.readout.text.contains("FINALIZE AUTHORIZATION"), "Leaving ready state requires physical return")
		_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(31, 0.03, -12.3)), Vector3(1.5, 0, 0)), "M-4 remains inaccessible")
		await _use(terminal.get_node("Control"), Vector3(27.25, 0.03, 11.45))
		_check(state.director_authorization_valid and terminal.readout.text.contains("COMPLETE"), "Terminal finalizes")
		var screen_bounds: AABB = terminal.readout.get_aabb()
		_check(screen_bounds.size.x < 0.67 and screen_bounds.size.y < 0.45, "Terminal report fits CRT")
		var status: String = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text
		for text: String in ["MAIN POWER             ONLINE", "SECURITY CLEARANCE     VALID", "DIRECTOR AUTHORIZATION VALID", "MANUAL RELEASE ENABLED"]: _check(status.contains(text), "Hub status " + text)
		var label: Label3D = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text")
		_check(label.get_aabb().size.x < 2.55 and label.get_aabb().size.y < 1.35, "Completed Hub report fits backing")
		_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(18.5, 0.03, -2.3)), Vector3(0, 0, -2)), "Egress remains physically sealed")
		await _use(intercom, Vector3(2.13, 0.03, -1.8))
		await _choose(ui, "recall")
		_key(KEY_ENTER)
		_check(ui.text_label.text == "C3 - A1 - D4 - B2", "Earlier recall remains after completion")
		_key(KEY_ESCAPE)
		level.queue_free()
		await process_frame
		await create_timer(0.2).timeout
	print("Director secondary smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
