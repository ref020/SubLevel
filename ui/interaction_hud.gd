extends CanvasLayer

@onready var prompt_label: Label = $Prompt
@onready var reticle: ColorRect = $Reticle
var message_remaining: float = 0.0


func _ready() -> void:
	add_to_group("interaction_feedback")


func show_message(message: String) -> void:
	$Message.text = message
	$Message.show()
	message_remaining = 2.5


func show_prompt(prompt: String) -> void:
	prompt_label.text = prompt
	prompt_label.visible = not prompt.is_empty()
	reticle.color = Color(0.55, 0.9, 0.75) if not prompt.is_empty() else Color(1, 1, 1, 0.5)


func _process(delta: float) -> void:
	message_remaining = maxf(0.0, message_remaining - delta)
	$Message.visible = message_remaining > 0.0
	reticle.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
