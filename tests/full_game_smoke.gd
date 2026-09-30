extends "res://tests/egress_smoke.gd"
## One production scene, no injected inventory or direct macro completion flags.
## Public interaction APIs/real pickup paths; known approach positions skip travel.


func _choice(ui: Node, id: String) -> void:
	for index: int in ui.conversation.choices.size():
		if ui.conversation.choices[index]["id"] == id:
			ui.conversation.choose(index)
			return
	_check(false, "Progression choice available: " + id)


func _until(ui: Node, id: String) -> void:
	for step: int in range(24):
		if (ui.conversation.node_id == id or ui.conversation.node_id.ends_with(":" + id)): return
		if not ui.conversation.choices.is_empty(): break
		ui.conversation.advance()
	_check((ui.conversation.node_id == id or ui.conversation.node_id.ends_with(":" + id)), "Conversation reached " + id)


func _take(item: Node3D, approach: Vector3) -> void:
	await _use(item, approach)
	_check(camera.get_node("Inspection").active_item == item, "Real inspection before collection " + str(item.name))
	_key(KEY_F)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	_setup(level)
	var inventory: PlayerInventory = player.get_node("Inventory")
	var ui: Node = player.get_node("DialogueUI")
	var cabinet: Node3D = level.get_node("PuzzleProps/Cabinet")
	_check(cabinet.get_node("Keypad").submit_code("4371"), "Canonical cabinet code")
	await _use(cabinet.get_node("Door"), Vector3(-2.9, 0.03, 0.7), cabinet.get_node("Door/Body").to_global(Vector3(0.345, 1.05, 0)))
	await create_timer(0.9).timeout
	await _take(cabinet.get_node("Contents/Screwdriver"), Vector3(-2.9, 0.03, 1.0))
	await _take(cabinet.get_node("Contents/Cassette"), Vector3(-2.9, 0.03, 1.0))
	var grate: Node3D = level.get_node("PuzzleProps/VentilationGrate/Grate")
	var breaker: Node3D = level.get_node("PuzzleProps/VentilationGrate/Breaker")
	for screw: Node3D in grate.get_node("Fasteners").get_children():
		await _use(screw, Vector3(screw.global_position.x, 0.03, 1.9))
		await create_timer(0.8).timeout
	await _use(grate, Vector3(1.6, 0.03, 1.9), breaker.global_position)
	await create_timer(0.9).timeout
	await _use(breaker, Vector3(1.6, 0.03, 1.9))
	var intercom: Node3D = level.get_node("PuzzleProps/Intercom")
	await _use(intercom, Vector3(2.13, 0.03, -1.8))
	ui.conversation.advance()
	_choice(ui, "answer")
	ui.conversation.advance()
	_choice(ui, "trapped")
	_until(ui, "menu")
	_choice(ui, "surroundings")
	ui.conversation.advance()
	_choice(ui, "inspect")
	_until(ui, "report")
	_check(ui.text_label.text == "C3 - A1 - D4 - B2", "Mara first canonical clue")
	_key(KEY_ESCAPE)
	var drawer: Openable = level.get_node("Furniture/Desk/LockedDrawer")
	_check(drawer.get_node("Body/Combination").submit_code("4778"), "Canonical drawer code")
	await _use(drawer, Vector3(-1.25, 0.03, -1.2), Vector3(-3.09, 0.62, -1.445))
	await create_timer(0.9).timeout
	await _take(drawer.get_node("Body/ExitKey"), Vector3(-2.1, 0.03, -1.05))
	var observation_exit: Openable = level.get_node("PuzzleProps/ExitDoor")
	await _use(observation_exit, Vector3(3.5, 0.03, 1.7), Vector3(4.5, 1.4, 1.7))
	_check(not observation_exit.is_locked, "Owned key unlocks Observation exit")
	observation_exit.interact()
	await create_timer(0.9).timeout
	var radio: TunableRadio = level.get_node("FacilityInvestigation/M2")
	radio.interact()
	for tick: int in range(78): radio.tune(1)
	await create_timer(1.0).timeout
	_check(ui.visible and ui.npc.npc_id == &"elias", "107.3 establishes Elias contact")
	_until(ui, "menu")
	_choice(ui, "bypass")
	_until(ui, "menu")
	_key(KEY_ESCAPE)
	var systems: Node3D = level.get_node("FacilitySystems")
	await _use(systems.get_node("BatteryUnit/Cover"), Vector3(15.6, 0.03, -7.6))
	await create_timer(0.7).timeout
	await _take(systems.get_node("BatteryUnit/Battery"), Vector3(15.6, 0.03, -7.6))
	var deck: Node3D = systems.get_node("CassetteWorkstation")
	await _use(deck.get_node("BatteryInput"), Vector3(15, 0.03, 13.9))
	await _use(deck.get_node("TapeSlot"), Vector3(14.4, 0.03, 13.9))
	await _use(deck.get_node("Play"), Vector3(14.4, 0.03, 13.9))
	_check(player.get_node("RecordingUI").visible, "Battery/cassette playback accessible")
	_key(KEY_ESCAPE)
	var generator: Node3D = systems.get_node("Generator")
	await _use(generator.get_node("Controls/prime"), Vector3(29.7, 0.03, -6.9))
	await create_timer(5.0).timeout
	await _use(generator.get_node("Controls/prime"), Vector3(29.7, 0.03, -6.9))
	await create_timer(1.6).timeout
	for control: String in ["breaker_2", "field", "breaker_4", "breaker_1", "breaker_3"]:
		await _use(generator.get_node("Controls/" + control), Vector3(29.7, 0.03, -6.9))
	_check(systems.get_node("State").main_power_online, "Cooperative Generator restores mains")
	await _use(intercom, Vector3(2.13, 0.03, -1.8))
	_choice(ui, "phase")
	_until(ui, "phase_report")
	_check(ui.text_label.text.contains("C = 0"), "Mara powered phase report remains available")
	_key(KEY_ESCAPE)
	await _take(level.get_node("SecurityInvestigation/ValeCard"), Vector3(15.28, 0.03, 10.8))
	var access: Node3D = level.get_node("SecurityAccess")
	var encoder: CredentialEncoder = access.get_node("Encoder")
	encoder.insert_card()
	encoder.set_inputs("0614", 4, "4321")
	_check(encoder.submit(), "Canonical encoder input accepted")
	await create_timer(1.3).timeout
	_check(encoder.eject_card(), "Restored same card retrieved")
	await _use(access.get_node("InnerDoor"), Vector3(27.4, 0.03, 4.9))
	_check(access.get_node("State").security_clearance_valid, "Reader establishes Security")
	access.get_node("InnerDoor").interact()
	await create_timer(0.9).timeout
	await _use(access.get_node("DirectorDoor"), Vector3(26, 0.03, 7.8))
	await create_timer(0.9).timeout
	var office: Node3D = level.get_node("DirectorOffice")
	var lock: SymbolLock = office.get_node("Cabinet/Door/Body/Lock")
	_check(lock.submit(PackedStringArray(["diamond", "circle", "plus", "triangle", "square"])), "Canonical symbols accepted without clue flags")
	await _use(office.get_node("Cabinet/Door"), Vector3(27.55, 0.03, 11.75))
	await create_timer(0.9).timeout
	await _take(office.get_node("Cabinet/Module"), Vector3(27.55, 0.03, 11.75))
	var terminal: AuthorizationTerminal = office.get_node("Terminal")
	await _use(terminal.socket, Vector3(26.46, 0.03, 11.45))
	await create_timer(1.1).timeout
	_check(office.get_node("State").director_primary_authorized, "Physical token validated")
	await _use(intercom, Vector3(2.13, 0.03, -1.8))
	_choice(ui, "communications")
	_choice(ui, "routing")
	_choice(ui, "line_D")
	_until(ui, "menu")
	_key(KEY_ESCAPE)
	await _use(terminal.get_node("Control"), Vector3(27.25, 0.03, 11.45))
	_check(office.get_node("State").director_secondary_session_active, "Physical terminal challenge starts")
	await _use(intercom, Vector3(2.13, 0.03, -1.8))
	_choice(ui, "communications")
	_choice(ui, "response")
	for pair: Array in [["direction", "EAST"], ["color", "AMBER"], ["circuit", "B"]]:
		_choice(ui, "select_" + pair[0] + "_" + pair[1])
		ui.conversation.advance()
	_choice(ui, "transmit")
	_until(ui, "menu")
	_key(KEY_ESCAPE)
	_check(office.get_node("State").director_secondary_ready, "Mara relay and Elias action ready M-4")
	await _use(terminal.get_node("Control"), Vector3(27.25, 0.03, 11.45))
	_check(office.get_node("State").director_authorization_valid, "Returned terminal finalization")
	await _exercise_ending(level, false)
	_check(inventory.has_item(&"screwdriver"), "Original Observation screwdriver survives whole game")
	level.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	print("Full game smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
