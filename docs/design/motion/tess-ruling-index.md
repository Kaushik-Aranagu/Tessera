# Haptic and motion ruling index (Oct 17, 4 PM PT onward)

Board 71. One page: each ruling, the spec that carries it, and every line that still contradicts it. Sources: `decisions.md` (DEC, line numbers from the 1043-line copy on the shared drive; the repo copy stops near line 995), the haptic map in `DesignSystem/Haptics.swift` (the map is the code and wins over any sheet), and the files in this folder. Stamps are real PT.

**This is a work list, not a ruling source:** the rulings are in `decisions.md` and the haptic map; a line here only points at them. Status: **OK** carried and nothing contradicts it. **FIX** a stale line exists. **GAP** no spec carries it.
"MRA" = `tess-money-reading-motion-amended.md` (#963, not yet on master). "Day screens" = `tess-day-screens-motion-pass.md` (#966, not yet on master). "Row 26" = the UNDO-alone row in #964. "groceries-lp" = `tess-groceries-lists-and-home-settings-lowpower.md`.

## 1. Haptics: which case plays

| # | Ruling (DEC line, time) | Carried by | Status and stale lines |
|---|---|---|---|
| H1 | Kitchen timer end and rest end play `.timeUp`; `.success` is Done's. Pick landing stays light 0.5. (1021, 9:25 PM; 1025) | haptics-sheet-audit M1; cook-clock-lowpower; training-motion-lowpower | FIX (Design): kitchen/12-cook-mode.md:47 (`.success` timer end), kitchen/lists-9-12.md:56 (pick landing medium) |
| H2 | Timer-end haptic only if seen live within 2 s; two timers inside 600 ms give one. (1015) | cook-clock; training; live-activity motion | OK |
| H3, H4 | Bead step haptic and his own touches stay in Low Power; "timer-end success" in G223 means `.timeUp`. (1007, 1011, 1015) | cook-clock; migration table §5 | OK |
| H5 | Groceries Done `.done`; Clear the basket is a tap key and plays `.success`; Reset medium. (1009, 1025) | groceries-lp:33-45 | FIX (lab): groceries-lp:38 puts Clear on `.done`; groceries-lp:43 calls Clear named-action-only (it is a tap key, DEC 1027, 1039) |
| H6 | Finishes play `.done` (Done, shutdown close, habit check-in, hold "Done for today"). (1025, 1041) | day-screens; haptics-sheet-audit M7-M9 | FIX (lab): groceries-finish-copylist-motion.md:12/:14/:19 (`.success`). FIX (Design): shutdown.md:42, shutdown-grammar.md:21/:63, evening-on-now.md:49, habits-grammar.md:25/:53, upkeep-people-grammar.md:22, recipe-clock.md:53, live-workout.md:31-32 |
| H7 | Capture commit plays `.made`, not raw `.success`; Pantry swipe-add keeps `.made`. (1031, 9:34 PM) | day-screens:53; speak-plan; migration row 14 | GAP: pantry-v2-motion-check.md:40 still "Open for Product". FIX (Design): gaps-98.md:19 "nothing else" |
| H8 | Hold-to-start timer plays no completion haptic; grocery check is the light cue; the Next bar is retired. (1035 for the first two; 1007 and 1011 for the Next bar) | migration rows 21-23; audit M2-M4 | FIX (lab): cook-clock:71/:72 (Next step medium; hold-start medium 0.8). FIX (Design): 12-cook-mode.md:36/:41 |
| H9 | The soul plays no haptic; delete the raw `.success` at TessSoul.swift:143. (the haptic map and sheet 38:111; #962, #957) | migration row 25; training; MRA | FIX (lab): tess-motion.md, tess-quiet-versions.md, tess-motion-build.md, tess-title-progress.md, tess-home-day-continuity.md still say "Done's own `.success`" |
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
| M1 | RM keeps Tess at full opacity, halo and grade; asleep keeps full pigment; no poster frame in the 500 ms fade. (991, 1003) | tess-motion; never-diffused-audit; cook-clock | FIX (lab): tess-quiet-versions.md:12 says 20 fps for the idle LP form (ruling: 30 fps, six lights). "Mode by size and grade" there matches the ruling. |
| M2 | Low Power = Reduce Motion everywhere, sides included; soul keeps her own LP form. (991, 1003, 1023) | sides-motion; page-turn; groceries-lp; training | FIX (lab): tess-quiet-versions.md:29/:35 keep the side spring in LP. tess-motion.md:226 and quiet-versions:12 say 20 fps; ruling says 30 fps, six lights |
| M3 | Zoom into a screen is a 150 ms crossfade in LP. (1009) | groceries-lp; day-screens:17; MRA:10 | OK |
| M4 | The reduced Look change is 150 ms (HS43). (1017) | none | GAP. FIX (lab): tess-motion.md:237 (250 ms), groceries-lp:67 (flood stays in LP) |
| M5 | Speak dry window stays 3 s in LP with a stepped drain; VoiceOver ghost wait is a flat 10 s with Cancel; listen ends on a pause. (1031, 1039) | day-screens:50-60; speak-plan | OK |
| M6 | Low Power rows for Shutdown and Habits (G317, G318). (1039) | day-screens:72/:84 | FIX (Design): shutdown.md:56-57, shutdown-grammar.md:64, habits-grammar.md:54 have no LP row |
| M7 | Drums: RM and LP are one path, no coast, no tick on its own; 420 ms travel. (1041) | MRA:32/:52 | FIX (Design): money-dial.md:32, reading.md:42 mention RM only |
| M8 | Home's automatic Claude call, Plan wording and the week story wait for power OK; his own asked call runs. (1017, 1023, 1033, 1039; 1023 supersedes 1017, which said the Home ask runs in Low Power) | day-screens:34/:126; MRA | OK |
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

- **Lab fixes:** done in #972 (drum 40 ms, hold hint, #966 lows, banner on the old drums sheet, rows H11/H14) and this follow-up (index and Settings lows). Left: H5/H6 (groceries wording), M1/M2/M4, Q1/Q3 line edits in the older lab files listed above, and migration row 14's "a miss routed to Claude and written plays `.made`", which is a lab default for Product, not a ruling.
- **Design's files (not mine):** every line marked FIX (Design). They are listed once here so Design can work them top to bottom.
- **Product, answered at 10:15 PM Oct 17 (DEC:1045):** H7 Pantry add plays `.made`; H13 "Haptics, on" off silences every app haptic except the failed-save `.warning`, and timer-end and rest-end notifications still ring; U2 the shared UNDO line sits directly above the key row, UNDO at its right, and above the bottom chrome when there is no key row; user lines say "best", never "record" (day-log-v1.md:52 is Design's to fix).
- Also noticed: board motion.md quotes Rotate 650 ms, page-turn spec carries Design's 460 ms.

## 6. Rulings since this index (DEC:1053 to 1069, Oct 17 10:58 PM to Oct 18 12:23 AM)

Same rule: a work list, not a ruling source. "Matrix" = `tess-lowpower-reducemotion-matrix.md`; "HAB" = `tess-habits-shutdown-quiet-private-pass.md`; "LRB" = `tess-look-settings-rotate-budget-check.md`; "BHR" = `tess-backups-health-review-motion.md`; "LAW" = `tess-live-activity-lockscreen-widget-motion.md`.

| # | Ruling (DEC line, time) | Carried by | Status and stale lines |
|---|---|---|---|
| N1 | Widget new-day words appear at 07:00; the data day still turns at 04:00. (1053, 10:58 PM) | LAW §5 (#981) | OK |
| N2 | Restore plays `.made`, hold key, named-action-only, action "Restore"; Backups line on the shared slot now; receipt "Backup, saved."; Face ID before an export leaves the app; Health permission only on his foreground tap, at most once a day. (1055, 11:04 PM) | BHR (#976, #981) | OK. Build: `Paint.swift:314` still completes a hold on one double tap |
| N3 | The week story is one gate inside the Claude client for every automatic job (Low Power, the 07:00 floor, the switch, the cap); asked only from Monday 07:00; a skipped week shows three count lines. (1057 item 1-2, 11:07 PM) | BHR §4; Matrix (Review row) | OK |
| N4 | Remove key is a two-step ("Remove the Claude key?", "Remove", "Keep it"), plain receipt, no UNDO. (1057 item 4; 1067 item 2) | none | **GAP (lab):** `tess-settings-motion.md` carries no UNDO but not the two-step wording or its motion |
| N5 | A capture miss routed to Claude and written plays `.made` once. (1059, 11:31 PM) | HMT row 14 (#981) | OK. Row H14 above is stale: it says row 14's `.made` is wrong; the too-long line and the dropped cook phrase are the no-haptic cases, row 14 now says so |
| N6 | A reduced page turn is a tapped word cutting to the new page with a 150 ms crossfade; a finger swipe is untouched; one shared helper for the Plans and exercise pagers. (1061 item 2, 11:40 PM) | none | **GAP (lab):** `tess-page-turn-motion.md` has the 150 ms crossfade for the word, not the "finger swipe untouched" half or the shared helper |
| N7 | Private text goes through one function with a "Private habit" case; the "Read today?" ask sits in the Shutdown band as one plain line. (1067 item 6-7, 12:22 AM) | HAB §3 | OK. FIX (Design): `shutdown.md` empty-band wording |
| N8 | Rotate 160 / 260 / 24 (460 ms at six rows) is the Rotate turn only; other Look/Settings motion has a 260 ms ceiling; first Shutdown line "3 moving to tomorrow. Tap any to keep."; private-habit receipts; pause/resume UNDO 10 s; Settings waits for the Low Power flag PR. (1065, 12:20 AM) | LRB; HAB | OK. FIX (lab): `tess-settings-motion.md:14` (40 ms, 420 ms grow) predates it. FIX (Design): `pages-90.md:21`; `shutdown.md` first-line wording |
| N9 | The raw `.sensoryFeedback` sites go through the haptic map (rides #958); Haptics off gates them; row values read Off/On everywhere. (1067 items 3-4) | Matrix (b), HMT | OK. Count differs: the ruling says 27, the code has 25 outside `Haptics.swift` (re-count when #958 lands) |
| N10 | Clear the basket plays `.done`. (1069 item 1, 12:23 AM) | groceries-lp:38 | OK. **Row H5 above is superseded:** it says Clear plays `.success` and `groceries-lp:38` is wrong; the ruling is `.done` and the spec was right. Still FIX (lab): `groceries-lp:43` lists Clear as named-action-only (it is a tap key) |
| N11 | Rest-end notification title "Timer", body "Rest is up". (1069 item 2) | LAW | **Row Q3 above is superseded** (it says title "Rest is up"). FIX (lab): `tess-training-motion-lowpower-pass.md:95` ("Set 3 is up"), and `RestActivityController.swift:152` |
| N12 | Soul Low Power form runs 30 fps, full opacity; older 20 fps lines are superseded. (1069 item 3) | Matrix (soul row) | FIX (lab): `tess-quiet-versions.md:12,15,43` (20 fps), `tess-motion.md:242` |
| N13 | Builder A owns the clock page; Builder B owns the recipe page, Pantry screens and the hand-off into the cook. (1063, 11:49 PM) | Matrix (owner column) | OK |

**Folded into the specs (lane 82):** N4 (Remove key two-step, `tess-settings-motion.md`), N6 (reduced page turn helper, `tess-page-turn-motion.md`), N10 (`groceries-lp:43`), N11 (`tess-training-motion-lowpower-pass.md:95`), N12 (`tess-quiet-versions.md`, `tess-motion.md`). **Left:** the Q1 and M1 to M4 lines in section 5 above, and N8's `tess-settings-motion.md:14` timings.

## 7. Rulings after DEC:1069 (DEC:1071 to 1085, Oct 18 1:12 AM to 5:17 AM)
Same columns and statuses as section 6. Line numbers are the 1083-line copy on the shared drive.

| # | Ruling | Spec that carries it | Status |
|---|---|---|---|
| N14 | An offline capture miss queues only when no wall applies; a walled phrase (money, body, secret words) is never queued or logged; the ask slot shows one plain line "Couldn't read that offline. Try again online." and the text stays in his box. (1071, 1:12 AM) | `tess-capture-miss-motion.md` | OK (lab): rows in `tess-capture-miss-motion.md` (words only, no haptic, the line takes the shared slot with no UNDO, his text stays) |
| N15 | Note write `.made`; one "Note, saved." on leaving an edited note (10 s UNDO); portion drum on the money-drum rules; link-wait line "Asking Claude to read the recipe."; left-swipe add stays until the peek exists; a private recipe title never reveals on tap. (1073, 1:15 AM) | `tess-notes-recipes-motion.md` §7 | OK (folded in #1001). Closed: the private-title reveal is already gone in #912 |
| N16 | Hunt 26: #884 gates any capture-miss build; the Ask-slot line and UNDO read from one source (newest wins); the line reads "No connection." until the retry inbox is wired; the "Sent ... to Claude" notice shows on send, not on success; a miss plays no haptic and the Claude write that lands plays `.made` once; the Claude wait is one plain line "Asking Claude" with Cancel, capped at 8 s. (1077, 1:20 AM) | `tess-capture-miss-motion.md` | OK (lab): the 8 s wait line with Cancel and the one-source slot are in `tess-capture-miss-motion.md`. (was GAP:) Check against `tess-notes-recipes-motion.md` §2 (its link-wait row says "Reading <host>." for the fetch, DEC:522) |
| N17 | Row 28 is ON THEM; "Pantry, 6 kept." shows only on the Pantry page with no UNDO (Groceries' Done owns the slot); rows 28 and 31 get one glance fact; row 30 uses the Settings Page turn word; the house spring 0.42 s wins over "320 ms". (1075, 1:17 AM) | `tess-pantry-first-day-and-four-sides-motion.md` | OK (lane 84, #1002 plus follow-up) |
| N18 | The muscle figure is approved for Exercise MUSCLES and Routine; every drawn food stand-in is withdrawn (Recipe pocket is his photo or nothing, Ingredient none, nothing on Groceries, Pantry or Kitchen). (1079, 1:30 AM) | `tess-muscle-figure-and-food-drawings-motion.md` | OK (lane 85) |
| N19 | The Kitchen medium widget wash is withdrawn too (a widget draws plain ground); `Ingredient.colour` has no consumer; the Kitchen mark on the Dynamic Island stays; `ObjectPlate.swift`, `PlateWash.swift` and `PlateWashTests.swift` are deleted by Builder B. (1081, 1:34 AM) | none | Checked in lane 85: no Live Activity or widget motion row here assumes a food wash (the washes in `tess-live-activity-lockscreen-widget-motion.md` are Tess's cobalt ground and the rest sky). OK |
| N20 | The muscle figure's worked parts dry in together with no stagger; hidden from VoiceOver; none on Private or a live workout. (1083, 2:16 AM) | `tess-muscle-figure-and-food-drawings-motion.md` §1, §2 | OK (lab defaults now ruled) |
| N21 | Hunt 27: G447 `SpeechListener.start()` re-checks state after every await, so a release during the first mic prompt ends the listen and nothing records after Allow unless he is still holding; G451 every notification title and body passes the one private-text function ("Private task" when masked, same as the timer rule), a before-build gate for Core since the app schedules no notifications yet. (1085, 5:17 AM) | none | OK (lab): both rows are in `tess-speak-plan-daylog-copylist-lowpower-pass.md` section B |
| N22 | G220: the cook screen in Low Power equals Reduce Motion (bead still, no ring, 150 ms fades, haptics kept); the horizon steps once a minute, every 10 s in the last minute (Oct 17 9:22 PM). | CCK:17, CCK:20 | OK, with FIX (lab): CCK:80 still lists "10 s steps: Design confirms" as open. |
| N23 | G222: the cook Lock Screen card uses system timer text; the update carries no sound; the notification is the only alert (Oct 17 9:46 PM). | CCK:46 | OK |
| N24 | G226: the Home cook bar steps every 5 s (not each second); in Low Power or Reduce Motion one step a minute with a 150 ms fade. | CCK:23 | OK |
| N25 | G227: the one Reduce Motion fade is 150 ms everywhere (Oct 17 9:23 PM, HS43). | CCK:20, tess-pantry-v2-motion-check.md:14 | FIX open (guard): tess-motion.md:237 (Look flood "250 ms crossfade" in Reduce Motion), GRO:67 (flood "stays" in Low Power). |
| N26 | G240: a cook step change is a focus move with no announcement; a timer end is one announcement, not a live region. | CCK:31, CCK:52 (end only) | GAP (lab): no step-change row in CCK (grep "focus" finds nothing). |
| N27 | G244: the shop seam is still and lit in Low Power or Reduce Motion; in normal power the timeline runs only across the 1.35 s glint. | GRO:16 | OK |
| N28 | G245: one cached reduced flag drives the grocery check, aisle handoff, peek and basket breath; meaning, count and haptics unchanged. | GRO:14, GRO:15 | OK |
| N29 | G246: the aisle fade goes through `MotionPolicy.reducedMotionFade` (150 ms); the 0.18 literals go; one test. | GRO:15, GRO:65 | OK (the test is not named in GRO; add it to the build list). |
| N30 | G248: the ambient wash is paused, with no key sheen or bead, in Low Power; the key still fills and completes with the same haptic. | GRO:17 | OK |
| N31 | G252: Groceries Undo shares the Bottom chrome undo, says the taken-back line and plays `.undo`; label "Undo", hint "Puts back what was just done". | GRO:29 | GAP (lab): the label and hint are not in GRO:29. |
| N32 | G266: a failed Lists save says "Didn't save that. Try again." and plays `.notSaved` once on both screens (Oct 17 7:39 PM D3). | tess-error-notice.md:9 (slot) | FIX (lab): tess-error-notice.md:23 copy reads "Didn't save. Try again." (see index H13). GAP (lab): no Lists row. |
| N33 | G393: a failed plan write plays `.notSaved` once and says "Didn't save that. Try again." through one path on the routine screens. | tess-error-notice.md:9 | GAP (lab): no routine-screen row; same copy FIX as N32. |
| N34 | G267: proposed plan rows sit still at a fixed breath in Low Power or Reduce Motion; normal power uses one repeating opacity animation or stops after a few cycles. | GRO:53, DAY:26 | OK for Low Power; GAP (lab): the normal-power cheaper breath is not in GRO:53. |
| N35 | G270: every raw `withAnimation` goes through the policy; the one reduced number is 150 ms. | MAT:77 (list), GRO:65 | OK |
| N36 | G289: opening a note is a 150 ms crossfade, not a zoom, in Reduce Motion and Low Power, through the Arrival shape. | NRM:5, NRM:17 | OK, with FIX (lab): MAT:43 still says Notes "NOT specced for motion". |
| N37 | G290: the Notes list entrance is opacity only under the flag; a new row is a 150 ms fade; no replay on a revisit. | none (NRM:17 covers open only) | GAP (lab): no entrance or revisit row in NRM. |
| N38 | G304: Reading Finish is a named action only under VoiceOver; Delete spend is a named action with 10 s UNDO; Set aside is a plain button. | MRA:87, MRA:58, MRA:117 | OK |
| N39 | G308: the 2 s Money ghost is for sighted use; under VoiceOver it waits for a tap or action and UNDO is a flat 10 s (Oct 16 1:35 PM). | MRA:60, MRA:56 | OK |
| N40 | G309: skipping the Groceries total has a 10 s UNDO and the control is named "Skip the Groceries total". | MRA:54, MRA:55, MRA:62 | OK |
| N41 | G313: in Low Power or Reduce Motion the mic bloom is a still mark at 1.2x, words crossfade and the level is not fed; listen, pause end and 60 s cap unchanged. | DAY:48, SPD:27 | FIX (lab): DAY:48 and SPD:27 say Low Power samples the mic "at most 20 times a second"; MAT:45 and MAT:64 repeat it. |
| N42 | G314: Reduce Motion dry windows are 0.8 s Speak and 0.6 s Write; Low Power keeps 3 s with a stepped drain through `withTesseraAnimation` (Oct 17 9:34 PM). | DAY:51, SPD:31 | OK for Speak and Low Power; GAP (lab): DAY:51 and SPD:31 give 0.6 s only for a live-workout set, not for Write. |
| N43 | G319: after a plan row is taken back Tess says "<title>, taken back." and "Plan, taken back."; the UNDO key reads "Undo <thing>". | DAY:30, DAY:37 | OK (key label not stated; low). |
| N44 | G320: a kept plan row reads "<title>, <time>, kept" with no "Proposed", no hint, only Undo; Keep and Skip actions are dropped. | none | GAP (lab): DAY has the keep and UNDO moments but no kept-row VoiceOver row. |
| N45 | G331: Shutdown flip is announced "<thing>, later" with a 10 s UNDO "<thing>, taken back". | DAY:68 | OK |
| N46 | G339: the widget rest Go swap is a crossfade and the digits do not roll in Low Power, through a shared helper. | LAW:85, LAW:86 | GAP (lab): the Low Power column says only "system throttles" and "system". |
| N47 | G359: the daily backup skips work already done today; in Low Power the first daily copy still runs, late-tail refreshes and folder re-check wait. | BHR:24, BHR:10 | GAP (lab): BHR has no Low Power row for the daily copy. |
| N48 | G371: folder pick, change and stop-using each get a 10 s UNDO with new words ("Backup folder, ...") and the local Undo word goes (Oct 17 9:28 PM). | BHR:19, BHR:20, BHR:21 | FIX (lab): BHR:19 "Saved a copy there. One a day from now on.", BHR:20 "Copies stay on this iPhone only now."; no "changed" row. |
| N49 | G373: VoiceOver Restore is the named action "Restore" only, no double-tap completion; announce "Restore, waiting. ..." once (Oct 17 11:04 PM). | BHR:32 | OK (announcement wording not in BHR:32; add it). |
| N50 | G383: the Trend wet tip sits still at 0.75 opacity in Low Power or Reduce Motion, and the loop stops when the page leaves. | none | GAP (lab): grep finds no Trend tip row in any motion spec. |
| N51 | G384: exercise page zooms (history, muscle, path) use the 150 ms Low Power crossfade. | GRO:60 (Kitchen and workout rise only) | GAP (lab): exercise page zooms not listed. |
| N52 | G386: no tick on any exercise page turn and none on appear; the raw selection haptic goes (Oct 17 3:55 PM R2). | tess-page-turn-motion.md:3 (none on a user turn) | FIX (lab): HMT:22 keeps `.selection` on the rail detent (`CarriageRail.swift:47`); also tess-sides-motion.md:20 has no haptic row for the rail. |
| N53 | G387: the Plans and Exercise day-word stagger and press fade go through `tesseraAnimation`; reduced branch drops offsets. | none | GAP (lab): no Plans row; a source scan test is owed. |
| N54 | G390: "Add to routine" says "Bench press, added to Push A." in the shared line, UNDO 4 s (10 s under VoiceOver), `.made`. | HMT:35 (`.made` only) | GAP (lab): receipt and UNDO not carried. |
| N55 | G428: when the first-send notice and a receipt both want the Ask line, the receipt shows first and the notice second, one claim and one UNDO. | CMS:6, CMS:18 | GAP (lab): CMS:18 says the notice shows on send and yields to "Asking Claude", but not the receipt-first order. |
| N56 | G436: undoing a capture plays `.undo`, says "Tacos, taken back." once at high priority and replaces the old receipt. | DAY:54 | OK |
| N57 | G441: typing "undo" undoes, the same check as saying it. | none | GAP (lab): not in DAY or SPD. |
| N58 | G457: Low Power never changes a ring; the in-app flare follows Reduce Motion (Oct 18 12:23 AM). | CCK:46, MAT:58 | OK |
| N59 | G460: cold launch in Low Power skips the full-history warm-up and builds on the first query. | none | GAP (lab): not in NAL or MAT. |

**Still to fold into specs:** N14 and N16 are done (`tess-capture-miss-motion.md`); N21's rows are done (Speak section B).

**Design files not on master yet:** `shutdown.md` (branch commit `3fd66f0f`) and `pockets-91.md` (`9fb7d9b1`, branch `claude/project-thread-b3tu3f`) are cited by the day-screens and muscle-figure specs; read them at those commits until Design's PRs merge.

**Open asks for Product (from `tess-capture-miss-motion.md`):** (1) the offline line holds 10 s (lab default); (2) Cancel has no spoken confirmation, focus returns to the box (lab default).

**Kitchen's 225 open calls (7:24 AM Oct 18):** rows N22 to N59 fold the 38 that rule motion, haptics, Low Power or UNDO. Cite prefixes in those rows (from the folding draft): `docs/design/motion/` (prefix dropped): CCK = tess-cook-clock-lowpower-and-timer-end, GRO = tess-groceries-lists-and-home-settings-lowpower, DAY = tess-day-screens-motion-pass, SPD = tess-speak-plan-daylog-copylist-lowpower-pass, MRA = tess-money-reading-motion-amended, BHR = tess-backups-health-review-motion, LAW = tess-live-activity-lockscreen-widget-motion, NRM = tess-notes-recipes-motion, HMT = tess-haptics-migration-table, CMS = tess-capture-miss-motion, NAL = tess-notification-ask-and-launch-notes-motion, MAT = tess-lowpower-reducemotion-matrix. G227 says "Design edits sheet 69"; recipe-clock.md is not in this repo, so that line is not checked. Skipped as already carried (confirmed): G446 (NAL:28), G458 (NAL).
