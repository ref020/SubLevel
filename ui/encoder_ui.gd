extends CanvasLayer
## Enlarged hardware face: digit wheels, four class keys, insert/write/eject keys.

@export var input_session: PlayerModalInput
var active_encoder: CredentialEncoder
var selected_bank: int = 0
var digit_buttons: Array[Button] = []
var bank_buttons: Array[Button] = []
var class_buttons: Array[Button] = []
var status_label: Label
var insert_button: Button
var write_button: Button
var eject_button: Button


func _button(parent: Node, caption: String, size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size = size
	button.add_theme_font_size_override("font_size", 20)
	parent.add_child(button)
	return button


func _ready() -> void:
	add_to_group("encoder_presenter")
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.02, 0.016, 0.85)
	add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	center.add_child(panel)
	var enclosure: StyleBoxFlat = StyleBoxFlat.new()
	enclosure.bg_color = Color(0.32, 0.33, 0.28)
	enclosure.border_color = Color(0.5, 0.51, 0.43)
	enclosure.set_border_width_all(5)
	panel.add_theme_stylebox_override("panel", enclosure)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var title: Label = Label.new()
	title.text = "HALCYON / CREDENTIAL ENCODER"
	title.add_theme_font_size_override("font_size", 23)
	content.add_child(title)
	var crt: PanelContainer = PanelContainer.new()
	var screen: StyleBoxFlat = StyleBoxFlat.new()
	screen.bg_color = Color(0.025, 0.045, 0.03)
	screen.content_margin_left = 15
	screen.content_margin_top = 15
	screen.content_margin_bottom = 15
	crt.add_theme_stylebox_override("panel", screen)
	content.add_child(crt)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(610, 40)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.61))
	status_label.add_theme_font_size_override("font_size", 21)
	crt.add_child(status_label)
	var banks: HBoxContainer = HBoxContainer.new()
	banks.add_theme_constant_override("separation", 40)
	content.add_child(banks)
	for bank: int in range(2):
		var column: VBoxContainer = VBoxContainer.new()
		banks.add_child(column)
		var selector: Button = _button(column, ["EMPLOYEE ID", "VERIFICATION HASH"][bank], Vector2(284, 36))
		selector.pressed.connect(_select_bank.bind(bank))
		bank_buttons.append(selector)
		var wheels: HBoxContainer = HBoxContainer.new()
		column.add_child(wheels)
		for digit: int in range(4):
			var wheel: Button = _button(wheels, "_", Vector2(68, 64))
			wheel.add_theme_font_size_override("font_size", 34)
			wheel.pressed.connect(_step_digit.bind(bank, digit, 1))
			wheel.gui_input.connect(_wheel_input.bind(bank, digit))
			digit_buttons.append(wheel)
	var classes: HBoxContainer = HBoxContainer.new()
	classes.add_theme_constant_override("separation", 16)
	content.add_child(classes)
	var legend: Label = Label.new()
	legend.text = "CLEARANCE CLASS"
	classes.add_child(legend)
	for number: int in range(1, 5):
		var button: Button = _button(classes, ["I", "II", "III", "IV"][number - 1], Vector2(80, 42))
		button.pressed.connect(_select_class.bind(number))
		class_buttons.append(button)
	var keys: HBoxContainer = HBoxContainer.new()
	keys.add_theme_constant_override("separation", 12)
	content.add_child(keys)
	insert_button = _button(keys, "INSERT CARD", Vector2(196, 44))
	insert_button.pressed.connect(_insert)
	write_button = _button(keys, "WRITE", Vector2(196, 44))
	write_button.pressed.connect(_write)
	eject_button = _button(keys, "EJECT CARD", Vector2(196, 44))
	eject_button.pressed.connect(_eject)
	var hints: Label = Label.new()
	hints.text = "Digit wheels: click + / right-click -   |   0-9: type   |   Tab: select bank\nLeft/Right: class   |   Backspace: erase   |   C: clear bank   |   Enter: write"
	hints.add_theme_font_size_override("font_size", 15)
	content.add_child(hints)
	_button(content, "RETURN [ESC]", Vector2(0, 36)).pressed.connect(close_encoder)
	hide()


