# Milestone 12B: secondary Director authorization

DIRECTOR AUTHORIZATION = IMPLEMENTED.
FINAL EMERGENCY EGRESS RELEASE = IMPLEMENTED in Milestone 13; see [final_egress.md](final_egress.md).
The following describes the earlier authorization stage.

## Physical documents and discovery

All three new records are noncollectible Inspectables with physical TextMesh
printing, equal-weight rows, ordinary service headings and records-copy footers.
They may be read before power, primary authorization or any conversation.

| Document | World position / facing | Canonical contents |
|---|---|---|
| Maintenance north-wall communications register | (23.8, 1.6, -4.15), south | M-1/C, M-2/F, M-3/A, M-4/D |
| Maintenance east-wall phase reference | (29.35, 1.6, -2.7), west | 1=NORTH, 2=EAST, 3=SOUTH, 4=WEST |
| Archive south-wall load reference | (14.4, 1.6, 15.55), north | 2=WHITE, 4=BLUE, 6=AMBER, 8=RED |

No document identifies a preferred row, tells the player which line to connect,
or mentions its role in the Director puzzle. No clue-history flags gate actions.
The canonical interpretation remains PHASE 2 / LOAD 6 / CIRCUIT B -> EAST / AMBER / B.

## Mara routing and witnessed contact

After Main Power, Mara's ordinary intercom menu adds a communications topic.
A dedicated submenu keeps her earlier observation/phase/recall topics available.
Choose service routing, then LINE A-F. Wrong lines have only an unanswered
carrier and immediately allow another choice. Line D starts this witnessed exchange:

- Mara: Maintenance, can you hear me?
- Elias: Mara? Yes. Barely. Where are you routing this from?
- Mara: Observation-side intercom. Someone out here needs service control M-4.
- Elias: I can reach M-4 from the service side. Its network link is down, but I can work the controls. Tell me what the Director terminal wants.
- Mara: I'll keep this line connected. Tell me what you need passed along.

Selecting D alone does not establish contact. Elias's contact_m4 action runs
at his access-confirmation stage. Closing early leaves routing available so the
exchange can be repeated; no once-only choice can strand progression. Changing
to another line disconnects contact; choosing D again repeats the exchange.
Neither NPC changes world location or teleports. Their logical participants
remain under the existing Observation and service-side layers.

## Multi-participant conversation architecture

Conversation retains its lead participant and adds current_actor. Qualified
node destinations such as elias:m4_access resolve through the lead participant's
explicit conversation_partners map. Content, condition flags, once-history and
actions belong to the actor whose node is being shown. Unqualified destinations
retain the existing lead-participant behavior; cross-participant nodes use
qualified destinations explicitly. PLAYER remains a speaker override.

The runner duplicates each entered node before formatting text from actor-owned
dialogue_values. Optional node values update that actor's draft, and optional
parameters are delivered to request_action / _perform_action. Shared DialogueData
is not mutated. DialogueUI renders current_actor and monitors linked participants
for deletion, retaining modal acquisition, keyboard/mouse controls, revision
checks, focus-loss and source-deletion cleanup.

Mara and Elias keep separate dialogue resources and action implementations.
Elias's lines are not stored as Mara text. Mara's relay_m4 action copies the
constructed response into Elias.receive_m4_response. His configure_m4 action
then applies the received configuration to authoritative facility state and
supplies his own result line. This is an explicit participant-to-participant
data transfer followed by the receiving participant's physical action.

## Terminal session and response construction

The Director CRT remains inspectable. A separate raised SESSION / CONFIRM button
on its lower front starts the secondary session only when mains, primary token
acceptance, Line D and witnessed contact are present. Read the CRT afterward:

PHASE 2
LOAD 6
CIRCUIT B

At Mara, choose the response topic. Three staged menus independently select
NORTH/EAST/SOUTH/WEST, WHITE/BLUE/AMBER/RED, and A/B/C/D. Each selection is confirmed
with Continue; a review shows the player's constructed values. Give response,
Change response and Not yet are explicit choices. There is no preselected correct
combination. Mouse, number keys, arrows/Enter and Escape use existing DialogueUI
and PlayerModalInput. Movement/look/world interaction are suspended throughout.

On transmission the player speaks their values, Mara repeats them without
judgment, then explicitly says: Elias, response is {direction}, {color}, circuit
{circuit}. Elias answers Copy. Setting M-4. Advancing invokes his configure_m4
action. Incorrect values produce only: No. M-4 rejected that combination. I can
try another setting. The link/session persist, with unlimited retries and no
component-specific hints. Exiting before an action resolves leaves the response
workflow available again.

Correct EAST / AMBER / B sets secondary readiness and lights a small READY
indicator on the existing inaccessible M-4 housing. Elias reports station
readiness. There is no new sound or voice asset; feedback is text plus the remote
indicator. The grille and all physical access boundaries remain intact.

## Authoritative progression and endpoint

DirectorOffice/State (FacilityDirector) owns read-only session properties:
- director_primary_authorized
- communications_line_connected (selected line string)
- participants_connected (the witnessed D-line contact action)
- director_secondary_session_active
- director_secondary_ready
- director_authorization_valid

Explicit guarded methods change state; changed, m4_attempted and
authorization_completed signals notify consumers. The original primary signal
is preserved. Conversation flags project availability only and cannot confer
facility authorization. New scene instances reset all state.

Readiness does NOT complete Director Authorization. The CRT reports READY /
FINALIZE AUTHORIZATION. The player returns and deliberately presses SESSION /
CONFIRM again. Finalization requires Main Power, Security Clearance, primary,
active secondary session and M-4 ready. Only then does authorization become valid.
The CRT displays COMPLETE / PRIMARY VALID / SECONDARY M-4 VALID. Hub status becomes:

MAIN POWER             ONLINE
SECURITY CLEARANCE     VALID
DIRECTOR AUTHORIZATION VALID
READY FOR MANUAL RELEASE

The existing EMERGENCY EGRESS heading remains. No door opens, mechanical release
is installed, item is consumed, or final escape gameplay is introduced.

## Validation and manual review

Run tests/director_secondary_smoke.gd headlessly, followed by all smoke suites.
The new suite covers early document inspection and a separate no-clue session,
canonical tables, document targeting/margins, prior Mara window/recall and Elias
reminder/bypass actions, wrong-line retry, interrupted contact recovery, real NPC
speaker identity, deliberate challenge activation, mouse response construction,
uniform wrong/partial failures, NPC action execution, remote indicator, leaving
M-4 ready and returning to finalize, Hub text bounds, sealed egress and scene reset.
Main Power and primary acceptance are set directly in this isolated branch test;
existing main_power, security_access and director_office suites exercise their
full physical prerequisites. No debug controls are added to the game.

Manual F5 review:
1. Complete the existing Main Power/Security/primary-module flow; inspect the new records in any order.
2. At Mara, try an incorrect line, then D. Read the alternating Mara/Elias exchange.
3. Return to the Director desk and press SESSION / CONFIRM. Inspect the challenge.
4. Return to Mara, construct a wrong response and observe the generic rejection.
5. Construct EAST / AMBER / B, witness her relay and Elias's action, then leave.
6. Check the inaccessible M-4 READY indicator and return to confirm at the desk.
7. Check all three Hub rows and READY FOR MANUAL RELEASE; the exit must stay closed.

No editor configuration or new Input Map action is required. Headless checks do
not establish rendered legibility, perceived lighting, conversation pacing,
mouse feel or audio balance. Those still need a visual/dialogue playtest. There
is no voice acting or added relay audio in this milestone.
