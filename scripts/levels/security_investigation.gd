extends Node
## Cross-scene wiring belongs to the main level, not to individual instruments.

@export var state: FacilityPower
@export var terminal: PoweredReadout
@export var analyzer: PoweredReadout
@export var tape_slot: ItemSocket
@export var mara: ConversationParticipant


func _ready() -> void:
	terminal.configure(state)
	analyzer.configure(state, tape_slot)
	mara.configure(state)
