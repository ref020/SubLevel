extends CanvasLayer

@export var input_session: PlayerModalInput
var active_lock: SymbolLock
var entered: PackedStringArray = []
var symbol_buttons: Array[Button] = []
@onready var display: Label = $Backdrop/Center/Panel/Margin/Content/Display
@onready var status: Label = $Backdrop/Center/Panel/Margin/Content/Status


func _ready() -> void:
	add_to_group("symbol_lock_presenter")
	var font: FontFile = preload("res://assets/fonts/halcyon_symbols.ttf").duplicate()
	font.fallbacks = [ThemeDB.fallback_font]
	display.add_theme_font_override("font", font)
	for index: int in range(SymbolLock.SYMBOLS.size()):
		var button: Button = Button.new()
		button.add_theme_font_override("font", font)
		button.text = SymbolLock.GLYPHS[index] + "\n" + SymbolLock.SYMBOLS[index].to_upper()
		button.custom_minimum_size = Vector2(115, 86)
		button.add_theme_font_size_override("font_size", 23)
		$Backdrop/Center/Panel/Margin/Content/Symbols.add_child(button)
		button.pressed.connect(append_symbol.bind(index))
		symbol_buttons.append(button)
	$Backdrop/Center/Panel/Margin/Content/Controls/Reset.pressed.connect(reset)
	$Backdrop/Center/Panel/Margin/Content/Controls/Submit.pressed.connect(submit)
	$Backdrop/Center/Panel/Margin/Content/Return.pressed.connect(close_lock)
	hide()


func open_lock(lock: SymbolLock) -> void:
	if active_lock != null or not input_session.acquire(self):
		return
	active_lock = lock
	lock.tree_exiting.connect(_target_exiting)
	entered.clear()
	status.text = "UNLOCKED" if lock.succeeded else "ENTER SEQUENCE"
	show()
	_refresh()


func close_lock(restore_mouse: bool = true) -> void:
	if input_session.active_owner != self:
		return
	if is_instance_valid(active_lock):
		active_lock.tree_exiting.disconnect(_target_exiting)
	active_lock = null
	hide()
	input_session.release(self, restore_mouse)


func append_symbol(index: int) -> void:
	if active_lock.succeeded or entered.size() >= 5:
		return
	entered.append(SymbolLock.SYMBOLS[index])
	_refresh()


func reset() -> void:
	entered.clear()
	status.text = "UNLOCKED" if active_lock.succeeded else "ENTER SEQUENCE"
	_refresh()


func submit() -> void:
	status.text = "UNLOCKED" if active_lock.submit(entered) else "SEQUENCE REJECTED"
	if not active_lock.succeeded:
		entered.clear()
	_refresh()


func _refresh() -> void:
	var glyphs: PackedStringArray = []
	for symbol: String in entered:
		glyphs.append(SymbolLock.GLYPHS[SymbolLock.SYMBOLS.find(symbol)])
	while glyphs.size() < 5: glyphs.append("_")
	display.text = "   ".join(glyphs)
	for button: Button in symbol_buttons: button.disabled = active_lock.succeeded


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	if key == KEY_ESCAPE: close_lock()
	elif key == KEY_ENTER or key == KEY_KP_ENTER: submit()
	elif key == KEY_C: reset()
	elif key == KEY_BACKSPACE and not entered.is_empty():
		entered.resize(entered.size() - 1)
		_refresh()
	elif key >= KEY_1 and key <= KEY_5: append_symbol(key - KEY_1)


func _target_exiting() -> void:
	close_lock(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and visible:
		close_lock(false)


func _exit_tree() -> void:
	if is_node_ready() and visible: close_lock(false)
