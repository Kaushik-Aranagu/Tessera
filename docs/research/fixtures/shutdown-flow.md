# Shutdown, start to closed (board item 148)

For: Builder B, Core, QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `ae3d11b` and Design's branch (`origin/claude/project-thread-b3tu3f`, same text in `/mnt/project-files/tessera/design/`). Traced by hand, nothing was run.

**Sources.** Design 63 `docs/design/shutdown-grammar.md` (wins over 34 `shutdown.md` where they differ), Design 64 = the Oct 16
addendum at the end of `docs/design/habits-grammar.md`, `evening-on-now.md` §4 to §6. Research `shutdown-daylog-copy.md`
(slots A to F), `fixtures/asks-after-close.md` (C1 to C14, CL1 to CL11), `asks-one-list.md`. Product `decisions.md`
3:34, 3:43, 3:46 AM and 11:35 AM PT Oct 16. Fixed: Shutdown 9 pm, silent close 10 pm, day turns 4 am, quiet hours 11 pm to 7 am.
All names, counts and times below are made up.

## The flow (words quoted from Design 63/64; "Default proposed" marks a gap)

1. **9 pm, Shutdown sets in on Home.** Day label "Thursday evening", context line "9:04 pm", hero "Shutdown". From 11 pm the label is "Thursday night".
2. **The carry-over label:** "3 MOVING TO TOMORROW" (past midnight "2 MOVING TO FRIDAY"). Absent when nothing rolls.
3. **One line per rolling row**, value TOMORROW at the right, at most 3; with 4 or more the third place reads "5 MORE" and a pull shows the rest.
4. **Tess's band says the opener**, slot B, no UNDO: "Did 4 tasks, 1 workout, cooked once." Quiet day: "A quiet one. Want a line for tomorrow?" Late night: "Filed under Thursday. Did 3 tasks, cooked once." **First Shutdown ever:** slot C instead, once: "3 moving to tomorrow. Tap any to keep."
5. **The habits check-in (Design 64),** after the opener dries, one hand-counted habit at a time: "Read today?" with DONE and NOT TODAY. DONE: "Read, done." with UNDO 10 s. NOT TODAY writes nothing and the ask fades. Unanswered, it lapses with the hold.
6. **Tap a row:** TOMORROW crossfades to LATER, `.selection`. Tap again to bring it back.
7. **TOMORROW, FIRST** label, then the writing line with slot D's placeholder: "Tomorrow starts with Standup at 9:30 am." or "One line for tomorrow, if you want." (no placeholder on a quiet day).
8. **Typed:** tap the line, the keyboard rises, DONE over the keys. Tess says nothing. **Said:** hold the soul, "tomorrow first, reply to the landlord"; Tess: "Reply to the landlord, tomorrow first." No UNDO. Nothing is stored until the hold.
9. **CLOSE THE DAY, hold 0.7 s.** The ink line empties to a trace and repaints, then the bead, `.success`. Each kept TOMORROW lifts away, LATER rows stay, the column folds, the soul plays `done`.
10. **The closed day:** "Thursday night", context "tomorrow, first", hero "Reply to the landlord", label "THEN PULL A, 7:30 AM" (no line: hero "Pull A", label "7:30 AM").
11. **Tess's close** (slot E, or F3/F4 late at night): "Closed. Your line is waiting at 8 am." with UNDO for 10 s. UNDO: "Shutdown, taken back." and Shutdown returns as he left it.
12. **From 10 pm without a hold** the day closes by itself: a crossfade, no Tess line, no UNDO. CLOSE THE DAY brings Shutdown back until 4 am.
13. **The close stores** (one undoable step): kept rows to tomorrow, LATER rows to Later, the tomorrow line, the frozen Day log line (slot A), and the closed-day mark with its time (CL2). App asks hold from here to 7 am (AQ6).

## Scenarios (week of Oct 19, 2026; times PDT)

