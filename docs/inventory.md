# Milestone 6B: inventory and cabinet collection

No manual editor configuration is required. F5 runs the Observation Room;
open `scenes/levels/inventory_test.tscn` and press F6 for an independent test.

## Interactive test

1. Press Tab before collecting anything: the inventory displays an empty state.
   Try movement, jumping, mouse look, and E; gameplay stays suspended.
   Tab or Escape returns to gameplay.
2. In the test scene, aim at the screwdriver or cassette on the table and press
   E. Rotate with LMB drag and zoom with the wheel. F takes the item, closes
   inspection, and removes its world visuals, collision, and interaction target.
   Escape/RMB instead returns without taking it.
3. Inspect the photograph or asymmetric block: neither offers a Take action.
4. Collect both items, press Tab, and select an entry. Its name and description
   appear. Click Inspect to reuse the existing 3D rotation/zoom presentation.
   Escape/RMB returns to inventory; Tab/Escape then returns to gameplay.
5. Inventory cannot interrupt a world inspection or keypad session. Losing
   focus closes modal views and releases the mouse. Escape recaptures it.
6. In the Observation Room, enter 4371 at the cabinet keypad, then open its
   left door with E. Approach the upper shelf and aim at each small item:
   Screwdriver, Cassette Tape, and Folded Note. Inspect and take each with E/F.
   Revisit the cabinet: collected items remain absent during this scene session.
   Check all three inventory entries and inspect them again.

## Architecture

`InventoryItem` is a Resource containing item ID, name, description, an optional
mesh-only PackedScene, and inspection settings. `PlayerInventory` belongs to
the player, stores unique IDs, and exposes add_item, has_item, get_item,
get_items, remove_item, and select_item. Changes and selection emit signals.
Duplicate or empty IDs are rejected; removing the selected entry clears selection.

`PickupItem` remains an Inspectable subtype. Only world pickups offer F (the
take_item Input Map action). The existing inspection presenter snapshots static
mesh visuals into an InventoryItem, adds it, closes inspection, and immediately
detaches the pickup before freeing it. Failed additions leave the world item intact.
Visual snapshots contain no collision, scripts, or world interaction behavior.

`InventoryUI` uses the inventory signals to show a list and selected metadata.
For 3D inspection it constructs a temporary, noncollectible Inspectable from
the stored visual and sends it to the same inspection presenter. No second
rotation or zoom implementation exists. Entries without visuals disable Inspect.

`PlayerModalInput.transfer(previous_owner, next_owner)` explicitly transfers
an existing session without restoring gameplay or overwriting its saved state:

    gameplay -> inventory -> inspection -> inventory -> gameplay

Other modals still require exclusive acquisition. The inspector remembers its
return owner; returning transfers ownership back to inventory. Only closing the
outer inventory restores gameplay. Focus loss unwinds the nested session.
The movement controller itself is unchanged.

Future world objects can receive a PlayerInventory reference and call
`inventory.has_item(&"required_item_id")`, or read selected_item_id/get_item.
Requirements belong to those objects, never to the generic inventory. No
item-use behavior is implemented here.

## Cabinet and limits

Reusable primitive item scenes replace the inert cabinet props. All three sit
on its upper shelf within standing-camera reach. Their exact requested metadata
is retained; the folded note has only temporary faded-writing description text.
No new clues, cassette purpose, screwdriver use, or other puzzle behavior exists.

Inventory lasts for the player's current scene instance. Restarting resets it.
There is no saving, stacking, dropping, capacity, or item combination. Inspection
supports static mesh hierarchies with shared read-only materials, as before.
Small cabinet objects require precise aiming. Physical capture, lighting, and
visual readability still require an interactive playtest.

## Automated validation

Run `godot --headless --path . --script res://tests/inventory_smoke.gd`.
It covers the independent scene and production cabinet, collection/removal,
metadata, duplicate rejection, selection/removal, noncollectibles, empty UI,
input suppression, modal exclusion, nested inspection, and focus-loss cleanup.
Also run interaction, inspection, door_drawer, keypad, and observation_room
smoke scripts, both relevant scenes headlessly, and `git diff --check`.
