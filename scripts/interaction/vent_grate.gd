extends Openable

var removed_count: int = 0


func _ready() -> void:
	super._ready()
	for screw: Node in $Fasteners.get_children():
		screw.removed.connect(_on_fastener_removed)


func _on_fastener_removed() -> void:
	removed_count = 0
	for screw: Node in $Fasteners.get_children():
		if screw.is_removed:
			removed_count += 1
	if removed_count == 4:
		unlock()


func get_open_transform(closed_transform: Transform3D) -> Transform3D:
	return closed_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-100.0))


func get_interaction_prompt() -> String:
	if is_locked:
		return "Examine Grate"
	if state == State.OPEN:
		return "Grate Open"
	return "Opening..." if state == State.OPENING else "Open Grate"


func interact() -> void:
	if is_locked:
		feedback("The grate is still secured.")
	elif state == State.CLOSED:
		super.interact()
