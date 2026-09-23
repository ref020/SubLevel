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


func _click(button: Button) -> void:
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


func _index(ui: Node, id: String) -> int:
	for index: int in ui.conversation.choices.size():
		if ui.conversation.choices[index]["id"] == id:
			return index
	return -1


func _choose(ui: Node, id: String) -> void:
	var index: int = _index(ui, id)
	_check(index >= 0, "Choice available: " + id)
	if index >= 0:
		_key(KEY_1 + index)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	for production: bool in [false, true]:
		var level: Node3D = load("res://scenes/levels/observation_room.tscn" if production else "res://scenes/levels/dialogue_test.tscn").instantiate()
		root.add_child(level)
		await physics_frame
		var player: CharacterBody3D = level.get_node("Player")
		var camera: Camera3D = player.get_node("Head/Camera3D")
		var ray: RayCast3D = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		ray.add_exception(player)
		var ui: CanvasLayer = player.get_node("DialogueUI")
		var modal: PlayerModalInput = player.get_node("ModalInput")
		var inventory_ui: CanvasLayer = player.get_node("InventoryUI")
		var keypad_ui: CanvasLayer = player.get_node("KeypadUI")
		var inspector: Node = camera.get_node("Inspection")
		var intercom: Interactable = level.get_node("PuzzleProps/Intercom" if production else "Intercom")
		var npc: ConversationParticipant = level.get_node("PuzzleProps/ObservationWindow/Mara" if production else "Mara")
		var counts: Dictionary = {"action": 0}
		npc.action_resolved.connect(func(_id: String) -> void: counts["action"] += 1)
		_check(npc.npc_id == &"mara" and npc.flags.is_empty() and not npc.contacted, "Mara starts with fresh independent session state")
		_check(not npc.request_action("inspect_window") and not npc.request_action("unknown"), "Unavailable actions refused")
		if production:
			intercom.interact()
			_check(not ui.visible and not npc.contacted, "Unpowered intercom cannot start first contact")
			level.get_node("AuxiliaryPower").activate_power()
		inventory_ui.open_inventory()
		intercom.interact()
		_check(not ui.visible and not npc.contacted, "Dialogue cannot steal inventory ownership or mark contact")
		inventory_ui.close_inventory()
		player.position = Vector3(2.13, 0.03, -1.8) if production else Vector3(0, 0.03, 2.0)
		camera.look_at(intercom.global_position)
		await physics_frame
		ray.refresh_target()
		_check(ray.current_target == intercom, "Camera targets intercom")
		var mouse_before: Input.MouseMode = Input.mouse_mode
		_key(KEY_E)
		_check(ui.visible and modal.active_owner == ui and ui.conversation.node_id == "first", "E opens first contact and acquires modal")
		_check(ui.speaker_label.text == "MARA" and ui.text_label.text == "Hello?", "Speaker and NPC line displayed")
		var before: Transform3D = player.transform
		var look: Transform3D = camera.transform
		Input.action_press("move_forward")
		Input.action_press("jump")
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.screen_relative = Vector2(100, 100)
		root.push_input(motion)
		_key(KEY_E)
		_key(KEY_TAB)
		inventory_ui.open_inventory()
		var photo: Inspectable = load("res://scenes/interactables/photograph.tscn").instantiate()
		level.add_child(photo)
		inspector.inspect(photo)
		var keypad: Keypad = load("res://scenes/interactables/keypad.tscn").instantiate()
		level.add_child(keypad)
		keypad_ui.open_keypad(keypad)
		await physics_frame
		_check(player.transform.is_equal_approx(before) and camera.transform.is_equal_approx(look), "Movement/jump/look suppressed")
		_check(not ray.gameplay_enabled and ray.current_target == null and not player.get_node("InteractionHUD").visible, "World targeting and HUD suppressed")
		_check(not inventory_ui.visible and not keypad_ui.visible and not inspector.inspecting and modal.active_owner == ui, "All competing modals refused")
		Input.action_release("move_forward")
		Input.action_release("jump")
		_key(KEY_ENTER)
		_check(ui.conversation.choices.size() == 2, "First-contact choices displayed")
		# Real GUI routing exercises a branching choice.
		await process_frame
		await process_frame
		_click(ui.buttons.get_child(0))
		_check(npc.flags.get("has_introduced_herself", false) and ui.conversation.node_id == "introduction", "Mouse choice introduces Mara")
		_key(KEY_ENTER)
		_check(_index(ui, "inspect") == -1, "Window direction hidden before context")
		_choose(ui, "location")
		_key(KEY_ENTER)
		_check(ui.text_label.text.contains("different rooms"), "Location branch establishes separation")
		_key(KEY_ENTER)
		_choose(ui, "trapped")
		# An interrupted player statement must remain available until heard.
		_key(KEY_ESCAPE)
		_check(not ui.visible and modal.active_owner == null and player.is_physics_processing(), "Escape restores gameplay")
		_check(Input.mouse_mode == mouse_before, "Escape restores the previous mouse mode")
		intercom.interact()
		_check(ui.conversation.node_id == "menu" and _index(ui, "trapped") >= 0, "Repeat menu and unfinished topic recover after interruption")
		_choose(ui, "trapped")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_check(npc.flags.get("knows_player_is_trapped", false), "Mara remembers player is trapped")
		_choose(ui, "surroundings")
		_key(KEY_ENTER)
		_check(_index(ui, "inspect") >= 0 and not npc.flags.get("window_inspected", false), "Context enables instruction without performing it")
		await process_frame
		await process_frame
		var panel: Control = ui.get_node("Backdrop/Center/Panel")
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.get_global_rect()), "Full menu fits normal 1152x648 viewport")
		_choose(ui, "inspect")
		_check(ui.speaker_label.text == "PLAYER", "Instruction is voiced by player")
		_key(KEY_ENTER)
		_check(ui.conversation.node_id == "waiting" and counts["action"] == 0, "Mara responds before resolving action")
		_key(KEY_ENTER)
		_check(ui.conversation.node_id == "discovery" and npc.flags.get("window_inspected", false), "NPC resolves window action")
		_check(not npc.flags.get("window_code_reported", false), "Inspection and report are distinct stages")
		_key(KEY_ESCAPE)
		intercom.interact()
		_check(_index(ui, "inspect") == -1 and _index(ui, "unreported") >= 0, "Interrupted discovery recovers report without repeating action")
		_choose(ui, "unreported")
		_check(ui.text_label.text == "C3 - A1 - D4 - B2" and npc.flags.get("window_code_reported", false), "Exact canonical report and persistent flag")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_choose(ui, "recall")
		_key(KEY_ENTER)
		_check(ui.text_label.text == "C3 - A1 - D4 - B2" and counts["action"] == 1, "Recall preserves code without repeating action")
		_check(not npc.request_action("inspect_window"), "Completed action refused")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_choose(ui, "else")
		_key(KEY_ENTER)
		_check(_index(ui, "else") == -1, "One-time topic is remembered")
		_choose(ui, "goodbye")
		_key(KEY_ENTER)
		_check(not ui.visible and modal.active_owner == null, "Goodbye ends conversation")
		# Bidirectional modal exclusion and focus/deletion cleanup.
		keypad_ui.open_keypad(keypad)
		_check(not ui.open_dialogue(npc, intercom), "Keypad blocks dialogue")
		keypad_ui.close_keypad()
		inspector.inspect(photo)
		_check(not ui.open_dialogue(npc, intercom), "Inspection blocks dialogue")
		inspector.finish_inspection()
		intercom.interact()
		await process_frame
		await process_frame
		_click(ui.get_node("Backdrop/Center/Panel/Margin/Content/End"))
		_check(not ui.visible and modal.active_owner == null, "Mouse End button closes dialogue")
		intercom.interact()
		ui._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(not ui.visible and modal.active_owner == null and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Focus loss closes and releases mouse")
		intercom.interact()
		intercom.queue_free()
		await process_frame
		await process_frame
		_check(not ui.visible and modal.active_owner == null, "Deleting source cleans modal")
		ui.open_dialogue(npc)
		npc.queue_free()
		await process_frame
		await process_frame
		_check(not ui.visible and modal.active_owner == null, "Deleting NPC cleans modal")
		var replacement: ConversationParticipant = load("res://scenes/npc/mara.tscn").instantiate()
		level.add_child(replacement)
		ui.open_dialogue(replacement)
		_check(ui.conversation.node_id == "first", "Fresh NPC instance resets state")
		ui.close_dialogue()
		ui.open_dialogue(replacement)
		_check(ui.conversation.node_id == "menu" and _index(ui, "name") >= 0, "Aborted greeting still allows introduction from repeat menu")
		_choose(ui, "name")
		_check(replacement.flags.get("has_introduced_herself", false), "Introduction survives early greeting cancellation")
		level.queue_free()
		await process_frame
		await process_frame
	print("Dialogue smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
