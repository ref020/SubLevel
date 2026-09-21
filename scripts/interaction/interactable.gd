class_name Interactable
extends Node3D
## Extend this on an object's root and override interact(). Put collision bodies
## on this node or beneath it. The first collision hit blocks the targeting ray.

@export var interaction_prompt: String = "Interact"


func get_interaction_prompt() -> String:
	return interaction_prompt


func interact() -> void:
	pass