func open_encoder(encoder: CredentialEncoder) -> void:
	if not encoder.powered or active_encoder != null or not input_session.acquire(self):
		return
	active_encoder = encoder
	encoder.changed.connect(_render)
	encoder.tree_exiting.connect(_target_exiting)
	selected_bank = 0
	show()
	_render()


func close_encoder(restore_mouse: bool = true) -> void:
	if input_session.active_owner != self:
		return
	if is_instance_valid(active_encoder):
		active_encoder.changed.disconnect(_render)
		active_encoder.tree_exiting.disconnect(_target_exiting)
	active_encoder = null
	hide()
	input_session.release(self, restore_mouse)


func _render() -> void:
	if not is_instance_valid(active_encoder):
		return
	status_label.text = active_encoder.status
	var banks: Array[String] = [active_encoder.employee, active_encoder.verification]
	for bank: int in range(2):
		bank_buttons[bank].modulate = Color(0.75, 0.95, 0.7) if bank == selected_bank else Color.WHITE
		for digit: int in range(4):
			var button: Button = digit_buttons[bank * 4 + digit]
			button.text = banks[bank][digit] if digit < banks[bank].length() else "_"
			button.disabled = active_encoder.writing
	for index: int in range(4):
		class_buttons[index].modulate = Color(0.75, 0.95, 0.7) if index + 1 == active_encoder.clearance else Color.WHITE
		class_buttons[index].disabled = active_encoder.writing
	insert_button.disabled = active_encoder.writing or active_encoder.socket.installed_item != null
	write_button.disabled = active_encoder.writing or active_encoder.socket.installed_item == null
	eject_button.disabled = active_encoder.socket.installed_item == null


func _select_bank(bank: int) -> void:
	selected_bank = bank
	_render()


func _select_class(number: int) -> void:
	active_encoder.set_inputs(active_encoder.employee, number, active_encoder.verification)


func _set_bank(value: String) -> void:
	active_encoder.set_inputs(value if selected_bank == 0 else active_encoder.employee, active_encoder.clearance,
		value if selected_bank == 1 else active_encoder.verification)


func _bank() -> String:
	return active_encoder.employee if selected_bank == 0 else active_encoder.verification


func _step_digit(bank: int, index: int, step: int) -> void:
	if active_encoder.writing:
		return
	selected_bank = bank
	var value: String = _bank()
	while value.length() <= index:
		value += "_"
	value[index] = str(posmod(int(value[index]) + step, 10)) if value[index] != "_" else ("0" if step > 0 else "9")
	_set_bank(value)


func _wheel_input(event: InputEvent, bank: int, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_step_digit(bank, index, -1)
		get_viewport().set_input_as_handled()


func _insert() -> void:
	active_encoder.insert_card()


func _write() -> void:
	active_encoder.submit()


func _eject() -> void:
	active_encoder.eject_card()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	if key == KEY_ESCAPE:
		close_encoder()
	elif key == KEY_TAB:
		_select_bank(1 - selected_bank)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_write()
	elif key == KEY_LEFT or key == KEY_RIGHT:
		_select_class(posmod(active_encoder.clearance - 1 + (-1 if key == KEY_LEFT else 1), 4) + 1)
	elif key == KEY_BACKSPACE:
		_set_bank(_bank().left(maxi(0, _bank().length() - 1)))
	elif key == KEY_C:
		_set_bank("")
	elif key >= KEY_0 and key <= KEY_9 and _bank().length() < 4:
		_set_bank(_bank() + str(key - KEY_0))
	elif key >= KEY_KP_0 and key <= KEY_KP_9 and _bank().length() < 4:
		_set_bank(_bank() + str(key - KEY_KP_0))


func _target_exiting() -> void:
	close_encoder(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and visible:
		close_encoder(false)


func _exit_tree() -> void:
	if is_node_ready() and visible:
		close_encoder(false)
