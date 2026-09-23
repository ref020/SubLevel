# Milestone 7: vent and auxiliary power

No editor setup or new Input Map actions are required. F5 runs the production
Observation Room. No later puzzle solutions or dialogue are implemented.

## Manual test

1. Before collecting the screwdriver, approach the south-wall vent. Aim at each
   corner fastener: E examines it and briefly displays "I need something that
   fits this." E on the panel reports "The grate is still secured."
2. Try the north-wall intercom: E displays "No power." Its small indicator is
   dark and the desk CRT has no standby glow.
3. Solve the cabinet with 4371, open its door with E, inspect the screwdriver
   with E, then take it with F. No inventory selection/equipping is necessary.
4. Return to the vent, standing about 1.5 m back so all corners are visible.
   Aim at each screw and press E. Each rotates three turns and backs out over
   0.75 seconds, then disappears. Repeated presses do not restart it. Try the
   grate after one, two, or three screws: it must remain secured.
5. After four completed removals, aim at the panel and press E to Open Grate.
   It folds down on its bottom hinge and remains attached. Its collision moves
   with it. The wiring and breaker inside the existing cavity are now accessible.
6. Aim through the opening at the breaker and press E. The handle moves to ON,
   the intercom indicator illuminates, and the CRT gains a subtle standby glow.
   Repeated presses cannot turn auxiliary power off.
7. Return to the intercom: E displays "The intercom is active." No dialogue
   starts. Check Tab inventory: the screwdriver remains; cassette/note are
   unaffected. Restarting the scene resets the puzzle.

## Reuse and ownership

`RequiredItemInteractable` exports an inventory reference, required_item_id,
missing/ready prompts, and a missing-tool message. It queries PlayerInventory
without changing it. Other tool-dependent objects can inherit this class and
call check_requirement(); the generic inventory knows nothing about tools.

`VentFastener` adds removing/is_removed state and a removed signal. Its visual
tween is bound to the node, ignores repeated activation, and disables collision
on completion. Its slotted head makes axial rotation visible. Hitboxes are
slightly larger than the small physical heads for prototype targeting.

`vent_grate.gd` extends the existing Openable. It counts the four fasteners'
completed states and unlocks only at four. The ordinary Openable animation
moves the panel and collider together. This panel opens once and stays open.
The opaque backing blocks camera rays, including while secured; the breaker
also refuses activation until the fully-open signal enables it.

`power_breaker.gd` is a reusable latching Interactable with a physical lever,
is_on state, and an activated signal. It does not know about rooms/intercoms.

`observation_power.gd` is a level-local node with explicit scene references.
It supplies inventory to the screws and wires grate.opened -> breaker access,
breaker.activated -> auxiliary power. Activation is idempotent and updates the
intercom and CRT standby presentation, then emits auxiliary_power_activated.
Existing room illumination is retained; this is not main facility power.

The intercom exposes powered state and powered_interaction. A future dialogue
controller should connect to powered_interaction. That signal never fires
without power; the intercom has no NPC, conversation, or clue knowledge.

Interactable.feedback() sends text to the local interaction_feedback HUD group.
The HUD displays a single 2.5-second message; newer messages replace older ones.
It never acquires modal input. It is hidden with the existing HUD during modal
views. Like the existing presenters, this assumes one local player.

## Validation and limits

Run `godot --headless --path . --script res://tests/vent_smoke.gd`.
The test uses the production cabinet/tool, standing-camera rays to all screws
and the breaker, timed removal/opening, missing-tool messages, repeat guards,
tool retention, and local power/intercom signals. Existing inventory, keypad,
inspection, door_drawer, interaction, and observation_room suites also apply.

The room itself is the integration test scene; reusable panel/fastener/breaker
scenes can be instanced elsewhere. Wire their inventory/access references when
reusing them. No save/load, sound, first-person tool/hand rig, or dialogue exists.
The rotating/backing-out screw supplies the requested prototype tool feedback.
Small target readability, dim-cavity appearance, and physical mouse capture
still need an interactive visual playtest. The existing Openable movement does
not reverse on obstruction; stand clear of the downward-opening panel.
