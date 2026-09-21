class_name Openable
extends Interactable
## Shared state/lock contract. Future item systems compare lock_id and call unlock().
## Instantiate a concrete door/drawer scene; Body is the moving collision body.

signal opened
signal closed
signal unlocked
signal locked

enum State { CLOSED, OPENING, OPEN, CLOSING }

@export var starts_locked: bool = false
@export var lock_id: StringName = &""
@export_range(0.05, 10.0, 0.05) var animation_duration: float = 0.8

var state: State = State.CLOSED
var is_locked: bool = false
var _elapsed: float = 0.0
var _closed_transform: Transform3D
var _open_transform: Transform3D

@onready var body: AnimatableBody3D = $Body


func _ready() -> void:
	is_locked = starts_locked
	_closed_transform = body.transform
	_open_transform = get_open_transform(_closed_transform)
	set_physics_process(false)


func get_open_transform(closed_transform: Transform3D) -> Transform3D:
	return closed_transform


func get_object_label() -> String:
	return "Object"


func get_interaction_prompt() -> String:
	if is_locked:
		return "Locked"
	match state:
		State.OPENING:
			return "Opening..."
		State.CLOSING:
			return "Closing..."
		State.OPEN:
			return "Close " + get_object_label()
	return "Open " + get_object_label()


func interact() -> void:
	if is_locked or state == State.OPENING or state == State.CLOSING:
		return
	state = State.OPENING if state == State.CLOSED else State.CLOSING
	_elapsed = 0.0
	set_physics_process(true)


func unlock() -> void:
	if is_locked:
		is_locked = false
		unlocked.emit()


## Refuse to lock an open or moving object. Caller can close it and retry.
func lock() -> bool:
	if state != State.CLOSED:
		return false
	if not is_locked:
		is_locked = true
		locked.emit()
	return true


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var progress: float = clampf(_elapsed / maxf(animation_duration, 0.05), 0.0, 1.0)
	var weight: float = smoothstep(0.0, 1.0, progress)
	if state == State.CLOSING:
		weight = 1.0 - weight
	body.transform = _closed_transform.interpolate_with(_open_transform, weight)
	if progress >= 1.0:
		var finished_opening: bool = state == State.OPENING
		body.transform = _open_transform if finished_opening else _closed_transform
		state = State.OPEN if finished_opening else State.CLOSED
		set_physics_process(false)
		if finished_opening:
			opened.emit()
		else:
			closed.emit()
