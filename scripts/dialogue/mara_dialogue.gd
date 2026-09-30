extends DialogueData


func _init() -> void:
	actions = {
		"inspect_phase_chart": {
			"requires": ["main_power_online"], "excludes": ["phase_chart_inspected"],
			"sets": ["phase_chart_inspected"]
		},
		"inspect_window": {
			"requires": ["has_introduced_herself", "knows_player_is_trapped", "window_context"],
			"excludes": ["window_inspected"], "sets": ["window_inspected"]
		}
	}
	nodes = {
		"phase_request": {"text": "There's a light on over an observation panel now. I'll go closer and read it.", "next": "phase_discovery"},
		"phase_discovery": {"action": "inspect_phase_chart", "action_unavailable": "menu",
			"text": "I can see a chart beside it. Four channels, each with a different marking.", "next": "phase_report"},
		"phase_report": {"text": "A = 90°\nB = 270°\nC = 0°\nD = 180°",
			"sets": ["phase_chart_reported"], "next": "phase_after"},
		"phase_after": {"text": "That's what's printed here. I don't know what the channels connect to.", "next": "menu"},
		"phase_recall": {"text": "I remember the markings on that chart.", "next": "phase_report"},
		"first": {"text": "Hello?", "next": "hearing"},
		"hearing": {"text": "Can you hear me? I thought this thing was dead.", "choices": [
			{"id": "answer", "text": "Yes. Who are you?", "next": "introduction"},
			{"id": "where_first", "text": "Where are you?", "next": "location"}
		]},
		"introduction": {"text": "Mara. Who's there? You don't sound like anyone I've heard here.",
			"sets": ["has_introduced_herself"], "next": "menu"},
		"menu": {"text": "I'm here. What is it?", "choices": [
			{"id": "phase", "text": "Has the restored power revealed anything on your side?",
				"requires": ["main_power_online"], "excludes": ["phase_chart_inspected"], "next": "phase_request"},
			{"id": "phase_unreported", "text": "What did you find by the powered observation panel?",
				"requires": ["phase_chart_inspected"], "excludes": ["phase_chart_reported"], "next": "phase_report"},
			{"id": "phase_recall", "text": "Repeat the channel markings you found.",
				"requires": ["phase_chart_reported"], "next": "phase_recall"},
			{"id": "name", "text": "Who are you?", "excludes": ["has_introduced_herself"], "next": "introduction"},
			{"id": "trapped", "text": "I'm locked in an observation room.", "excludes": ["knows_player_is_trapped"], "next": "trapped"},
			{"id": "location", "text": "Where are you?", "next": "location"},
			{"id": "surroundings", "text": "What can you see?", "requires": ["knows_player_is_trapped"], "next": "surroundings"},
			{"id": "inspect", "text": "Look at the other side of the observation window.",
				"requires": ["has_introduced_herself", "knows_player_is_trapped", "window_context"],
				"excludes": ["window_inspected"], "next": "request"},
			{"id": "unreported", "text": "What did you find at the window?", "requires": ["window_inspected"],
				"excludes": ["window_code_reported"], "next": "report"},
			{"id": "recall", "text": "Tell me the writing again.", "requires": ["window_code_reported"], "next": "recall"},
			{"id": "else", "text": "Anything else?", "once": true, "requires": ["has_introduced_herself"], "next": "else"},
			{"id": "goodbye", "text": "Goodbye.", "next": "goodbye"}
		]},
		"trapped": {"speaker": "PLAYER", "text": "I'm locked in an observation room. I can't get out.", "next": "trapped_reply"},
		"trapped_reply": {"text": "You too? All right. I was afraid you were the one keeping me here.",
			"sets": ["knows_player_is_trapped"], "next": "cooperate"},
		"cooperate": {"text": "I can't reach you from here. But I can look around if you need me to check something.", "next": "menu"},
		"location": {"text": "Somewhere in Sublevel 6. That's all I can tell you for certain.", "next": "separated"},
		"separated": {"text": "I'm locked in too. If you're by the intercom, we're in different rooms. I can't see you.", "next": "menu"},
		"surroundings": {"text": "There's an observation window on my side. The light catches the glass, but I can't make out your room.",
			"sets": ["window_context"], "next": "menu"},
		"request": {"speaker": "PLAYER", "text": "Can you check the other side of the observation window?", "next": "waiting"},
		"waiting": {"text": "Give me a second. I'll get closer.", "next": "discovery"},
		"discovery": {"action": "inspect_window", "action_unavailable": "menu",
			"text": "There's something written here. It's on this side of the glass.", "next": "report"},
		"report": {"text": "C3 - A1 - D4 - B2", "sets": ["window_code_reported"], "next": "uncertain"},
		"uncertain": {"text": "Does that mean anything to you? I don't know what it's for.", "next": "menu"},
		"recall": {"text": "I already checked it. The writing is still there.", "next": "report"},
		"else": {"text": "Nothing I'm sure of. I'd rather tell you what I can actually see.", "next": "menu"},
		"goodbye": {"text": "I'll listen for you. Don't forget I'm here.", "next": ""}
	}
	_add_routing()
	nodes["sector_released"] = {"text": "The lock just released. I can get out.", "next": ""}


