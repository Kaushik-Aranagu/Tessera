# Habits and Shutdown: quiet hours, Private habit, hold keys, UNDO windows (board 77)

Extends `tess-day-screens-motion-pass.md` §3 (Shutdown, :62-78) and §4 (Habits, :80-97); it does not restate their Normal / Reduce Motion (RM) / Low Power (LP) tables. This sheet adds what those tables leave open: every moment under quiet hours, the Private habit row by row, hold keys under VoiceOver, one UNDO table, and the gaps the sheets never specced. Rulings are cited; lab defaults are marked *(lab default)* and go to Product in §7. Checked at master `ce2cd3a3`.

**State of the code.** Neither screen is built. `Features/Habits/HabitsCopy.swift` is strings only (79 lines, no caller outside `TesseraTests/HabitsCopyTests.swift`), there is no Habit class, and there is no CLOSE THE DAY anywhere in `Features/`. "Shutdown" exists only as `DayPart.shutdown` (`NowRanker.swift:27,37`, 21:00 to 22:00) and the word "tonight" (`HomeLines.swift:409`). So there is no animation or haptic site to migrate on either screen; the build starts clean and must start right.

## 1. Rules in force for both screens
- LP = RM = one 150 ms crossfade, no stagger, blur or travel (G317/G318, DEC:1039(6)); the soul keeps her own LP form.
- One haptic per moment, always through `tesseraFeedback`; no raw `.sensoryFeedback` (test 7).
- Quiet hours are 23:00 to 07:00, fixed (DEC:1017). A Tess-initiated landing plays no haptic or sound in them (DEC:1011(3)); his own touch always plays, in LP and in quiet hours. `Haptic` has no origin field and no quiet-hours gate today (`DesignSystem/Haptics.swift`); `SoulRouter.swift:315` `isQuietHour` is the right window and is the one to reuse.
- The app raises no ask from 23:00 until 07:00, nor from the moment the day closes until 07:00 (DEC:598). A closed day never asks, but his own captures still get receipts (DEC:585).
- Check-in and close both play `.done`; the sheets' `.success` and medium 0.8 are retired (ruling index H6; DEC:1025, 1041).

## 2. Quiet hours, moment by moment
Whose is the moment decides the haptic. "His" = under his finger, so it plays; "Tess's" = she raised it, so it is silent after 23:00 and its words still appear.

