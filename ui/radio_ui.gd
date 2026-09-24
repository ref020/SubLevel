extends CanvasLayer
## Presentation and input only; the receiver owns tuning and reception.

@export var input_session: PlayerModalInput
var active_radio: TunableRadio
@onready var display: Label = $Backdrop/Center/Panel/Margin/Content/Display
@onready var status: Label = $Backdrop/Center/Panel/Margin/Content/Status
@onready var noise: AudioStreamPlayer = $Noise


func _ready() -> void:
	add_to_group("radio_presenter")
	hide()
	$Backdrop/Center/Panel/Margin/Content/Controls/Down.pressed.connect(_tune.bind(-1))
	$Backdrop/Center/Panel/Margin/Content/Controls/Up.pressed.connect(_tune.bind(1))
	$Backdrop/Center/Panel/Margin/Content/Return.pressed.connect(close_radio)
	# Quiet, locally generated static: no external audio asset or dependency.
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(22050)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 206
	for index: int in samples.size():
		samples[index] = random.randi_range(-24, 24) & 0xff
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.data = samples
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples.size()
	noise.stream = stream


func open_radio(radio: TunableRadio) -> void:
	if not is_instance_valid(radio) or not input_session.acquire(self):
		return
	active_radio = radio
	radio.tree_exiting.connect(_target_exiting)
	radio.frequency_changed.connect(_refresh)
	radio.transmission_found.connect(_received)
	$Backdrop/Center/Panel/Margin/Content/Title.text = radio.designation + " / FM"
	status.text = "[Soft static]"
	_refresh(radio.frequency)
	radio.begin_listening()
	noise.play()
	show()


func close_radio(restore_mouse: bool = true) -> void:
	if is_instance_valid(active_radio):
		active_radio.end_listening()
		active_radio.tree_exiting.disconnect(_target_exiting)
		active_radio.frequency_changed.disconnect(_refresh)
		active_radio.transmission_found.disconnect(_received)
	active_radio = null
	noise.stop()
	hide()
	input_session.release(self, restore_mouse)


func _refresh(value: float) -> void:
	display.text = "%.1f MHz" % value
	status.text = "[Soft static]"
	if visible and not noise.playing:
		noise.play()


func _received() -> void:
	noise.stop()
	status.text = "[Voice on the channel]"


func _tune(direction: int) -> void:
	if is_instance_valid(active_radio):
		active_radio.tune(direction)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
		if not event.pressed:
			return
		var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
		match key:
			KEY_ESCAPE: close_radio()
			KEY_LEFT, KEY_A: _tune(-1)
			KEY_RIGHT, KEY_D: _tune(1)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()
			_tune(1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1)


func _target_exiting() -> void:
	close_radio(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and visible:
		close_radio(false)


func _exit_tree() -> void:
	if is_node_ready() and visible:
		close_radio(false)