func _add_routing() -> void:
	actions["route_line"] = {}
	actions["relay_m4"] = {}
	nodes["menu"]["choices"].insert(0, {"id": "communications", "text": "Can you work with the communications panel?", "requires": ["main_power_online"], "next": "communications"})
	nodes["communications"] = {"text": "I'm at the routing panel. What do you need?", "choices": [
		{"id": "routing", "text": "Connect a service communication line.", "next": "routing"},
		{"id": "response", "text": "I have a response for the secondary station.", "requires": ["secondary_session"], "excludes": ["secondary_ready", "director_valid"], "next": "response_direction"},
		{"id": "back", "text": "Something else.", "next": "menu"}]}
	nodes["routing"] = {"text": "The routing panel on my side has power now. I can patch a service line through. Which line?", "choices": []}
	for line: String in ["A", "B", "C", "D", "E", "F"]:
		nodes["routing"]["choices"].append({"id": "line_" + line, "text": "LINE " + line, "next": "route_" + line})
		nodes["route_" + line] = {"action": "route_line", "parameters": {"line": line}, "action_unavailable": "menu", "text": "Line " + line + " connected. Listening.", "next": "call_elias" if line == "D" else "line_silent"}
	nodes["routing"]["choices"].append({"id": "back", "text": "Leave the panel for now.", "next": "menu"})
	nodes["line_silent"] = {"text": "Only a carrier. Nobody answering us on this line.", "next": "routing"}
	nodes["call_elias"] = {"text": "Maintenance, can you hear me?", "next": "elias:routing_reply"}
	nodes["routing_reply"] = {"text": "Observation-side intercom. Someone out here needs service control M-4.", "next": "elias:m4_access"}
	nodes["link_established"] = {"text": "I'll keep this line connected. Tell me what you need passed along.", "next": "menu"}
	var directions: Array[String] = ["NORTH", "EAST", "SOUTH", "WEST"]
	var colors: Array[String] = ["WHITE", "BLUE", "AMBER", "RED"]
	var circuits: Array[String] = ["A", "B", "C", "D"]
	for field: String in ["direction", "color", "circuit"]:
		var options: Array[String] = directions if field == "direction" else (colors if field == "color" else circuits)
		var next_stage: String = "response_color" if field == "direction" else ("response_circuit" if field == "color" else "response_review")
		nodes["response_" + field] = {"speaker": "PLAYER", "text": "RESPONSE / " + ("LOAD COLOR" if field == "color" else field.to_upper()), "choices": []}
		for value: String in options:
			var entry: String = "select_" + field + "_" + value
			nodes["response_" + field]["choices"].append({"id": entry, "text": value, "next": entry})
			nodes[entry] = {"speaker": "PLAYER", "text": field.to_upper() + ": " + value, "values": {field: value}, "next": next_stage}
		nodes["response_" + field]["choices"].append({"id": "cancel", "text": "Cancel response.", "next": "menu"})
	nodes["response_review"] = {"speaker": "PLAYER", "text": "DIRECTION: {direction}\nLOAD COLOR: {color}\nCIRCUIT: {circuit}", "choices": [
		{"id": "transmit", "text": "Give response to Mara.", "next": "response_player"},
		{"id": "edit", "text": "Change response.", "next": "response_direction"},
		{"id": "cancel", "text": "Not yet.", "next": "menu"}]}
	nodes["response_player"] = {"speaker": "PLAYER", "text": "{direction}. {color}. Circuit {circuit}.", "next": "response_confirm"}
	nodes["response_confirm"] = {"text": "{direction}, {color}, {circuit}. Got it.", "next": "response_relay"}
	nodes["response_relay"] = {"action": "relay_m4", "action_unavailable": "menu", "text": "Elias, response is {direction}, {color}, circuit {circuit}.", "next": "elias:m4_setting"}
