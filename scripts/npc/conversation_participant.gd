class_name ConversationParticipant
extends Node

signal action_resolved(action_id: String)

@export var npc_id: StringName
@export var display_name: String
@export var dialogue: DialogueData
var flags: Dictionary = {}
var completed_choices: Dictionary = {}
var contacted: bool = false


func meets_conditions(data: Dictionary) -> bool:
	for flag: String in data.get("requires", []):
		if not flags.get(flag, false):
			return false
	for flag: String in data.get("excludes", []):
		if flags.get(flag, false):
			return false
	return true


func set_flags(names: Array) -> void:
	for flag: String in names:
		flags[flag] = true


func can_request_action(action_id: String) -> bool:
	return dialogue != null and dialogue.actions.has(action_id) and meets_conditions(dialogue.actions[action_id])


func request_action(action_id: String) -> bool:
	if not can_request_action(action_id):
		return false
	set_flags(dialogue.actions[action_id].get("sets", []))
	action_resolved.emit(action_id)
	return true
