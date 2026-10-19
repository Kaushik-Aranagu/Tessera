# Cook: parallel-steps clock page and hands-free feedback (motion and feel)

DRAFT for Builder A (clock), Builder B (clock view), Kitchen lead (rows), Design (values). Docs only. Both parts are held work: parallel steps wait for "lanes" (`parallel-steps-acceptance.md:3`) and hands-free is "Later" unless Q3 names the clock app (`kitchen-v2-scope.md:40`). Nothing here is built. Anything not copied from a doc is marked (lab default).

Cite keys (`KEY:line`, docs/ paths): PS product/parallel-steps-acceptance.md (rows PS1-PS14 sit on lines 7-20, "Open" on 24-30); CMA product/cook-mode-acceptance.md; K84 product/kitchen-cook-mode-accessibility-acceptance.md; KB product/kitchen-v2-backlog.md; KS product/kitchen-v2-scope.md; GATE product/kitchen-cook-gate-rows-oct17.md; DEC product/decisions.md; CCK design/motion/tess-cook-clock-lowpower-and-timer-end.md; LAW design/motion/tess-live-activity-lockscreen-widget-motion.md; SPK design/motion/tess-speak-plan-daylog-copylist-lowpower-pass.md; MAT design/motion/tess-lowpower-reducemotion-matrix.md; HMT design/motion/tess-haptics-migration-table.md; RIX design/motion/tess-ruling-index.md; VOF research/fixtures/voiceover-recipe-clock-lists.md.

## Part 1. Parallel steps on the clock page

Rules from the docs that this part does not change: at most 2 live tracks, a third waits (`KB:84`, PS7 `PS:13`); cue words alone open lanes (`PS:24`); the join, not the guest, decides the next step (`PS:25`); one timer per timed step (`PS:9`); the clock is never a sum (`PS:8`); Low Power = Reduce Motion for this page, derived from `endsAt`, no running tick (`CCK:5, 9`).

### 1.1 How timers sit, which leads, ordering

