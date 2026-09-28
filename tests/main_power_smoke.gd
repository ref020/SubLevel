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


func _use(target: Node3D, approach: Vector3) -> void:
	player.position = approach
	camera.look_at(target.global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == target, "Physical E target: " + str(target.name))
	_key(KEY_E)


func _choose(ui: Node, id: String) -> void:
	for i: int in ui.conversation.choices.size():
		if ui.conversation.choices[i]["id"] == id:
			_key(KEY_1 + i)
			return
	_check(false, "Missing dialogue choice: " + id)


func _matrix() -> void:
	# Every wrong control at every pre-online stage must trip and recover.
	var stages: Array[int] = [GeneratorStartup.Stage.OFF, GeneratorStartup.Stage.BYPASS_READY,
		GeneratorStartup.Stage.PRESSURIZING, GeneratorStartup.Stage.SETTLING,
		GeneratorStartup.Stage.PRESSURE_STABLE, GeneratorStartup.Stage.BREAKER_2_SET,
		GeneratorStartup.Stage.FIELD_EXCITED, GeneratorStartup.Stage.BREAKER_4_SET, GeneratorStartup.Stage.BREAKER_1_SET]
	var expected: Array[StringName] = [&"", &"prime", &"prime", &"", &"breaker_2", &"field", &"breaker_4", &"breaker_1", &"breaker_3"]
	for index: int in stages.size():
		for command: StringName in [&"prime", &"field", &"breaker_1", &"breaker_2", &"breaker_3", &"breaker_4"]:
			if command == expected[index]:
				continue
			var state: FacilityPower = FacilityPower.new()
			root.add_child(state)
			if index > 0:
				state.open_coolant_bypass()
			var startup: GeneratorStartup = GeneratorStartup.new()
			root.add_child(startup)
			startup.set_process(false)
			startup.configure(state)
			startup.stage = stages[index] as GeneratorStartup.Stage
			startup.pressure = 40.0
			startup.operate(command)
			_check(startup.stage == GeneratorStartup.Stage.TRIPPED and startup.pressure == 0.0 and not state.main_power_online,
				"Invalid control trips: stage %d, %s" % [stages[index], command])
			startup._process(1.1)
			_check(startup.stage == (GeneratorStartup.Stage.BYPASS_READY if index > 0 else GeneratorStartup.Stage.OFF), "Trip auto-resets to correct bypass state")
			_check(state.coolant_bypass_open == (index > 0), "Trip preserves bypass")
			startup.free()
			state.free()
	var state: FacilityPower = FacilityPower.new()
	root.add_child(state)
	state.open_coolant_bypass()
	var pump: GeneratorStartup = GeneratorStartup.new()
	root.add_child(pump)
	pump.set_process(false)
	pump.configure(state)
	pump.operate(&"prime")
	pump._process(2.0)
	pump.operate(&"prime")
	_check(pump.stage == GeneratorStartup.Stage.TRIPPED, "Stopping below operating pressure trips")
	pump._process(1.1)
	pump.operate(&"prime")
	pump._process(6.0)
	_check(pump.stage == GeneratorStartup.Stage.TRIPPED, "Unattended overpressure trips")
	pump.free()
	state.free()


