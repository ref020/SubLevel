extends SceneTree
## godot --headless --path . --script res://tests/door_drawer_smoke.gd

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _settle() -> void:
	await create_timer(0.18, true, true).timeout
	await physics_frame
	await process_frame


func _run() -> void:
	var level: Node3D = load("res://scenes/levels/door_drawer_test.tscn").instantiate()
	root.add_child(level)
	var player: CharacterBody3D = level.get_node("Player")
	player.set_physics_process(false)
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	await _settle()
	for node_name: String in ["UnlockedDoor", "LockedDoor", "UnlockedDrawer", "LockedDrawer"]:
		var item: Openable = level.get_node(node_name)
		item.animation_duration = 0.1
		var initial: Transform3D = item.body.transform
		var counts: Dictionary = {"opened": 0, "closed": 0, "unlocked": 0, "locked": 0}
		item.opened.connect(func() -> void: counts["opened"] += 1)
		item.closed.connect(func() -> void: counts["closed"] += 1)
		item.unlocked.connect(func() -> void: counts["unlocked"] += 1)
		item.locked.connect(func() -> void: counts["locked"] += 1)
		var is_door: bool = item.get_object_label() == "Door"
		var aim: Vector3 = item.position + (Vector3(0.7, 1.4, 0) if is_door else Vector3(0, 1.05, 0.45))
		player.position = Vector3(aim.x, 0, 2)
		camera.look_at(aim)
		ray.refresh_target()
		_check(ray.current_target == item, node_name + ": camera ray resolves moving body")
		if item.starts_locked:
			_check(item.get_interaction_prompt() == "Locked", node_name + ": locked prompt")
			ray._unhandled_input(press)
			await _settle()
			_check(item.state == Openable.State.CLOSED and item.body.transform.is_equal_approx(initial), node_name + ": lock blocks opening")
			var control: Interactable = level.get_node("DoorUnlock" if is_door else "DrawerUnlock")
			camera.look_at(control.global_position)
			ray._unhandled_input(press)
			_check(not item.is_locked and counts["unlocked"] == 1, node_name + ": test control unlocks through E")
			camera.look_at(aim)
		_check(item.get_interaction_prompt() == "Open " + item.get_object_label(), node_name + ": closed prompt")
		if is_door:
			_check(player.test_move(player.transform, Vector3(0, 0, -4)), node_name + ": closed door blocks player capsule")
		for cycle: int in range(3):
			item.interact()
			_check(item.state == Openable.State.OPENING, node_name + ": opening state")
			_check(not item.lock(), node_name + ": cannot lock while moving")
			for spam: int in range(20):
				item.interact()
			await create_timer(0.04, true, true).timeout
			_check(not item.body.transform.is_equal_approx(initial), node_name + ": intermediate motion")
			_check(item.state == Openable.State.OPENING, node_name + ": animation does not snap")
			await _settle()
			_check(item.state == Openable.State.OPEN, node_name + ": opens")
			_check(item.get_interaction_prompt() == "Close " + item.get_object_label(), node_name + ": open prompt")
			_check(not item.lock() and not item.is_locked, node_name + ": cannot lock open")
			if is_door:
				_check(item.body.position.is_equal_approx(initial.origin), node_name + ": hinge stays fixed")
				_check(is_equal_approx(item.body.rotation.y, deg_to_rad(item.open_angle)), node_name + ": configured angle")
				_check(not player.test_move(player.transform, Vector3(0, 0, -4)), node_name + ": open doorway admits player capsule")
			else:
				_check(item.body.position.is_equal_approx(initial.origin + item.slide_direction.normalized() * item.travel_distance), node_name + ": configured local travel")
			item.interact()
			for spam: int in range(20):
				item.interact()
			await _settle()
			_check(item.state == Openable.State.CLOSED and item.body.transform.is_equal_approx(initial), node_name + ": closes without drift")
		_check(counts["opened"] == 3 and counts["closed"] == 3, node_name + ": signals fire once per completed motion")
		_check(item.lock() and item.is_locked, node_name + ": closed object relocks")
		item.lock()
		_check(counts["locked"] == 1, node_name + ": lock signal is idempotent")
		item.interact()
		_check(item.state == Openable.State.CLOSED, node_name + ": relock blocks opening")
		item.unlock()
		var unlock_count: int = counts["unlocked"]
		item.unlock()
		_check(counts["unlocked"] == unlock_count, node_name + ": unlock is idempotent")
	# Rotated/translated instances must use root-local drawer motion.
	var drawer: Openable = level.get_node("UnlockedDrawer")
	drawer.rotation.y = PI / 2.0
	var origin: Vector3 = drawer.body.global_position
	drawer.interact()
	await _settle()
	_check(drawer.body.global_position.is_equal_approx(origin + drawer.global_basis * Vector3(0, 0, drawer.travel_distance)), "Rotated drawer slides along local +Z")
	print("Door/drawer smoke test: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)
