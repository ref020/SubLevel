extends Node
## Scene wiring: neither the device nor the presenter owns NPC content.

@export var intercom: Interactable
@export var participant: ConversationParticipant
@export var presenter: Node


func _ready() -> void:
	intercom.powered_interaction.connect(_request)


func _request() -> void:
	presenter.open_dialogue(participant, intercom)
