# SUBLEVEL

3D first-person escape-room game built in Godot 4.7.2.

Language: GDScript
Renderer: Forward+

## Coding Rules

- Use typed GDScript where practical.
- Prefer reusable components over puzzle-specific duplicated code.
- Keep puzzle state separate from visual presentation.
- Do not hardcode dependencies between unrelated puzzles.
- Use signals for communication between systems.
- Player interaction must use the shared interaction system.
- All interactable objects should derive from the common
  interactable architecture.
- Do not modify established puzzle solutions unless explicitly
  requested.

## Project Structure

/scenes
/scripts
/assets
/ui
/audio

## Core Systems

- First-person controller
- Interaction system
- Inventory
- Object inspection
- Puzzle manager
- Dialogue
- NPC commands
- Notebook
- Save/load
- Game state

## Game

SUBLEVEL is a difficult first-person virtual escape room inspired
by games such as TRACE.

The player wakes inside the abandoned Halcyon Research Facility.

The final exit requires:

1. Main power
2. Security clearance
3. Director authorization

NPCs:
- Mara — Subject 02
- Elias — maintenance technician

The player communicates with and directs these NPCs.
Mara and Elias must also be capable of communicating with each
other and performing actions that affect puzzles.

Puzzle philosophy:
Important puzzles generally require connecting multiple clues.
Avoid simple "find code -> enter code" puzzles.