# Milestone 10B: M-2 investigation and Elias

F5 starts the existing complete Observation Room. Escape normally, then explore
Laboratory, Archive, and Maintenance in any order. No editor setup or new Input
Map action is required. No clue-inspection flags gate the radio.

## Clues and locations

- Observation cabinet: collectible Folded Note (`cabinet_note`), using E to
  inspect and F to take. Inventory retains both its text and inspectable model:
  “M-2 is still three tenths out. Vale refuses to change the card.”
- Laboratory calibration bench: noncollectible record at (13.1, 0.932, -11.55).
  Equal-weight rows read A-4 +0.1, M-2 -0.3, C-7 +0.2.
- Archive personnel cabinet: noncollectible Warren Vale record/contact card
  mounted at (14.9, 1.42, 9.639). It identifies the Facility Director and gives
  MAINT. BAND / 107.6 MHz. It does not mention M-2, 107.3, or employee ID 0614.
- Maintenance radio desk: M-2 at its existing reserved (24.8, 1.07, 2.05).

Canonical deduction: **107.6 MHz + (-0.3 MHz) = 107.3 MHz**. Document text is
physical TextMesh geometry, copied by the existing inspection system. Both
environmental records remain in place after inspection.

## Architecture and controls

`TunableRadio` extends Interactable. Exports configure minimum, maximum, tuning
step, starting and target frequencies, designation, and stable reception delay.
Integer dial positions prevent cumulative floating-point drift. M-2 uses
87.5–108.0 MHz, 0.1 MHz steps, starts at 99.5 MHz, and targets 107.3 MHz with a
0.9-second dwell. Frequency persists during the session; each new listening
session can discover the transmission again. There is no submit button or snap.

E opens RadioUI through the existing interaction ray. Left/Right or A/D tunes;
holding a key uses normal keyboard repeat. Mouse wheel or the two dial buttons
also tunes. Escape exits. PlayerModalInput suspends movement, look, interaction,
and the interaction HUD; other modals cannot steal ownership. Focus loss and
device deletion clean up the session. A physical frequency display and knob
update alongside the UI. Quiet procedural looping static requires no assets.

Radio emits `frequency_changed` and `transmission_found`. The main scene's
`RadioConversation` connects M-2 to Elias and transfers modal ownership directly
to the existing DialogueUI, retaining the original gameplay snapshot. The radio
and player contain no Elias dialogue. DialogueUI now accepts an optional prior
modal owner and channel caption; existing intercom calls retain their behavior.

Elias is a non-rendered ConversationParticipant with separate DialogueData.
First contact establishes his maintenance role, isolation on the service side,
emergency supply, and the need to coordinate his coolant bypass with the player's
Generator controls. No startup sequence is supplied. `contacted` and the
`generator_problem_established` flag persist only for the current game session.
Later calls open a short reminder/end menu. The reminder is available even if
the introduction was interrupted. Existing participant action requests support
future commands, but `open_coolant_bypass` is deliberately unregistered and
cannot pretend to operate equipment.

`facility_investigation.tscn` contains the active props and participant; the
static graybox remains separate. Radio conversation wiring belongs to the main
scene because it references the main player. No battery, cassette playback,
generator operation, main power, Security, Director, or new Mara progression
is implemented.

## Validation and manual check

Run `godot --headless --path . --script res://tests/radio_smoke.gd`, plus all
existing smoke suites. The radio suite covers normal ray/E interaction, modal
exclusion and handoff, tuning increments/bounds, incorrect and transient tuning,
first and repeat contact without reading clues, physical document targeting,
inspection, inventory note re-reading, and focus/deletion cleanup. The existing
escape and facility suites cover complete Observation progression and traversal.

For a manual F5 check, escape Observation and inspect the two records. Tune M-2
with keyboard and mouse, pass across 107.3 quickly, then hold it briefly. Confirm
static stops when Elias appears, complete his conversation, exit, and call again.
Also check document readability/rotation, physical radio display, audio volume,
and mouse capture restoration. Headless tests do not assess perceived text
legibility, audio quality, or visual composition. No voice acting is included.
