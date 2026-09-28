extends RequiredItemInteractable
## One captive fastener and a hinged cover; the shell blocks access from behind.

signal opened
var is_open: bool = false
var opening: bool = false


func interact() -> void:
	if is_open or opening or not check_requirement():
		return
	opening = true
	var tween: Tween = create_tween()
	tween.tween_property($Hinge, "rotation_degrees:y", -115.0, 0.6)
	tween.tween_callback(_finish)


func _finish() -> void:
	opening = false
	is_open = true
	opened.emit()


func get_interaction_prompt() -> String:
	if is_open: return "Cover Open"
	if opening: return "Opening..."
	return super.get_interaction_prompt()
