# SUBLEVEL
## Game Design Document

Status: Pre-production / Prototype

---

# 1. High Concept

SUBLEVEL is a difficult first-person 3D escape-room game set inside an abandoned underground research facility.

The player must investigate the environment, manipulate objects, interpret documents, communicate with trapped NPCs, and connect clues across multiple rooms to escape.

The game should reward observation and deduction rather than trial-and-error combination guessing.

---

# 2. Setting

Location:

Halcyon Research Facility
Sublevel 6

The facility appears to have been abandoned following an unknown incident.

The player wakes inside an Observation Room without knowing why they are there.

The final emergency exit is visible relatively early in the game.

Opening it eventually requires:

1. Main Power
2. Security Clearance
3. Director Authorization

These become the game's three major interconnected puzzle branches.

---

# 3. Player

The game is first-person.

Core capabilities will eventually include:

- Walk
- Look
- Jump
- Crouch if required
- Interact
- Pick up objects
- Inspect objects
- Rotate inspected objects
- Carry puzzle items
- Operate environmental controls
- Communicate with NPCs
- Direct NPCs
- Record/review information in a notebook

The player has no combat abilities.

---

# 4. NPCs

## Mara

Designation:
Subject 02

Location:
Initially unknown to the player.

Mara is trapped elsewhere in Sublevel 6.

Her physical separation from the player allows puzzles in which she can observe information the player cannot.

Mara can eventually:

- converse with the player
- describe objects
- inspect parts of her environment
- operate certain controls
- remember information
- receive instructions
- communicate with Elias

---

## Elias

Occupation:
Halcyon maintenance technician.

Elias has knowledge of facility infrastructure but does not know every security or research system.

He should provide contextual information rather than simply solving puzzles for the player.

Elias can eventually:

- converse with the player
- explain machinery
- move between accessible maintenance locations
- operate equipment
- receive player instructions
- communicate with Mara

---

# 5. Facility Structure

Planned major areas:

- Observation Room
- Central Hub
- Laboratory
- Archive
- Maintenance Corridor
- Generator Room
- Security Area
- Final Exit

Exact layout is not finalized.

---

# 6. Puzzle Philosophy

SUBLEVEL should be difficult but fair.

Important puzzles should usually involve multiple pieces of information.

The player should frequently encounter clues before understanding their purpose.

Desired player experience:

"I've seen that before."

rather than:

"The game just told me the answer."

Puzzle information may come from:

- documents
- object placement
- symbols
- clocks
- maps
- photographs
- employee records
- machines
- audio
- object inspection
- NPC dialogue
- NPC observations
- NPC actions
- NPC-to-NPC communication

Some interactable objects may have no puzzle significance.

---

# 7. Prototype Level — Observation Room

The Observation Room is the first playable level and teaches the game's systems through gameplay.

## Environment

Initial planned objects:

- desk
- computer
- mug
- photograph
- pencil
- locked desk drawer
- damaged employee badge
- wall clock
- emergency procedures poster
- ventilation grate
- cabinet with four-digit lock
- observation window
- intercom
- exit door

Additional decorative objects may be added.

---

# 8. Puzzle — Emergency Cabinet

The cabinet uses a four-digit combination.

A wall poster contains:

EMERGENCY RESPONSE PROCEDURE

FIRE ................. 4
CHEMICAL ............. 7
ELECTRICAL ........... 3
CONTAINMENT .......... 1

Symbols scratched into the desk appear in this order:

FIRE
ELECTRICAL
CHEMICAL
CONTAINMENT

Therefore:

FIRE -> 4
ELECTRICAL -> 3
CHEMICAL -> 7
CONTAINMENT -> 1

Solution:

4371

The stopped wall clock displays 4:37 and serves as an intentional misleading clue.

The clock alone must not solve the cabinet.

---

# 9. Cabinet Contents

Opening the cabinet currently provides:

- screwdriver
- cassette tape
- note

The screwdriver is required immediately.

The cassette and note are intended for later use.

Their exact later functions are not yet finalized and should not be invented during implementation.

---

# 10. Ventilation Puzzle

The screwdriver allows the player to remove a ventilation grate.

A hidden switch is located behind the grate.

Activating the switch restores power to part of the Observation Room and enables the intercom.

---

# 11. First Mara Interaction

After the hidden switch is activated, the intercom becomes usable.

The player speaks to Mara for the first time.

Mara can see writing on the opposite side of the Observation Room window that the player cannot read from their position.

The writing is:

C3 - A1 - D4 - B2

This information is used in a later step of the Observation Room escape.

The damaged employee badge on the small middle table has a SECURITY VERIFICATION grid.
It is inspectable but not collectible. Columns are A–D and rows are 1–4:

|   | A | B | C | D |
|---|---|---|---|---|
| 1 | 7 | 2 | 9 | 4 |
| 2 | 3 | 8 | 1 | 6 |
| 3 | 5 | 0 | 4 | 2 |
| 4 | 9 | 6 | 3 | 7 |

Mara's coordinate order gives C3 = 4, A1 = 7, D4 = 7, B2 = 8.
The finalized desk drawer combination is **4778**. Correct entry unlocks
the drawer; the player must then open it physically. Clues may be inspected
in any order; code entry does not require artificial clue-discovery flags.

---

# 12. Observation Room Exit

The locked desk drawer contains the collectible Observation Room Key:
item_id `observation_exit_key`, description `A heavy key stamped "OBS-06".`
It declares compatibility with lock_id `observation_room_exit`.

The player inspects and takes the key. Interacting with the locked exit while
carrying it unlocks the door without consuming the key. A second interaction
opens the door; unlocking does not automatically open it or move the player.

Opening the door leads to the Central Hub.

Milestone 9 ends at a sealed, temporary dark corridor beyond the exit.
The Central Hub itself is not built yet.

The Observation Room prototype is complete when this entire sequence can be played successfully.

---

# 13. Main Game Objectives

After reaching the Central Hub, the player eventually discovers that the final exit requires:

## Main Power

Primarily associated with:
- maintenance systems
- Elias
- Generator Room

## Security Clearance

Primarily associated with:
- Director Warren Vale
- access card
- security systems

A director access card is eventually discovered with revoked permissions.

Later, the player discovers a way to rewrite its permissions.

## Director Authorization

The most complex of the three branches.

The final authorization is derived from several clues throughout the facility rather than being directly written down.

Exact puzzle chain is not finalized.

---

# 14. Known Future Clue

An item associated with Dr. Warren Vale contains:

107.6 MHz

Later, the player discovers a calibration error:

-0.3 MHz

The intended frequency is therefore:

107.3 MHz

A radio tuned to 107.3 MHz eventually provides puzzle information.

Exact downstream puzzle is not finalized.

---

# 15. Design Status

FINALIZED:

- Core premise
- Halcyon Research Facility
- Mara
- Elias
- Three final exit requirements
- Observation Room cabinet solution: 4371
- Screwdriver -> ventilation grate
- Hidden switch -> intercom
- Mara sees C3-A1-D4-B2
- Employee badge grid interprets C3-A1-D4-B2 as desk drawer code 4778
- Observation Room key is inside locked desk drawer
- 107.6 / -0.3 -> 107.3 concept

NOT FINALIZED:

- Full facility layout
- cassette purpose
- cabinet note purpose
- complete Power puzzle chain
- complete Security puzzle chain
- complete Authorization puzzle chain
- ending
- full narrative explanation
