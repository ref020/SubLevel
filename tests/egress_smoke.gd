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


func _use(target: Node3D, approach: Vector3, point: Vector3 = Vector3.INF) -> void:
	player.position = approach
	player.velocity = Vector3.ZERO
	await physics_frame
	camera.look_at(point if point != Vector3.INF else (target.get_node("Body/Panel").global_position if target is Openable else target.global_position))
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


func _setup(level: Node3D) -> void:
	player = level.get_node("Player")
	camera = player.get_node("Head/Camera3D")
	ray = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	ray.add_exception(player)


func _exercise_ending(level: Node3D, test_missing_tool: bool) -> void:
	var assembly: Node3D = level.get_node("EmergencyEgress")
	var state: FacilityEgress = assembly.get_node("State")
	var door: Openable = assembly.get_node("Door")
	var final_door: Openable = assembly.get_node("SurfaceDoor")
	var cover: Node3D = assembly.get_node("Service/Cover")
	var linkage: Node3D = assembly.get_node("Service/Linkage")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var ui: Node = player.get_node("DialogueUI")
	var ending: Node = player.get_node("EndingUI")
	for entry: Array in [["Primary/Label", 0.35, 0.18], ["FaultText", 1.08, 0.27], ["EvacuationPanel/Readout", 1.44, 0.50], ["SurfaceSign", 1.75, 0.60]]:
		var mesh: TextMesh = assembly.get_node(entry[0]).mesh
		var bounds: AABB = mesh.get_aabb()
		_check(bounds.size.x < entry[1] and bounds.size.y < entry[2], "Mounted text fits backing: " + entry[0])
	_check(state.egress_authorized and door.is_locked and door.state == Openable.State.CLOSED, "Authorization never auto-opens egress")
	_check(level.get_node("Architecture/Facility/CentralHub/StatusPanel/Text").text.contains("MANUAL RELEASE ENABLED"), "Hub interlock feedback")
	for height: float in [0.03, 0.9]:
		for x: float in [17.7, 18.5, 19.5]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(x, height, -2.3)), Vector3(0, 0, -2)), "Sealed egress has no standing/jump gap")
	_check(not state.operate(&"secondary") and not state.operate(&"observation") and not state.operate(&"surface") and not state.cross_final_threshold(), "Premature APIs refused")
	await _use(assembly.get_node("Primary"), Vector3(19.55, 0.03, -1.6))
	_check(state.primary_release_open and not state.secondary_release_open and door.is_locked, "Primary release alone cannot open door")
	_check(_text(assembly).contains("SECONDARY: MECHANICAL FAULT"), "Seized secondary communicated")
	player.position = Vector3(16.8, 0.03, -1.65)
	await physics_frame
	camera.look_at(linkage.global_position)
	ray.refresh_target()
	_check(ray.current_target != linkage and not state.operate(&"secondary"), "Closed plate occludes and guards linkage")
	var fastener: Vector3 = cover.to_global(Vector3(0.47, 0.27, 0.04))
	if test_missing_tool:
		await _use(cover, Vector3(16.8, 0.03, -1.65), fastener)
		_check(not cover.opening and not cover.is_open, "Plate refuses missing screwdriver")
		var tool: InventoryItem = InventoryItem.new()
		tool.item_id = &"screwdriver"
		inventory.add_item(tool) # Isolated branch fixture; full-game suite collects the real tool.
	await _use(cover, Vector3(16.8, 0.03, -1.65), fastener)
	_check(not state.service_plate_open and not state.operate(&"secondary"), "Opening animation cannot expose linkage early")
	await create_timer(0.7).timeout
	_check(state.service_plate_open and cover.is_open and inventory.has_item(&"screwdriver"), "Screwdriver retained, plate open")
	await _use(linkage, Vector3(16.8, 0.03, -1.65))
	_check(state.secondary_release_open and not door.is_locked and door.state == Openable.State.CLOSED, "Secondary releases lock without opening door")
	await _use(door, Vector3(18.8, 0.03, -1.8))
	await create_timer(1.2).timeout
	_check(door.state == Openable.State.OPEN, "Heavy door physically opens")
	player.set_physics_process(false)
	player.position = Vector3(18.8, 0.03, -2.1)
	_check(player.move_and_collide(Vector3(0, 0, -4.5)) == null, "Player walks into vestibule")
	_check(player.move_and_collide(Vector3(0, 0, 4.5)) == null, "Player can return to Hub")
	player.set_physics_process(true)
	await _use(assembly.get_node("EvacuationPanel/Surface"), Vector3(18.65, 0.03, -6.42))
	_check(not state.surface_access_enabled and final_door.is_locked, "Surface refused before releases")
	await _use(assembly.get_node("EvacuationPanel/Observation"), Vector3(18.65, 0.03, -5.38))
	_check(state.observation_cells_released and ui.speaker_label.text == "MARA" and ui.text_label.text.contains("lock just released"), "Mara sector state and participant confirmation")
	_key(KEY_ENTER)
	_check(not ui.visible and not state.operate(&"surface"), "One sector alone cannot enable surface")
	await _use(assembly.get_node("EvacuationPanel/Maintenance"), Vector3(18.65, 0.03, -5.9))
	_check(state.maintenance_sector_released and ui.speaker_label.text == "ELIAS" and ui.text_label.text.contains("Service door"), "Elias sector state and participant confirmation")
	_key(KEY_ENTER)
	_check(_text(assembly.get_node("EvacuationPanel")).contains("SURFACE ACCESS      READY"), "Both releases make Surface READY")
	_check(not state.game_completed, "Sector release is not completion")
	await _use(assembly.get_node("EvacuationPanel/Surface"), Vector3(18.65, 0.03, -6.42))
	_check(state.surface_access_enabled and not state.game_completed and not final_door.is_locked and final_door.state == Openable.State.CLOSED, "Surface unlocks final door without auto-opening/ending")
	# Traverse the incline using the actual controller, not a teleport to the ending.
	player.position = Vector3(18.85, 0.03, -6.7)
	player.rotation = Vector3.ZERO
	player.get_node("Head").rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	# Headless cannot capture the mouse. Exercise real CharacterBody slope/collision
	# movement with the controller's speed/gravity, bypassing only that input gate.
	player.set_physics_process(false)
	for frame: int in range(150):
		player.velocity.x = 0.0
		player.velocity.z = -player.movement_speed
		player.velocity.y = -0.5 if player.is_on_floor() else player.velocity.y - 9.8 / 60.0
		player.move_and_slide()
		await physics_frame
	player.set_physics_process(true)
	_check(player.position.z < -12.5 and player.position.y > 2.1 and not state.game_completed, "Player capsule climbs route and stops at closed final door")
	for height: float in [2.43, 3.3]:
		for x: float in [18.0, 18.8, 19.6]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(x, height, -12.5)), Vector3(0, 0, -1.5)), "Final surface barrier has no capsule bypass")
	await _use(final_door, Vector3(18.8, 2.24, -12.9))
	await create_timer(1.2).timeout
	_check(final_door.state == Openable.State.OPEN and not state.game_completed, "Opening final door alone is not completion")
	player.set_physics_process(false)
	player.position = Vector3(18.85, 2.43, -13.4)
	await physics_frame
	_check(player.move_and_collide(Vector3(0, 0, -1.2)) == null, "Player crosses final threshold physically")
	await physics_frame
	await process_frame
	await create_timer(2.3).timeout
	_check(state.game_completed and ending.presented and ending.presentation_count == 1, "Crossing completes game and presents ending once")
	_check(player.get_node("ModalInput").active_owner == ending and not ray.gameplay_enabled, "Ending owns input")
	ending.present()
	_key(KEY_ESCAPE)
	_check(ending.visible and player.get_node("ModalInput").active_owner == ending, "Ending cannot accidentally resume gameplay")
	_check(not state.cross_final_threshold() and ending.presentation_count == 1, "Completion is idempotent")
	_check(state.observation_cells_released and state.maintenance_sector_released and inventory.has_item(&"screwdriver"), "Sector releases and tool persist")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var level: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	_setup(level)
	var state: FacilityEgress = level.get_node("EmergencyEgress/State")
	var power: FacilityPower = level.get_node("FacilitySystems/State")
	var security: FacilitySecurity = level.get_node("SecurityAccess/State")
	var director: FacilityDirector = level.get_node("DirectorOffice/State")
	_check(not state.egress_authorized and not state.operate(&"primary"), "Initial egress unavailable")
	power.restore_main_power()
	_check(not state.egress_authorized and not state.operate(&"primary"), "Power alone insufficient")
	security.establish_access()
	_check(not state.egress_authorized and not state.operate(&"primary"), "Power plus Security insufficient")
	director.accept_primary()
	director.connect_line("D")
	director.establish_contact()
	director.begin_secondary()
	director.configure_m4("EAST", "AMBER", "B")
	_check(not state.egress_authorized, "Secondary ready still insufficient")
	director.finalize()
	# Independently remove each authoritative prerequisite while the others are valid.
	var offline: FacilityPower = FacilityPower.new()
	state.power = offline
	_check(not state.egress_authorized and not state.operate(&"primary"), "Main Power is independently required")
	state.power = power
	offline.free()
	var invalid_security: FacilitySecurity = FacilitySecurity.new()
	state.security = invalid_security
	_check(not state.egress_authorized and not state.operate(&"primary"), "Security is independently required")
	state.security = security
	invalid_security.free()
	var invalid_director: FacilityDirector = FacilityDirector.new()
	state.director = invalid_director
	_check(not state.egress_authorized and not state.operate(&"primary"), "Director is independently required")
	state.director = director
	invalid_director.free()
	await _exercise_ending(level, true)
	level.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	print("Egress smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)
