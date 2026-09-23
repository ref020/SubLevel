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
	event.keycode = code
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


func _run() -> void:
	# Headless windows default to 64x64; give actual GUI clicks a usable viewport.
	root.size = Vector2i(1152, 900)
	for production: bool in [false, true]:
		var level: Node3D = load("res://scenes/levels/observation_room.tscn" if production else "res://scenes/levels/keypad_test.tscn").instantiate()
		root.add_child(level)
		var player: CharacterBody3D = level.get_node("Player")
		var camera: Camera3D = player.get_node("Head/Camera3D")
		var ray: RayCast3D = camera.get_node("InteractionRay")
		ray.set_script(InteractionSmoke.HeadlessInteraction)
		var ui: CanvasLayer = player.get_node("KeypadUI")
		var inspection: Node = camera.get_node("Inspection")
		var keypad: Keypad = level.get_node("PuzzleProps/Cabinet/Keypad" if production else "Keypad")
		var door: Openable = level.get_node("PuzzleProps/Cabinet/Door" if production else "Door")
		var counts: Dictionary = {"success": 0, "failure": 0}
		keypad.correct_code_entered.connect(func() -> void: counts["success"] += 1)
		keypad.incorrect_code_entered.connect(func() -> void: counts["failure"] += 1)
		_check(door.is_locked and not keypad.succeeded, "Fresh scene starts locked")
		player.position = Vector3(-2.9, 0.03, 0.6) if production else Vector3(-0.6, 0.03, 2)
		camera.look_at(keypad.global_position)
		await physics_frame
		await physics_frame
		ray.refresh_target()
		_check(ray.current_target == keypad, "Camera targets keypad")
		var interact: InputEventKey = InputEventKey.new()
		interact.physical_keycode = KEY_E
		interact.pressed = true
		ray._unhandled_input(interact)
		_check(ui.visible, "E opens keypad")
		_check(not player.is_physics_processing() and not player.is_processing_unhandled_input(), "Movement/look disabled")
		_check(not player.get_node("InteractionHUD").visible and not ray.gameplay_enabled, "World HUD/interaction disabled")
		var before: Transform3D = player.transform
		var look: Transform3D = camera.transform
		Input.action_press("move_forward")
		Input.action_press("jump")
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.screen_relative = Vector2(100, 100)
		root.push_input(motion)
		ray._unhandled_input(interact)
		await physics_frame
		await process_frame
		_check(player.transform.is_equal_approx(before) and camera.transform.is_equal_approx(look), "WASD/jump/look do not change player")
		_check(ray.current_target == null, "E cannot hit world behind UI")
		Input.action_release("move_forward")
		Input.action_release("jump")
		_key(KEY_1)
		_key(KEY_KP_2)
		_key(KEY_3)
		_key(KEY_4)
		_key(KEY_5)
		_check(ui.entered_code == "1234", "Numeric/numpad entry and length limit")
		_key(KEY_BACKSPACE)
		_check(ui.entered_code == "123", "Backspace")
		await process_frame
		_click(ui.buttons.get_node("KeyC"))
		_check(ui.entered_code == "", "Mouse C clears")
		_click(ui.buttons.get_node("Key1"))
		_check(ui.entered_code == "1", "Mouse digit enters")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_check(counts["failure"] == 1 and door.is_locked and ui.status.text == "INVALID CODE", "Wrong code feedback and repeated Enter guarded")
		await create_timer(0.9).timeout
		_check(ui.visible and ui.entered_code == "", "Failure clears and permits retry")
		_key(KEY_9)
		_key(KEY_ESCAPE)
		_check(not ui.visible and player.is_physics_processing() and ray.gameplay_enabled, "Escape restores gameplay")
		ui.open_keypad(keypad)
		_check(ui.entered_code == "", "New entry is clean")
		if production:
			inspection.inspect(level.get_node("Furniture/Desk/Photograph"))
			_check(not inspection.inspecting, "Inspection cannot steal ownership")
		for digit: String in ("4371" if production else "2580"):
			_key(KEY_0 + digit.to_int())
		_click(ui.buttons.get_node("KeyENTER"))
		_key(KEY_ENTER)
		_check(counts["success"] == 1 and keypad.succeeded and not door.is_locked, "Success emits once and unlocks receiver")
		_check(ui.status.text == "ACCESS GRANTED", "Success feedback")
		await create_timer(0.9).timeout
		_check(not ui.visible and ray.gameplay_enabled, "Success restores gameplay")
		door.animation_duration = 0.1
		var closed_pose: Transform3D = door.body.transform
		camera.look_at(door.body.to_global(Vector3(0.345, 1.05, 0)) if production else Vector3(0.7, 1.2, 0))
		ray.refresh_target()
		_check(ray.current_target == door, "Unlocked leaf can be targeted separately from keypad")
		ray._unhandled_input(interact)
		await create_timer(0.2).timeout
		_check(door.state == Openable.State.OPEN and not door.body.transform.is_equal_approx(closed_pose), "Connected openable opens physically")
		door.interact()
		await create_timer(0.2).timeout
		_check(door.state == Openable.State.CLOSED and door.body.transform.is_equal_approx(closed_pose), "Openable closes without drift")
		ui.open_keypad(keypad)
		_key(KEY_ENTER)
		_check(ui.status.text == "UNLOCKED" and counts["success"] == 1, "Persistent solved state")
		ui._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		_check(not ui.visible and ray.gameplay_enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Focus loss restores released input")
		if production:
			inspection.inspect(level.get_node("Furniture/Desk/Photograph"))
			ui.open_keypad(keypad)
			_check(inspection.inspecting and not ui.visible, "Keypad cannot steal inspection ownership")
			inspection.finish_inspection()
		ui.open_keypad(keypad)
		keypad.queue_free()
		await process_frame
		await process_frame
		_check(not ui.visible and player.is_physics_processing(), "Deleted keypad restores gameplay")
		level.queue_free()
		await process_frame
		await process_frame
	var standalone: Keypad = Keypad.new()
	standalone.code_length = 6
	standalone.correct_code = "001234"
	_check(not standalone.submit_code("1234") and standalone.submit_code("001234"), "Variable code length and leading zeros")
	standalone.free()
	var detached: Keypad = Keypad.new()
	var receiver: Openable = load("res://scenes/interactables/door.tscn").instantiate()
	detached.correct_code_entered.connect(receiver.unlock)
	receiver.free()
	_check(detached.submit_code("2580"), "Deleted signal receiver is safe")
	detached.free()
	print("Keypad smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
