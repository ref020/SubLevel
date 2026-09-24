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

Canonical major areas:

- Observation Wing / Observation 06
- Central Hub
- Laboratory
- Archive
- Maintenance
- Generator
- Security
- Director's Office
- Emergency Egress

Observation 06 exits through an institutional service corridor toward the
Central Hub, the geographic anchor. The Hub connects toward Laboratory,
Archive, Maintenance, Security, and Emergency Egress. Generator access branches
through Maintenance; the Director's Office belongs to the Security /
administrative side. Broad progression is nonlinear and interconnected, with
compact routes and easy backtracking. Graybox dimensions remain provisional.

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

Their future purposes are finalized in sections 13-14 below. In Milestone 10A,
their existing item descriptions and behavior remain unchanged; those future
systems and clue presentations are not implemented yet.

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

Milestone 10A extends the former temporary corridor into the Central Hub and
adjacent graybox wings. Post-Observation equipment remains nonfunctional.

The Observation Room prototype is complete when this entire sequence can be played successfully.

---

# 13. Post-Observation Design and Main Game Objectives

The finalized concepts below are canonical for FUTURE implementation.
Milestone 10A implements only documentation, layout, navigation, and atmosphere.
It does not implement these puzzle systems, new dialogue, or Elias.

The final emergency egress requires all three macro conditions:

- MAIN POWER
- SECURITY CLEARANCE
- DIRECTOR AUTHORIZATION

The Hub's nonfunctional status panel presents:

```text
EMERGENCY EGRESS
MAIN POWER             OFF
SECURITY CLEARANCE     INVALID
DIRECTOR AUTHORIZATION REQUIRED
EXIT SEALED
```

This display is presentation only until a future milestone.

## Radio / Elias

The folded note carried from Observation 06 will ultimately communicate:

> M-2 is still three tenths out. Vale refuses to change the card.

Archive information associated with Dr. Warren Vale reads:

```text
MAINT. BAND
107.6 MHz
```

The Laboratory calibration record reads `M-2    -0.3`.
Maintenance contains radio unit M-2. The correct frequency is
**107.6 - 0.3 = 107.3 MHz**. Tuning M-2 to 107.3 eventually contacts Elias,
a maintenance technician trapped in an inaccessible service area.

## Cassette / Generator / Main Power

The Observation 06 cassette contains a recorded generator startup drill.
A removable **12V instrument battery** from Laboratory equipment can temporarily
power an Archive cassette deck before main power is restored. The screwdriver
is required to access/remove that battery.

The generator startup procedure is:

1. Bypass open.
2. Prime until pressure reaches **40**.
3. Wait for stabilization.
4. Close breaker **2**.
5. Field excitation.
6. Close breaker **4**.
7. Close breaker **1**.
8. Close breaker **3**.

Elias physically operates the inaccessible coolant bypass; the player operates
the generator controls. Both actions are required for MAIN POWER. Incorrect
generator operation should trip/reset, never create an unrecoverable state.

## Security Clearance

After main power is restored, Security equipment becomes usable. The player
eventually obtains Warren Vale's revoked Director Access Card. Its encoder
requires EMPLOYEE ID, CLEARANCE CLASS, and VERIFICATION HASH.

Vale's employee ID is **0614**; Facility Director clearance is **Class IV**.
The verification hash combines three sources:

| Symbol | Cassette analyzer | Mara's later report |
|---|---|---|
| A | 3 | 90 degrees |
| B | 1 | 270 degrees |
| C | 4 | 0 degrees |
| D | 2 | 180 degrees |

Laboratory apparatus order is **0, 90, 180, 270 degrees**. This orders symbols
**C, A, D, B**, giving **4, 3, 2, 1**. The verification hash is **4321**.

Correct encoder information is **0614 / Class IV / 4321**. This restores the
Director Access Card and satisfies SECURITY CLEARANCE.

## Director Authorization

Security clearance permits access to the Director's Office. A Director document
cabinet uses five symbols. Department mapping and incident priority are:

| Priority | Department | Symbol |
|---|---|---|
| 1 | Containment | diamond |
| 2 | Laboratory | circle |
| 3 | Archive | plus |
| 4 | Maintenance | triangle |
| 5 | Administration | square |

The cabinet sequence is **diamond, circle, plus, triangle, square**. It contains
a Director Authorization Module. The Director terminal accepts the primary
module but requires secondary authorization from maintenance terminal **M-4**.

M-4 is inaccessible to the player, reachable by Elias, and has poor/no radio
reception. Mara can access an intercom routing system. Generator/maintenance
documentation establishes:

| Terminal | Line |
|---|---|
| M-1 | C |
| M-2 | F |
| M-3 | A |
| M-4 | D |

The player directs Mara to route **Line D**. Mara contacts Elias directly.
This NPC-to-NPC interaction must become meaningful gameplay/dialogue, not
background lore. No such communication is implemented in Milestone 10A.

The finalized challenge-response example at the Director terminal is:

```text
PHASE 2
LOAD 6
CIRCUIT B
```

Maintenance documentation maps Phase 1 = North, Phase 2 = East,
Phase 3 = South, Phase 4 = West. The Archive emergency table maps
Load 2 = White, Load 4 = Blue, Load 6 = Amber, Load 8 = Red.

Thus **PHASE 2 / LOAD 6 / CIRCUIT B** becomes **EAST / AMBER / B**.
The player supplies the interpreted information to Mara; Mara relays it to
Elias; Elias configures M-4; the player completes primary authorization.
This satisfies DIRECTOR AUTHORIZATION.

---

# 14. Final Egress � Future Implementation

When MAIN POWER, SECURITY CLEARANCE, and DIRECTOR AUTHORIZATION are valid,
Emergency Egress permits manual release. The first mechanical release only
partially disengages because the secondary release is seized. The screwdriver
is used again to access the final manual linkage, echoing the Observation Room
vent interaction. The player manually releases the second lock and opens the exit.

At the final evacuation control the player can release:

- Observation Cells
- Maintenance Sector
- Surface Access

This frees Mara and Elias before the player reaches the surface. Do not expand
the ending beyond this without a future design decision. None of this final
escape functionality is implemented in Milestone 10A.

---

# 15. Design Status

FINALIZED:

- Core premise, Halcyon Research Facility, Mara, and Elias
- Three final exit requirements
- Observation Room cabinet solution: 4371
- Screwdriver -> ventilation grate -> hidden switch -> intercom
- Mara sees C3-A1-D4-B2
- Employee badge grid interprets C3-A1-D4-B2 as desk drawer code 4778
- Observation Room key is inside locked desk drawer
- Note, Archive band, Laboratory calibration, and M-2 contact at 107.3 MHz
- Cassette drill, removable 12V battery, and cooperative generator procedure
- Director card encoder: 0614 / Class IV / 4321
- Department symbol sequence and Director Authorization Module
- M-4 / Line D routing, Mara-to-Elias relay, and EAST / AMBER / B response
- Final manual linkage and evacuation release of Mara and Elias
- Compact Hub-centered area relationships and nonlinear broad progression

NOT FINALIZED:

- Final physical dimensions, detailed prop/clue placement, and art
- Detailed dialogue/action presentation for future puzzle systems
- Full narrative explanation
