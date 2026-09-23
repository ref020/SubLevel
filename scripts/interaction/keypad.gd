class_name Keypad
extends Interactable
## Validation only. Connect correct_code_entered to any compatible receiver.

signal correct_code_entered
signal incorrect_code_entered

@export var correct_code: String = "2580"
@export var entry_prompt: String = "Use Keypad"
@export_range(1, 12, 1) var code_length: int = 4

var succeeded: bool = false


func get_interaction_prompt() -> String:
	return "Unlocked" if succeeded else entry_prompt


func interact() -> void:
	get_tree().call_group("keypad_presenter", "open_keypad", self)


func submit_code(code: String) -> bool:
	if succeeded:
		return true
	if code.length() == code_length and code == correct_code and _digits_only(code):
		succeeded = true
		correct_code_entered.emit()
		return true
	incorrect_code_entered.emit()
	return false


func _digits_only(code: String) -> bool:
	for character: String in code:
		if character < "0" or character > "9":
			return false
	return not code.is_empty()
