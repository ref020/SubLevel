# Milestone 6A: keypad and emergency cabinet

No editor configuration is required. F5 still starts the Observation Room.
The canonical poster, desk order, and clock are unchanged. No new clues exist.

## Interactive test

1. Press F5. Approach the west-wall emergency cabinet. Aim at the left door:
   it reports Locked. Aim at the small keypad on its right and press E.
2. Click digits or type top-row/numpad numbers. Backspace removes one digit;
   C clears the entry. Enter or the ENTER button submits. Input is limited to
   the configured length. Escape or RETURN cancels and restores gameplay.
3. Try an incorrect code. INVALID CODE appears for 0.8 seconds, then the entry
   clears and you can retry. Movement, jumping, look, and world interactions
   remain suspended throughout keypad mode.
4. Enter 4371. ACCESS GRANTED appears briefly; the cabinet unlocks immediately
   and the UI returns to gameplay after 0.8 seconds. Aim at the left door and
   press E to open it smoothly. Press E on the open leaf to close it.
5. Inspect the revealed interior visually: screwdriver, cassette, and blank
   note are nonfunctional geometry. Nothing is collectible or usable yet.
6. Revisit the keypad: it displays UNLOCKED and requires no further code. It
   remains unlocked for this scene instance; restarting the scene resets it.
7. Open `scenes/levels/keypad_test.tscn` and press F6 to test an independent
   keypad connected to the existing Door scene. Its code is 2580.
8. Verify Escape, focus loss, normal interaction, and object inspection still
   work. Losing window focus exits the UI and leaves the mouse released.

## Architecture and reuse

`Keypad` extends Interactable. `correct_code` is a string so leading zeros are
preserved; `code_length` sets the length (1–12 digits). Configure both to agree.
`submit_code()` checks exact numeric content and emits `correct_code_entered`
once, or `incorrect_code_entered` for failure. `succeeded` persists in the scene
instance. No cabinet names, inventory, or global puzzle state appear in it.

Instance `scenes/interactables/keypad.tscn`, configure the code/length, and connect
`correct_code_entered` to an Openable's `unlock()` or another signal receiver.
The independent test scene demonstrates Keypad -> Door. The reusable cabinet
scene demonstrates Keypad -> Cabinet leaf. Godot disconnects freed receivers.

The shared `PlayerModalInput` node saves/restores player physics and unhandled
input, interaction-ray processing and gameplay gate, HUD visibility, and mouse
mode. Both inspection and keypad UI acquire this owner; a second modal cannot
take over an active session. Movement remains unchanged. Inspection retains
its visual-copy lifecycle and delegates only input suspension/restoration.

`keypad_ui.tscn` contains real Buttons and a display. Its script owns temporary
entry and feedback. Keyboard events are consumed before gameplay; mouse events
reach Controls normally. Feedback blocks duplicate submissions. Escape, focus
loss, deleting the active keypad, and UI teardown restore the saved input state.

The cabinet retains its original west-wall transform and approximate outer
dimensions. A hollow fixed shell replaces the solid block. A narrow fixed
right post holds the keypad; the left leaf has an AnimatableBody3D whose mesh
and collision rotate together. `cabinet.gd` inherits the existing door motion
and only changes the prompt noun. The signal connection calls `unlock()`; no
cabinet-specific validation exists. There is no automatic opening or relock.

## Validation and limitations

`tests/keypad_smoke.gd` covers both scenes, actual GUI click routing, keyboard
and numpad input, length/leading zeros, clear/backspace, wrong/right submissions,
signals, repeat Enter, persistent success, movement/look/world-input blocking,
modal exclusion, cancellation, focus loss, deletion, and physical opening.
The headless test explicitly sizes its viewport for real GUI hit-testing.

```text
godot --headless --path . --script res://tests/keypad_smoke.gd
godot --headless --path . --script res://tests/observation_room_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/inspection_smoke.gd
godot --headless --path . --script res://tests/door_drawer_smoke.gd
git diff --check
```

Headless tests simulate mouse capture, so physical capture and final visual feel
still need interactive review. The existing openable motion has no obstruction
reversal; stand clear of the swinging leaf. Prototype UI assumes a normal game
window size. No save persistence, item collection/use, vent/switch functionality,
dialogue, or later puzzle logic is included.
