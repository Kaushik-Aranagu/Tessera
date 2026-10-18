# Day screens motion pass: Plan my day, Speak, Day log, Shutdown, Habits (board 70)

Lab spec with Normal / Reduce Motion + Low Power (RM/LP) / VoiceOver columns and one haptic per moment, written against Product's
rulings of Oct 17, 9:56 PM PT (`decisions.md` line 1039, "Kitchen gap hunt 20 calls, PR #961, defaults accepted, reversible"; the
hunt-20 file itself says "None yet", so cite the decision, not the hunt), the lab rulings at 9:34 PM (line 1031) and 9:58 PM (line 1041).
It extends `tess-speak-plan-daylog-copylist-lowpower-pass.md` (Speak, Plan, Day log: the VoiceOver columns and the Plan hold rows
here win) and adds the two screens that sheet lacked, Shutdown and Habits. Code read at master `efb867b`.

Rulings in force:

1. A masked habit reads **"Private habit"**, by the one private-text check (G334).
2. **Every hold key that writes more than one thing is named-action-only under VoiceOver**: START WITH (up to seven ops), CLOSE THE DAY, Finish, Done, Reset. Tap keys stay tap (G323). The key's double tap speaks "Hold to ..."; the action completes it.
3. Plan my day: a sighted skip stays silent; VoiceOver gets a spoken line plus a 10 s UNDO; **the hold keeps only the visible rows** (G321, G322).
4. The plan wording and the Monday week story wait for power OK and retry on the next open (G312, G316).
5. Speak under VoiceOver: the listen **ends on a pause** as for a tap; the ghost's wait is **a flat 10 s with a Cancel action** (G324, G325).
6. Shutdown and Habits carry Low Power rows, the Reduce Motion path (G317, G318).
Standing: D5 (LP = RM, 150 ms crossfade, the soul keeps her own LP form); one haptic per moment through `tesseraFeedback`; his own touches
play in LP and quiet hours; Tess-initiated landings follow quiet hours (23:00 to 07:00) and make no sound or haptic; UNDO 4 s new /
10 s change / flat 10 s under VoiceOver (`HomeQueue.swift:43-51` already holds the 10 s); "best" never "record"; clocks "8:30 pm".

## 1. Plan my day

