# SUBLEVEL — Codex Project Instructions

## Project

SUBLEVEL is a difficult 3D first-person virtual escape-room game built in Godot 4.x using GDScript.

The game is inspired by the puzzle philosophy of games such as TRACE, but all environments, characters, story, puzzles, dialogue, and assets must be original.

The player wakes inside Sublevel 6 of the abandoned Halcyon Research Facility and must escape.

The game should emphasize:
- interconnected puzzles
- environmental observation
- manipulating physical objects
- information discovered long before it becomes useful
- NPC communication
- directing NPCs
- NPC-to-NPC interaction
- minimal hand-holding

Read GAME_DESIGN.md before implementing gameplay or puzzle-specific behavior.

---

# Development Rules

## General

- Use Godot 4.x APIs only.
- Use GDScript.
- Use typed GDScript where practical.
- Prefer simple, maintainable implementations over unnecessary complexity.
- Avoid deprecated Godot APIs.
- Do not introduce plugins or external dependencies without permission.
- Do not modify established puzzle solutions without explicit instruction.
- Do not invent major story elements or puzzles unless requested.
- Do not delete working systems merely to replace them with a different architecture.
- Keep systems modular so individual puzzles can be changed without breaking unrelated puzzles.

## Architecture

Prefer reusable systems over puzzle-specific duplicated code.

Major systems will include:

- First-person player controller
- Interaction system
- Object inspection
- Inventory
- Puzzle state management
- Dialogue
- NPC behavior
- NPC commands
- NPC-to-NPC communication
- Notebook
- Save/load
- Audio
- Game state

Use signals where appropriate to reduce tight coupling between systems.

Puzzle logic should be separated from visual presentation whenever practical.

Global state should not be scattered throughout unrelated scripts.

---

# Interaction Architecture

The player should eventually be able to:

- look at interactable objects
- see an interaction prompt
- interact
- pick up certain objects
- inspect objects
- rotate inspected objects
- operate buttons
- operate switches
- enter keypad codes
- open drawers
- open doors
- use terminals
- communicate with NPCs

Do not create a separate player interaction implementation for every object.

Create reusable interaction abstractions.

---

# Puzzle Design Rules

Important puzzles should generally require the player to connect two or more clues.

Avoid puzzles equivalent to:

"Find 3917 written on a note, then type 3917 into a keypad."

Clues may:
- appear before their corresponding puzzle
- require transformation
- depend on environmental information
- require information from NPCs
- require NPC actions
- require communication between NPCs
- become meaningful much later

Some environmental objects may be irrelevant.

Do not automatically highlight every clue or tell the player when something is important.

---

# NPC Requirement

NPC interaction is a core assignment requirement, not optional flavor.

Primary NPCs:

## Mara
Subject 02.

Mara is trapped elsewhere in the facility.

She can:
- talk to the player
- inspect things in her environment
- provide information unavailable to the player
- operate certain devices
- receive instructions
- communicate with Elias

## Elias
Maintenance technician.

Elias is trapped in a maintenance section.

He can:
- talk to the player
- explain facility equipment
- move between accessible locations
- operate machinery
- receive instructions
- communicate with Mara

Some puzzles must require NPC actions.

Some puzzles must require NPC-to-NPC communication.

---

# Current Development Strategy

Build vertically.

Do NOT attempt to construct the entire game immediately.

Current prototype target:

OBSERVATION ROOM

Required prototype flow:

1. Player wakes in Observation Room.
2. Player explores room.
3. Player discovers emergency procedure poster.
4. Player discovers symbols scratched into desk.
5. Player derives cabinet combination 4371.
6. Player opens cabinet.
7. Player obtains screwdriver.
8. Player removes ventilation grate.
9. Player activates hidden switch.
10. Intercom becomes active.
11. Player communicates with Mara.
12. Mara provides information visible only from her location.
13. Player uses that information to obtain the Observation Room key.
14. Player unlocks the exit.
15. Player enters the Central Hub.

Do not build later areas until the prototype systems are working.

---

# Current Development Order

Implement systems in approximately this order:

1. First-person controller
2. Basic test environment
3. Interaction system
4. Doors/drawers
5. Pickups
6. Object inspection
7. Interaction HUD
8. Keypad
9. Inventory
10. Puzzle state
11. Dialogue
12. Observation Room puzzle
13. Mara interaction
14. Observation Room completion

Do not jump significantly ahead unless explicitly instructed.

---

# Testing

After meaningful changes:

- check for GDScript parse errors
- check node paths
- check signal connections
- check null references
- verify Input Map actions
- keep scenes runnable independently where practical

When implementing a feature, explain any required manual Godot Editor configuration that cannot safely be performed through project files.

Do not claim something was tested if it was not actually run.

---

# Documentation

GAME_DESIGN.md is the canonical source for:
- story
- puzzle solutions
- clue placement
- NPC information
- level progression

AGENTS.md is the canonical source for:
- coding conventions
- architecture
- development process

If implementation and GAME_DESIGN.md conflict, do not silently change the design. Flag the conflict.