extends RayCast3D
## Mount at the camera origin, facing camera-local -Z.

signal prompt_changed(prompt: String)

@export_range(0.1, 10.0, 0.1) var interaction_range: float = 3.0
@export var player_body: CollisionObject3D

var current_target: Interactable
var _displayed_prompt: String = ""


func _ready() -> void:
	if player_body != null:
		add_exception(player_body)


func _process(_delta: float) -> void:
	# Refresh each displayed frame, including after mouse look and capture changes.
	refresh_target()


func is_gameplay_input_active() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func refresh_target() -> void:
	current_target = null
	if is_gameplay_input_active():
		target_position = Vector3(0.0, 0.0, -interaction_range)
		force_raycast_update()
		if is_colliding():
			var hit_node: Node = get_collider() as Node
			while hit_node != null:
				if hit_node is Interactable:
					if not hit_node.is_queued_for_deletion():
						current_target = hit_node as Interactable
					break
				hit_node = hit_node.get_parent()

	var prompt: String = ""
	if is_instance_valid(current_target):
		prompt = "[E] " + current_target.get_interaction_prompt()
	if prompt != _displayed_prompt:
		_displayed_prompt = prompt
		prompt_changed.emit(prompt)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		# Revalidate on the press; never act on last frame's stale target.
		refresh_target()
		if is_instance_valid(current_target):
			current_target.interact()
			refresh_target()
			get_viewport().set_input_as_handled()