| Thing | Normal | Reduce Motion and Low Power (same) | Cite |
|---|---|---|---|
| Two lines, one clock | the current track's line is set apart by the accent; the other is dimmer with its own timer under it. Never three lines | same | `PS:9, 13` |
| Lane opens (guest step starts at the host's start minute) | second short stroke forks beside the host stroke, drawn wet in 420 ms ease-out, dries over 2 s like a step title; its own bead lands at its start. Two tracks show only where they overlap | stroke appears whole, 150 ms fade; lands dry | `PS:7`, `CCK:21-22`; 420 ms is `CCK:53`'s number (lab default) |
| Beads | only the lead track's bead breathes (x1.14, 2.4 s, one ring per breath); the other holds still and dim so there is one breath on the page | both still; each moves in 1-minute steps with a 150 ms fade | `CCK:20`; one-breath rule (lab default) |
| Which track leads | the one he last touched; with neither touched, the host's | same | `PS:30` Open 7 |
| Lead changes (he touches the other line) | accent weight and the breath hand over in 320 ms | 150 ms crossfade | `PS:10`; 320 ms (lab default) |
| Order of lines | lead track, other track, then spoken timers under the key row by end time, soonest first, each on its own labelled line, none dropped | same | `CMA:80`, `K84:21` |
| Key row | one figure from the clock's join, never a sum ("12 MIN LEFT"); changes at the minute boundary of `endsAt` | 150 ms crossfade, no roll | `PS:9, 28`, `CCK:19` |
| Third candidate | waits; never a third lane; drawn after the earlier stroke; starts on the freed lane at the earliest end | when the lane frees it forks like any lane | `PS:13` |
| Lock Screen and Island | one cook, the soonest of the two timers leads, "+1" for the other | system-owned | `PS:20`, `LAW:53-54` |

### 1.2 One ending, the other keeps going

| Moment | Normal | Reduce Motion and Low Power | Haptic |
|---|---|---|---|
| Guest ends (2 min, host has 6 left) | that track's line flares cadmium, its stroke blooms to 6 pt, one ring leaves its bead (once), its step slides back as an overlay in 420 ms. The host's line, bead and timer carry on untouched; the bead of the ended track holds at the step's end until he moves on | line turns cadmium, 150 ms, no bloom or ring; overlay crossfades 150 ms | one `timeUp` (heavy 0.9) only if seen live within 2 s |
| Overlay when another timer is live | the overlay is a band over the ended track's own lane and the top of the page, not the whole page; the other timer's line stays drawn and counting, never dimmed below its lead/other weight (lab default; `CCK:55` says the step "slides back over the page" for one timer, so Design confirms this for two) | same | none extra |
| Host ends, no guest live | the host's step stays lit and held; step 4 is not lit by itself | same | one `timeUp` + one notification |
| Two end within 600 ms | both lines flare, one ring per line, one haptic, one overlay (the soonest), the other waits behind "+1"; the notification reads "2 timers are done." (new copy, Design to rule) | same, no rings | one `timeUp` |
| More than 600 ms apart | a new moment, a new haptic | same | `timeUp` each |
| "5 more minutes" on a held host | host restarts its own timer; later strokes shift right by 5 in 320 ms (lab default); a running guest is untouched; key row follows | later strokes crossfade 150 ms | none |
| Stop one line (drag left or Stop action) | that line fades 150 ms; "Rice stopped."-style receipt with UNDO; the other keeps running | same | none on a stop |
| Pause (slice 12b) | both beads hold, key row "PAUSED", minutes kept; both pending notifications removed; a spoken timer is not touched | same | none |
| Finish: hold DONE with a guest still live | hold fills left to right; no confirm; the page closes and both step timers stop silently; timers that belong to no step survive. Tess: "Paprika chicken, cooked." UNDO 10 s reopens the cook on its last step | cover fades out | `done` once; no flare, no `timeUp` |

Sources for the table: `PS:11, 12, 19, 20`, `CCK:52-56, 64-65`, `CMA:76, 78`, `PS:29`, `K84:38, 61`. Haptic cases and quiet hours below.

### 1.3 Haptics, quiet hours, Low Power

| Haptic | Whose | Normal / RM / LP | Quiet hours 23:00-07:00 |
|---|---|---|---|
| `timeUp` heavy (timer end) | his timer | yes / yes / yes | yes |
| Bead lights a step, soft impact (guest lands too) | Tess's | yes / yes / yes | no |
| Touching the other line | his touch | `selection` once (lab default; no map row) | yes |
| `done` on Finish hold | his hold | yes | yes |

Rows from `CCK:69-77`. A guest and its host starting together give one haptic (`CCK:77`). Low Power: no new timeline; both beads and both timers read one `endsAt` each, the page timeline pauses when the scene is inactive, DrainBar steps once a minute (`CCK:9, 23`). The notification of each timed step rings at any hour, quiet hours and Low Power included (`CCK:46`, `LAW:58`).

### 1.4 VoiceOver

- Each track is one stop: "Roast timer", value "8 minutes left, ends 6:52 pm", action "Stop" (`VOF:30`, `K84:54`). Order: lead track, other track, spoken timers soonest first, Tess line, key row (lab default; `CMA:7` says the clock page follows VO5-VO24, not the cover order).
- Value changes only at whole-minute boundaries; no per-second change (`CCK:29`, `VOF:23`).
- A timer end: one high-priority announcement "Roast, done." and focus does not move (`K84:56`, `VOF:29`). Two within 600 ms: one announcement "Roast and chicken, done." (lab default; one moment, one announcement).
- Lane opening is not announced; the step's own lit state is (`VOF:22`).

### 1.5 Build checks (camelCase)

`secondTimerEndsWithoutTouchingFirst`, `endedTrackHoldsWhileOtherCounts`, `twoTimersEndingTogetherGiveOneHaptic` (`CCK:77`), `leadFollowsLastTouchedLine`, `onlyLeadBeadBreathes`, `keyFigureUsesJoinNotSum`, `overlayLeavesOtherTimerDrawn`, `spokenTimerValueChangesOnlyAtMinuteBoundaries` (`CCK:33`), `finishStopsBothTracksSilently`, `pauseHoldsBothBeads`, `laneStrokeIsWholeUnderReduceMotion`, `quietHoursSilencesBeadNotTimeUp`.

## Part 2. Hands-free cook feedback

Ground: "Next", "back", "timer" by voice; on-device speech, grammar only (`KB:18`); Speak is SpeechAnalyzer on the phone (`DEC:880`); the cook phrases stay on the phone and never go to Claude (`GATE:6`). The docs name no wake word, no always-on listening and no spoken reply: those are open (Asks). Today a cook phrase reads: "8 mins" starts "Timer, 8 min."; "pasta 10" starts "Pasta, 10 min."; "step 3" goes to that step; "stop the rice" stops it (`GATE:18-23`). "next" and "back" are not in that list yet (Ask to Core).

Ruled by Product (Oct 19, mirror only): listening is opened by a tap (no always-on mic), there is no wake word, the window ends after 8 s of silence or when he leaves the page, a visible listening mark shows while it is open, there is no earcon (kitchens are loud), and a heard command gets one light haptic tick through MotionPolicy. Ambient talk with no cook keyword gets no reply at all.

### 2.1 The four states (what shows; no sound of ours)

| State | Normal | Reduce Motion and Low Power | Haptic and sound |
|---|---|---|---|
| Window opens (by his tap; closes after 8 s of silence or when he leaves the page) | a small cobalt mark appears beside the key row, "Listening" for first use only, then the mark alone; cobalt is Tess's voice (`K84:8`) | mark fades in 150 ms; Low Power: still mark at x1.2, mic level not fed (`SPK:27`, `MAT:64`) | `listening` once at open (`SPK:27`); no sound |
| Heard | the keyword as heard rises into Tess's line out of a 6 pt blur, large type for reading from across the room (`SPK:29`) | word fades in, 150 ms, no blur | one light tick through MotionPolicy on a heard command (ruled); no sound; the action's own haptic below is held back inside the same moment |
| Understood | the action's own motion is the answer: "next" moves the current track's bead only (`PS:10`); "timer 8" or "pasta 10" adds a labelled line; then a receipt in Tess's line: "Timer, 8 min." (`GATE:18-19`); step: "Step 3 of 6" | 150 ms crossfades; bead steps 150 ms (`K84:46`) | at most the action's own haptic: bead soft impact for a step (Tess's, off 23:00-07:00, `CCK:74`); a timer start has none (hold-to-start plays no haptic, `HMT:4`); no sound |
| Not understood | keyword heard, nothing it can act on ("timer" with no number; "stop the pasta" when no pasta timer): the existing line "Didn't catch that." plus the context example, nothing else (`GATE:36`) | 150 ms fade | none, no retry, not queued, not logged (`DEC:941`, `GATE:36`) |
| Wall-refused | key-shaped text or a phrase over 600 characters: refused first, nothing acts, nothing logged, "That's too long to send. Say it shorter." for length (`GATE:42, 51`); a walled word in a timer label (private name) still starts the timer but the label reads "Timer" (`LAW:53`, `DEC:89` rule: the wall masks the label, never the kind) | 150 ms fade | none, once, no retry (`GATE:51`) |
| Cannot listen (mic off, speech off, no on-device language, busy) | one cobalt line with one ink word that still works; the window never sticks in "listening" (`SPK:34`, `DEC:554`) | 150 ms fade | none |

Timing (lab default): a cook command commits when the grammar matches plus a 400 ms trailing pause, not the 1.2 s pause of a full Speak (`SPK:22`); no 2-3 s ghost wait, because "back" undoes "next". Timer start gets UNDO 4 s, a stop gets 10 s, flat 10 s under VoiceOver (`K84:10`).

### 2.2 Per-word behavior (lab default except cited)

| Word | Does | Notes |
|---|---|---|
| "next" | current track forward one step (`PS:10`, `K84:46`) | the Next key is retired on the clock page (RIX:18); the voice word replaces it |
| "back" | current track back one step | on step 1 it does nothing and the line reads "Step 1 of 6." |
| "timer ..." | starts a spoken timer on its own line under the key row, outside the stroke (`CMA:80`) | survives pause, done and leaving the page |
| "pause", "5 more" | as `CMA:76, 78` | already ruled; same feedback rows |

### 2.3 VoiceOver, quiet hours, privacy

- Window mark: label "Listening for next, back and timer", hidden when closed. Each receipt is announced once, high priority, focus does not move (`K84:56` pattern); "Didn't catch that." is announced once too (lab default, since the line is the only feedback). VoiceOver's own speech is not interrupted by "heard".
- Quiet hours: voice is his own; commands work at any hour, Tess's bead landing stays silent 23:00-07:00 (`CCK:74, 81`).
- A private cook reads "Private recipe" on every surface, drawn or spoken; receipts never name the recipe (`K84:7`).

### 2.4 Build checks (camelCase)

`handsFreeGrammarMakesNoNetworkRequest` (spy 0, `GATE:6`), `handsFreeNoKeywordStaysSilent`, `handsFreeKeywordWithoutSlotSaysDidntCatchThat`, `handsFreeNextMovesCurrentTrackOnly`, `handsFreeBackOnStepOneDoesNothing`, `handsFreeUnderstoodPlaysAtMostOneHaptic`, `handsFreeRefusalPlaysNoHaptic`, `handsFreeLongPhraseRefusedOnce` (`GATE:51`), `handsFreeKeyShapedTextNeverActs` (`GATE:42`), `handsFreePrivateLabelReadsTimer`, `handsFreeReducedMotionIsOneCrossfade`, `handsFreeLowPowerDoesNotFeedMicLevel`, `handsFreeVoiceOverAnnouncesOnce`, `handsFreeWindowClosesWithThePage`.

## Asks

- **Product:** answered Oct 19 (mirror only): tap-opened, no wake word, 8 s of silence ends it, no earcon, one light tick on a heard command. Still open: does Low Power end a listening window early (lab default: no, it is short and tap-opened)?
- **Core:** add "next" and "back" to the cook grammar next to N21-N26 (`GATE:18-23`); add a "2 timers are done." line (`LAW:61`).
- **Design:** confirm the overlay as a band when two timers are live (1.2), the one-breath rule, and the 320 ms hand-over.
- **Builder A:** the lane fork needs the draw path for a second stroke and a second bead; both read one `endsAt` each.
