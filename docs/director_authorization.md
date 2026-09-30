# Milestone 12A: Director primary authorization

PRIMARY AUTHORIZATION = IMPLEMENTED.
SECONDARY / COMPLETE DIRECTOR AUTHORIZATION = IMPLEMENTED in Milestone 12B.
See [director_secondary.md](director_secondary.md) for routing, relay and finalization.
FINAL EMERGENCY EGRESS RELEASE = IMPLEMENTED in Milestone 13; see [final_egress.md](final_egress.md).
The following describes the earlier authorization stage.

The following describes the primary stage and its intermediate endpoint.

## Layout and clues

The existing 6 x 5 m Director shell and Security-released doorway are unchanged.
A separate DirectorOffice layer adds a laminate desk/CRT toward the south,
metal document cabinet on the east, evacuation map on the west, storage/binders,
a chair, paperwork, dictation unit, wall clock and two local fluorescent fixtures.
The desk leaves a clear east-west approach to the cabinet. No navigation boundary,
existing clue, NPC dialogue, movement or interaction-range setting changes.

The noncollectible evacuation map is at (23.65, 1.7, 11.65), facing east.
Its alphabetical legend maps Administration=square, Archive=plus,
Containment=diamond, Laboratory=circle and Maintenance=triangle. A restrained
route schematic provides ordinary map context, not a playable new location.
The noncollectible Archive incident register is at (16.15, 1.5, 8.84), facing south.
It lists Containment, Laboratory, Archive, Maintenance, Administration in numbered
priority order with emergency-operations/records formatting and no symbols.
Both use inspectable TextMesh surfaces and can be discovered in either order.
No inspection-history flags exist.

Combining these clues yields diamond, circle, plus, triangle, square. This
explanation is documentation only, not supplied by gameplay or NPCs.

## Symbol cabinet

SymbolLock is a reusable Interactable with a configurable five-symbol sequence
and solved/rejected signals. A physical raised-button plate opens SymbolLockUI,
which owns the existing PlayerModalInput session. Mouse buttons or keys 1-5
select circle, triangle, square, diamond, plus. Enter submits, C resets,
Backspace removes a symbol, Escape exits. Failure displays SEQUENCE REJECTED,
clears the entry, and permits immediate retry without identifying any position.
Success emits solved to the existing Openable cabinet door's unlock method.
The leaf stays closed until a separate world interaction opens it.

The new original halcyon_symbols.ttf contains only five geometric symbol glyphs
(and a missing-glyph box); it avoids platform font substitutions. Ordinary UI
letters use the existing fallback font. No external dependency or font was added.

## Module and terminal

The cabinet module uses PickupItem and the existing E inspect / F take flow:
- item_id: director_authorization_module
- display_name: Director Authorization Module
- description: A hardware authorization token issued for the facility director's emergency terminal.
- installation tag: director_primary_token

The cartridge has a keyed ridge, pull and brass contacts rather than a card form.
The cabinet casing/leaf occlude it; its interaction collider is enabled only
after the leaf has fully opened, disabled on closing. The wiring safely tolerates
its removal after pickup.

The beige authorization CRT at (27.05, 1.11, 12.57) faces north. Its separate
physical socket uses PoweredItemSocket, a mains-gated extension of ItemSocket.
It accepts installation tags, not a hardcoded player item ID. E at the socket
deliberately removes the same InventoryItem from carried inventory, retaining
it and its physical visual at the terminal. No normal ejection is offered or
required by this milestone; the inherited architecture still supports ejection.
The portable battery cannot energize this socket or terminal.

The powered CRT initially shows PRIMARY TOKEN: NOT PRESENT and SECONDARY:
UNAVAILABLE / AWAITING PRIMARY. Installation begins a one-second validation.
During validation the terminal gives brief feedback rather than opening a stale
inspection snapshot. Afterward E on the CRT provides a readable inspection:
PRIMARY AUTHORIZATION: ACCEPTED; SECONDARY AUTHORIZATION: REQUIRED;
SECONDARY TERMINAL: SERVICE CONTROL M-4; NETWORK LINK: OFFLINE.

## State and endpoint

DirectorOffice/State (FacilityDirector) owns session-only primary acceptance.
accept_primary emits primary_authorization_changed once. The read-only
director_primary_authorized becomes true, while director_authorization_valid
remains false at this primary stage. Milestone 12B completes it separately. New scene
instances reset primary state. The Hub remains Director Authorization REQUIRED,
EXIT SEALED. Main Power and Security Clearance are unaffected.

A backed SERVICE CONTROL / M-4 designation is mounted on the existing remote
Generator service equipment at (33.638, 1.4, -12.3), facing west. The existing
full collision grille remains. Milestone 12B adds a remotely operated READY
indicator and secondary progression; there are no player-accessible M-4 controls
or final egress release.

## Validation and manual playtest

Run tests/director_office_smoke.gd with Godot --headless --path . --script.
It exercises both clue orders and no-clue success, actual ray/E targeting,
mouse symbol input, failed retry, exclusive modal ownership, physical entry,
cabinet access, F collection, exact metadata, retained socket item, timed primary
acceptance, inspected M-4 text, unchanged Hub state, blocked service side, glyph
availability, text margins and sampled clear office approaches. Security access
smoke independently covers the full card rewrite/acceptance gate.

Manual F5 procedure:
1. Complete existing Main Power and Security progression, then open the Director door.
2. Inspect the west-wall map and the Archive north-wall incident register, in either order.
3. At the east-wall cabinet try an incorrect sequence, then diamond/circle/plus/triangle/square.
4. Exit the modal, open the cabinet manually, E inspect its cartridge and F take.
5. Read the desk CRT, E at its separate token socket, wait briefly, then read the CRT again.
6. Confirm M-4/OFFLINE, the sealed egress and the unchanged Director REQUIRED status.

No manual editor configuration is required. A rendered playtest is still needed
for lighting, map/CRT legibility, furniture composition and mouse feel; headless
geometry/text checks do not substitute for a visual review.
