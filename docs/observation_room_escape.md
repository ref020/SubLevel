# Milestone 9: badge, drawer, and exit

No manual Godot configuration or Input Map changes are required. F5 runs the
production Observation Room. The finalized grid and solution are recorded in
GAME_DESIGN.md. Mara's original coordinate clue is unchanged.

## Manual test: complete sequence

1. Explore freely. The employee badge at the desk's right edge is inspectable
   before any conversation. E inspects, LMB drag rotates, wheel zooms, and
   Escape/RMB returns. F must not collect the badge. Its grid faces the camera
   initially; check that all row/column labels and numbers are readable.
2. Read the emergency procedure poster and desk symbol order. Enter 4371 at
   the cabinet keypad, then press E on the cabinet leaf to open it.
3. Inspect/take the screwdriver with E/F. At the south vent, use E on each of
   the four screws. After their animations finish, open the grate and activate
   the breaker. Before obtaining the tool, removal must fail.
4. Use the powered intercom. Ask Mara who she is, tell her you are trapped,
   ask what she sees, and direct her to inspect the other side of the window.
   She reports `C3 - A1 - D4 - B2`. Escape ends the conversation.
5. Inspect the badge. Its columns A–D and rows 1–4 resolve those coordinates
   to 4, 7, 7, 8. No solution or explanatory hint is written on the badge.
6. Approach the desk from the right/front, clear of the chair. Aim at the small
   four-window combination plate on the drawer's front, left of its handle.
   Press E. Try 4371: INVALID CODE, with retry after the short feedback delay.
   Enter 4778: the drawer unlocks; the existing code UI closes after feedback.
7. Press E on the drawer front/handle to slide it open. Look down into the tray
   from the right/front. E inspects the key, F takes it. It disappears from the
   tray and remains inspectable through Tab inventory.
8. Approach the exit and press E: the compatible key unlocks it, with brief
   feedback, but it stays closed. Press E again to open it. The key remains
   in inventory and the player is not teleported.
9. Step into the short dark corridor beyond the door. Its sealed end, marked
   PROTOTYPE BOUNDARY, is the current development boundary. No Hub is built.

Before collecting the key, the exit stays locked. Before entering 4778, the
drawer stays locked. Clue inspection is never ordered by hidden flags: knowing
and entering the right code early is allowed, just as with the cabinet.

## Badge and drawer

`employee_badge.tscn` uses the existing Inspectable and static mesh copier.
TextMesh resources make headings, row/column labels, and all sixteen digits
part of the copied 3D visual. The card is worn, with obscured identity markings
clear of the verification grid. There is no employee backstory or pickup data.

`drawer_combination.tscn` uses Keypad validation and the existing modal code UI.
Its compact four-window face differs from the cabinet's keypad geometry.
The room sets correct_code to 4778 and connects correct_code_entered only to
drawer.unlock. The configurable entry_prompt defaults to Use Keypad for all
existing keypads; this one uses Enter Combination. The physical face is
prototype geometry; digit entry is displayed in the modal UI.

The key and combination plate are children of the drawer's moving Body.
A fixed metal sleeve encloses the drawer sides/back/top/bottom and blocks
camera rays to the key while the front is closed. It stays fixed when the
drawer slides. No clue flags or invisible pickup gate are needed.

## Compatible-key architecture

PickupItem and InventoryItem export `unlocks: Array[StringName]`. Collection
copies that list into owned data along with existing metadata and visual data.
The new key contains exactly:

    item_id: observation_exit_key
    display_name: Observation Room Key
    description: A heavy key stamped "OBS-06".
    unlocks: [observation_room_exit]

The primitive key has a ring bow, shaft, teeth, and an OBS-06 mesh-text stamp.

Openable exports an optional PlayerInventory reference. When locked, it checks
owned items for an unlocks entry equal to its nonempty lock_id. A match changes
the prompt to Unlock Door/Drawer. Interaction unlocks and returns immediately;
the next interaction performs the existing opening behavior. Keys are not
consumed or required to be selected. Without inventory or a compatible entry,
the lock remains closed. No item IDs appear in player movement or inventory
logic. Existing code-controlled locks retain their signal-based unlock path.

To add another key, configure its unlocks list and the destination Openable's
lock_id/inventory reference. One item can support multiple locks. No new Door
subclass or global puzzle manager is needed.

## Validation and limits

Run `godot --headless --path . --script res://tests/escape_smoke.gd`.
It runs the production cabinet -> tool -> vent -> power -> Mara -> drawer ->
key -> exit chain using camera targeting and E/F/code/dialogue input. Player
positions are set to known approaches; it is not an automated walking playtest.
It also checks the grid, inspection mesh text, wrong codes, closed-drawer ray
occlusion from standing/jump viewpoints, generic lock compatibility, retained
keys, separate unlock/open steps, and the corridor boundary.

All earlier smoke suites remain applicable. The room navigation test retains
its existing checks and includes the three new interactables in its count.

Headless checks cannot judge final visual readability or physical mouse feel.
The badge is deliberately larger than a modern ID card for prototype clarity.
Existing openable animation does not reverse on obstruction. State resets on
scene restart. The corridor is a sealed development stub, not the Central Hub.
No cassette/note purpose, later puzzles, persistence, NPC systems, or audio
have been added.
