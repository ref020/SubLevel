extends DialogueData


func _init() -> void:
	# No bypass action is registered until there is real equipment to operate.
	# ConversationParticipant already supports condition-gated action requests.
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
			{"id": "end", "text": "I'll call back.", "next": "goodbye"}
		]},
		"reminder": {"text": "The coolant bypass is on my side. The synchronization and startup controls are on yours. Neither of us can restore main power alone.", "sets": ["generator_problem_established"], "next": "menu"},
		"goodbye": {"text": "All right. I'll keep listening.", "next": ""}
	}
