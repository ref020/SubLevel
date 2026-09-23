extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0
var power_events: int = 0
var intercom_events: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var room: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(room)
	await physics_frame
	var player: CharacterBody3D = room.get_node("Player")
	player.set_physics_process(false)
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	ray.add_exception(player)
	var inventory: PlayerInventory = player.get_node("Inventory")
	var inspector: Node = camera.get_node("Inspection")
	var hud: CanvasLayer = player.get_node("InteractionHUD")
	var grate: Openable = room.get_node("PuzzleProps/VentilationGrate/Grate")
	var breaker: Interactable = room.get_node("PuzzleProps/VentilationGrate/Breaker")
	var intercom: Interactable = room.get_node("PuzzleProps/Intercom")
	var power: Node = room.get_node("AuxiliaryPower")
	power.auxiliary_power_activated.connect(func() -> void: power_events += 1)
	intercom.powered_interaction.connect(func() -> void: intercom_events += 1)
	intercom.interact()
	_check(not intercom.powered and hud.get_node("Message").text == "No power.", "Intercom starts without power")
	_check(not power.standby_light.visible, "Standby illumination initially off")
	_check(intercom_events == 0, "Unpowered intercom does not request future dialogue")
	var first: VentFastener = grate.get_node("Fasteners/Screw1")
	first.interact()
	_check(not first.removing and not first.is_removed, "Missing tool blocks removal")
	_check(hud.get_node("Message").text == "I need something that fits this.", "Restrained missing-tool message")
	_check(player.get_node("ModalInput").active_owner == null, "Feedback never owns modal input")
	hud._process(3.0)
	_check(not hud.get_node("Message").visible, "Feedback expires automatically")
	grate.interact()
	_check(grate.is_locked and hud.get_node("Message").text == "The grate is still secured.", "Secured grate feedback")
	player.position = Vector3(1.6, 0.03, 1.9)
	camera.look_at(breaker.global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == grate, "Closed panel physically blocks switch ray")
	breaker.interact()
	_check(not breaker.is_on, "Closed panel also guards direct breaker calls")
	# Obtain the real tool through the production cabinet and existing collection.
	var keypad: Node = room.get_node("PuzzleProps/Cabinet/Keypad")
	keypad.submit_code("4371")
	var door: Openable = room.get_node("PuzzleProps/Cabinet/Door")
	door.interact()
	await create_timer(0.9).timeout
	var tool: PickupItem = room.get_node("PuzzleProps/Cabinet/Contents/Screwdriver")
	inspector.inspect(tool)
	_check(inspector.take_item(), "Actual cabinet tool collected")
	_check(first.has_required_item() and first.get_interaction_prompt() == "Use Screwdriver", "Owned tool updates requirement and prompt")
	# No selected/equipped item is required.
	inventory.select_item(&"")
	var count: int = 0
	for screw: VentFastener in grate.get_node("Fasteners").get_children():
		player.position = Vector3(screw.global_position.x, 0.03, 1.9)
		camera.look_at(screw.global_position)
		await physics_frame
		ray.refresh_target()
		_check(ray.current_target == screw, "Standing camera targets " + screw.name)
		screw.interact()
		screw.interact()
		await create_timer(0.3).timeout
		_check(screw.removing and screw.get_node("Visual").position.z < 0.0, "Screw animates outward")
		_check(absf(screw.get_node("Visual").rotation.z) > 1.0, "Screw visibly rotates")
		grate.interact()
		_check(grate.is_locked, "Grate stays secured during removal")
		await create_timer(0.5).timeout
		count += 1
		_check(screw.is_removed and not screw.visible and screw.get_node("Body/Collision").disabled, "Screw visual and collider removed")
		screw.interact()
		_check(grate.removed_count == count, "Each screw counts exactly once")
		_check(grate.is_locked == (count < 4), "Only four completed removals unlock grate")
	_check(inventory.has_item(&"screwdriver"), "Tool never consumed")
	grate.interact()
	grate.interact()
	await create_timer(0.9).timeout
	_check(grate.state == Openable.State.OPEN and breaker.accessible, "Grate opens and enables switch")
	player.position = Vector3(1.6, 0.03, 1.9)
	camera.look_at(breaker.global_position)
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == breaker, "Standing camera reaches switch through opened cavity")
	breaker.interact()
	breaker.interact()
	await create_timer(0.4).timeout
	_check(breaker.is_on and power.auxiliary_power_active and intercom.powered, "Switch activates local auxiliary circuit")
	_check(power.standby_light.visible and intercom.get_node("ReadyLight").visible, "Both environmental power responses visible")
	_check(power.standby_screen.material_override.emission_enabled, "CRT gains standby glow")
	_check(breaker.get_node("Lever").rotation.x < 0.0, "Breaker reaches physical ON position")
	intercom.interact()
	_check(hud.get_node("Message").text == "The intercom is active.", "Powered intercom feedback")
	_check(intercom_events == 1 and power_events == 1, "Clean powered-interaction and one-shot power signals")
	grate.interact()
	breaker.interact()
	_check(grate.state == Openable.State.OPEN and breaker.is_on, "Repeated interaction cannot reverse progression")
	room.queue_free()
	await process_frame
	print("Vent smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
