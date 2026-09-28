extends Interactable
## A reusable physical button/lever. Receivers supply behavior through signals.

signal activated


func interact() -> void:
	activated.emit()