| # | When | State before | He does | On screen | The close stores | Master today |
|---|---|---|---|---|---|---|
| S1 | Wed Oct 21, 9:00 pm | First Shutdown ever; 3 tasks today open; Read due | Looks | Hero "Shutdown", "3 MOVING TO TOMORROW", Tess C4 "3 moving to tomorrow. Tap any to keep." | nothing yet | not built; `NowRanker.swift:37` is `.shutdown` only |
| S2 | Wed Oct 21, 9:02 pm | S1, C line dried | Waits | "Read today?" DONE · NOT TODAY | nothing yet | no habits code (only `Haptics.swift:8,10` comments) |
| S3 | Wed Oct 21, 9:03 pm | S2 | Taps DONE | "Read, done." UNDO 10 s | Read check-in for Wed, at once (own UNDO) | not built |
| S4 | Wed Oct 21, 9:06 pm | S3, no line | Taps Clean the oven, holds CLOSE THE DAY | TOMORROW to LATER; E4 "Closed. 5 things in Wednesday's log." UNDO 10 s | 2 rows to Thu, oven to Later, slot A frozen, closed mark 9:06 pm | not built; no closed state (CL2) |
| S5 | Thu Oct 22, 9:00 pm | Second Shutdown; 4 tasks, Push A done, cooked once; 3 roll | Looks | Label "3 MOVING TO TOMORROW"; Tess B4 "Did 4 tasks, 1 workout, cooked once." (C not said again) | nothing yet | not built |
| S6 | Thu Oct 22, 9:04 pm | S5; Push A logged by Train's rule (counts workouts) | Waits | No ask for Train (rule-counted); "Read today?" only | nothing yet | not built |
| S7 | Thu Oct 22, 9:05 pm | Read already counted from "read 20 pages" at 7 pm | Waits | No "Read today?" (RF18) | nothing | not built |
| S8 | Thu Oct 22, 9:07 pm | S5 | Says "tomorrow first, reply to the landlord" | Line streams in; "Reply to the landlord, tomorrow first." no UNDO | nothing yet | no lead-phrase grammar in `TessGrammar` |
| S9 | Thu Oct 22, 9:10 pm | S8 | Holds CLOSE THE DAY | Lift, fold; "Closed. Your line is waiting at 8 am." UNDO; hero "Reply to the landlord", "THEN PULL A, 7:30 AM" | 3 rows to Fri, the line, slot A, closed 9:10 pm | `Haptics.swift:10` `.done` covers it; page not built |
| S10 | Thu Oct 22, 9:10 pm + 6 s | S9 | Taps UNDO | "Shutdown, taken back." Shutdown as he left it, line still written | everything from S9 reversed | not built |
| S11 | Thu Oct 22, 9:12 pm | S10, check-in lapsed at S9 | Holds again | Same as S9; no second "Read today?" | as S9, one step | not built |
| S12 | Thu Oct 22, 9:20 pm | Closed at 9:10 pm | Says "rice 12" | "Rice, 12 min." UNDO 4 s; rings 9:32 pm (CL9) | timer only | timer never fires (CL6) |
| S13 | Thu Oct 22, 10:40 pm | Closed | Types "buy stamps" | His receipt as usual (CL11); Now stays on the closed day | a task; Default proposed: dated Friday (SH6) | lands today, rolls at 4 am (`RollForward.swift:56-77`) |
| S14 | Fri Oct 23, 9:00 to 10:00 pm | 2 tasks open; never opens the app | Nothing | nothing | Default proposed: closed mark 10:00 pm written on next open, no rows moved (SH1) | `.late` from 10 pm (`NowRanker.swift:38`), nothing stored |
| S15 | Sat Oct 24, 7:10 am | Skipped yesterday | Opens app | Rolled rows on Now; no word about last night | 4 am roll, `rolls` +1 | `AppModel.swift:332` runs the roll |
| S16 | Sat Oct 24, 9:00 pm | Only Pull A done; "Call the bank" rolls | Looks | Label "1 MOVING TO TOMORROW"; B5 "Pull A, done. That counts." | nothing yet | not built |
| S17 | Sat Oct 24, 9:00 pm | Nothing done, no facts, nothing rolls | Looks | No label, no rows; B7 "A quiet one. Want a line for tomorrow?"; line has no placeholder | on hold: line, slot A, closed mark | not built |
| S18 | Sun Oct 25, 9:00 pm | Pull A running since 8:15 pm | Logs sets | Workout stays the hero; Shutdown waits for Finish (Product 11:57 AM PT) | nothing | ranker puts a running process first (`NowRanker.swift:3-5`) |
| S19 | Sun Oct 25, 9:40 pm | S18, finishes Pull A | Taps Finish | Finish view, then Shutdown; "Read today?" may now show | as S9 when held | not built |
| S20 | Sun Oct 25, 9:00 pm | Chili cook running, timer to 9:25 pm | Looks | Shutdown sets in; timer rings at 9:25 pm over it; check-in waits for an empty band (Default proposed) | cook stays open across the close | not built; CL6 |
| S21 | Mon Oct 26, 9:00 pm EDT | Travel day, phone in Eastern | Looks | Shutdown at 9 pm on the phone's clock; B line as usual | as S9 | `TesseraDay` reads wall clock (`TesseraDay.swift:1-10`) |
| S22 | Thu Oct 22, 10:00 pm | Shutdown on screen, typing the line | Still typing | Default proposed: silent close waits until he leaves the page (SH2) | nothing until hold or leave | not built |
| S23 | Thu Oct 22, 11:30 pm | Silent close at 10 pm | Taps CLOSE THE DAY, holds | "Thursday night"; F1 "Filed under Thursday. Did 3 tasks, 1 workout, cooked once."; close F3 "Closed. Sleep is also training." (workout day); no check-in (expired at 10 pm) | rows, line, closed mark kept at 10 pm | not built |
| S24 | Fri Oct 23, 12:20 am | Silent close Thu | CLOSE THE DAY, holds | "2 MOVING TO FRIDAY"; F4 "Saved to Thursday. Pick up tomorrow." | rows go to Friday (today after 4 am) | not built |
| S25 | Fri Oct 23, 4:05 am | Thu closed | Opens app | "Friday morning"; no CLOSE THE DAY | slot A frozen at 4 am if not held | turnover `AppModel.swift:331-338` |
| S26 | Thu Oct 22, 9:08 pm | Shutdown open | Says "tomorrow first, wifi password is 4471" | "Private note, kept." line stays empty (Default proposed) | private note only | `SecretWords.swift:6` exists, not wired here |
| S27 | Wed Oct 21, 10:30 pm | Legs B running since 9:20 pm, no Shutdown yet | Taps Finish at 10:30 pm | Finish view, then Shutdown; the 10 pm close waited and runs now | closed mark stamped 10:00 pm Wed; workout filed on Wed, the day it started; rows roll as at the close (SH4) | 10 pm close not built; nothing waits on a live workout |

