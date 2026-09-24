extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var room: Node3D = load("res://scenes/levels/observation_room.tscn").instantiate()
	root.add_child(room)
	var player: CharacterBody3D = room.get_node("Player")
	player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var facility: Node3D = room.get_node("Architecture/Facility")
	var space: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("CollisionShape3D").shape
	query.exclude = [player.get_rid()]
	# Floor-supported connected cells, joined only by full capsule sweeps. Furniture
	# participates. This detects obstructed portals and paths into blocked rooms.
	var cells: Dictionary = {}
	for x: int in range(76):
		for z: int in range(76):
			var foot: Vector3 = Vector3(4.8 + x * 0.4, 0.03, -14.0 + z * 0.4)
			query.transform = Transform3D(Basis.IDENTITY, foot + Vector3(0, 0.9, 0))
			if not space.intersect_shape(query, 1).is_empty():
				continue
			var floor_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(foot + Vector3(0, 0.1, 0), foot - Vector3(0, 0.2, 0), 1, [player.get_rid()])
			if space.intersect_ray(floor_ray).is_empty():
				continue
			cells[Vector2i(x, z)] = foot
	var seed: Vector2i = Vector2i(1, 39) # (5.2, 0.03, 1.6), just outside Observation.
	_check(cells.has(seed), "Transition corridor has a clear supported starting cell")
	var visited: Dictionary = {seed: 0.0}
	var queue: Array[Vector2i] = [seed]
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + step
			if cells.has(next) and not visited.has(next):
				var from: Vector3 = cells[current]
				var to: Vector3 = cells[next]
				if not player.test_move(Transform3D(Basis.IDENTITY, from), to - from):
					visited[next] = float(visited[current]) + 0.4
					queue.append(next)
	var destinations: Dictionary = {
		"Central Hub": Vector3(14, 0.03, 1.7),
		"Laboratory": Vector3(14, 0.03, -9),
		"Archive": Vector3(14, 0.03, 12),
		"Maintenance": Vector3(26, 0.03, -1),
		"Generator": Vector3(28, 0.03, -10),
		"Security outer": Vector3(26, 0.03, 6)
	}
	for label: String in destinations:
		var shortest: float = INF
		for cell: Vector2i in visited:
			if (cells[cell] as Vector3).distance_to(destinations[label]) < 0.6:
				shortest = minf(shortest, visited[cell])
		_check(is_finite(shortest), "Connected capsule path to " + label)
		_check(shortest / player.movement_speed < 30.0, "Compact travel time to " + label)
		print("Transition to ", label, ": ", snappedf(shortest, 0.1), " m; ", snappedf(shortest / player.movement_speed, 0.1), " s at normal speed")
	# Move the real body through representative routes, then reverse each route.
	var routes: Array[Array] = [
		[Vector3(14, 0.03, 1.7), Vector3(13, 0.03, 1.7), Vector3(13, 0.03, -6.2), Vector3(14, 0.03, -7.2), Vector3(14, 0.03, -9)],
		[Vector3(14, 0.03, 1.7), Vector3(13, 0.03, 1.7), Vector3(13, 0.03, 10), Vector3(14, 0.03, 12)],
		[Vector3(14, 0.03, 1.7), Vector3(18, 0.03, -0.3), Vector3(26, 0.03, -0.3), Vector3(26, 0.03, -7), Vector3(28, 0.03, -7), Vector3(28, 0.03, -10)],
		[Vector3(14, 0.03, 1.7), Vector3(17, 0.03, 1.7), Vector3(18, 0.03, 4.7), Vector3(26, 0.03, 4.7), Vector3(26, 0.03, 6)]
	]
	for route: Array in routes:
		player.position = route[0]
		for direction: int in range(2):
			for target: Vector3 in route:
				var collision: KinematicCollision3D = player.move_and_collide(target - player.position)
				_check(collision == null and player.position.distance_to(target) < 0.01, "Physical traversal and backtracking route to " + str(target))
			route.reverse()
	for region: Rect2 in [Rect2(31.7, -14.1, 2.5, 7.5), Rect2(28.7, 3.9, 4.5, 4.5), Rect2(23.7, 8.9, 5.5, 4.5)]:
		for cell: Vector2i in visited:
			var point: Vector3 = cells[cell]
			_check(not region.has_point(Vector2(point.x, point.z)), "Blocked future space excluded from reachable area")
	# Full-width sweeps at standing and jumping heights catch gaps in each barrier.
	for height: float in [0.03, 0.9]:
		for z: float in [-13.0, -12.0, -11.0, -10.0, -9.0, -8.0, -7.6]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(30.8, height, z)), Vector3(1.5, 0, 0)), "Service grille blocks player")
		for z: float in [4.5, 5.3, 6.1, 7.0, 7.8]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(27.9, height, z)), Vector3(1.4, 0, 0)), "Security controlled threshold sealed")
		for x: float in [25.3, 26.0, 26.7]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(x, height, 8.0)), Vector3(0, 0, 1.5)), "Director threshold sealed")
		for x: float in [17.7, 18.5, 19.5]:
			_check(player.test_move(Transform3D(Basis.IDENTITY, Vector3(x, height, -2.3)), Vector3(0, 0, -2)), "Emergency egress remains sealed")
	# Every available room has a complete shell except its intentional portals.
	var shells: Array[Dictionary] = [
		{"bounds": Rect2(10.5, -12.3, 7, 7), "gaps": {"S": [Vector2(12, 14)]}},
		{"bounds": Rect2(10.5, 8.7, 7, 7), "gaps": {"N": [Vector2(12, 14)]}},
		{"bounds": Rect2(22.5, -4.3, 7, 7), "gaps": {"N": [Vector2(25, 27)], "W": [Vector2(-1.3, 0.7)]}},
		{"bounds": Rect2(22.5, -14.3, 9, 8), "gaps": {"S": [Vector2(25, 27)]}},
		{"bounds": Rect2(22.5, 3.7, 6, 5), "gaps": {"W": [Vector2(3.7, 5.7)]}},
		{"bounds": Rect2(10.5, -3.3, 10, 10), "gaps": {"N": [Vector2(12, 14)], "S": [Vector2(12, 14)], "W": [Vector2(0.8, 2.6)], "E": [Vector2(-1.3, 0.7), Vector2(3.7, 5.7)]}}
	]
	for shell: Dictionary in shells:
		var bounds: Rect2 = shell["bounds"]
		for side: String in ["N", "S", "W", "E"]:
			var horizontal: bool = side == "N" or side == "S"
			var lo: float = bounds.position.x if horizontal else bounds.position.y
			var hi: float = bounds.end.x if horizontal else bounds.end.y
			var along: float = lo + 0.35
			while along < hi - 0.3:
				var portal: bool = false
				for gap: Vector2 in shell["gaps"].get(side, []):
					portal = portal or (along > gap.x - 0.3 and along < gap.y + 0.3)
				if not portal:
					var origin: Vector3
					var motion: Vector3
					match side:
						"N":
							origin = Vector3(along, 1.6, bounds.position.y + 0.25)
							motion = Vector3(0, 0, -0.6)
						"S":
							origin = Vector3(along, 1.6, bounds.end.y - 0.25)
							motion = Vector3(0, 0, 0.6)
						"W":
							origin = Vector3(bounds.position.x + 0.25, 1.6, along)
							motion = Vector3(-0.6, 0, 0)
						"E":
							origin = Vector3(bounds.end.x - 0.25, 1.6, along)
							motion = Vector3(0.6, 0, 0)
					var wall_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + motion, 1, [player.get_rid()])
					_check(not space.intersect_ray(wall_ray).is_empty(), "Wing shell wall present")
				along += 0.5
	var required_signs: Array[String] = ["LABORATORY", "ARCHIVE", "MAINTENANCE", "SECURITY", "EMERGENCY EGRESS", "DIRECTOR'S OFFICE", "GENERATOR"]
	var signs: Array[String] = []
	var nodes: Array[Node] = [facility]
	var reserves: int = 0
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children())
		_check(node.get_script() == null and not node is Interactable, "Graybox contains no new gameplay scripts/interactables")
		if node is Label3D:
			signs.append(node.text)
			_check(node.get_parent().has_node("Plate") and not node.no_depth_test and node.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Sign is mounted on physical plate")
			var plate: MeshInstance3D = node.get_parent().get_node("Plate/Mesh")
			var bounds: AABB = node.get_aabb()
			var plate_bounds: AABB = plate.get_aabb()
			for corner: int in range(8):
				var point: Vector3 = plate.to_local(node.to_global(bounds.get_endpoint(corner)))
				_check(point.x >= plate_bounds.position.x + 0.01 and point.x <= plate_bounds.end.x - 0.01 and point.y >= plate_bounds.position.y + 0.01 and point.y <= plate_bounds.end.y - 0.01, "Sign lettering fits plate with margin: " + str(node.get_parent().name))
		if node is Marker3D:
			reserves += 1
	for text: String in required_signs:
		_check(signs.has(text), "Major facility sign: " + text)
	var panel: String = facility.get_node("CentralHub/StatusPanel/Text").text
	for text: String in ["MAIN POWER             OFF", "SECURITY CLEARANCE     INVALID", "DIRECTOR AUTHORIZATION REQUIRED", "EXIT SEALED"]:
		_check(panel.contains(text), "Static egress status: " + text)
	_check(reserves >= 14, "Future equipment locations reserved without gameplay")
	# Use the player's actual camera at standing height along the corridor,
	# looking toward the mounted sign, rather than an editor-camera viewpoint.
	var camera: Camera3D = player.get_node("Head/Camera3D")
	root.size = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width", 1152), ProjectSettings.get_setting("display/window/size/viewport_height", 648))
	var observation_sign: Label3D = facility.get_node("ObservationTransition/ObservationSign/Text")
	for viewpoint: Vector3 in [Vector3(5.5, 1.63, 2.15), Vector3(6.4, 1.63, 2.15), Vector3(7.0, 1.63, 2.15)]:
		camera.global_position = viewpoint
		camera.look_at(observation_sign.global_position)
		for corner: int in range(8):
			var point: Vector3 = observation_sign.to_global(observation_sign.get_aabb().get_endpoint(corner))
			var sight: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(viewpoint, point, 1, [player.get_rid()])
			_check(space.intersect_ray(sight).is_empty(), "Observation sign unobstructed from standing corridor viewpoint")
			_check(not camera.is_position_behind(point) and root.get_visible_rect().has_point(camera.unproject_position(point)), "Observation sign fits normal player camera when viewed from corridor")
	_check(room.get_node("PuzzleProps/ExitDoor").is_locked and room.get_node("Furniture/Desk/LockedDrawer").is_locked, "Observation locks unchanged")
	_check(not room.get_node("AuxiliaryPower").auxiliary_power_active and room.get_node("Player/Inventory").get_items().is_empty(), "Observation initial inventory/power unchanged")
	_check(not room.get_node("PuzzleProps/ObservationWindow/Mara").contacted, "Mara state unchanged")
	room.queue_free()
	await process_frame
	print("Facility smoke test: %d failure(s); %d connected floor-supported cells." % [failures, visited.size()])
	quit(0 if failures == 0 else 1)