| Moment | Normal | RM/LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Plan offered | the rules plan draws at once, silent | opacity only, 150 ms | read as one list | none (the offer opens 08:00 to 21:00, so no quiet-hours landing) |
| Rows breathing | opacity 0.5 to 0.66, one shared timeline (not one per row) | still at 0.6 (`HomePlan.swift:342`) | n/a | none |
| Arm a swipe (past 120 pt) | n/a | n/a | n/a | `.selection` once at the threshold |
| Keep a row (swipe right) | title dries by a 700 ms clip sweep, time +250 ms; Tess "Reply to landlord, 8 am." with UNDO, 10 s | one 150 ms ink fade | spoken receipt; actions "Keep" and "Skip" | `.made` once |
| Skip a row (swipe left) | row slides off, queue closes 320 ms | 150 ms fade | spoken line + **10 s UNDO** | `.notNow` once (RELH:11 and :30; the earlier lab sheet's "none" is retired: the row moves, so it is `.notNow`, "nothing is written") |
| Skip the plan (hero swipe left or the action) | silent for a sighted user | 150 ms fade | spoken "Plan skipped for today." + 10 s UNDO ("Plan, taken back.") | none; `.undo` only on UNDO |
| **Hold START WITH (0.7 s)** | line empties to a 0.9 pt trace at 35%, repaints with a bead; the hero lifts (up 24 pt, blur, 320 ms) and the first item rises into the hero (480 ms house); Tess "Plan kept. X is up." with UNDO 10 s | fill without thickening, no bead, hero and first item crossfade 150 ms | double tap does **not** complete (speaks the hint "Hold to keep N tasks"; the named action is "Keep"); the named action completes with no hold fill | **`.made` once at completion, however many rows**. The press-begin tick and the raw medium 0.8 are deleted (migration table rows 22 and 23). |
| Rows past five | "N MORE" label stays untouched; those rows never dry | same | "N more" is a button | none |
| Claude call out | cloud mark, three wisps rise off the soul; Tess works | no wisps; soul at full opacity (G225) | "Thinking" once | none |
| Claude call in Low Power | automatic call does not run; the wording is owed and retried on the next open with power OK; his own pull still runs | same | same | none |
| Reply lands | titles slide on the settle spring 520 ms, key words crossfade blur 4 to 0 over 420 ms, VIA CLAUDE fades in | one 150 ms crossfade | announced once | none |
| Failure line | "Claude didn't answer in time. Here's your usual plan." 4 s | 150 ms fade | announced | none |
| UNDO of a keep | the row's ink returns to proposed; "Reply to landlord, taken back." | fade | flat 10 s | `.undo` once |

Defects to fix with it: `keepPlan` loops every row (`HomePlan.swift:173-181`), so cap it to the visible five and state the count in the
hint ("Hold to keep N tasks", action "Keep"; ruled 10:05 PM, DEC:1043); `Paint.swift:314` completes a hold key on one VoiceOver double tap (see section 6);
the row-keep receipt passes `undo: record` (`HomePlan.swift:156`) and the plan-kept receipt passes `takeBack:` (`:188`), and both closures change data and speak nothing; `HomePlan.swift` never calls `soul.handle(.askClaude)`.

## 2. Speak

| Moment | Normal | RM/LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Soul touch-down | swell 1.06 over 130 ms | no swell | n/a | `.selection` once |
| Hold 400 ms: listening begins | bloom x1.4, breathes with the level up to x1.55 | RM: still bloom x1.2; LP: soul's LP form, microphone sampled at most 20 times a second (today about 43) | the action "Talk to Tess" starts a **tap-style listen** (`hold: false`, `BottomChrome.swift:279-285`), opens the layer, announces "Listening" | `.listening` once when listening begins (never played today) |
| Words as heard | each word rises from 6 pt blur | fade in, no blur, 150 ms | transcript announced when settled, not word by word | none |
| End of the listen | 1.2 s pause, or tap the bloom, or 5 s of no words ("Didn't hear anything."), or 60 s | same | **ends on a pause** like a tap (today `SpeechListener.swift:168` ignores pauses in hold mode); the action renames to "Stop listening" while active | none |
| Ghost and dry | clean sentence at 45%, cobalt line drains right to left: **3 s** (2 s in a live workout) | RM: 0.8 s (0.6 s in a workout); **LP: the full 3 s with a stepped drain, about 0.75 s x4** (ruled 9:34 PM) | **flat 10 s, a named Cancel action, never shortened by RM or LP**; the layer announces "<sentence>. Keeping it in 10 seconds"; the ghost is a button "Edit" with the action "Cancel"; the full heard text shows | none |
| Touch the ghost | stops drying, the sentence opens in the Write line | same | "Edit" opens it | none |
| Commit | everything gathers into the soul, 220 ms; Tess says the result with UNDO | 150 ms crossfade | spoken receipt | **`.made` once** (ruled 9:34 PM). Replaces the raw `.success` (`BottomChrome.swift:131`). |
| UNDO | "...taken back." | fade | flat 10 s | **`.undo` only**: the UNDO word's press must be silent (migration table row 26) |
| Doubtful parse | no draining line; Tess names her guesses as value words | same | read in order | none |
| Refusal line | house spring in, cobalt line and one working ink word | 150 ms fade | read as text | none (`.notSaved` is for a failed write only) |
| Cancel | drag left off the soul, or tap the veil: nothing saved, no line | same | the named action "Cancel" | none |

`BottomChrome.swift:653` shortens the ghost wait to 0.8 s under Reduce Motion with no VoiceOver exception; it would shorten the
VoiceOver wait too. The VoiceOver 10 s is a separate branch, tested.

## 3. Shutdown (not built: no CLOSE THE DAY anywhere in the code)

`shutdown-grammar.md` (item 63) wins over `shutdown.md` (item 34). There is no day stroke on Home and no strike on a flipped row.

| Moment | Normal | RM/LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Flip a row (tap) | value crossfades TOMORROW to LATER, blur 4, 160/360 ms; the name drops to `inkSecondary` | crossfade only | "<thing>, later" + 10 s UNDO (Kitchen proposal; lab default) | `.selection` once |
| Type the first line | keyboard rises 340 ms (system); TOMORROW, FIRST, line and hairline ride up; the rest fades back to 25%, blur 3, 420 ms | no ride: the column hides, the line shows above the keys in place | normal text field | none |
| Say the line | words stream into the line (6 pt blur), the lead phrase squeezes 320 ms, a wet cobalt breath dries to ink over 3 s; Tess "Reply to the landlord, tomorrow first." | 150 ms crossfade | announced when settled | `.listening` at the hold start |
| Habit ask | "Read today?" with DONE and NOT TODAY after the opener dries; a masked habit asks **"Private habit today?"** | 150 ms | the two words are buttons | the answer is `.selection`; DONE writes "Read, done." with UNDO 10 s |
| **Hold CLOSE THE DAY (0.7 s)** | ink line empties to a trace at 35%, repaints with a bead | fill without the bead; the check-in stroke without the drop (the Low Power row, G317) | double tap does **not** close; the named action "Close the day" does | **`.done` once** (the map's "Shutdown complete"). Retires the sheet's `.success` (`shutdown-grammar.md:21`, :63 item 5; `shutdown.md:42`; audit M8). |
| Handoff | each kept row's TOMORROW lifts toward the top, 620 ms, 80 ms apart, shrinking and blurring; the column folds, blur 3, 420 ms; the soul plays `done` | crossfades, no lift | rows announced as moved | none |
| Closed day | the day label crossfades to "Thursday night"; the hero is his line or tomorrow's first timed item; Tess "Closed. Your line is set for 8 am." with UNDO 10 s | 150 ms | spoken once | none |
| UNDO of the close | "Shutdown, taken back."; everything reverses, the soul wakes | 150 ms | flat 10 s | `.undo` once, never `.success` |
| 22:00 close by itself | crossfade, no Tess line, no UNDO | same | silent | none. **No timer or poll at 22:00: the mark is written on the next open.** |

Never after 23:00: any haptic the app raises on its own. The hold under his finger is his.

## 4. Habits (copy only today: `HabitsCopy.swift` has no caller and there is no Habit class)

| Moment | Normal | RM/LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Check in (tap today's stroke, or any day this week) | the stroke falls 26 pt, lands wet at x1.25 with 2 pt blur, settles 460 ms, dries to the rest tint over 2 s; the count rolls; Tess "Read, 3 of 5 this week." UNDO 4 s | strokes fade in place, counts crossfade, 150 ms (LP = RM, G318) | one stop per habit "Read, 3 of 5 this week, marked today" with actions Mark today / Mark another day / Open | **`.done` once**, plays in LP and quiet hours (his touch). Retires `.impact(medium, 0.8)` (`habits-grammar.md:25`, audit M9). |
| Swipe right on the line | arms past 140 pt; a fleck arcs to the soul, 520 ms, she brightens once, silent | no fall, no fleck, stroke fades 150 ms | the action does the same | arm `.selection`; completion `.done`; the fleck makes no sound (it is not `.fleckReachesNow`) |
| Already in | Tess "Read is already in for today." | same | spoken | none |
| Clear a done stroke | reverse drop; UNDO 10 s | fade | flat 10 s | `.undo` on UNDO |
| Week met | the strokes join into one painted stroke Monday to that day, 700 ms left to right; Tess "Read done for the week." No confetti, no `.success` | the joined stroke appears whole | spoken once | none beyond the check-in's `.done` |
| Counted by a rule | a stroke flies in from the top, 700 ms, lands wet, dries; Tess "Push A counted for Train, 2 of 3." | fade in place | spoken | none (the finish had its own) |
| New habit | the line rises 10 pt, 360 ms, seven guides, "5 a week"; Tess "Read added, 5 times a week." UNDO 4 s | 150 ms fade | spoken | `.made` once |
| Rule cycle (COUNTS BY HAND etc.) | value-word swap; finished workouts paint in 120 ms apart | fade | the word is a button | `.selection` |
| Pause or delete (ink-line words) | Tess lines; delete UNDO 10 s | fade | named actions | `.selection` / `.undo` |
| Side (LATELY, HOW IT COUNTS) | right edge glance, then the full side | 150 ms crossfade | the side is a page | `.selection` once on the full side |
| A masked habit | reads **"Private habit"** everywhere; same height, 100% ink, same timings; the check-in animates identically | same | same | same |

Never: streaks, "best", "missed", red, rings, percentages. The soul's tick beat (`SoulRouter.swift:36`, 520 ms) plays for a habit
check-in only as her own state; she adds no haptic (the raw `.success` at `TessSoul.swift:143` is deleted first).

## 5. Day log (the screen does not exist yet: Core has `DayStory`, Review shows week lines)

The Speak/Plan/Day-log sheet's Day-log section stands. Additions from the rulings:

| Moment | Normal | RM/LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Margin scrub, per day | lines to 30% in 200 ms; numeral 80 Light beside the finger | 150 ms crossfades, numeral without travel | the scrub is the day list (adjustable) | `.selection` per day, capped at 25 a second; the landing tick always plays |
| Margin scrub, per week boundary | the same | the same | the same | **`.pickedUp`** (light 0.5): the nearest light cue in the map; lab default, a new case is the alternative (Product to rule) |
| Row read aloud | n/a | n/a | "6:12 pm, Benched 80 by 5, best" (`DayLine.spoken`, `DayStory.swift:40`, has no caller today); "by" for x; "best", never "PR" (`day-log-v1.md:52` still says "PR": Design's file) | none |
| Tap a line with an object | the object reveals from the row, 440 ms house | 150 ms | a button only when it has an `objectID` | `.selection` once |

Mask gaps to close in the log's lines (workout, new routine, "Ticked N on <list>", private note bodies): they print raw today. They
look and move identically once masked.

## 6. Hold keys under VoiceOver (shared defect, G323)

`PaintKey` completes on one double tap (`Paint.swift:314`, `.accessibilityAction { complete() }`). Ruling: a hold key that writes more than one
thing (START WITH, CLOSE THE DAY, Finish, Done, Reset) speaks "Hold to <verb>" on double tap and completes only through a named
action ("Keep", "Close the day", "Finish <title>", "Done", "Reset"). Tap keys stay tap. Single-write holds (a habit check-in on a
list line) still follow the one-stop-with-actions rule. Voice Control and Switch Control complete by the action names. The hold's visual
fill does not run for a named action: the result lands at once, with the same single haptic as the hold.

## 7. Tests the build should carry

1. Plan: hold plays `.made` once and keeps only the visible rows; rows past five stay proposed.
2. Plan: VoiceOver double tap on START WITH does not keep; the named action does, with the same one `.made`.
3. Plan: a VoiceOver skip speaks a line and offers UNDO for 10 s; a sighted skip speaks nothing.
4. Plan wording does not run in Low Power and is retried on the next open with power OK; his own pull runs.
5. Speak: under VoiceOver the listen ends on a pause; the ghost wait is exactly 10 s under VoiceOver, Reduce Motion and Low Power, with Cancel; sighted waits are 3 s, 0.8 s (RM), 3 s stepped (LP).
6. Speak: commit plays `.made` once; UNDO plays `.undo` once and never `.selection` with it; `.listening` plays once at the start.
7. Shutdown: close plays `.done` once, never `.success`; UNDO plays `.undo`; the 22:00 close needs no timer and writes its mark on the next open.
8. Habits: check-in plays `.done` once; a masked habit reads "Private habit" in every receipt, ask and VoiceOver label with identical timings.
9. Day log: scrub ticks at most 25 a second and always on the landing number; VoiceOver rows say "best", never "PR".
10. Grep: none of the five screens uses a raw `.sensoryFeedback`.

## 8. Asks

- Product (ruled, DEC:1043): Plan row skip is `.notNow`; the Day log week-boundary tick is `.pickedUp`; the Plan hold hint is "Hold to keep N tasks" with action "Keep". Nothing left to confirm.
- Design (their files): `shutdown.md` and `shutdown-grammar.md` say `.success` for the close (map: `.done`); `habits-grammar.md:25` says medium 0.8 (map: `.done`); `day-log-v1.md:52` says "PR" (must be "best"). Kitchen's G319, G320 and G327 to G333 (spoken forms) were proposals; only the six calls above are ruled.
- Build: `TessVoice.hold(undo:holds:)` gives any UNDO line 10 s unless the caller passes `holds` (`HomeQueue.swift:45-52`), so every row here that says "UNDO 4 s" (check-in, new habit) must pass `holds: .seconds(4)`; under VoiceOver it is a flat 10 s regardless.
- Build: there is no timer or poll at 22:00; the Shutdown mark is written on the next open (row 76, test 7).
- Design (new strings, unruled): "Plan skipped for today." and "Private habit today?" need Design's wording verdict before the build.