## Edge rules

- **Opened after 11 pm:** only through CLOSE THE DAY (Shutdown sets in only 9 to 10 pm). Late-night slots F1 to F4; the day label reads "Thursday night". The check-in never shows (expired at the close, C6; quiet hours, C1).
- **After 4 am:** yesterday's Shutdown can't be opened. CLOSE THE DAY goes at 4 am, the roll runs, slot A freezes. A "tomorrow first" phrase at 5 am is before 9 pm, so it becomes the next day's line with UNDO "Tomorrow line, taken back.".
- **Twice in one evening:** UNDO within 10 s reopens as he left it; a second hold is a new step, no second check-in. After the 10 s, Default proposed: no way back (no CLOSE THE DAY after a held close); a said line replaces the hero (Design 34).
- **Never opened:** the day closes by itself at 10 pm. Default proposed (SH1): no write at 10 pm; on the next open Core writes the closed mark at 10:00 pm, moves no rows, keeps no line; rows roll at 4 am as today.
- **Live workout at Shutdown** (Product, decisions.md 11:57 AM PT): the workout stays the hero and Shutdown waits for Finish; no check-in while it runs. The 10 pm close waits too: it runs after Finish, stamped 10:00 pm, and the workout is filed on the day it started (S18, S19, S27). Builder B: no Shutdown over a live workout.
- **Claude off vs on:** Shutdown is rules only, the same words either way (slot rule: no model call). The line, the rows and the check-in never go to Claude. A phrase without the lead phrase goes to capture as usual; money, body and secret words never leave the phone (MU2, NE1). A Claude reply after the close is held (C13).
- **Reduce Motion:** crossfades only; no lift, no bead, no keyboard ride (the column hides, the line shows above the keys in place); the check-in stroke appears without the drop.
- **Quiet hours:** no haptic the app raises after 11 pm; his own timers ring (CL9). The hold's `.success` after 11 pm: SH7.

