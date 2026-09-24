extends Node
## Instance wiring, independent of the generic receiver and player.

@export var radio: TunableRadio
@export var participant: ConversationParticipant
@export var radio_presenter: CanvasLayer
@export var dialogue_presenter: CanvasLayer


func _ready() -> void:
	radio.transmission_found.connect(_receive)


func _receive() -> void:
	if radio_presenter.active_radio != radio:
		return
	# Atomic ownership handoff retains the original gameplay/mouse snapshot.
	if dialogue_presenter.open_dialogue(participant, radio, radio_presenter, "RADIO / " + radio.designation):
		radio_presenter.close_radio()
