# Milestone 11A: Security investigation

Milestone 11A provides the information to derive **0614 / IV / 4321**. Milestone
11B now implements rewriting and reader acceptance; see [security_access.md](security_access.md).
Security begins INVALID and stays so until the active card is accepted. Director
Authorization and egress progression remain unimplemented.

## Physical information

- Archive personnel cabinet: existing Vale record at (14.9, 1.42, 9.639) now
  carries EMPLOYEE ID: 0614, with the original 107.6 MHz contact card preserved.
- Beside it, the revoked card at (15.28, 1.22, 9.639) identifies WARREN VALE /
  FACILITY DIRECTOR. E inspects, F takes, and inventory retains its static model.
  `vale_access_card`, **Director Access Card**, description: "An access credential
  issued to Facility Director Warren Vale. Its permissions have been revoked."
  Its `unlocks` array is empty. Milestone 11B adds a separate mutable credential
  with `security_inner` compatibility, initially revoked/inactive/class 0. There
  is no category field in the current inventory.
- Laboratory north wall above the calibration bench: authorization reference at
  (13.1, 1.65, -12.16). Technical Staff I, Research Staff II, Section Supervisor
  III, Facility Director IV all have identical styling. Inspectable, not takeable.
- Laboratory bench: the inert analyzer placeholder is replaced by a noncollectible
  phase instrument at (16.7, 1.24, -10.8), facing west. Four ports run left-to-right
  **0°, 90°, 180°, 270°**, without letters. Available before power.
- Archive recorder table: compact analyzer at (13.71, 1.07, 15.05), alongside
  rather than overlapping the existing deck. Main Power boots its READY readout;
  E deliberately analyzes the cassette installed in the existing tape socket.
  It shows separate channel/amplitude rows **A=3, B=1, C=4, D=2**. Battery power
  alone does not enable analysis. Missing cassette gives restrained feedback.
- Security outer pedestal: CRT at (27.3, 1.515, 4.1), facing south. Dead before
  Main Power, then inspectable. Reports HALCYON ACCESS CONTROL, CARD STATUS:
  REVOKED, CLEARANCE: NONE, ENCODER: AVAILABLE, and EMPLOYEE ID / CLEARANCE CLASS /
  VERIFICATION HASH fields. No answer values or objective checklist.

Paper, card stock, painted metal and modest monochrome CRT phosphor preserve
institutional presentation. All clue text uses TextMesh so the existing isolated,
lit inspection viewer can magnify/rotate it. No marker, outline, clue glow, new
spotlight, or global lighting change. Laboratory fixtures cover the bench/chart;
Archive's existing lights cover personnel storage and the recorder. Readout and
paper margins are checked using actual mesh bounds, including copied inspection
text. Perceived lighting, text size and composition still require an F5 visual pass.

## State and architecture

`security_investigation.tscn` contains active props independently of the inert
facility shell. Main-scene `SecurityWiring` binds the existing authoritative
`FacilitySystems/State`, two `PoweredReadout` instruments, the existing tape
socket, and Mara. Standalone instruments fail closed until configured.

`PoweredReadout` extends Inspectable, subscribes to `main_power_changed`, and
copies its mutable TextMesh/material per instance. An analyzer reads the installed
InventoryItem's existing RecordingData `channel_amplitudes`; it never consumes,
replaces, or changes the cassette. The original drill lines and battery playback
remain intact. Readouts use the existing inspection modal; no player changes or
new Input Map actions are required.

Mara's participant subclass mirrors physical Main Power into dialogue conditions
and guards `inspect_phase_chart` against the real state. The original window action
is unchanged. The new option needs no prior chart, apparatus, analyzer, window,
or introduction flags. Request acknowledgement precedes action resolution;
`phase_chart_inspected` and `phase_chart_reported` persist separately. Leaving
before investigation keeps the request available. Leaving after investigation
exposes an unreported-result option. Recall repeats the report without action:

```text
A = 90°
B = 270°
C = 0°
D = 180°
```

All state is session-only, as before. Auxiliary intercom power remains separate;
normal progression already enables it during Observation escape.

## Canonical deduction (documentation only)

Vale record supplies **0614**. The role chart supplies **IV**. Phase order
0/90/180/270 and Mara's mapping order channels **C A D B**. Their analyzer
amplitudes yield **4 3 2 1**. No normal gameplay dialogue, prop, or terminal explains
that transformation or displays the joined solution.

## Validation and manual procedure

`tests/security_investigation_smoke.gd` runs two fresh sessions: documents before
power then analyzer before Mara; and power/Mara/analyzer before documents. It
checks physical ray/E targeting, E/F card collection, inventory snapshot, exact
clue content, actual text bounds, battery-vs-mains gates, empty-tape rejection,
deliberate analysis, original playback, modal exclusion, interrupted Mara action
and report, recall, dialogue panel bounds, and unchanged Security/Director/egress
status and physical barriers. It sets Main Power directly to isolate this branch;
`main_power_smoke.gd` independently tests the real cooperative startup procedure.
All previous smoke suites remain required.

Run `godot --headless --path . --script res://tests/security_investigation_smoke.gd`
and all other `tests/*_smoke.gd` files. Also load the main scene headlessly and run
`git diff --check`. No manual editor configuration is required.

For manual testing, F5 and complete Observation, M-2 contact and the existing
Generator sequence. Discover documents/card before or after power. Confirm both
CRTs begin dead, then wake on Main Power. E the Archive analyzer with the cassette
installed; return to the intercom and request Mara's new investigation. Interrupt
before her action and after her discovery, reconnect, and later recall the mapping.
Reverse analyzer/Mara order in a new session. Verify card inspection/inventory,
readability at normal standing positions and in the inspection viewer, original
tape replay, mouse capture restoration, and that all later barriers remain sealed.
