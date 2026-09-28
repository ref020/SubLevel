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
