class_name GeneratorStartup
extends Node
## Physical startup rules; presentation and power consumers subscribe separately.

signal changed
signal tripped

enum Stage { OFF, BYPASS_READY, PRESSURIZING, SETTLING, PRESSURE_STABLE,
	BREAKER_2_SET, FIELD_EXCITED, BREAKER_4_SET, BREAKER_1_SET, ONLINE, TRIPPED }

@export var prime_rate: float = 8.0
@export var target_pressure: float = 40.0
@export var pressure_tolerance: float = 2.0
@export var stabilization_seconds: float = 1.5
@export var trip_reset_seconds: float = 1.0
var power: FacilityPower
var stage: Stage = Stage.OFF
var pressure: float = 0.0
var _remaining: float = 0.0


func configure(state: FacilityPower) -> void:
	power = state
	power.coolant_bypass_opened.connect(_bypass_ready)
	stage = Stage.ONLINE if power.main_power_online else (Stage.BYPASS_READY if power.coolant_bypass_open else Stage.OFF)
	changed.emit()


func _bypass_ready() -> void:
	if stage == Stage.OFF:
		stage = Stage.BYPASS_READY
		changed.emit()


func operate(command: StringName) -> void:
	if power == null or stage == Stage.ONLINE or stage == Stage.TRIPPED:
		return
	if command == &"prime":
		if stage == Stage.BYPASS_READY:
			stage = Stage.PRESSURIZING
		elif stage == Stage.PRESSURIZING and absf(pressure - target_pressure) <= pressure_tolerance:
			stage = Stage.SETTLING
			_remaining = stabilization_seconds
		else:
			_trip()
			return
	elif command == &"breaker_2" and stage == Stage.PRESSURE_STABLE:
		stage = Stage.BREAKER_2_SET
	elif command == &"field" and stage == Stage.BREAKER_2_SET:
		stage = Stage.FIELD_EXCITED
	elif command == &"breaker_4" and stage == Stage.FIELD_EXCITED:
		stage = Stage.BREAKER_4_SET
	elif command == &"breaker_1" and stage == Stage.BREAKER_4_SET:
		stage = Stage.BREAKER_1_SET
	elif command == &"breaker_3" and stage == Stage.BREAKER_1_SET:
		stage = Stage.ONLINE
		power.restore_main_power()
	else:
		_trip()
		return
	changed.emit()


func _trip() -> void:
	stage = Stage.TRIPPED
	pressure = 0.0
	_remaining = trip_reset_seconds
	tripped.emit()
	changed.emit()


func _process(delta: float) -> void:
	match stage:
		Stage.PRESSURIZING:
			pressure += prime_rate * delta
			if pressure > target_pressure + pressure_tolerance * 2.0:
				_trip()
			else:
				changed.emit()
		Stage.SETTLING:
			_remaining -= delta
			if _remaining <= 0.0:
				pressure = target_pressure
				stage = Stage.PRESSURE_STABLE
				changed.emit()
		Stage.TRIPPED:
			_remaining -= delta
			if _remaining <= 0.0:
				stage = Stage.BYPASS_READY if power.coolant_bypass_open else Stage.OFF
				changed.emit()
