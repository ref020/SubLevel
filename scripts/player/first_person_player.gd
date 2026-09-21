extends CharacterBody3D
## Reusable player. The root origin is at the player's feet.

@export_range(0.1, 20.0, 0.1) var movement_speed: float = 4.0
## Degrees of rotation per pixel of mouse movement.
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity: float = 0.1
@export_range(0.1, 15.0, 0.1) var jump_velocity: float = 4.5

@onready var head: Node3D = $Head


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.screen_relative.x * mouse_sensitivity))
		head.rotation.x = clampf(
			head.rotation.x - deg_to_rad(event.screen_relative.y * mouse_sensitivity),
			deg_to_rad(-89.0), deg_to_rad(89.0)
		)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var movement_input: Vector2 = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		movement_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	# Only the body yaws, so looking up/down never changes walking direction.
	var direction: Vector3 = global_transform.basis * Vector3(movement_input.x, 0.0, movement_input.y)
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	move_and_slide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
