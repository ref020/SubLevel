# Milestone 10C: cassette, coolant, and Main Power

F5 starts the complete Observation Room and continues into the facility. No
editor configuration, new Input Map actions, dependencies, or debug controls
are required. This milestone ends at Main Power; card rewriting, Director
Authorization, and Emergency Egress progression remain unimplemented. Milestone
11A adds Security investigation only; see [security_investigation.md](security_investigation.md).

## Physical route and controls

1. Use the existing screwdriver on the Laboratory calibration unit's captive
   screw. Its cover hinges open in 0.6 seconds. The surrounding shell and cover
   block access, and the battery's targeting collider activates only after the
   cover opens. The screwdriver is retained.
2. E inspects the battery; F takes it. Metadata is `instrument_battery_12v`,
   **12V Instrument Battery**, “A heavy rechargeable 12V battery removed from
   laboratory equipment.” It does not describe the Archive as its destination.
3. At the Archive recorder, E on **12V DC AUX** installs a compatible battery;
   E on the cassette well installs the Observation cassette. Both interactions
   work without Elias contact, and insertion does not start playback.
4. E on physical **PLAY** starts the training recording. One timed subtitle
   appears at a time over quiet procedural tape hiss. Space pauses/resumes,
   R rewinds/replays, and Escape stops/leaves. Mouse buttons provide the same
   controls. The original recording is always replayable.
5. Contact Elias at M-2 (107.3 MHz) and request the coolant bypass. He acknowledges;
   continuing resolves his physical action and confirmation. This choice does
   not require cassette playback. The service-side valve turns, the panel's
   coolant lamp lights, and the bypass stays open for the session.
6. At the Generator console, E on PRIME starts the pump; E again stops it.
   Pressure rises at 8 units/second. Stop within **38–42**; it settles to **40**
   after **1.5 seconds**. Read the analog gauge/numeric pressure plate while
   priming. There is no automatic stop at the solution.
7. Close **2**, operate **FIELD**, close **4**, close **1**, close **3**.
   These are individually targetable physical levers, not keypad entries.

Recording content is stored on the cassette via `RecordingData`:

> Bypass open. Prime until pressure reaches forty. Stop priming. Wait for
> pressure to stabilize. Close breaker two. Field excitation. Close breaker
> four. Bring breaker one online. Breaker three last.

## State and ownership

`FacilitySystems/State` is the sole scene-owned `FacilityPower` instance.
`main_power_online` and `coolant_bypass_open` are read-only properties backed by
private session fields. `main_power_changed(online)` and `coolant_bypass_opened`
notify consumers. Reloading the scene resets both. Observation's auxiliary
state remains completely separate.

`GeneratorStartup` owns these explicit stages:

OFF → BYPASS_READY → PRESSURIZING → SETTLING → PRESSURE_STABLE → BREAKER_2_SET
→ FIELD_EXCITED → BREAKER_4_SET → BREAKER_1_SET → ONLINE.

Wrong controls, stopping below/above the allowed pressure band, premature
controls during settling, and unattended pressure above 44 cause TRIPPED.
Pressure drops to zero, the handles reset, the status reads TRIPPED, and a
restrained message appears. After one second the sequence returns to OFF or
BYPASS_READY. No items are consumed and the bypass stays open. ONLINE is stable:
further control presses cannot trip the running generator or emit duplicate
Main Power events. Startup rules have no clue-discovery requirements.

`ItemSocket` checks each item's exported `installation_tags`. The battery uses
`power_12v`; the cassette uses `compact_cassette`. Inspection snapshots copy
these tags and optional recording data into InventoryItem. Installation moves
the same InventoryItem from carried inventory into `installed_item` and places
its static visual snapshot at the socket. Neither item is destroyed. Retrieval
is intentionally outside this milestone. Generic player code contains no
battery/deck item-ID checks.

`ConversationParticipant` now offers a `_perform_action` hook before setting
flags/emitting action resolution. Mara retains that behavior for the original
window action; Milestone 11A adds a physically Main-Power-gated phase-chart action.
Elias's
implementation opens the real facility bypass only after contact and only once;
dialogue confirms success afterward. Aborting the acknowledgement leaves the
request available. His flags record the conversation; physical bypass state
belongs to FacilityPower.

`RecordingUI` uses PlayerModalInput to suspend movement, look, targeting, and
HUD while listening. Other modals cannot steal the session. Closing, focus
loss, or device deletion stops playback and releases ownership.

## Main Power reactions

Main-scene wiring links the startup to independent consumers. Generator code
does not enumerate lights, rooms, or future equipment.

- Generator panel shows RUNNING and a procedural local 60/120 Hz hum begins.
- Hub west/east, Archive records, and Generator console lights increase output.
- An additional Hub fluorescent circuit illuminates its existing housing.
- Archive's AC lamp wakes. The recorder works on battery **or** facility mains;
  restoring mains preserves any installed battery/cassette and playback access.
- A small standby lamp wakes on the Security outer pedestal, without changing
  its physical boundary. Milestone 11A additionally boots the investigation
  terminal and enables Archive analysis through the same state.
- The Hub status panel changes only MAIN POWER from OFF to ONLINE. SECURITY
  CLEARANCE INVALID, DIRECTOR AUTHORIZATION REQUIRED, and EXIT SEALED remain.

`facility_power_response.gd` demonstrates a signal-driven environmental consumer.
Future systems can subscribe to the same state without editing GeneratorStartup.
The battery instrument and recorder replace only their inert graybox housings;
existing room shells, reserved positions, connections, and barriers are retained.

## Validation and manual review

`tests/main_power_smoke.gd` covers physical ray/E targeting, screwdriver access,
inspection/take, metadata, compatible insertion, item retention, deliberate
play/replay/pause, modal exclusion, recording before Elias, radio contact and
NPC action, inaccessible bypass, pump/stabilization, all wrong controls at each
startup stage, under/over-pressure trips, retry, and physical success. It also
checks authoritative state, unchanged auxiliary state, environmental reactions,
unchanged Security/Director/egress status, mains-only deck power, and session reset.
`radio_smoke.gd` additionally requests the bypass before cassette discovery.
All earlier suites remain in use for Observation progression and facility travel.

Run `godot --headless --path . --script res://tests/main_power_smoke.gd` and the
other `tests/*_smoke.gd` scripts. Headless tests do not assess perceived lighting,
gauge legibility, audio balance, or input feel. Use F5 to check the opened cover,
installed item models, pressure timing, subtitles, hum, power transition, and
mouse capture. Audio is procedural placeholder ambience; no voiced training
recording or final art is included.
