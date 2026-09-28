extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
const PHASE_REPORT: String = "A = 90°\nB = 270°\nC = 0°\nD = 180°"
var failures: int = 0
var player: CharacterBody3D
var camera: Camera3D
var ray: RayCast3D
var inspector: Node


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
	_check(ray.current_target == target, "Standing ray/E reaches " + str(target.name))
	_key(KEY_E)


func _text(visual: Node) -> String:
	var result: String = ""
	for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh is TextMesh:
			result += mesh.mesh.text + "\n"
	return result


func _fits(mesh: MeshInstance3D, backing: MeshInstance3D) -> void:
	var bounds: AABB = backing.mesh.get_aabb()
	for corner: int in range(8):
		var point: Vector3 = backing.to_local(mesh.to_global(mesh.mesh.get_aabb().get_endpoint(corner)))
		_check(point.x > bounds.position.x and point.x < bounds.end.x and point.y > bounds.position.y and point.y < bounds.end.y,
			"Lettering stays on backing: " + str(mesh.get_path()))


func _inspect(item: Inspectable, position: Vector3, text: String) -> void:
	await _use(item, position)
	_check(inspector.active_item == item, "Existing inspection opens: " + str(item.name))
	_check(_text(inspector.pivot).contains(text), "Clue survives mesh-copy inspection: " + text)
	_check(not inspector.take_item(), "Environmental clue is not collectible")
	_key(KEY_ESCAPE)


func _choose(ui: Node, id: String) -> void:
	for i: int in ui.conversation.choices.size():
		if ui.conversation.choices[i]["id"] == id:
			_key(KEY_1 + i)
			return
	_check(false, "Missing choice: " + id)


func _mara(level: Node3D) -> void:
	var npc: ConversationParticipant = level.get_node("PuzzleProps/ObservationWindow/Mara")
	var ui: CanvasLayer = player.get_node("DialogueUI")
	# Auxiliary activation is covered by escape_smoke. Here only isolate the new circuit.
	var intercom: Interactable = level.get_node("PuzzleProps/Intercom")
	intercom.set_powered()
	var count: Array[int] = [0]
	npc.action_resolved.connect(func(id: String) -> void:
		if id == "inspect_phase_chart": count[0] += 1)
	intercom.interact()
	# Reaching the repeat menu needs no prior window clue or character knowledge flags.
	_key(KEY_ESCAPE)
	intercom.interact()
	_check(ui.conversation.node_id == "menu", "Reconnect reaches Mara menu")
	await process_frame
	await process_frame
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.get_node("Backdrop/Center/Panel").get_global_rect()), "Extended Mara menu fits normal viewport")
	_choose(ui, "phase")
	_check(not npc.flags.get("phase_chart_inspected", false), "Request precedes action")
	_key(KEY_ESCAPE)
	intercom.interact()
	_choose(ui, "phase")
	_key(KEY_ENTER)
	_check(npc.flags.get("phase_chart_inspected", false) and not npc.flags.get("phase_chart_reported", false), "Investigation resolves before report")
	_key(KEY_ESCAPE)
	intercom.interact()
	_choose(ui, "phase_unreported")
	_check(ui.text_label.text == PHASE_REPORT and npc.flags.get("phase_chart_reported", false), "Interrupted result recoverable and canonical")
	await process_frame
	await process_frame
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(ui.get_node("Backdrop/Center/Panel").get_global_rect()), "Four-line report fits normal viewport")
	_key(KEY_ESCAPE)
	intercom.interact()
	_choose(ui, "phase_recall")
	_key(KEY_ENTER)
	_check(ui.text_label.text == PHASE_REPORT and count[0] == 1, "Recall retains result without repeated investigation")
	_check(not npc.request_action("inspect_phase_chart"), "Action cannot be repeated")
	_key(KEY_ESCAPE)
	_check(player.get_node("ModalInput").active_owner == null and player.is_physics_processing(), "Dialogue restores gameplay")


func _analyze(analyzer: PoweredReadout) -> void:
	await _inspect(analyzer, Vector3(13.71, 0.03, 13.9), "CHANNEL    AMPLITUDE\nA          3\nB          1\nC          4\nD          2")
	_fits(analyzer.display_mesh, analyzer.visual_root.get_node("Screen"))


