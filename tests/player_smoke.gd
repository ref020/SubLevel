extends SceneTree

class TestPlayer extends "res://scripts/player/first_person_player.gd":
	var gameplay_active: bool = true

	func is_movement_input_active() -> bool:
		return gameplay_active

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var shift_bound: bool = false
	for event: InputEvent in InputMap.action_get_events("sprint"):
		if event is InputEventKey:
			shift_bound = shift_bound or event.physical_keycode == KEY_SHIFT
	_check(shift_bound, "Sprint is bound to Shift")
	# Headless cannot capture the mouse: override only the capture predicate.
	var player: TestPlayer = TestPlayer.new()
	var head: Node3D = Node3D.new()
	head.name = "Head"
	player.add_child(head)
	root.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	Input.action_press("move_forward")
	player._physics_process(1.0 / 60.0)
	_check(is_equal_approx(-player.velocity.z, 4.0), "Default walking speed")
	Input.action_press("sprint")
	player._physics_process(1.0 / 60.0)
	_check(is_equal_approx(-player.velocity.z, 6.0), "Held sprint increases speed")
	Input.action_press("move_right")
	player._physics_process(1.0 / 60.0)
	_check(is_equal_approx(Vector2(player.velocity.x, player.velocity.z).length(), 6.0), "Diagonal sprint is normalized")
	Input.action_release("move_right")
	Input.action_release("sprint")
	player._physics_process(1.0 / 60.0)
	_check(is_equal_approx(-player.velocity.z, 4.0), "Release restores walking")
	player.sprint_multiplier = 2.0
	Input.action_press("sprint")
	player._physics_process(1.0 / 60.0)
	_check(is_equal_approx(-player.velocity.z, 8.0), "Sprint multiplier is configurable")
	player.gameplay_active = false
	player._physics_process(1.0 / 60.0)
	_check(player.velocity.x == 0.0 and player.velocity.z == 0.0, "Released capture blocks movement even with sprint held")
	Input.action_release("sprint")
	Input.action_release("move_forward")
	player.queue_free()
	await process_frame
	print("Player smoke failures: ", failures)
	quit(1 if failures else 0)
