class_name PlayerModalInput
extends Node
## One modal input owner per player. Inspection/keypad provide their own UI.

@export var player: CharacterBody3D
@export var interaction_ray: RayCast3D
@export var interaction_hud: CanvasLayer

var active_owner: Node
var _physics: bool
var _input: bool
var _ray_process: bool
var _ray_input: bool
var _ray_enabled: bool
var _hud_visible: bool
var _mouse_mode: Input.MouseMode


func acquire(requester: Node) -> bool:
	if is_instance_valid(active_owner):
		return false
	active_owner = requester
	_physics = player.is_physics_processing()
	_input = player.is_processing_unhandled_input()
	_ray_process = interaction_ray.is_processing()
	_ray_input = interaction_ray.is_processing_unhandled_input()
	_ray_enabled = interaction_ray.gameplay_enabled
	_hud_visible = interaction_hud.visible
	_mouse_mode = Input.mouse_mode
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	interaction_ray.gameplay_enabled = false
	interaction_ray.refresh_target()
	interaction_ray.set_process(false)
	interaction_ray.set_process_unhandled_input(false)
	interaction_hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return true


func release(requester: Node, restore_mouse: bool = true) -> void:
	if active_owner != requester:
		return
	active_owner = null
	player.set_physics_process(_physics)
	player.set_process_unhandled_input(_input)
	interaction_ray.gameplay_enabled = _ray_enabled
	interaction_ray.set_process(_ray_process)
	interaction_ray.set_process_unhandled_input(_ray_input)
	interaction_hud.visible = _hud_visible
	Input.mouse_mode = _mouse_mode if restore_mouse else Input.MOUSE_MODE_VISIBLE


## Explicit handoff preserves the original gameplay snapshot across related UIs.
func transfer(previous_owner: Node, next_owner: Node) -> bool:
	if active_owner != previous_owner or not is_instance_valid(next_owner):
		return false
	active_owner = next_owner
	return true
