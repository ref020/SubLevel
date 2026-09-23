extends CanvasLayer

@export var input_session: PlayerModalInput

var active_keypad: Keypad
var entered_code: String = ""
var _feedback_remaining: float = 0.0

@onready var display: Label = $Backdrop/Center/Panel/Margin/Content/Display
@onready var status: Label = $Backdrop/Center/Panel/Margin/Content/Status
@onready var buttons: GridContainer = $Backdrop/Center/Panel/Margin/Content/Buttons


func _ready() -> void:
	add_to_group("keypad_presenter")
	hide()
	for button: Button in buttons.get_children():
		button.pressed.connect(_on_button.bind(button.text))
	$Backdrop/Center/Panel/Margin/Content/Return.pressed.connect(close_keypad)


func open_keypad(keypad: Keypad) -> void:
	if is_instance_valid(active_keypad) or not input_session.acquire(self):
		return
	active_keypad = keypad
	keypad.tree_exiting.connect(_on_keypad_exiting, CONNECT_ONE_SHOT)
	entered_code = ""
	_feedback_remaining = 0.0
	status.text = "UNLOCKED" if keypad.succeeded else "ENTER CODE"
	status.modulate = Color.WHITE
	_refresh()
	show()


func close_keypad(restore_mouse: bool = true) -> void:
	if not visible:
		return
	if is_instance_valid(active_keypad) and active_keypad.tree_exiting.is_connected(_on_keypad_exiting):
		active_keypad.tree_exiting.disconnect(_on_keypad_exiting)
	active_keypad = null
	entered_code = ""
	_feedback_remaining = 0.0
	hide()
	input_session.release(self, restore_mouse)


func append_digit(digit: String) -> void:
	if not _editable() or digit.length() != 1 or digit < "0" or digit > "9":
		return
	if entered_code.length() < active_keypad.code_length:
		entered_code += digit
	_refresh()


func clear_input() -> void:
	if _editable():
		entered_code = ""
		_refresh()


func backspace() -> void:
	if _editable():
		entered_code = entered_code.left(maxi(entered_code.length() - 1, 0))
		_refresh()


func submit() -> void:
	if not _editable():
		return
	# Set busy before emitting signals: receivers may close/delete UI targets.
	_feedback_remaining = 0.8
	var accepted: bool = active_keypad.submit_code(entered_code)
	if not visible or not is_instance_valid(active_keypad):
		return
	status.text = "ACCESS GRANTED" if accepted else "INVALID CODE"
	status.modulate = Color(0.65, 1, 0.65) if accepted else Color(1, 0.6, 0.45)
	_refresh()


func _process(delta: float) -> void:
	if not visible or _feedback_remaining <= 0.0:
		return
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	if _feedback_remaining == 0.0:
		if not is_instance_valid(active_keypad) or active_keypad.succeeded:
			close_keypad()
		else:
			entered_code = ""
			status.text = "ENTER CODE"
			status.modulate = Color.WHITE
			_refresh()


func _editable() -> bool:
	return visible and is_instance_valid(active_keypad) and not active_keypad.succeeded and _feedback_remaining <= 0.0


func _refresh() -> void:
	display.text = entered_code + "_".repeat(maxi(active_keypad.code_length - entered_code.length(), 0))
	for button: Button in buttons.get_children():
		button.disabled = active_keypad.succeeded or _feedback_remaining > 0.0


func _on_button(label: String) -> void:
	match label:
		"C": clear_input()
		"ENTER": submit()
		_: append_digit(label)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Mouse events reach Controls. The modal owner already suspends world input.
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if not event.pressed or event.echo:
			return
		var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
		if key >= KEY_0 and key <= KEY_9:
			append_digit(str(key - KEY_0))
		elif key >= KEY_KP_0 and key <= KEY_KP_9:
			append_digit(str(key - KEY_KP_0))
		elif key == KEY_BACKSPACE:
			backspace()
		elif key == KEY_ENTER or key == KEY_KP_ENTER:
			submit()
		elif key == KEY_ESCAPE:
			close_keypad()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and visible and is_node_ready():
		close_keypad(false)


func _on_keypad_exiting() -> void:
	close_keypad()


func _exit_tree() -> void:
	if visible and is_node_ready():
		close_keypad(false)
