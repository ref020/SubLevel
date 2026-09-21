extends SceneTree
## Run: godot --headless --path . --script res://tests/interaction_smoke.gd

var failures: int = 0


class HeadlessInteraction:
	extends "res://scripts/interaction/player_interaction.gd"
	# The headless display driver cannot capture a mouse. Simulate only this gate;
	# use the real ray, collision world, input events, objects and HUD connection.
	var gameplay_active: bool = true

	func is_gameplay_input_active() -> bool:
		return gameplay_active


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


func _run() -> void:
	var level: Node3D = load("res://scenes/levels/controller_test.tscn").instantiate()
	root.add_child(level)
	var player: CharacterBody3D = level.get_node("Player")
	player.set_physics_process(false)
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	_check(not ray.is_gameplay_input_active(), "Headless driver should report uncaptured mouse")
	ray.set_script(HeadlessInteraction)
	var hud: CanvasLayer = player.get_node("InteractionHUD")
	var button: Interactable = level.get_node("InteractionTests/Button")
	var switch: Interactable = level.get_node("InteractionTests/Switch")
	var object: Interactable = level.get_node("InteractionTests/TestObject")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	_check(InputMap.has_action("interact") and press.is_action_pressed("interact"), "Physical E must map to interact")
	await physics_frame
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == null, "Spawn must be outside interaction range")
	for target: Interactable in [button, switch, object]:
		player.position = Vector3(target.position.x, 0.0, 3.0)
		camera.look_at(target.global_position)
		ray.refresh_target()
		_check(ray.current_target == target, "Ray must resolve collider child to interactable root")
		_check(hud.get_node("Prompt").visible, "Prompt must be visible on target")
		_check(hud.get_node("Prompt").text == "[E] " + target.get_interaction_prompt(), "Prompt must match target")
		ray._unhandled_input(press)
	_check(button.pressed, "Button must respond to E")
	_check(switch.switched_on, "Switch must respond to E")
	player.position = Vector3(0, 0, 3)
	camera.look_at(switch.global_position)
	ray._unhandled_input(press)
	_check(not switch.switched_on, "Switch must toggle back")
	press.echo = true
	ray._unhandled_input(press)
	_check(not switch.switched_on, "Key repeat must not interact")
	press.echo = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ray.gameplay_active = false
	ray._unhandled_input(press)
	_check(not switch.switched_on and ray.current_target == null, "Released mouse must prevent interaction and clear target")
	_check(not hud.get_node("Prompt").visible, "Released mouse must hide prompt")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray.gameplay_active = true
	ray.refresh_target()
	_check(ray.current_target == switch, "Recapture must restore targeting")
	camera.rotation = Vector3(0, PI, 0)
	ray._unhandled_input(press)
	_check(ray.current_target == null and not switch.switched_on, "Looking away must prevent stale interaction")
	_check(not hud.get_node("Prompt").visible, "Looking away must hide prompt")
	camera.look_at(switch.global_position)
	ray.interaction_range = 0.5
	ray._unhandled_input(press)
	_check(ray.current_target == null and not switch.switched_on, "Configured range must prevent interaction")
	ray.interaction_range = 3.0
	var blocker: StaticBody3D = StaticBody3D.new()
	var collision: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1, 3, 0.2)
	collision.shape = box
	blocker.add_child(collision)
	level.add_child(blocker)
	blocker.position = Vector3(0, 1.5, 2)
	await physics_frame
	await physics_frame
	ray._unhandled_input(press)
	_check(ray.current_target == null and not switch.switched_on, "Solid geometry must block interaction")
	blocker.queue_free()
	await physics_frame
	await physics_frame
	ray.refresh_target()
	_check(ray.current_target == switch, "Removing blocker must restore target")
	switch.queue_free()
	ray._unhandled_input(press)
	_check(ray.current_target == null, "Queued target deletion must be safe")
	await process_frame
	ray.refresh_target()
	_check(ray.current_target == null, "Freed target must be safe")
	print("Interaction smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
