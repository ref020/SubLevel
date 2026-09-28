extends CanvasLayer
## Replayable, timed subtitles represent a physical tape recording.

@export var input_session: PlayerModalInput
var source: Node3D
var recording: RecordingData
var line_index: int = 0
var paused: bool = false
var _elapsed: float = 0.0
@onready var text_label: Label = $Backdrop/Center/Panel/Margin/Content/Text
@onready var hiss: AudioStreamPlayer = $Hiss


func _ready() -> void:
	add_to_group("recording_presenter")
	hide()
	$Backdrop/Center/Panel/Margin/Content/Replay.pressed.connect(replay)
	$Backdrop/Center/Panel/Margin/Content/Pause.pressed.connect(toggle_pause)
	$Backdrop/Center/Panel/Margin/Content/Return.pressed.connect(close_recording)
	var samples: PackedByteArray = PackedByteArray()
	samples.resize(22050)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 12
	for i: int in samples.size():
		samples[i] = random.randi_range(-12, 12) & 0xff
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.data = samples
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples.size()
	hiss.stream = stream


func open_recording(device: Node3D, data: RecordingData) -> void:
	if data == null or data.lines.is_empty() or not is_instance_valid(device) or not input_session.acquire(self):
		return
	source = device
	recording = data
	source.tree_exiting.connect(_source_exiting)
	$Backdrop/Center/Panel/Margin/Content/Title.text = "CASSETTE / " + data.title
	show()
	replay()


func replay() -> void:
	if not visible:
		return
	line_index = 0
	_elapsed = 0.0
	paused = false
	hiss.stream_paused = false
	if not hiss.playing:
		hiss.play()
	source.set_playing(true)
	_render()


func toggle_pause() -> void:
	if not visible or line_index >= recording.lines.size():
		return
	paused = not paused
	hiss.stream_paused = paused
	source.set_playing(not paused)
	_render()


func _render() -> void:
	text_label.text = recording.lines[line_index] if line_index < recording.lines.size() else "[The recording ends.]"
	$Backdrop/Center/Panel/Margin/Content/Pause.text = "Resume [Space]" if paused else "Pause [Space]"


func _process(delta: float) -> void:
	if not visible or paused or line_index >= recording.lines.size():
		return
	_elapsed += delta
	if _elapsed >= recording.seconds_per_line:
		_elapsed = 0.0
		line_index += 1
		_render()
		if line_index == recording.lines.size():
			hiss.stop()
			source.set_playing(false)


func close_recording(restore_mouse: bool = true) -> void:
	if not visible:
		return
	if is_instance_valid(source):
		source.set_playing(false)
		source.tree_exiting.disconnect(_source_exiting)
	source = null
	recording = null
	hiss.stop()
	hide()
	input_session.release(self, restore_mouse)


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
	match key:
		KEY_ESCAPE: close_recording()
		KEY_SPACE: toggle_pause()
		KEY_R: replay()


func _source_exiting() -> void:
	close_recording(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and visible:
		close_recording(false)


func _exit_tree() -> void:
	if is_node_ready() and visible:
		close_recording(false)
