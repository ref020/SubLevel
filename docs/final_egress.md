# Milestone 13: playable evacuation ending

The intended gameplay progression is implemented from Observation Room through
physical departure. This milestone adds payoff only: no new codes, NPCs,
information puzzle, combat, timer or post-ending lore.

## State and interlocks

EmergencyEgress/State is FacilityEgress. Its egress_authorized getter reads the
actual FacilityPower, FacilitySecurity and FacilityDirector instances, requiring
all three macro conditions. The door does not contain duplicate power/security
flags. Macro signals drive presentation; authorization never opens the door.

Read-only session properties distinguish primary_release_open, service_plate_open,
secondary_release_open, observation_cells_released, maintenance_sector_released,
surface_access_enabled and game_completed. Guarded operate actions enforce the
sequence. changed, sector_released and completed signals notify scene consumers.
All states reset with a new production scene; persistent here means the current
session, not save/load.

The existing Hub panel changes to MANUAL RELEASE ENABLED. A small local indicator
and procedural interlock clunk accompany authorization. The old solid decorative
egress leaves/frame are replaced by a real door and an actual north-wall opening.
The rest of the facility layout and progression stay intact.

## Mechanical sequence

1. E on the primary release beside the right jamb at (20, 1.35, -3.02).
   Its substantial handle turns, the first latch retracts and the second shifts
   slightly then stops. The nearby mounted report says PRIMARY: OPEN /
   SECONDARY: MECHANICAL FAULT. The heavy door stays locked.
2. The secondary service plate below the Hub status panel uses one captive
   slotted fastener. It extends the existing tool_access_cover and
   RequiredItemInteractable architecture. Before the primary attempt its service
   interlock refuses operation. Without the screwdriver it gives the existing
   restrained missing-tool feedback. With the original screwdriver, E opens the
   hinged plate in 0.6 seconds; the tool is retained.
3. The housing and plate block the linkage ray. Only the fully-open signal enables
   its collider and authoritative service-access state. E deliberately pulls the
   exposed secondary linkage. The second latch retracts with a clunk; the door
   unlocks but stays closed.
4. E on the heavy door swings it inward over 1.1 seconds. It can be closed and
   reopened from either side. Neither release is reset by backtracking.

Door leaves reuse Openable animation/lock behavior. The small EgressControl
component supplies state-aware prompts/actions; no player/inventory puzzle code
was added. The short procedural clunk is synthesized locally with no asset or
plugin dependency. Audio level and mechanical feel still need manual review.

## Vestibule, sector releases and surface route

The compact steel/concrete vestibule lies immediately north of the Hub, roughly
x=17.5..20.2, z=-3.3..-7.3. A wall-mounted emergency panel faces west at
(19.94, 1.45, -5.9). Each labeled physical lever is independently targeted with E:

- OBSERVATION CELLS starts SECURED. Its release sets authoritative sector state
  and opens Mara's single-line facility-voice confirmation: "The lock just
  released. I can get out."
- MAINTENANCE SECTOR starts SECURED. Its release sets its sector state and Elias
  confirms: "Service door's open. I'm moving."
- SURFACE ACCESS starts LOCKED, becomes READY only after both sectors, and becomes
  ENABLED only when the player deliberately operates it. Pressing it does not end
  the game or automatically open the final door.

The short confirmations are nodes in the existing separate Mara/Elias dialogue
resources. Conversation/DialogueUI now accept an optional explicit entry node;
normal first/repeat conversations keep their prior behavior. End/Continue/Escape
can dismiss these confirmations without reversing the physical release. No NPC
model moves or teleports, and no pathfinding is added.

A six-meter upward service ramp rises 2.4 m toward a locked surface door at
z=-13.3. Side walls, solid jambs/header, floor and ceiling enclose it. Surface
Access unlocks that door; E still opens it manually. A short upper landing with
neutral daylight spill provides the exterior threshold without an outdoor level.
The generator hum fades an additional 28 dB along this route, restoring if the
player returns. Lighting shifts from the institutional green toward neutral.

## Completion

Only the actual player entering FinalThreshold and crossing z=-14.4 requests
cross_final_threshold. State checks authorization, both latches, both sectors and
Surface Access; repeated requests are ignored. Door/control presses do not call
this method. A one-shot EndingUI acquires existing PlayerModalInput, fades to a
quiet screen and displays:

SUBLEVEL 6
EVACUATION COMPLETE

MARA - RELEASED
ELIAS - RELEASED

Ending ownership prevents resuming movement beneath the fade. Restart the scene
with the normal editor controls to play again. No menu, save system, epilogue,
sequel hook or additional puzzle is introduced.

## Validation

Run every tests/*_smoke.gd with Godot --headless --path . --script.

- egress_smoke.gd isolates each macro prerequisite, missing-tool recovery,
  service-plate occlusion and animation guards, retained screwdriver, separate
  unlock/open behavior, vestibule traversal/backtracking, both sector confirmations,
  Surface gating, ramp capsule movement, standing/jumping collision sweeps,
  mounted-text bounds, physical threshold completion and one-shot ending input.
  Its isolated branch fixture supplies the tool and completes macro state via APIs.
- full_game_smoke.gd uses one production scene from fresh Observation through
  final departure. It obtains the actual screwdriver/cassette through 4371,
  operates vent screws and auxiliary power, receives Mara's report, opens 4778,
  collects/uses the exit key, tunes 107.3, requests Elias's bypass, installs the
  real battery/cassette, plays the recorder, performs timed Generator startup,
  restores/retrieves Vale's card with 0614/IV/4321, uses the reader, opens the
  Director cabinet with canonical symbols, collects/installs the module, routes
  Line D, transmits EAST/AMBER/B through the participants, finalizes Director
  authorization and exercises the complete egress sequence. It never injects
  inventory or sets macro-completion flags and has no clue-inspection prerequisites.
- Earlier smoke suites continue to cover their original branches. Observation's
  local interactable count excludes the new layer, and the Director completion
  assertion now expects MANUAL RELEASE ENABLED.

Tests use known approach positions between rooms and public device APIs for some
code/dialogue entries. They are not an automated blind walking playtest. The
headless display cannot capture the mouse; the ramp test drives the real
CharacterBody collision/slope movement at controller speed instead. Existing
movement/interaction Input Map actions are unchanged.

## Manual review

No editor configuration is required. F5 runs the full game. After completing
Director authorization, operate the primary handle, open the service plate with
the retained screwdriver, pull the linkage, and manually open the egress. Release
both sectors at the vestibule panel, enable Surface Access, walk up the ramp,
open the upper door and cross the final threshold.

Still review rendered control/sign legibility, low service-plate targeting,
heavy-door swing clearance, clunk volume, voice-text pacing, ramp feel, daylight
transition and the ending fade. Existing Openable motion does not reverse on
obstruction; standing inside a moving door's sweep can push the player. Collision
sampling is extensive but not an exhaustive exploit search. All art/audio remain
prototype quality, and NPC confirmations are text rather than voiced recordings.