## Gaps

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| SH1 | No closed state and no silent-close write; the app may be asleep at 10 pm | `NowRanker.swift:37-38`; CL2 | Closed mark (held or silent, with time) written on the first open after 10 pm, stamped 10:00 pm | Core |
| SH2 | The 10 pm close can land while he is typing the line or flipping rows | Design 63 §12 | Wait while Shutdown is on screen; close when he leaves; keep his draft for CLOSE THE DAY until 4 am | Core, Builder B |
| SH3 | Kept rows moved by the hold skip `RollForward`, so `rolls` never counts and a task kept every night never ages to Later | `RollForward.swift:56-77` | The hold sets `rolledFrom` and `rolls` +1 exactly as the 4 am roll | Core |
| SH4 | Live workout at 9 pm: Shutdown, the check-in and the 10 pm close not drawn | Design 63; ranker precedence | Ruled 11:57 AM PT: all wait for Finish; close stamped 10:00 pm (S27) | Core, Builder B |
| SH5 | First Shutdown with nothing rolling: slot C is silent | Design 63 "first Shutdown ever" | Say B; keep the first-ever flag until a Shutdown with rows | Core |
| SH6 | A task captured after the close lands today and counts a roll at 4 am | `RollForward.swift:56-61` | Date it to the next day | Core |
| SH7 | `.success` on a hold after 11 pm: 63 says "before quiet hours", 34 allows "under his finger" | Design 63, 34 | Play it; the hold is his finger (CL9 reading) | Design |
| SH8 | B2 and E2 say "PR"; Product's "best" everywhere | `shutdown-daylog-copy.md` B2, E2 | "Plus a best on bench." / "Closed. Bench best filed under Thursday." | Design |
| SH9 | C7 says no ask over Shutdown; CL10 puts the check-in there | asks-after-close C7 | CL10 wins for the check-in only; it waits for an empty band (no UNDO, no timer ring) | Core |
| SH10 | Order when his phrase lands during "Read today?" | Design 64 | His receipt takes the band; the check-in returns once after, still one ask per habit per day | Core |
| SH11 | A secret or money line said as the tomorrow line | NE1, MU2 | Secret: private note, line empty. Money: stays the line, never to Claude | Core |
| SH12 | Slot D, E3 and A printed 24 h ("09:30", "08:00") | `shutdown-daylog-copy.md` | Done: "9:30 am", "8 am"; A2, B2, E2 say "best" (SH8 drawn copy still Design) | Research |

Ruled (Product, decisions.md 11:57 AM PT): Shutdown and the 10 pm close wait for Finish; the close is stamped 10:00 pm and the workout is filed on the day it started. SH1, SH2, SH3 and SH9 taken as proposed.
