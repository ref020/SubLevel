# Milestone 3: doors and drawers

Open `scenes/levels/door_drawer_test.tscn` and press F6. F5 still runs the
original controller test. No editor setup or new Input Map actions are needed.

## Interactive check

1. Use WASD/mouse to approach the labeled unlocked door on the left. Within
   3 meters, aim at the panel and press E. Verify Open Door -> Opening... ->
   Close Door. The panel swings around its left edge. Walk through the opening.
2. Aim at the open panel and press E again. Stand clear of its sweep and verify
   it closes smoothly and blocks walking through. Tap E rapidly during motion:
   additional presses should be ignored until the animation completes.
3. Approach the locked door. Verify [E] Locked and that E does not open it.
   Aim at its nearby green TEST UNLOCK control and press E, then open/close it.
4. Repeat with the two labeled drawers on the right. Look slightly downward
   at the drawer front, not its gray stand. The tray slides toward you. The
   locked drawer has its own green unlock control.
5. Look away, step out of range, and release mouse capture with Escape. The
   existing targeting and input rules still apply. Escape recaptures the mouse.

## Reuse and state

Instance `scenes/interactables/door.tscn` or `drawer.tscn`. Configure the root's
animation_duration, starts_locked, and lock_id in the Inspector. A door also
exports open_angle (degrees); a drawer exports slide_direction (root-local,
normalized automatically) and travel_distance (meters). Configure these before
the scene starts: closed/open endpoints are captured in `_ready()`. Keep root
scale at one and resize geometry/shapes together when making size variants.

Both scripts inherit Openable, which inherits the existing Interactable.
The existing ray resolves the moving Body to this ancestor; movement, targeting,
HUD, input bindings, and the original test scene are unchanged.

Openable exposes `state` (CLOSED, OPENING, OPEN, CLOSING), `is_locked`, `lock_id`,
`unlock()`, and `lock()`. Treat state/is_locked as read-only to callers.
`lock()` returns false unless fully closed. Lock/unlock calls are idempotent.
Future item systems can compare lock_id against their own rules and call unlock;
no key rules are embedded here.

Signals: `opened`, `closed`, `unlocked`, `locked`. Motion signals fire on arrival;
lock signals fire only on an actual lock-state change. Interactions while moving
are ignored. During motion prompts say Opening... or Closing....

The door's AnimatableBody3D origin is its side hinge, with panel mesh and shape
offset together. The drawer's tray mesh and shapes share one AnimatableBody3D.
Physics updates interpolate between saved local endpoints with smooth easing;
completion assigns the exact endpoint to avoid cumulative drift.

The unlock controls are isolated test fixtures, not inventory or puzzle mechanics.

## Validation

From the project folder (substitute your Godot executable):

```text
godot --headless --path . --script res://tests/door_drawer_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . res://scenes/levels/door_drawer_test.tscn --quit-after 120
git diff --check
```

The tests simulate only the captured-input gate because the headless display
driver cannot capture a mouse. Interactive visual feel still needs playtesting.
Motion is scripted, not a simulated free-swinging hinge. There is no obstruction
detection or automatic reversal: moving parts can push/overlap a player standing
in their path. Stand clear during these prototype tests. The dedicated test floor
has open edges; F6 restarts the scene if you walk off.
