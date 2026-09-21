extends SceneTree

const InteractionSmoke = preload("res://tests/interaction_smoke.gd")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/levels/observation_room.tscn", "Observation Room is main scene")
	var room: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(room)
	var player: CharacterBody3D = room.get_node("Player")
	player.set_physics_process(false)
	var camera: Camera3D = player.get_node("Head/Camera3D")
	var ray: RayCast3D = camera.get_node("InteractionRay")
	ray.set_script(InteractionSmoke.HeadlessInteraction)
	var inspection: Node = camera.get_node("Inspection")
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("CollisionShape3D").shape
	query.exclude = [player.get_rid()]
	query.transform = player.get_node("CollisionShape3D").global_transform
	_check(space.intersect_shape(query).is_empty(), "Spawn capsule does not overlap geometry")
	# Connected walkable sample grid, with capsule sweeps along each neighbor edge.
	var cells: Dictionary = {}
	for x: int in range(28):
		for z: int in range(21):
			var point: Vector3 = Vector3(-4.05 + x * 0.3, 0.03, -3.0 + z * 0.3)
			query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0, 0.9, 0))
			if space.intersect_shape(query).is_empty():
				cells[Vector2i(x, z)] = point
	var start: Vector2i = Vector2i(10, 18)
	_check(cells.has(start), "Walkability seed near spawn is clear")
	var visited: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + step
			if cells.has(next) and not visited.has(next):
				var from: Vector3 = cells[current]
				var to: Vector3 = cells[next]
				if not player.test_move(Transform3D(Basis.IDENTITY, from), to - from):
					visited[next] = true
					queue.append(next)
	var approaches: Dictionary = {
		"exit": Vector3(3.5, 0.03, 1.7),
		"desk": Vector3(-1.25, 0.03, -1.2),
		"poster": Vector3(3.55, 0.03, -1.4),
		"cabinet": Vector3(-2.9, 0.03, 0.95),
		"window": Vector3(0, 0.03, -2.7),
		"intercom": Vector3(2.1, 0.03, -2.6),
		"vent": Vector3(1.6, 0.03, 2.7)
	}
	for label: String in approaches:
		var reachable: bool = false
		for cell: Vector2i in visited:
			if (cells[cell] as Vector3).distance_to(approaches[label]) < 0.45:
				reachable = true
				break
		_check(reachable, "Reachable approach: " + label)
	# Sweep a player capsule outward across every wall segment, at standing/jump height.
	# Ignore furnishings here so overlapping a cabinet cannot trigger depenetration
	# instead of testing the room shell. Navigation above includes all furniture.
	var shell_exclusions: Array[RID] = [player.get_rid()]
	var boundary_nodes: Array[Node] = [room]
	while not boundary_nodes.is_empty():
		var node: Node = boundary_nodes.pop_back()
		boundary_nodes.append_array(node.get_children())
		if node is CollisionObject3D:
			var path: String = str(room.get_path_to(node))
			if not (path.begins_with("Architecture/") or path.begins_with("PuzzleProps/ObservationWindow/") or path.begins_with("PuzzleProps/ExitDoor/") or path.begins_with("PuzzleProps/VentilationGrate/")):
				shell_exclusions.append(node.get_rid())
	query.exclude = shell_exclusions
	for height: float in [0.03, 0.9]:
		for x: float in [-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 1.6, 2.0, 3.0, 4.0]:
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, height + 0.9, -2.8))
			query.motion = Vector3(0, 0, -3)
			_check(space.cast_motion(query)[0] < 1.0, "North boundary sealed")
			query.transform.origin.z = 2.7
			query.motion = Vector3(0, 0, 3)
			_check(space.cast_motion(query)[0] < 1.0, "South boundary/vent sealed")
		for z: float in [-3.0, -2.0, -1.0, 0.0, 1.0, 1.7, 2.4, 3.0]:
			query.transform = Transform3D(Basis.IDENTITY, Vector3(-3.7, height + 0.9, z))
			query.motion = Vector3(-3, 0, 0)
			_check(space.cast_motion(query)[0] < 1.0, "West boundary sealed")
			query.transform.origin.x = 3.7
			query.motion = Vector3(3, 0, 0)
			_check(space.cast_motion(query)[0] < 1.0, "East boundary/exit sealed")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	var door: Openable = room.get_node("PuzzleProps/ExitDoor")
	var drawer: Openable = room.get_node("Furniture/Desk/LockedDrawer")
	for item: Openable in [door, drawer]:
		player.position = approaches["exit"] if item == door else approaches["desk"]
		camera.look_at(Vector3(4.5, 1.4, 1.7) if item == door else Vector3(-3.09, 0.62, -1.445))
		ray.refresh_target()
		if ray.current_target != item:
			print("Missed target ", item.name, ": ", ray.get_collider())
		_check(ray.current_target == item, item.name + ": accessible camera target")
		_check(item.is_locked and item.get_interaction_prompt() == "Locked", item.name + ": starts locked")
		ray._unhandled_input(press)
		_check(item.state == Openable.State.CLOSED, item.name + ": interaction cannot open")
	_check(door.lock_id == &"observation_room_exit" and drawer.lock_id == &"observation_desk_drawer", "Lock identifiers preserved")
	for name: String in ["Photograph", "Mug"]:
		var item: Inspectable = room.get_node("Furniture/Desk/" + name)
		player.position = approaches["desk"]
		camera.look_at(item.global_position)
		ray.refresh_target()
		_check(ray.current_target == item, name + ": inspectable within practical reach")
		var before: Transform3D = item.global_transform
		ray._unhandled_input(press)
		_check(inspection.inspecting and inspection.active_item == item, name + ": inspection starts")
		inspection.finish_inspection()
		_check(item.global_transform.is_equal_approx(before) and item.visual_root.visible, name + ": world state restored")
	_check(not room.get_node("Furniture/Desk/Photograph/Visual/BackMarkA").visible, "Test photograph clue is absent")
	_check(is_equal_approx(room.get_node("PuzzleProps/WallClock/MinuteHand").rotation_degrees.z, -222.0), "Clock minute hand is at 37")
	_check(is_equal_approx(room.get_node("PuzzleProps/WallClock/HourHand").rotation_degrees.z, -138.5), "Clock hour hand is at 4:37")
	var interactables: int = 0
	var nodes: Array[Node] = [room]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children())
		if node is Interactable:
			interactables += 1
	_check(interactables == 4, "Only exit, drawer, photograph and mug are interactable")
	print("Observation Room smoke test: %d failure(s); %d connected walkable sample cells." % [failures, visited.size()])
	quit(0 if failures == 0 else 1)
