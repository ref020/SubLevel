extends Node3D

var power: FacilityPower
var powered: bool = false
var playing: bool = false


func _ready() -> void:
	$BatteryInput.item_installed.connect(_installed)
	$TapeSlot.item_installed.connect(_installed)
	$Play.activated.connect(play)


func configure(state: FacilityPower, inventory: PlayerInventory) -> void:
	power = state
	$BatteryInput.inventory = inventory
	$TapeSlot.inventory = inventory
	power.main_power_changed.connect(_power_changed)
	_refresh()


func _installed(_item: InventoryItem) -> void:
	_refresh()


func _power_changed(_online: bool) -> void:
	_refresh()


func _refresh() -> void:
	powered = $BatteryInput.installed_item != null or (power != null and power.main_power_online)
	$PowerLamp.visible = powered
	$MainsLamp.visible = power != null and power.main_power_online


func play() -> void:
	if not powered:
		$Play.feedback("No power.")
		return
	var tape: InventoryItem = $TapeSlot.installed_item
	if tape == null:
		$Play.feedback("The cassette well is empty.")
		return
	if tape.recording == null:
		$Play.feedback("Only tape hiss.")
		return
	get_tree().call_group("recording_presenter", "open_recording", self, tape.recording)


func set_playing(value: bool) -> void:
	playing = value
	$TransportLamp.visible = playing