func _run() -> void:
	root.size = Vector2i(1152, 648)
	for early_documents: bool in [true, false]:
		var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
		root.add_child(level)
		await physics_frame
		await physics_frame
		player = level.get_node("Player")
		camera = player.get_node("Head/Camera3D")
		ray = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		ray.add_exception(player)
		inspector = camera.get_node("Inspection")
		var props: Node3D = level.get_node("SecurityInvestigation")
		var state: FacilityPower = level.get_node("FacilitySystems/State")
		var terminal: PoweredReadout = props.get_node("Terminal")
		var analyzer: PoweredReadout = props.get_node("Analyzer")
		var card: PickupItem = props.get_node("ValeCard")
		var chart: Inspectable = props.get_node("AuthorizationChart")
		var apparatus: Inspectable = props.get_node("PhaseApparatus")
		var record: Inspectable = level.get_node("FacilityInvestigation/ValeRecord")
		var npc: ConversationParticipant = level.get_node("PuzzleProps/ObservationWindow/Mara")
		var inventory: PlayerInventory = player.get_node("Inventory")
		var deck: Node3D = level.get_node("FacilitySystems/CassetteWorkstation")
		_check(not terminal.powered and not analyzer.powered and terminal.display_mesh.mesh.text.is_empty(), "Fresh mains instruments are visibly dead")
		await _use(terminal, Vector3(27.3, 0.03, 5.2))
		_check(not inspector.inspecting, "Unpowered terminal refuses use")
		_check(not npc.can_request_action("inspect_phase_chart") and not npc.request_action("inspect_phase_chart"), "Unpowered Mara opportunity unavailable")
		# Existing pickup and installation, not a replacement recording or analyzer-local tape.
		var tape: PickupItem = level.get_node("PuzzleProps/Cabinet/Contents/Cassette")
		tape.interact()
		_key(KEY_F)
		var owned_tape: InventoryItem = inventory.get_item(&"cassette_tape")
		_check(deck.get_node("TapeSlot").install(owned_tape), "Existing cassette installs")
		var battery: PickupItem = level.get_node("FacilitySystems/BatteryUnit/Battery")
		battery.interact()
		_key(KEY_F)
		_check(deck.get_node("BatteryInput").install(inventory.get_item(&"instrument_battery_12v")), "Existing battery installs")
		await _use(analyzer, Vector3(13.71, 0.03, 13.9))
		_check(deck.powered and not analyzer.powered and not inspector.inspecting, "Battery playback power never enables analyzer")
		_check(owned_tape.recording.channel_amplitudes == {"A": 3, "B": 1, "C": 4, "D": 2}, "Canonical signal retained on same recording")
		if early_documents:
			await _inspect(record, Vector3(14.9, 0.03, 10.8), "EMPLOYEE ID: 0614")
			await _inspect(chart, Vector3(13.1, 0.03, -10.7), "FACILITY DIRECTOR")
			await _inspect(apparatus, Vector3(15.5, 0.03, -10.8), "270°")
		await _use(card, Vector3(15.28, 0.03, 10.8))
		_check(inspector.active_item == card, "Card inspectable before collection")
		_check(not _text(card.visual_root).contains("0614") and not _text(card.visual_root).contains("4321"), "Card supplies identity, not answers")
		_key(KEY_F)
		var owned: InventoryItem = inventory.get_item(&"vale_access_card")
		_check(owned != null and owned.display_name == "Director Access Card", "Vale card collectible with canonical identity")
		_check(owned.description == "An access credential issued to Facility Director Warren Vale. Its permissions have been revoked." and owned.unlocks.is_empty(), "Revoked metadata and no lock compatibility")
		_check(props.get_node_or_null("ValeCard") == null, "Collection removes world card")
		var snapshot: Node3D = owned.visual_scene.instantiate()
		_check(_text(snapshot).contains("ACCESS REVOKED"), "Inventory snapshot retains revoked card face")
		snapshot.free()
		# Main Power's complete legal startup is separately exercised by main_power_smoke.
		state.restore_main_power()
		_check(terminal.powered and analyzer.powered and npc.can_request_action("inspect_phase_chart"), "One authoritative power event boots consumers")
		_check(analyzer.display_mesh.mesh.text == analyzer.standby_text, "Power alone never analyzes")
		var empty_slot: ItemSocket = ItemSocket.new()
		level.add_child(empty_slot)
		var spare: PoweredReadout = load("res://scenes/interactables/cassette_analyzer.tscn").instantiate()
		level.add_child(spare)
		spare.position = Vector3(100, 100, 100)
		spare.configure(state, empty_slot)
		spare.interact()
		_check(spare.powered and not inspector.inspecting and spare.display_mesh.mesh.text == spare.standby_text, "Late-bound mains works, empty tape cannot produce analysis")
		spare.queue_free()
		empty_slot.queue_free()
		await _inspect(terminal, Vector3(27.3, 0.03, 5.2), "CARD STATUS: REVOKED")
		for field: String in ["HALCYON ACCESS CONTROL", "CLEARANCE: NONE", "ENCODER: AVAILABLE", "EMPLOYEE ID", "CLEARANCE CLASS", "VERIFICATION HASH"]:
			_check(terminal.display_mesh.mesh.text.contains(field), "Terminal field: " + field)
		_fits(terminal.display_mesh, terminal.visual_root.get_node("Screen"))
		if early_documents:
			await _analyze(analyzer)
			await _mara(level)
		else:
			await _mara(level)
			await _analyze(analyzer)
			await _inspect(apparatus, Vector3(15.5, 0.03, -10.8), "0°")
			await _inspect(chart, Vector3(13.1, 0.03, -10.7), "FACILITY DIRECTOR")
			await _inspect(record, Vector3(14.9, 0.03, 10.8), "EMPLOYEE ID: 0614")
		_check(_text(record.visual_root).contains("107.6 MHz"), "Prior frequency clue preserved")
		for document: Inspectable in [record, chart]:
			for mesh: MeshInstance3D in document.visual_root.find_children("*", "MeshInstance3D", true, false):
				if mesh.mesh is TextMesh: _fits(mesh, document.visual_root.get_node("Paper"))
		_check(chart.visual_root.get_node("Role3").mesh.text == "FACILITY DIRECTOR" and chart.visual_root.get_node("Class3").mesh.text == "IV", "Director shares chart row with IV")
		var last_x: float = -INF
		for i: int in range(4):
			var label: MeshInstance3D = apparatus.visual_root.get_node("Phase%d" % i)
			_check(label.mesh.text == ["0°", "90°", "180°", "270°"][i] and label.position.x > last_x, "Physical phase ordering")
			last_x = label.position.x
			_fits(label, apparatus.visual_root.get_node("Faceplate"))
		# Reusable modal path and old tape playback survive deliberate analysis.
		deck.play()
		_check(player.get_node("RecordingUI").visible, "Original training recording remains replayable")
		analyzer.interact()
		_check(not inspector.inspecting, "Playback prevents competing inspection modal")
		_key(KEY_ESCAPE)
		_check(deck.get_node("TapeSlot").installed_item == owned_tape, "Analysis does not consume or replace cassette")
		for height: float in [0.03, 0.9]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(26, height, 8)), Vector3(0, 0, 1.5)), "Director remains blocked with card")
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(27.9, height, 6.1)), Vector3(1.4, 0, 0)), "Inner Security remains blocked")
		var status: String = level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text
		for line: String in ["MAIN POWER             ONLINE", "SECURITY CLEARANCE     INVALID", "DIRECTOR AUTHORIZATION REQUIRED", "EXIT SEALED"]:
			_check(status.contains(line), "Milestone endpoint: " + line)
		_check(owned.unlocks.is_empty(), "Investigation cannot rewrite card")
		for obj: Inspectable in [record, chart, apparatus, terminal, analyzer]:
			_check(not _text(obj.visual_root).contains("4321") and not _text(obj.visual_root).contains("3142"), "No joined solution on clue")
		level.queue_free()
		await process_frame
		await process_frame
		await create_timer(0.2).timeout # Allow the audio mixer to retire stopped playback.
	print("Security investigation smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
