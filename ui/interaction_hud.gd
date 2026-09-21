extends CanvasLayer

@onready var prompt_label: Label = $Prompt
@onready var reticle: ColorRect = $Reticle


func show_prompt(prompt: String) -> void:
	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()
	reticle.color = Color(0.55, 0.9, 0.75) if not prompt.is_empty() else Color(1, 1, 1, 0.5)


func _process(_delta: float) -> void:
	reticle.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
