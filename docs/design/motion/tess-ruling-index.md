# Haptic and motion ruling index (Oct 17, 4 PM PT onward)

Board 71. One page: each ruling, the spec that carries it, and every line that still contradicts it. Sources: `decisions.md` (DEC, line numbers from the 1043-line copy on the shared drive; the repo copy stops near line 995), the haptic map in `DesignSystem/Haptics.swift` (the map is the code and wins over any sheet), and the files in this folder. Stamps are real PT.

Status: **OK** carried and nothing contradicts it. **FIX** a stale line exists. **GAP** no spec carries it.
"MRA" = `tess-money-reading-motion-amended.md` (#963, not yet on master). "Day screens" = `tess-day-screens-motion-pass.md` (#966, not yet on master). "Row 26" = the UNDO-alone row in #964.

## 1. Haptics: which case plays

| # | Ruling (DEC line, time) | Carried by | Status and stale lines |
|---|---|---|---|
| H1 | Kitchen timer end and rest end play `.timeUp`; `.success` is Done's. Pick landing stays light 0.5. (1021, 9:25 PM; 1025) | haptics-sheet-audit M1; cook-clock-lowpower; training-motion-lowpower | FIX (Design): kitchen/12-cook-mode.md:47 (`.success` timer end), kitchen/lists-9-12.md:56 (pick landing medium) |
| H2 | Timer-end haptic only if seen live within 2 s; two timers inside 600 ms give one. (1015) | cook-clock; training; live-activity motion | OK |
| H3, H4 | Bead step haptic and his own touches stay in Low Power; "timer-end success" in G223 means `.timeUp`. (1007, 1011, 1015) | cook-clock; migration table §5 | OK |
| H5 | Groceries Done `.done`; Clear the basket is a tap key and plays `.success`; Reset medium. (1009, 1025) | groceries-lp:33-45 | FIX (lab): groceries-lp:38 puts Clear on `.done`; groceries-lp:43 calls Clear named-action-only (it is a tap key, DEC 1027, 1039) |
| H6 | Finishes play `.done` (Done, shutdown close, habit check-in, hold "Done for today"). (1025, 1041) | day-screens; haptics-sheet-audit M7-M9 | FIX (lab): groceries-finish-copylist-motion.md:12/:14/:19 (`.success`). FIX (Design): shutdown.md:42, shutdown-grammar.md:21/:63, evening-on-now.md:49, habits-grammar.md:25/:53, upkeep-people-grammar.md:22, recipe-clock.md:53, live-workout.md:31-32 |
| H7 | Capture commit plays `.made`, not raw `.success`; Pantry swipe-add keeps `.made`. (1031, 9:34 PM) | day-screens:53; speak-plan; migration row 14 | GAP: pantry-v2-motion-check.md:40 still "Open for Product". FIX (Design): gaps-98.md:19 "nothing else" |
| H8 | Hold-to-start timer plays no completion haptic; grocery check is the light cue; the Next bar is retired. (1035, 9:43 PM) | migration rows 21-23; audit M2-M4 | FIX (lab): cook-clock:71/:72 (Next step medium; hold-start medium 0.8). FIX (Design): 12-cook-mode.md:36/:41 |
| H9 | The soul plays no haptic; delete the raw `.success` at TessSoul.swift:143. (1035, #957) | migration row 25; training; MRA | FIX (lab): tess-motion.md, tess-quiet-versions.md, tess-motion-build.md, tess-title-progress.md, tess-home-day-continuity.md still say "Done's own `.success`" |
| H10 | Money Log plays `.made`, Finished book plays `.done`, set aside plays nothing. (1041, 9:58 PM) | MRA:53/:86-89 (branch) | GAP: SLM and SLR amendments have no haptic rows. FIX (lab): tess-drums-and-release14-walk.md:14/:31 needs a "superseded by MRA" banner. FIX (Design): money-dial.md:25, reading.md:23, money-reading-grammar.md:54/:69 |
| H11 | Plan row skip `.notNow`; Day log week-boundary tick `.pickedUp`. (1043, 10:05 PM) | day-screens:29/:106; release-haptics | FIX (lab): speak-plan-daylog-copylist-lowpower-pass.md:47 (skip "none") and :64 (week tick `.impact(.light)`); day-screens:136 still lists them as asks |
| H13 | One soft `.warning` per failed save, none for offline or info lines; Haptics-off silences all but this. (911, 967, 991, 1019) | error-notice; pantry-lean-notice; audit M14 | GAP: the "Haptics, on" row meaning is in no spec. FIX (lab): tess-error-notice.md:23 copy is "Didn't save that. Try again." FIX (Design): task-reward.md:99 bans `.warning` |
| H14 | Capture-miss "That's too long to send." and a dropped cook phrase play no haptic. (941, 945, 947) | none | FIX (lab): migration table row 14 says capture-miss plays `.made` |
| H15 | A Pantry tap that changes nothing: no receipt, no haptic. (977, 1003) | pantry-lean-notice; pantry-v2-motion-check | OK |
| H16 | A note write plays the landing tick (his touch only); note delete is a tap plus UNDO 10 s. (1029, 9:33 PM) | none | GAP. FIX (Design): notes-grammar.md:44 `.light` (map says `.made`) |
| H17 | UNDO plays `.undo` alone, never with `.selection`. | migration rows; day-screens:54; MRA:124 | OK once #964 lands row 26 (until then the cite dangles) |

## 2. Reduce Motion, Low Power, Tess

| # | Ruling | Carried by | Status and stale lines |
|---|---|---|---|
| M1 | RM keeps Tess at full opacity, halo and grade; asleep keeps full pigment; no poster frame in the 500 ms fade. (991, 1003) | tess-motion; never-diffused-audit; cook-clock | FIX (lab): tess-quiet-versions.md:12 says RM idle shows mode by grade; tess-motion.md:222 says never |
| M2 | Low Power = Reduce Motion everywhere, sides included; soul keeps her own LP form. (991, 1003, 1023) | sides-motion; page-turn; groceries-lp; training | FIX (lab): tess-quiet-versions.md:29/:35 keep the side spring in LP. tess-motion.md:226 and quiet-versions:12 say 20 fps; ruling says 30 fps, six lights |
| M3 | Zoom into a screen is a 150 ms crossfade in LP. (1009) | groceries-lp; day-screens:17; MRA:10 | OK |
| M4 | The reduced Look change is 150 ms (HS43). (1017) | none | GAP. FIX (lab): tess-motion.md:237 (250 ms), groceries-lp:67 (flood stays in LP) |
| M5 | Speak dry window stays 3 s in LP with a stepped drain; VoiceOver ghost wait is a flat 10 s with Cancel; listen ends on a pause. (1031, 1039) | day-screens:50-60; speak-plan | OK |
| M6 | Low Power rows for Shutdown and Habits (G317, G318). (1039) | day-screens:72/:84 | FIX (Design): shutdown.md:56-57, shutdown-grammar.md:64, habits-grammar.md:54 have no LP row |
| M7 | Drums: RM and LP are one path, no coast, no tick on its own; 420 ms travel. (1041) | MRA:32/:52 | FIX (Design): money-dial.md:32, reading.md:42 mention RM only |
| M8 | Home's automatic Claude call, Plan wording and the week story wait for power OK; his own asked call runs. (1017, 1023, 1033, 1039) | day-screens:34/:126; MRA | OK |
| M9 | The clock page is the cook (G228); cover-only rows are history. (1007, 1011) | cook-clock:11-17 | FIX (lab): cook-clock:71 still lists Next step |

## 3. Quiet hours, notifications, activities

| # | Ruling | Carried by | Status and stale lines |
|---|---|---|---|
| Q1 | Quiet hours 23:00 to 07:00 until he asks for a setting. (1017, 1019) | tess-picks; day-screens:18 | FIX (lab): tess-motion.md:258 says 06:00 |
| Q2 | Tess-initiated landings follow quiet hours (no haptic, sound or line); his touches and `.timeUp` always play. (1011, 1023, 1033, 1039) | cook-clock; MRA; day-screens; migration §5 | OK. Build gap: the `Haptic` origin field |
| Q3 | Rest end rings the same local notification as a kitchen timer ("Rest is up", masked body); the rest activity carries no alert. (1035, 1037) | live-activity motion | FIX (lab): training:95 ("Set 3 is up"). FIX (Design): live-activity.md:45, lockscreen.md:24/:43. Unmasked alert body at RestActivityController.swift:152 is flagged in #964 |
| Q4 | Activities and widgets let the system own their motion; the glow-breathing, 700 ms and 1.4 s lines come out. (1037) | live-activity motion | FIX (Design): live-activity.md:40/:41/:43, lockscreen.md:18 |

## 4. UNDO, receipts, VoiceOver, drums, pages

| # | Ruling | Carried by | Status and stale lines |
|---|---|---|---|
| U1 | One app-wide UNDO slot; a 4 s window for new, 10 s for a change, 10 s under VoiceOver. (1009, 1031, 1039) | groceries-lp; day-screens; pantry-lean-notice | OK |
| U2 | Review, Settings and Backups covers sit under the shared line; a key change gets a plain receipt with no UNDO. (1023, 1027) | none | GAP. groceries-lp:27 places the line differently from GL19 |
| U3 | Named-action-only VoiceOver is for hold keys only. (1027, 1039) | day-screens:113-119; migration table via #964 | FIX (lab): groceries-lp:43 lists Clear the basket |
| U4 | Plan hold VoiceOver hint reads "Hold to keep N tasks", action "Keep". (1043) | none | **FIX (lab, mine):** day-screens:31/:40/:117/:136 say "Keep the plan" / "Keeps 5 tasks" |
| U5 | Receipts name the thing first; masked forms "Private spend", "Private book", "Private habit". (1033, 1039) | MRA; day-screens | OK (ship-list rows are on branch only) |
| D1 | Drum ticks capped at 25 per second, landing tick always plays. (1001) | drums-and-release14-walk:11; day-screens:105 | **FIX (lab, mine):** MRA:31/:113 set a 30 ms floor (about 33/s); must become 40 ms |
| P1 | No haptic on any page turn; LP follows RM for page turns. (925, 933, 1023) | page-turn-motion | FIX (Design): pages-90.md:14 (`.selection` on landing, against its own R2) |

## 5. What happens next

- **Lab fixes now (mine):** this index. Once #963, #964 and #966 merge, one small follow-up PR carries D1 (40 ms), U4 (hint wording), the #966 QA lows, the banner on drums-and-release14-walk, H5/H6/H11/H14, M1/M2/M4, Q1/Q3 line edits in the lab files above.
- **Design's files (not mine):** every line marked FIX (Design). They are listed once here so Design can work them top to bottom.
- **Product questions:** H7 (Pantry add `.made`, still "Open for Product"), H13 (what "Haptics, on" silences), U2 (placement of the shared UNDO line), the "PR" word in day-log-v1.md:52 (ruled word is "best").
- Also noticed: board motion.md quotes Rotate 650 ms, page-turn spec carries Design's 460 ms.
