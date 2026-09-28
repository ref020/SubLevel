extends Node3D
## The panel renders state; the startup node owns every sequence rule.

@onready var startup: GeneratorStartup = $Startup


func _ready() -> void:
	for control: Node in $Controls.get_children():
		control.activated.connect(startup.operate.bind(StringName(control.name)))
	startup.changed.connect(_render)
	startup.tripped.connect(_trip_feedback)
	$Hum.stream = _hum()
	_render()


func _render() -> void:
	$Gauge/Needle.rotation_degrees.z = 120.0 - clampf(startup.pressure / 60.0, 0.0, 1.0) * 240.0
	$Gauge/Readout.text = "PRESSURE  %02d" % roundi(startup.pressure)
	var status: String = "STANDBY"
	match startup.stage:
		GeneratorStartup.Stage.ONLINE: status = "RUNNING"
		GeneratorStartup.Stage.TRIPPED: status = "TRIPPED"
		GeneratorStartup.Stage.PRESSURIZING: status = "PRIMING"
		GeneratorStartup.Stage.SETTLING: status = "SETTLING"
		GeneratorStartup.Stage.PRESSURE_STABLE: status = "STABLE"
	$Status.text = status
	$Controls/prime.interaction_prompt = "Stop Priming" if startup.stage == GeneratorStartup.Stage.PRESSURIZING else "Prime"
	var stages: Dictionary = {"breaker_2": GeneratorStartup.Stage.BREAKER_2_SET, "field": GeneratorStartup.Stage.FIELD_EXCITED,
		"breaker_4": GeneratorStartup.Stage.BREAKER_4_SET, "breaker_1": GeneratorStartup.Stage.BREAKER_1_SET, "breaker_3": GeneratorStartup.Stage.ONLINE}
	for control: String in stages:
		var closed: bool = startup.stage >= stages[control] and startup.stage <= GeneratorStartup.Stage.ONLINE
		get_node("Controls/" + control + "/Lever").rotation_degrees.x = -35.0 if closed else 35.0
	if startup.stage == GeneratorStartup.Stage.ONLINE and not $Hum.playing:
		$Hum.play()


func _trip_feedback() -> void:
	$Controls/prime.feedback("Generator tripped. Pressure falling.")


func _hum() -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(22050)
	for i: int in data.size():
		var t: float = float(i) / 22050.0
		data[i] = roundi(sin(TAU * 60.0 * t) * 28.0 + sin(TAU * 120.0 * t) * 9.0) & 0xff
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = data.size()
	return stream
