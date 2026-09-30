extends DialogueData


func _init() -> void:
	actions = {"open_coolant_bypass": {"excludes": ["bypass_opened"], "sets": ["bypass_opened"]}}
	nodes = {
		"first": {"text": "Hold there. Someone on this band? I thought I was the only one still moving.", "next": "identify"},
		"identify": {"speaker": "PLAYER", "text": "I hear you. Who is this?", "next": "elias"},
		"elias": {"text": "Elias. Maintenance. I'm shut in on the service side. The passage back is blocked.", "next": "power_question"},
		"power_question": {"speaker": "PLAYER", "text": "Can we get the power back?", "next": "power"},
		"power": {"text": "We're on emergency supply and whatever auxiliary circuits are still holding. I maintained this plant. The Generator may be recoverable.", "next": "bypass"},
		"bypass": {"text": "Its coolant bypass is over here. I can work that valve, but the synchronization and startup controls are on your side.", "next": "cooperation"},
		"cooperation": {"text": "You can't bring it up without coolant. I can't start it from here. We'll need each other. Don't touch the startup controls until we know the procedure.", "sets": ["generator_problem_established"], "next": "menu"},
		"menu": {"text": "Elias here. Still on the service side.", "choices": [
			{"id": "problem", "text": "Remind me what separates us from the Generator.", "next": "reminder"},
			{"id": "bypass", "text": "Open the coolant bypass on your side.", "excludes": ["bypass_opened"], "next": "bypass_ack"},
			{"id": "end", "text": "I'll call back.", "next": "goodbye"}
		]},
		"reminder": {"text": "The coolant bypass is on my side. The synchronization and startup controls are on yours. Neither of us can restore main power alone.", "sets": ["generator_problem_established"], "next": "menu"},
		"bypass_ack": {"text": "All right. Stand clear of the machinery. I'll open the bypass from here.", "next": "bypass_done"},
		"bypass_done": {"action": "open_coolant_bypass", "action_unavailable": "menu", "text": "It's open. Coolant has a path now. I'll leave it that way.", "next": "menu"},
		"goodbye": {"text": "All right. I'll keep listening.", "next": ""}
	}
	actions["contact_m4"] = {}
	actions["configure_m4"] = {}
	nodes["routing_reply"] = {"text": "Mara? Yes. Barely. Where are you routing this from?", "next": "mara:routing_reply"}
	nodes["m4_access"] = {"action": "contact_m4", "action_unavailable": "mara:menu", "text": "I can reach M-4 from the service side. Its network link is down, but I can work the controls. Tell me what the Director terminal wants.", "next": "mara:link_established"}
	nodes["m4_setting"] = {"text": "Copy. Setting M-4.", "next": "elias:m4_result"}
	nodes["m4_result"] = {"action": "configure_m4", "action_unavailable": "mara:menu", "text": "{m4_result}", "next": "mara:menu"}
	nodes["sector_released"] = {"text": "Service door's open. I'm moving.", "next": ""}
