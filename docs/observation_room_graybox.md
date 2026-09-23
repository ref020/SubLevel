# Observation Room 06 — milestone 5 graybox

F5 now launches `scenes/levels/observation_room.tscn`. No editor configuration or
external assets are required. All earlier test scenes remain available with F6.

The graybox includes the Milestone 6A cabinet keypad (see keypad.md) and
Milestone 6B collectible cabinet items (see inventory.md).
Milestone 7 adds the vent/auxiliary-power sequence (see vent_auxiliary_power.md).
Milestone 8 adds first contact with Mara through the powered intercom (see dialogue.md).
Milestone 9 completes the badge/drawer/key escape sequence (see
observation_room_escape.md). The exit leads only to a sealed development stub.

## Scale and provisional layout

The interior is 9 m east–west, 7 m north–south, and 3.2 m tall. North is -Z;
east is +X. Walls are 0.3 m thick. The existing player remains human-scale.

```text
                        NORTH (-Z)
       clock       observation window       intercom
       desk         dark bay behind          filing unit
  cabinet               low utility shelf       poster
                                             locked exit
       bench / player start       fixed vent
                        SOUTH (+Z)
```

- The northwest desk is 2.2 m wide with a desktop at 0.82 m. It contains the
  existing drawer scene, uniformly scaled to 0.55 and placed under the top.
  Its front projects slightly beyond the desktop for standing interaction.
  The extra handle is parented to its moving body. A displaced chair leaves
  access from the desk's right/front side.
- The north window is approximately 3.2 m wide and 1.45 m high, with a sill
  at 1 m. A sealed, inaccessible dark bay extends approximately 1.7 m beyond it.
  The far face of the glass is reserved for future writing; none exists now.
- The east exit uses the 1.4 × 2.4 m door scene. Its wall opening and frame
  match the leaf. A short sealed corridor provides a development boundary;
  no Central Hub is constructed.
- The south vent has a sealed recess approximately 0.5 m deep. Its four screws
  require the screwdriver; the panel folds down to expose an auxiliary breaker.
- The cabinet occupies the west side; the procedure poster is on the east wall
  near the exit/intercom side, separated from the keypad's close viewpoint. The stopped clock
  is above the desk. The poster and desktop labels retain the canonical clue
  values/order. Their derived code now unlocks the cabinet keypad.

These placements are provisional graybox decisions, not finalized puzzle design.
Review the relationship between the window and Mara's future viewpoint, the
vent reach/depth, and the desktop clue readability before later puzzle work.
GAME_DESIGN.md remains unchanged; no solutions or missing mechanisms were added.

## Scene organization and behavior

Top-level groups: Environment, Architecture, Furniture, PuzzleProps, Lighting,
and the reused Player instance. Geometry and materials are stored directly in
the scene and can be edited in Godot. No runtime level-generation script exists.

Existing systems used:

- Player with interaction HUD and inspection presenter.
- Door: starts locked, lock_id `observation_room_exit`.
- Drawer: starts locked, lock_id `observation_desk_drawer`.
- Photograph: inherits the existing inspectable photo. The production variant
  hides its test-only red X without modifying the original test asset.
- Mug: new primitive prop using the existing Inspectable script. No clue marks.

The exit, desk drawer, photograph, mug, cabinet leaf, keypad, and three cabinet
items are interactable, as are the vent, four screws, breaker, intercom,
employee badge, drawer combination plate, and collectible exit key.
There are no debug unlock controls.

The cabinet has a functional four-digit keypad and an openable leaf. The
poster reads FIRE 4 / CHEMICAL 7 / ELECTRICAL 3 / CONTAINMENT 1. Desktop labels
read FIRE / ELECTRICAL / CHEMICAL / CONTAINMENT from left to right. Clock hands
are fixed at 4:37 (minute 222 degrees; hour 138.5 degrees clockwise from twelve).
The intercom now responds to auxiliary power; the CRT gains standby glow.
The badge carries the inspectable verification grid. The pencil, keyboard,
and other furniture remain nonfunctional.

Olive lower-wall paint, concrete/plaster, tile seams, muted metal, wood,
fluorescent housings, conduit, pipes, filing furniture, and sparse surface wear
establish the institutional setting. Lighting is local and deliberately simple.

## Interactive verification

1. Press F5. Confirm the player begins by the south bench facing into the room.
2. Walk the central floor and approach the desk, cabinet/poster, window,
   intercom, vent, and exit. Try walking/jumping against boundaries and glass.
3. Aim at the east door: expect [E] Locked. E must not open it.
4. Approach the desk from the right/front and aim below the desktop at the
   drawer's front: expect [E] Locked. E must not open it.
5. Aim at the flat photograph or mug on the desktop and press E. Drag LMB to
   rotate, wheel to zoom, RMB/Escape to return. Verify each stays on the desk.
6. Read the east-wall poster and desktop labels. Inspect the analog clock visually.
   Test the cabinet as described in keypad.md, then follow vent_auxiliary_power.md.
7. Check lighting and label readability in your normal game-window size.
8. To revisit earlier tests, open their scene and press F6; F5 remains the room.

## Automated validation

Visual-playtest revision: a mounted room placard replaces floating identity text;
the intercom's floating label is removed. South-wall conduit, a junction box,
and return pipe place the unchanged vent among ordinary services. A 0.95 × 0.55 m
low shelf at (1.15, 0, 0.8) holds a box, binders, and a blank clipboard. Blank
papers and a stapler sit at the desk's left edge, clear of the clue area. A small
greenish fluorescent fixture adds local east-side fill; ambient lighting and the
dark observation bay remain unchanged. All additions are non-interactable.

`tests/observation_room_smoke.gd` checks main-scene configuration, nonoverlapping
spawn, connected capsule-sized navigation approaches, standing/jump-height
boundary sweeps, locked-door/drawer targeting and refusal to open, photograph
and mug inspection/restoration, clock angles, and the restricted interactable set.
Furniture participates in navigation checks. Boundary sweeps isolate the shell
so furniture overlap cannot distort the wall result.

```text
godot --headless --path . --script res://tests/observation_room_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/door_drawer_smoke.gd
godot --headless --path . --script res://tests/inspection_smoke.gd
godot --headless --path . --quit-after 120
git diff --check
```

Headless tests cannot judge final appearance, glass transparency, lighting,
physical mouse capture, or small-text readability. Navigation samples establish
access to the main stations, not an exhaustive traversal of every possible jump.
Primitive shapes and the mug's dark top are placeholders, not finished models.
