class_name SymbolLock
extends Interactable
## Validation is independent of clues, cabinet motion, and input presentation.

signal solved
signal rejected
const SYMBOLS: PackedStringArray = ["circle", "triangle", "square", "diamond", "plus"]
const GLYPHS: PackedStringArray = ["○", "△", "□", "◇", "+"]
@export var correct_sequence: PackedStringArray = []
var succeeded: bool = false


func get_interaction_prompt() -> String:
	return "Unlocked" if succeeded else "Use Symbol Lock"


func interact() -> void:
	get_tree().call_group("symbol_lock_presenter", "open_lock", self)


func submit(sequence: PackedStringArray) -> bool:
	if succeeded:
		return true
	if sequence.size() == 5 and sequence == correct_sequence:
		succeeded = true
		solved.emit()
		return true
	rejected.emit()
	return false
