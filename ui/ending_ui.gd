extends CanvasLayer
## A one-shot ending retains modal ownership until the scene is restarted.

@export var input_session: PlayerModalInput
var requested: bool = false
var presented: bool = false
var presentation_count: int = 0


func _ready() -> void:
	hide()
	set_process(false)


func present() -> void:
	if requested or presented: return
	requested = true
	set_process(true)


func _process(_delta: float) -> void:
	if not requested or presented or not input_session.acquire(self): return
	presented = true
	presentation_count += 1
	set_process(false)
	show()
	$Fade.color.a = 0.0
	$Fade/Text.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property($Fade, "color:a", 1.0, 1.2)
	tween.tween_property($Fade/Text, "modulate:a", 1.0, 0.8)


func _input(event: InputEvent) -> void:
	if presented and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if presented and is_instance_valid(input_session): input_session.release(self, false)
