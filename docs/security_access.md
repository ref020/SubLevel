# Milestone 11B: credential rewriting and Security access

The completed branch ends at **SECURITY CLEARANCE VALID** and an unlocked,
manually openable Director threshold. The threshold remains an empty graybox;
there is no Director puzzle, module, M-4 interaction, routing, authorization,
or final egress release. All previous investigation clues remain unchanged.

## Placement and hardware

The reserved encoder was inside the room its card must unlock. Its reservation
has therefore moved to **Security outer (24.2, 1.18, 7.85)**, facing north on a
1.4 m stand. This removes the circular physical prerequisite. The outer terminal
remains on its existing pedestal. Main Power energizes both encoder and reader;
the portable battery cannot power them.

The encoder is a beige/gray enclosure with CRT, card slot, two banks of four
numeric controls, four Roman-numeral class keys, WRITE/EJECT keys and small
power/write lamps. E opens an enlarged hardware panel using PlayerModalInput:
movement, look, world interaction and HUD suspend together. Escape or focus loss
releases the modal without losing the installed card. Other modals cannot steal it.

Mouse: select a bank or click a digit wheel to increment it (right-click to
decrement), choose I/II/III/IV, and press INSERT CARD / WRITE / EJECT CARD.
Keyboard: 0-9 or numpad enters the selected bank; Tab changes banks; Left/Right
changes class; Backspace erases; C clears the bank; Enter writes; Escape returns.
Digits start blank, so no leading zero is implicitly supplied. Inputs persist at
the device across modal exits. No generic text-entry fields or new Input Map
actions are used. The physical digit displays mirror the panel.

## Item ownership and credential state

`AccessCredential` is a resource with identity, active/revoked state, clearance
class, and compatible access-system IDs. PickupItem/InventoryItem carry it;
inspection duplicates the pickup template when collecting so new scenes cannot
inherit mutations. The generic player contains no Vale identity or puzzle checks.

Vale uses identity `warren_vale`, item ID `vale_access_card`, installation tag
`access_credential`, compatibility `security_inner`, and initially inactive /
revoked / class 0. Its ordinary-key `unlocks` array remains empty. Card identity,
mutable card validity, Main Power and macro Security completion are distinct.

The existing `ItemSocket` retains the same InventoryItem while installed and now
provides explicit ejection and visual refresh. INSERT CARD moves a compatible
carried item into that socket; a portion of its real static model projects from
the physical slot. EJECT returns that same object to inventory and removes the
installed visual. Exiting without success leaves it recoverable on reopening.
Ejection during a write cancels the write before returning it. Device deletion
also returns a retained card while releasing its modal. Battery/tape sockets
retain their existing interaction; this does not add a retrieval UI to them.

## Validation and write cycle

`CredentialProfile` is encoder configuration, held in
`data/vale_credential_profile.tres`. It checks credential identity and all three
exact fields: **0614 / IV / 4321**. `614`, incorrect classes, `3142`, `CADB`,
`1073`, and partial input fail. There are no clue-inspection prerequisites,
attempt counters, per-field errors, or progressive hints.

Every credential mismatch reports **CREDENTIAL MISMATCH**, preserves the card,
and permits immediate retry. A match starts **1.2 seconds** of ENCODING with a
write lamp. The cycle can finish after the player exits the panel. On completion,
the same card becomes active, not revoked, Class IV; its description becomes
"An active Class IV access credential issued to Facility Director Warren Vale."
Its inspection snapshot changes ACCESS REVOKED to ACTIVE / CLASS IV without
mutating shared meshes. The CRT reports CREDENTIAL RESTORED / CLASS IV. The card
stays in the socket until explicitly ejected. No macro condition changes here.

## Access and facility reactions

`CredentialDoor` extends the existing hinged door, adds Main Power and credential
compatibility checks, and emits `credential_accepted(item)`. The inner leaf
occupies the original 1.4 x 2.5 m opening (hinge at 28.5, 0, 4.2). First valid
interaction accepts the retained Class IV card and unlocks; the next physically
opens it. Revoked, inactive, insufficient-class, incompatible and still-inserted
cards cannot grant access. The glazing/header remain solid. Ordinary keyed
Observation doors are unchanged.

`SecurityAccess/State` is the sole authoritative `FacilitySecurity` instance.
`security_clearance_valid` is read-only session state; `establish_access()` sets
it once and emits `security_clearance_changed(true)`. Main-level wiring calls it
only on reader acceptance. The encoder has no reference to this state.

Independent consumers then:
- change the Hub's SECURITY CLEARANCE row from INVALID to VALID;
- retain MAIN POWER ONLINE, DIRECTOR AUTHORIZATION REQUIRED and EXIT SEALED;
- illuminate small local access lamps and unlock the Director threshold;
- update the outer terminal to CARD STATUS ACTIVE / CLEARANCE IV.

The Director leaf keeps its existing 2 x 2.5 m opening at (26, 1.25, 8.7), now
hinged from (25, 0, 8.7). It stays closed until the player opens it. Inner Security
retains its desk/rack and gains three static CRTs, conduit and a junction box;
its existing fluorescent becomes more readable on mains. No new clue or puzzle
is inside. Reloading resets Security, both doors and the card.

## Validation and manual testing

`tests/security_access_smoke.gd` tests two fresh sessions, physical E targeting,
real mouse buttons and keyboard entry, modal ownership and viewport fit, power
and compatibility gates, every wrong field/partial alternative, generic failure,
retry, exit/recover/reinsert, cancelling a write by ejection, same-item restoration,
explicit retrieval, updated inventory inspection, no automatic macro completion,
reader acceptance, no auto-open, actual capsule traversal and backtracking through
both open doors, closed-door standing/jumping sweeps, unchanged egress, session
reset, focus loss and device-deletion cleanup. It deliberately does not inspect
clue props. It sets Main Power for isolated branch coverage; the existing
`main_power_smoke.gd` exercises the legal cooperative startup. All prior smoke
suites continue to cover the earlier game.

Run `godot --headless --path . --script res://tests/security_access_smoke.gd`, all
other `tests/*_smoke.gd`, a headless main-scene load, and `git diff --check`.
No manual editor configuration is required.

Manual F5 procedure: complete Observation and Main Power normally, collect Vale's
card, then visit the outer Security encoder. Insert it, try a wrong credential,
exit, reopen and eject; reinsert and enter 0614 / IV / 4321. Watch the write lamp
and confirmation, eject and inspect the active card in inventory. E the inner
Security door to accept it, then E again to open. Walk inside and back, check
Hub status, and open the Director threshold. Emergency Egress must remain sealed.
Check perceived CRT/digit legibility, card insertion visibility, mouse controls,
door swing clearance, lighting and mouse capture in the actual rendered game;
headless tests do not establish visual quality. The write effect is a short
status/lamp cycle, with no added audio or final art.
