class_name Conversation
extends Node
## Small graph runner independent of UI and intercom implementation.

signal changed
signal ended
var participant: ConversationParticipant
var node_id: String = ""
var current: Dictionary = {}
var choices: Array[Dictionary] = []


func start(npc: ConversationParticipant) -> bool:
	if is_instance_valid(participant) or not is_instance_valid(npc) or npc.dialogue == null:
		return false
	var entry: String = npc.dialogue.repeat_node if npc.contacted else npc.dialogue.first_node
	if not npc.dialogue.nodes.has(entry):
		return false
	participant = npc
	npc.contacted = true
	_enter(entry)
	return true


func _enter(id: String) -> void:
	if id.is_empty():
		finish()
		return
	if not participant.dialogue.nodes.has(id):
		push_error("Missing dialogue node: " + id)
		finish()
		return
	node_id = id
	current = participant.dialogue.nodes[id]
	var action: String = current.get("action", "")
	if not action.is_empty() and not participant.request_action(action):
		_enter(current.get("action_unavailable", participant.dialogue.repeat_node))
		return
	participant.set_flags(current.get("sets", []))
	choices.clear()
	for choice: Dictionary in current.get("choices", []):
		if not participant.meets_conditions(choice):
			continue
		if choice.get("once", false) and participant.completed_choices.has(choice["id"]):
			continue
		choices.append(choice)
	changed.emit()


func choose(index: int) -> void:
	if not is_instance_valid(participant) or index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if not participant.meets_conditions(choice):
		return
	if choice.get("once", false):
		if participant.completed_choices.has(choice["id"]):
			return
		participant.completed_choices[choice["id"]] = true
	_enter(choice.get("next", ""))


func advance() -> void:
	if is_instance_valid(participant) and choices.is_empty():
		_enter(current.get("next", ""))


func finish() -> void:
	participant = null
	current = {}
	choices.clear()
	node_id = ""
	ended.emit()