| Moment | Whose | At 21:30 | At 23:30 | Haptic |
|---|---|---|---|---|
| Habit check-in (tap, swipe, hold) | his | stroke drop, count roll, Tess line, UNDO 4 s | the same | `.done` always |
| New habit written | his | line rises, UNDO 4 s | the same | `.made` always |
| Swipe armed past 140 pt | his | arms | arms | `.selection` always |
| Fleck to the soul | hers | arcs 520 ms | arcs | none (silent at all hours) |
| Counted by a rule (a finished workout or cook) | hers | stroke flies in 700 ms | flies in | none at all hours (the finish had its own) |
| Shutdown opener ("Did 4 tasks, 1 workout, cooked once.") | hers | after the hero settles | the line shows, no sound | none |
| Habit ask ("Read today?") | hers | after the opener dries | **not raised**: held until 07:00 (DEC:598) | n/a |
| Answer DONE / NOT TODAY | his | writes "Read, done." UNDO 10 s | n/a (no ask) | `.selection` |
| Hold CLOSE THE DAY | his | ink line empties, bead | the same (Shutdown stays reachable until 04:00) | `.done` always |
| "Closed. Your line is set for 8 am." | hers, but the answer to his hold | UNDO 10 s | the same line, UNDO 10 s | none (the hold's `.done` is the one haptic) |
| UNDO of the close | his | everything reverses | the same | `.undo` always |
| 22:00 close by itself | hers | crossfade, no Tess line, no UNDO, no timer | n/a | none; the mark is written on the next open |
| Finish after 23:00 | his | n/a | closes the day quietly stamped 10:00 pm, no Shutdown page (DEC:221(1)) | the finish's own |
| Soul tick for a done habit (`SoulRouter.swift:36`, 520 ms) | hers | brightens once | brightens once, at her quiet-hours pigment | none; the raw `.success` at `TessSoul.swift:143` is deleted first |

Never after 23:00: a haptic, sound or new line the app raises on its own. Nothing here sets a timer for 22:00, 23:00 or 04:00.

## 3. Private habit, row by row
A private habit reads **"Private habit"** (DEC:1039(1), 1049, 1051), never its words, with no tap-to-reveal; it is not Spotlight-indexed and not in widget or Live Activity text. The motion is identical to any other habit: same height, 100% ink, same timings, same haptic. Only the words differ.

| Where | Reads | Motion and haptic |
|---|---|---|
| Habit line on the page | "Private habit", count "3 of 5" | as any habit |
| Check-in receipt (Tess) | "Private habit, 3 of 5 this week." *(lab default; thing first)* | as any habit; `.done` |
| Habit ask (Shutdown) | sits in the Shutdown band as one plain line (G418, DEC:1067 item 7; DEC:593 wins over the empty band in `shutdown.md`); masked: "Private habit today?" with DONE and NOT TODAY (the "Private habit" case of the one private-text function, G416/G417; the exact ask wording still needs Design's verdict, `tess-day-screens-motion-pass.md:140`) | as any ask; answer `.selection` |
| Ask receipt | "Private habit, done." UNDO 10 s *(lab default)* | as any habit |
| Week met | "Private habit is done for the week." (the code's plural form, `HabitsCopy.swift:31`); in a list: "Private habit and Stretch are done for the week." | joined stroke, 700 ms; none |
| Rule line ("Train now counts workouts.") | "Private habit now counts workouts." | `.selection` |
| New-habit receipt | "Private habit added, 5 times a week." | `.made` |
| Delete / pause lines | "Private habit deleted." / "Private habit paused this week." | UNDO as §6 |
| VoiceOver label | "Private habit, 3 of 5 this week, marked today" | the same actions |
| Widget, Lock Screen, extension payload | "Private habit" (DEC:1049) | none |

Test: with a private habit, no receipt, ask, VoiceOver label or extension payload contains a word of its name, and every timing matches a normal habit to the frame.

## 4. Hold keys under VoiceOver
- **CLOSE THE DAY** writes several things (kept rows to tomorrow, LATER rows to Later, the line stored, the Day log frozen), so it is a hold key that writes: it speaks **"Hold to close the day"** *(spoken form inferred from the "Hold to ..." rule, DEC:1027, 1043)* and completes only through the named action **"Close the day"** (DEC:1039(2); `tess-day-screens-motion-pass.md:72`). No hold fill: the result lands at once with the same single `.done`. Voice Control and Switch Control complete it by that name. `Paint.swift:314` still completes any hold on one double tap, so the build closes that first.
- **Hold on a habit line** is the check-in shortcut, not the only path: the tap on the stroke does the same single write and exists beside it. It stays one stop with the actions Mark today / Mark another day / Open, and is **not** named-action-only *(lab default; single write, DEC:1039(2) names only hold keys that write more than one thing)*.
- Tap keys stay tap: the TOMORROW / LATER flip, DONE, NOT TODAY, the rule-cycle word, PAUSE / DELETE ink-line words.

## 5. UNDO windows, one table
Windows are 4 s for a new write, 10 s for a change or removal, and a flat 10 s under VoiceOver. One slot, app-wide; a new line replaces the old. The line sits directly above the key row with UNDO at its right (the shared line). `TessVoice.hold` defaults an UNDO line to 10 s (`Features/Home/HomeQueue.swift:43-51`), so every 4 s row passes `holds: .seconds(4)`.

| Action | Window | UNDO line | Haptic on UNDO |
|---|---|---|---|
| Check-in (new stroke) | 4 s | "Read, taken back." *(lab default; thing first)* | `.undo` |
| Clear a done stroke (change) | 10 s | none needed: tap again re-marks | `.undo` |
| New habit | 4 s | "Read, taken back." | `.undo` |
| Rule cycle | 4 s (the sheet's number, the only source) | "Train rule taken back." | `.undo` |
| Pause / resume this week | 10 s *(lab default: a change to a habit that exists)* | "Read, taken back." | `.undo` |
| Delete habit | 10 s | "Read is back." | `.undo` |
| "Read, done." from the Shutdown ask | 10 s | "Read, taken back." | `.undo` |
| Close the day | 10 s | **"Shutdown, taken back."** *(comma form: thing first, DEC:716)* | `.undo`, never `.success` |
| Flip a row to LATER under VoiceOver | 10 s | "<thing>, later" | `.undo` (a Kitchen proposal, unruled) |
| Type or say tomorrow's line | none inside Shutdown; 4 s before 21:00 ("Tomorrow line, taken back.") | | `.undo` |
| 22:00 silent close | none | none | none |

## 6. Gaps the sheets never specced *(all lab defaults)*
1. **Habits page arrival.** The old dab pop-in is superseded (`habits.md:3`, DEC:668 G20) and nothing replaced it. Use the shared first-visit entrance (`EntranceModifier`, `Editorial.swift:56-81`): rows rise 14 pt in reading order, `.smooth(0.28)`, 35 ms apart, first six only; RM and LP opacity only. Later visits: no entrance.
2. **Edit a habit** (rename, change the target). No sheet exists. Edit is delete and re-add on the writing line ("new habit read 6 a week"), with the new-habit motion; no edit sheet. Product to rule whether an edit gesture is wanted.
3. **Count at creation.** Sheet 85 and DEC:85 say a just-made habit reads "5 a week", never "0 of 5"; DEC:668 G1 and `habits-grammar.md` H11 say "0 of 5". Sheet 85 wins.
4. **Week-met line.** `HabitsCopy.swift:31` and sheet 85 say "Read is done for the week."; `habits-grammar.md` A4 says "Read done for the week." The code form wins.
5. **Paused week.** Strokes stay as guides, the count reads "paused"; a log in a paused week answers "The week stays paused." (DEC:694); no motion beyond a 150 ms crossfade of the count word; `.selection` on pause and resume.
6. **Quiet-hours landing for a late first-open of Shutdown.** The opener and closed-day line appear with words only (§2), no haptic, no change in look.

## 7. Asks
1. **Product:** first-Shutdown line, `DEC:590` "3 moving to tomorrow. Tap any to keep." against `DEC:342` and `shutdown-grammar.md:31` "Tap any for later." Which wins?
2. **Product:** confirm §3's two receipts, "Private habit, 3 of 5 this week." and "Private habit, done."; confirm §5's pause window (10 s) and the thing-first undo wording; confirm §6 items 1, 2, 3 and 4.
3. **Design:** the verdict on "Private habit today?" (open since `tess-day-screens-motion-pass.md:140`); `shutdown.md` and `shutdown-grammar.md` still say `.success` for the close, `habits-grammar.md:25` still says medium 0.8, and the sheets differ on the undo line ("Shutdown, taken back." against "Shutdown taken back.").
4. **Builder A (when built):** the quiet-hours gate and origin field on `Haptic`; close `Paint.swift:314`; delete the raw `.success` at `TessSoul.swift:143`; pass `holds: .seconds(4)` on the 4 s rows.

## 8. Tests
1. At 23:30: a habit check-in plays `.done`; a rule-counted stroke, the Shutdown opener and the soul's tick play nothing.
2. No habit ask is raised from 23:00 to 07:00, nor after the day has closed; his own capture still gets its receipt.
3. Hold CLOSE THE DAY: `.done` once, never `.success`; VoiceOver double tap does not close, the action "Close the day" does with the same one `.done` and no fill.
4. UNDO of the close plays `.undo` once; the line reads "Shutdown, taken back."
5. The 22:00 close needs no timer; its mark is written on the next open.
6. A private habit: no word of its name in any receipt, ask, VoiceOver label or extension payload; every timing equals a normal habit's.
7. Grep: neither screen uses a raw `.sensoryFeedback`; the 4 s rows pass `holds`.
8. Under RM and LP every moment is one 150 ms crossfade; the fleck and the week-met stroke do not travel.
