# Milestone 4: inspection and pickup metadata

Open `scenes/levels/inspection_test.tscn` and press F6. No manual configuration
is required. F5 continues to run the original controller test scene.

## Controls and interactive verification

1. Walk toward the three labeled objects. Aim at one within the existing
   3-meter interaction range and press E.
2. Inspection replaces the world view with a centered, lit object and hints.
   Hold LMB and drag to rotate; release and drag again for larger rotations.
   Scroll up to move closer or down to move farther. Zoom has safe limits.
3. Photograph: its blue/green front initially faces you. Rotate it around to
   reveal the red X on its cream-colored back.
4. Asymmetric block: turn it upside down to find the two cyan underside stripes.
   The yellow side tab provides an orientation reference.
5. Test Item: inspect the purple/yellow placeholder. It exposes pickup metadata
   but remains in the world; no take action or inventory exists yet.
6. During inspection try WASD, Space, ordinary mouse movement, and E: the player
   and camera should stay still and no other object should activate.
7. Press RMB or Escape to return. Normal gameplay and captured mouse resume.
   Press Escape again in gameplay to release the mouse as before.
8. Repeat inspection and exit several times. Original position, orientation,
   visibility, and targeting should remain unchanged. Losing application focus
   exits inspection and leaves the mouse released; use Escape after returning.

## Reuse

Inspectable extends Interactable. Configure its inherited interaction_prompt,
visual_root, inspection_distance, rotation_sensitivity (degrees per pixel),
minimum_distance, maximum_distance, and initial_inspection_rotation (degrees).
The visual root defines the object's local axes. Place static MeshInstance3D
visuals under it, and collision bodies beneath the interactable root. World
placement/orientation is deliberately not used as the initial inspection pose.

Mesh bounds are centered and scaled so the longest dimension is 0.8 inspection
units. Zoom distances refer to this normalized representation, not world size.
The minimum distance is clamped to at least 0.85 to protect the near plane; an
invalid maximum is raised to the minimum. Initial distance is clamped too.

PickupItem extends Inspectable with item_id, display_name, and description.
Use `item is PickupItem` to identify pickup capability. The photo/block use
Inspectable directly. No collection, storage, ownership, key matching, item use,
or inventory UI is implemented.

## Input and presentation architecture

The player's camera owns one Inspection node. Inspectable.interact() sends a
request to the inspection_presenter group (one local player is assumed).
The controller emits inspection_started(item) and inspection_ended.

The controller saves and suspends player physics/unhandled input, ray processing
and unhandled input, and the interaction HUD. A generic gameplay_enabled gate
also clears/prevents direct ray interaction calls while suspended. The movement
script does not contain inspection logic. Player velocity is retained while
physics is suspended, so a midair inspection resumes its prior motion on exit.

Inspection handles input in `_input`, consuming Escape/RMB before gameplay can
see them. Exiting restores previous process flags, HUD visibility, and mouse
mode. Focus loss, item deletion, and controller teardown clean up the session.

A full-screen SubViewport uses its own 3D world, camera, ambient illumination,
and directional light. Only static mesh visuals/materials and local transforms
are copied; no scripts, collision, or physics bodies enter the presentation.
The original visual root is hidden temporarily. Its transforms, collision
layers/masks, and body state are never edited. Exit restores its prior visibility
and removes the presentation copy. World interaction is disabled throughout.

## Validation and current limits

```text
godot --headless --path . --script res://tests/inspection_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/door_drawer_smoke.gd
godot --headless --path . res://scenes/levels/inspection_test.tscn --quit-after 120
git diff --check
```

Headless tests simulate the existing captured-input gate; physical mouse capture
and visual presentation still need an interactive playtest.

This first version supports static mesh hierarchies, including imported static
meshes and mesh-based markings. Animated/skinned meshes, particles, Label3D,
and dynamic rigid-body items are not supported inspection assets yet. Use a
static mesh representation for those later. Materials are shared read-only.
The separate inspection view has a plain dark backdrop. Close zoom may crop
edges of wide objects; zoom out to see the whole object. The test floor has open
edges; restart with F6 if you walk off.
