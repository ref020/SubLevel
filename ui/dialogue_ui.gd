extends CanvasLayer

@export var input_session: PlayerModalInput
var npc: ConversationParticipant
var source: Node
var _revision: int = 0
var _selected: int = 0

@onready var conversation: Conversation = $Conversation
@onready var speaker_label: Label = $Backdrop/Center/Panel/Margin/Content/Speaker
@onready var text_label: Label = $Backdrop/Center/Panel/Margin/Content/Text
@onready var buttons: VBoxContainer = $Backdrop/Center/Panel/Margin/Content/Choices


func _ready() -> void:
	hide()
	conversation.changed.connect(_render)
	conversation.ended.connect(close_dialogue)
	$Backdrop/Center/Panel/Margin/Content/End.pressed.connect(close_dialogue)


func open_dialogue(participant: ConversationParticipant, device: Node = null) -> bool:
	if not is_instance_valid(participant) or participant.dialogue == null or not input_session.acquire(self):
		return false
	npc = participant
	source = device
	npc.tree_exiting.connect(_target_exiting)
	if is_instance_valid(source):
		source.tree_exiting.connect(_target_exiting)
	show()
	if not conversation.start(npc):
		close_dialogue()
		return false
	return true


func close_dialogue(restore_mouse: bool = true) -> void:
	if input_session.active_owner != self:
		return
	for target: Node in [npc, source]:
		if is_instance_valid(target) and target.tree_exiting.is_connected(_target_exiting):
			target.tree_exiting.disconnect(_target_exiting)
	npc = null
	source = null
	hide()
	input_session.release(self, restore_mouse)
	# finish emits ended; ownership guard makes that callback a no-op.
	if is_instance_valid(conversation.participant):
		conversation.finish()


func _render() -> void:
	_revision += 1
	for child: Node in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	speaker_label.text = str(conversation.current.get("speaker", npc.display_name)).to_upper()
	text_label.text = conversation.current.get("text", "")
	var choices: Array[Dictionary] = conversation.choices
	if choices.is_empty():
		_add_button("Continue", -1)
	else:
		for index: int in choices.size():
			_add_button("%d. %s" % [index + 1, choices[index]["text"]], index)
	_selected = 0
	_focus_selected()


func _add_button(label: String, index: int) -> void:
	var button: Button = Button.new()
	button.text = label
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 18)
	buttons.add_child(button)
	button.pressed.connect(_activate.bind(index, _revision))


func _activate(index: int, revision: int) -> void:
	if not visible or revision != _revision:
		return
	if index < 0:
		conversation.advance()
	else:
		conversation.choose(index)


func _focus_selected() -> void:
	if buttons.get_child_count() > 0:
		(buttons.get_child(_selected) as Button).grab_focus()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	# Consume keyboard events before gameplay/other modal toggles see them.
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	match key:
		KEY_ESCAPE:
			close_dialogue()
		KEY_UP, KEY_DOWN:
			_selected = posmod(_selected + (-1 if key == KEY_UP else 1), buttons.get_child_count())
			_focus_selected()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate(-1 if conversation.choices.is_empty() else _selected, _revision)
		_:
			if key >= KEY_1 and key <= KEY_9:
				_activate(key - KEY_1, _revision)


func _target_exiting() -> void:
	close_dialogue(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and visible:
		close_dialogue(false)


func _exit_tree() -> void:
	if is_node_ready() and visible:
		close_dialogue(false)
