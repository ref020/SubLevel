# Milestone 8: intercom contact with Mara

No editor configuration or new Input Map actions are required. F5 continues to
run the Observation Room. No physical Mara model or room is added; the window
bay remains dark and the writing is never rendered on the player's side.

## Manual testing

For a quick test, open `scenes/levels/dialogue_test.tscn` and press F6. Walk up
to the labeled intercom on the table and press E. This scene starts with power
and does not require the cabinet/vent sequence. The photograph and pickups
remain available for testing modal conflicts.

For production, press F5. Try the unpowered intercom: it only reports No power.
Enter 4371 at the cabinet, open it, inspect/take the screwdriver with E/F,
remove the four vent fasteners, open the grate, and activate the breaker.
Return to the intercom and press E to begin first contact.

1. Read Hello? and advance with Enter, Space, or the Continue button.
2. Choose Yes. Who are you? Mara introduces herself. Ask Where are you? to
   hear that she is also trapped in Sublevel 6, in a separate room.
3. Choose I'm locked in an observation room. Advance through her responses,
   then ask What can you see? She describes her side of the observation window.
4. Select Look at the other side of the observation window. Advance through
   the player's request, Mara's acknowledgment, her discovery, and the report:
   `C3 - A1 - D4 - B2`. She does not know its interpretation.
5. Choose Goodbye and continue, click End conversation, or press Escape.
   Gameplay and the previous mouse mode resume. Reuse the intercom: it opens
   the repeat menu, and Tell me the writing again recalls the code.
6. During dialogue try WASD, Space, mouse look, E, and Tab. Space advances
   dialogue; it does not jump. Movement/look/world interaction remain disabled.
7. Close during the window discovery, before the code. Reconnect and choose
   What did you find at the window? The code remains obtainable without
   repeating the inspection. Closing before the action resolves leaves the
   original instruction available.

Choices support mouse clicks, number keys 1-9, or Up/Down then Enter/Space.
Tab is consumed during dialogue. Escape always closes it. Losing application
focus closes dialogue and leaves the mouse released; Escape in gameplay
recaptures it. Source/NPC deletion and scene teardown also clean up ownership.

## Architecture

`DialogueData` is read-only Resource content: first/repeat node IDs, a nodes
dictionary, and an actions dictionary. `mara_dialogue.gd` supplies Mara's
content; none of it lives in the intercom, movement script, or UI.

Each dialogue node can contain text, a speaker override, next node, choices,
flags to set on entry, and an action request. Without a speaker override the
participant's display_name is used. Each choice has an ID, text, destination,
optional requires/excludes flag lists, and an optional once property. An empty
destination ends the conversation. Continue advances nodes without choices.

`Conversation` runs this graph and emits changed/ended. It supports branching,
return-to-menu nodes, conditional choices, and participant-owned one-time
choice history. It does not depend on UI or an intercom.

`ConversationParticipant` is a logical NPC entity with npc_id, display_name,
dialogue, contacted state, flags, and completed_choices. Mara's scene is a
non-rendered Node under the ObservationWindow node in the production room.
Content Resources may be shared; runtime state is per NPC instance.

`DialogueUI` renders speaker/text/choice buttons and owns the existing
PlayerModalInput session. It uses exclusive acquire/release; no changes to
modal_input.gd or movement were needed. Existing keypad, inventory, and world
inspection requests cannot acquire the session while dialogue owns it, and
dialogue cannot interrupt those modes. Button callbacks carry a view revision
so stale controls cannot select a choice from a later node.

`intercom_conversation.gd` is scene wiring with explicit references to the
intercom, participant, and presenter. It connects powered_interaction to the
presenter. The intercom still owns only power and interaction behavior. Its
optional starts_powered property is used only by the independent test scene.
The production auxiliary-power controller is unchanged.

## NPC actions and state

The only action currently defined is inspect_window. request_action checks
requires/excludes, applies result flags, and emits action_resolved(action_id).
It is invoked after the player has advanced past Mara's acknowledgment, before
the discovery line. No navigation or background AI is simulated.

Mara's flags are:

- has_introduced_herself: her introduction has been displayed.
- knows_player_is_trapped: she has responded to the player's situation.
- window_context: she has described the window on her side.
- window_inspected: the guarded inspect_window action has resolved.
- window_code_reported: the exact canonical report has been displayed.

The first three enable the inspection request. window_inspected blocks another
execution. The result-report and recall choices keep the code available even
if the conversation is interrupted. Progress-critical choices use completion
flags, not one-time selection, so canceling a player statement cannot lock
progress. The optional Anything else topic demonstrates a one-time choice.

contacted is set only after modal acquisition and successful conversation
start. Subsequent calls open the menu, even if the greeting was interrupted;
Who are you remains available until she has introduced herself.

Elias can later use another ConversationParticipant instance with different
DialogueData and actions, through the same runner and UI. A future NPC-to-NPC
coordinator can query/request participant actions and subscribe to
action_resolved; no coordinator or NPC-to-NPC behavior is implemented here.

## Validation and limitations

Run `godot --headless --path . --script res://tests/dialogue_smoke.gd`.
It checks the independent scene and production wiring, real mouse clicks,
keyboard selection, UI fit at 1152x648, suppression and modal exclusion,
branching/first/repeat contact, interrupted stages, exact report, action guards,
one-time topics, focus loss, source/NPC deletion, fresh state, and scene teardown.
Run the existing vent, inventory, keypad, inspection, door_drawer, interaction,
and observation_room smoke scripts for regression coverage.

Headless tests simulate the captured-input gate. Physical capture and visual
presentation still require an interactive playtest. UI targets normal desktop
window sizes; there is no localization or tiny-window adaptive layout yet.
Flags are monotonic booleans for this prototype, and action resolution is
synchronous at the dialogue stage. State resets when the scene/NPC is replaced.
There is no voice, persistence, or pathfinding. Milestone 9 finalizes the badge
grid interpretation and drawer mechanism; see observation_room_escape.md and
GAME_DESIGN.md. Dialogue content and the coordinate sequence remain unchanged.
