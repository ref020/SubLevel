class_name RecordingData
extends Resource

@export var title: String
@export var lines: PackedStringArray
@export_range(1.0, 12.0, 0.5) var seconds_per_line: float = 4.0