func _run() -> void:
	root.size = Vector2i(1152, 648)
	_matrix()
	var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	player = level.get_node("Player")
	camera = player.get_node("Head/Camera3D")
	ray = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	ray.add_exception(player)
	var systems: Node3D = level.get_node("FacilitySystems")
	var state: FacilityPower = systems.get_node("State")
	var deck: Node3D = systems.get_node("CassetteWorkstation")
	var cover: RequiredItemInteractable = systems.get_node("BatteryUnit/Cover")
	var battery: PickupItem = systems.get_node("BatteryUnit/Battery")
	var generator: Node3D = systems.get_node("Generator")
	var startup: GeneratorStartup = generator.get_node("Startup")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var inspector: Node = camera.get_node("Inspection")
	var recording_ui: CanvasLayer = player.get_node("RecordingUI")
	var dialogue: CanvasLayer = player.get_node("DialogueUI")
	var modal: PlayerModalInput = player.get_node("ModalInput")
	var elias: ConversationParticipant = level.get_node("FacilityInvestigation/Elias")
	var battery_socket: ItemSocket = deck.get_node("BatteryInput")
	var tape_socket: ItemSocket = deck.get_node("TapeSlot")
	var lab_approach: Vector3 = Vector3(15.6, 0.03, -7.6)
	var archive_approach: Vector3 = Vector3(14.4, 0.03, 13.9)
	var generator_approach: Vector3 = Vector3(29.7, 0.03, -6.9)
	_check(not state.main_power_online and not state.coolant_bypass_open and not deck.powered, "Fresh independent facility state")
	_check(not level.get_node("AuxiliaryPower").auxiliary_power_active, "Auxiliary starts separately offline")
	# Inspect camera rays toward the battery from the front and instrument sides.
	for point: Vector3 in [lab_approach, Vector3(15.8, 0.03, -6.8), Vector3(15.8, 0.03, -8.4)]:
		player.position = point
		camera.look_at(battery.global_position)
		await physics_frame
		ray.refresh_target()
		_check(ray.current_target != battery, "Closed instrument prevents battery targeting")
	await _use(cover, lab_approach)
	_check(not cover.opening and not cover.is_open, "No screwdriver: cover stays shut")
	# Existing escape suite covers obtaining the screwdriver and cassette through 4371.
	var tool: PickupItem = level.get_node("PuzzleProps/Cabinet/Contents/Screwdriver")
	tool.interact()
	_key(KEY_F)
	_check(inventory.has_item(&"screwdriver"), "Existing inspection/take tool flow")
	await _use(cover, lab_approach)
	await create_timer(0.7).timeout
	await physics_frame
	_check(cover.is_open and inventory.has_item(&"screwdriver"), "Cover opens without consuming tool")
	await _use(battery, lab_approach)
	_check(inspector.active_item == battery, "Accessible battery inspects")
	_key(KEY_F)
	var owned_battery: InventoryItem = inventory.get_item(&"instrument_battery_12v")
	_check(owned_battery != null, "Battery collected")
	if owned_battery == null:
		quit(1)
		return
	_check(owned_battery.display_name == "12V Instrument Battery" and owned_battery.description == "A heavy rechargeable 12V battery removed from laboratory equipment.", "Exact battery metadata")
	_check(owned_battery.installation_tags.has(&"power_12v"), "Battery carries compatible supply tag")
	await _use(deck.get_node("Play"), archive_approach)
	_check(not recording_ui.visible and not deck.powered, "Unpowered PLAY does nothing")
	await _use(tape_socket, archive_approach)
	_check(tape_socket.installed_item == null, "Missing cassette leaves well empty")
	_check(not battery_socket.install(inventory.get_item(&"screwdriver")), "Socket rejects incompatible item")
	await _use(battery_socket, Vector3(15.0, 0.03, 13.9))
	_check(deck.powered and not state.main_power_online and not inventory.has_item(&"instrument_battery_12v"), "Battery powers deck and leaves carried inventory")
	_check(battery_socket.installed_item == owned_battery and battery_socket.get_node("Installed").get_child_count() == 1, "Installed battery object and physical visual retained")
	var installed_bounds: AABB = inspector._mesh_bounds(battery_socket.get_node("Installed").get_child(0))
	var cradle: MeshInstance3D = battery_socket.get_node("Well")
	_check(installed_bounds.position.y >= cradle.position.y + cradle.get_aabb().end.y - 0.001,
		"Cradle supports rather than encloses the installed battery")
	var tape: PickupItem = level.get_node("PuzzleProps/Cabinet/Contents/Cassette")
	tape.interact()
	_key(KEY_F)
	var owned_tape: InventoryItem = inventory.get_item(&"cassette_tape")
	await _use(tape_socket, archive_approach)
	_check(tape_socket.installed_item == owned_tape and not inventory.has_item(&"cassette_tape") and tape_socket.get_node("Installed").get_child_count() == 1, "Cassette installs visibly and remains owned by socket")
	_check(not recording_ui.visible and not deck.playing, "Insertion does not auto-play")
	await _use(deck.get_node("Play"), archive_approach)
	_check(recording_ui.visible and modal.active_owner == recording_ui and deck.playing, "Physical PLAY starts modal recording")
	_check(not elias.contacted, "Battery / installation / recording allowed before Elias contact")
	var canonical: PackedStringArray = PackedStringArray(["Bypass open.", "Prime until pressure reaches forty.", "Stop priming. Wait for pressure to stabilize.", "Close breaker two.", "Field excitation.", "Close breaker four.", "Bring breaker one online.", "Breaker three last."])
	_check(owned_tape.recording.lines == canonical, "Canonical recording ordering")
	player.get_node("InventoryUI").open_inventory()
	level.get_node("FacilityInvestigation/M2").interact()
	player.get_node("KeypadUI").open_keypad(level.get_node("PuzzleProps/Cabinet/Keypad"))
	inspector.inspect(level.get_node("FacilityInvestigation/CalibrationLog"))
	_check(not dialogue.open_dialogue(elias) and not inspector.inspecting and not player.get_node("KeypadUI").visible, "Playback excludes dialogue, inspection and keypad")
	_check(not player.get_node("InventoryUI").visible and not player.get_node("RadioUI").visible and not player.is_physics_processing() and not ray.gameplay_enabled, "Recording excludes gameplay and other modals")
	_key(KEY_SPACE)
	var current_line: int = recording_ui.line_index
	recording_ui._process(5.0)
	_check(recording_ui.line_index == current_line, "Pause retains line")
	_key(KEY_SPACE)
	for line: String in canonical:
		_check(recording_ui.text_label.text == line, "Timed transcript line: " + line)
		recording_ui._process(4.0)
	_check(not deck.playing, "Tape ends without destroying recording")
	_key(KEY_R)
	_check(recording_ui.line_index == 0 and deck.playing, "Replay rewinds to beginning")
	_key(KEY_ESCAPE)
	_check(modal.active_owner == null and player.is_physics_processing(), "Recording exit restores gameplay")
	# First failed attempt before bypass; then actual radio contact and direction.
	await _use(generator.get_node("Controls/prime"), generator_approach)
	_check(startup.stage == GeneratorStartup.Stage.TRIPPED and startup.pressure == 0.0, "No coolant: priming cannot prepare generator")
	await create_timer(1.1).timeout
	_check(startup.stage == GeneratorStartup.Stage.OFF, "Pre-bypass trip resets")
	var radio: TunableRadio = level.get_node("FacilityInvestigation/M2")
	await _use(radio, Vector3(24.8, 0.03, 0.9))
	for step: int in range(78):
		_key(KEY_RIGHT)
	await create_timer(1.0).timeout
	_check(elias.contacted and dialogue.visible, "Normal radio first contact preserved")
	for line: int in range(7):
		if dialogue.conversation.node_id != "menu":
			_key(KEY_ENTER)
	_choose(dialogue, "bypass")
	_check(not state.coolant_bypass_open, "Acknowledgement precedes physical action")
	_key(KEY_ENTER)
	_check(state.coolant_bypass_open and elias.flags.get("bypass_opened", false), "Elias action updates canonical bypass state")
	_check(generator.get_node("BypassLamp").visible, "Bypass environmental confirmation")
	_check(not elias.request_action("open_coolant_bypass"), "Bypass is one-time physical action")
	_key(KEY_ESCAPE)
	# Boundary remains physical; the valve itself offers no player interaction.
	_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(30.8, 0.03, -10)), Vector3(3, 0, 0)), "Service grille blocks access to bypass")
	player.position = Vector3(30.8, 0.03, -10)
	camera.look_at(systems.get_node("Bypass").global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == null, "No remote interaction through grille")
	# Premature field excitation trips even with the bypass open.
	await _use(generator.get_node("Controls/field"), generator_approach)
	_check(startup.stage == GeneratorStartup.Stage.TRIPPED, "Premature field trips")
	await create_timer(1.1).timeout
	_check(state.coolant_bypass_open and startup.stage == GeneratorStartup.Stage.BYPASS_READY, "Retry retains Elias cooperation")
	await _use(generator.get_node("Controls/prime"), generator_approach)
	await create_timer(5.0).timeout
	_check(startup.pressure >= 38.0 and startup.pressure <= 42.0, "Real-time pump reaches target tolerance")
	_check(absf(generator.get_node("Gauge/Needle").rotation_degrees.z - 120.0) > 100.0, "Analog needle visibly moves")
	await _use(generator.get_node("Controls/prime"), generator_approach)
	_check(startup.stage == GeneratorStartup.Stage.SETTLING, "Stopping at forty requires stabilization")
	await create_timer(1.6).timeout
	_check(startup.stage == GeneratorStartup.Stage.PRESSURE_STABLE and startup.pressure == 40.0, "Pressure stabilizes")
	var notifications: Array[int] = [0]
	state.main_power_changed.connect(func(_value: bool) -> void: notifications[0] += 1)
	var hub_light: Light3D = level.get_node("Architecture/Facility/CentralHub/WestFixtureLight")
	var offline_energy: float = hub_light.light_energy
	for command: String in ["breaker_2", "field", "breaker_4", "breaker_1", "breaker_3"]:
		await _use(generator.get_node("Controls/" + command), generator_approach)
	_check(state.main_power_online and startup.stage == GeneratorStartup.Stage.ONLINE and notifications[0] == 1, "Correct physical procedure restores Main Power once")
	_check(hub_light.light_energy > offline_energy and systems.get_node("HubMainsFixture/Light").visible and systems.get_node("SecurityStandby").visible, "Facility consumers react")
	var status: String = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text
	_check(status.contains("MAIN POWER             ONLINE") and status.contains("SECURITY CLEARANCE     INVALID") and status.contains("DIRECTOR AUTHORIZATION REQUIRED") and status.contains("EXIT SEALED"), "Only Main Power changes at egress")
	_check(not level.get_node("AuxiliaryPower").auxiliary_power_active, "Main Power never solves Observation auxiliary puzzle")
	_check(deck.powered and deck.get_node("MainsLamp").visible and tape_socket.installed_item == owned_tape and battery_socket.installed_item == owned_battery, "Mains preserves installed setup")
	await _use(deck.get_node("Play"), archive_approach)
	_check(recording_ui.visible, "Cassette remains replayable after Main Power")
	_key(KEY_ESCAPE)
	startup.operate(&"field")
	_check(state.main_power_online and notifications[0] == 1, "Online state persists and controls cannot retrip")
	# Independently demonstrate mains-only operation, without installing a battery.
	var spare: Node3D = load("res://scenes/interactables/cassette_workstation.tscn").instantiate()
	level.add_child(spare)
	spare.configure(state, inventory)
	_check(spare.powered and spare.get_node("BatteryInput").installed_item == null, "Mains powers an empty workstation independently of battery")
	recording_ui.open_recording(spare, owned_tape.recording)
	recording_ui._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not recording_ui.visible and modal.active_owner == null and not spare.playing, "Playback focus loss releases modal and transport")
	recording_ui.open_recording(spare, owned_tape.recording)
	spare.queue_free()
	await process_frame
	await process_frame
	_check(not recording_ui.visible and modal.active_owner == null, "Deleting deck closes playback safely")
	level.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	var fresh: FacilityPower = FacilityPower.new()
	_check(not fresh.main_power_online and not fresh.coolant_bypass_open, "New session state resets")
	fresh.free()
	print("Main Power smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
