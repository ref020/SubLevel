class_name Conversation
extends Node
## Small graph runner independent of UI and intercom implementation.

signal changed
signal ended
var participant: ConversationParticipant
var current_actor: ConversationParticipant
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
	current_actor = participant
	var local_id: String = id
	if ":" in id:
		var parts: PackedStringArray = id.split(":", true, 1)
		current_actor = participant if parts[0] == str(participant.npc_id) else participant.conversation_partners.get(parts[0])
		local_id = parts[1]
	if not is_instance_valid(current_actor) or not current_actor.dialogue.nodes.has(local_id):
		push_error("Missing dialogue node: " + id)
		finish()
		return
	node_id = id
	current = current_actor.dialogue.nodes[local_id].duplicate(true)
	current_actor.dialogue_values.merge(current.get("values", {}), true)
	var action: String = current.get("action", "")
	if not action.is_empty() and not current_actor.request_action(action, current.get("parameters", {})):
		_enter(current.get("action_unavailable", participant.dialogue.repeat_node))
		return
	current_actor.set_flags(current.get("sets", []))
	current["text"] = str(current.get("text", "")).format(current_actor.dialogue_values)
	choices.clear()
	for choice: Dictionary in current.get("choices", []):
		if not current_actor.meets_conditions(choice):
			continue
		if choice.get("once", false) and current_actor.completed_choices.has(choice["id"]):
			continue
		choices.append(choice)
	changed.emit()


func choose(index: int) -> void:
	if not is_instance_valid(participant) or index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if not current_actor.meets_conditions(choice):
		return
	if choice.get("once", false):
		if current_actor.completed_choices.has(choice["id"]):
			return
		current_actor.completed_choices[choice["id"]] = true
	_enter(choice.get("next", ""))


func advance() -> void:
	if is_instance_valid(participant) and choices.is_empty():
		_enter(current.get("next", ""))


func finish() -> void:
	participant = null
	current_actor = null
	current = {}
	choices.clear()
	node_id = ""
	ended.emit()
