# Shutdown evening fixture (Product item AE)

For: Builder B, Core, Builder A, QA, Product. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Traced by hand on `origin/master` at `4d67f94` (Merge #492), nothing run; line numbers are master's. Design's §7 is on
`origin/claude/project-thread-b3tu3f` (`docs/design/m4-steers.md`), not on master.

**Sources.** `fixtures/shutdown-flow.md` (148: flow steps 1 to 13, S1 to S27, SH1 to SH12), `fixtures/day-marks.md` (147),
`time-words-sweep.md` (TW rows), `undo-windows-audit.md` (X rows), `fixtures/home-lines-day-one.md` (Q rows),
`plan-my-day-flow.md` (plan window ends at 9 pm), m4-steers §7, and `docs/product/decisions.md` (11:57 am, 12:29 pm,
12:35 pm, 12:39 pm, 12:45 pm PT Oct 16; 3:43 am and 3:46 am PT Oct 16).
**Rules under test.** Shutdown at 9 pm; silent close 10 pm; quiet hours 11 pm to 7 am; day turns at 4 am. A live workout
holds Shutdown and the 10 pm close until Finish (close stamped 10:00 pm, workout filed on the day it started). From 9 pm
the label says "night" and Now reads "tomorrow, first". Receipts name the thing first; UNDO says "X, taken back.". One
UNDO constant: 4 s new, 10 s change or destructive, 10 s for all under VoiceOver, paused in the background. Money and
body facts never go to Claude; secret words stay private. Shutdown is rules only, so in every case nothing of the
evening goes to Claude; the "Claude" column says what could leak if a path were wrong.

**Made-up state.** PPL x2, Push A done Thursday, Pull A next (Fri 7:30 am). Tasks today: "Call the bank", "Clean the oven",
"Pay the plumber". Habit Read, counted by hand. Times are PDT unless marked; Nov 1 is PST after 2 am.

| Id | Time | State | Expected screen lines | He does | Receipt and UNDO | Home and Tess | May go to Claude | Master today (file:line) | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| SH1 | Thu Oct 22, 8:30 pm to 9:00 pm | Normal evening; Push A done 6 pm, 3 tasks open, cooked once | 8:30 pm: "Thursday evening", hero "Call the bank". 9:00 pm: "Thursday night", hero "Shutdown", label "3 MOVING TO TOMORROW", 3 rows with TOMORROW | Looks | None (no write) | Tess B4: "Did 1 task, 1 workout, cooked once." No UNDO | Nothing | 8:30 pm passes. 9 pm label "evening" until 10 pm (`HomeSpatialView.swift:679`, `DayStrip.swift:63`); no Shutdown, `.shutdown` is only an enum case (`NowRanker.swift:37`) | not built |
| SH2 | Thu 9:06 pm | SH1; he keeps 2 rows, sends 1 to Later | TOMORROW crossfades to LATER on "Clean the oven"; hold CLOSE THE DAY 0.7 s; hero "Pull A", ctx "tomorrow, first", label "7:30 AM" | Taps a row, holds | E4 "Closed. 4 things in Thursday's log." (no line written, so not E3); UNDO 10 s | Kept rows lift away; `.success` | Nothing | No row grid, no hold, no closed mark; hold rows would skip `rolls` (`RollForward.swift:56-77`, SH3) | not built |
| SH3 | Thu 9:06 pm + 5 s; and 8:45 pm | SH2 just closed; earlier at 8:45 pm he swiped "Pay the plumber" to tomorrow | 8:45 pm: "Pay the plumber, tomorrow." 9:06 pm + 5 s: Shutdown back as he left it (oven still LATER) | Taps UNDO both times | "Pay the plumber, taken back." (10 s); "Shutdown, taken back." (10 s, one step for rows, Later, closed mark) | Rows return; no second check-in | Nothing | 8:45 pm says "Moved to tomorrow." (`HomeQueue.swift:480`), UNDO line silent (X3); close UNDO not built | wrong |
| SH4 | Sun Oct 25, 9:00 pm to 9:40 pm (Builder A) | Pull A running since 8:15 pm | 9:00 pm: hero stays "Pull A, rows set 2", ctx "now"; no Shutdown, no check-in. 9:40 pm Finish: finish view "Sunday, 8:15 pm to 9:40 pm", then Shutdown sets in | Logs sets, taps Finish | Finish UNDO 10 s "Pull A, back on."; Shutdown as SH1; any 10 pm close waits for Finish | B line counts the workout: "Did 2 tasks, 1 workout." | Nothing | 9 pm hero passes (`NowPage.swift:41-50`); finish view prints "20:15 to 21:40" (`WorkoutFinishView.swift:97`, `AppClock.swift:49`); no hold, nothing waits | not built |
| SH5 | Sun 9:00 pm | Chili cook running, step 4, timer to 9:25 pm | Hero "Chili, step 4", ctx "now" (a running cook takes Now, 12:29 pm); Shutdown sets in under it, cook not a rolling row; timer rings 9:25 pm, haptic included (CL9) | Looks, then holds close at 9:30 pm | Close as SH2; the cook stays open across the close | Timer ring beats the check-in (waits for an empty band) | Nothing | Running cook is not Now: only the session workout (`NowPage.swift:41-42`), ledger drops running (`ProcessTable.swift:53-57`); timer never fires (no notification code on master, CL6) | miss |
| SH6 | Thu 9:00 pm | Push A paused at incline since 8:20 pm (not running) | Default proposed: paused is not live, so Shutdown sets in; a row "Push A, paused" sits above the label, neither rolling nor closing; 6 h wrap-up stays Core's (2:20 am) | Looks | None; wrap-up "Push A, no sets, not saved." only if empty, UNDO 10 s | B line leaves it out until finished | Nothing | Hero "Push A, paused at incline" (`NowPage.swift:51-58`); wrap-up at 6 h (`ProcessTable.swift:14, 112`) | not built |
| SH7 | Sat Oct 24, 9:00 pm | Empty day: nothing done, nothing rolls | "Saturday night", hero "Shutdown", no label, no rows; line with no placeholder | Looks, holds | E line, UNDO 10 s | B7 "A quiet one. Want a line for tomorrow?" Before 9 pm: "All quiet." once | Nothing | "Nothing else is planned today." plus "Look back at the week →" (`NowPage.swift:184, 191`) and "Nothing else today." (`HomeQueue.swift:103`); `HomeLines.quiet` unused (`HomeLines.swift:157`) | wrong |
| SH8 | Fri Oct 23, 9:00 pm to 10:15 pm | 2 tasks open; he ignores Shutdown, opens at 10:15 pm | 10:15 pm: "Friday night", hero "Pull A", ctx "tomorrow, first"; CLOSE THE DAY brings Shutdown back until 4 am | Opens, does nothing | Closed mark stamped 10:00 pm on this open, no rows moved, no line (SH1 ruled); no UNDO | No Tess line, no ask (closed day) | Nothing | Nothing stored at 10 pm; `.late` from 10 pm (`NowRanker.swift:38`); rows roll only at 4 am (`AppModel.swift:333`) | not built |
| SH9 | Thu 11:30 pm | Closed at 9:06 pm; quiet hours | "Thursday night", hero "Pull A", ctx "tomorrow, first"; no ask, no app haptic | Types "buy stamps" | "Buy stamps, Friday." UNDO 4 s (dated Friday, SH6) | Soul rests; his receipt still shows (CL11) | Nothing (a miss phrase may, if Claude is on and it is not walled) | Label passes; hero is Fri 9 am task from the 14 h to 12 h window, no "tomorrow" (`AppModel.swift:476, 494-497`); stamps land today and roll (`RollForward.swift:56-61`) | wrong |
| SH10 | Fri Oct 23, 1:00 am | Still his Thursday, not closed (held nothing, silent close done) | "Thursday night"; CLOSE THE DAY: "2 MOVING TO FRIDAY" | Holds CLOSE THE DAY | F4 "Saved to Thursday. Pick up tomorrow." UNDO 10 s | No check-in (expired at 10 pm) | Nothing | Label passes (`HomeLineHero.swift:100-103`, TesseraDay); hero again a Friday task with no "tomorrow" (`AppModel.swift:476`); close not built | wrong |
| SH11 | Fri Oct 23, 4:10 am | New day; Thursday closed at 10 pm | "Friday early morning", hero "Pull A", ctx "today"; no CLOSE THE DAY | Opens | Roll line thing first: "2 tasks, carried into today." | Soul rests until 7 am; no asks | Nothing | Label "Friday night" (`HomeSpatialView.swift:680`, 4 am is "night", TW2); soul wakes at 6 am (`SoulRouter.swift:72`, TW30); roll line "2 tasks carried into today." (`RollForward.swift:41`) | wrong |
| SH12 | Mon Oct 26, 9:00 pm EDT (6:00 pm PDT) | Trip in New York, phone in Eastern | Shutdown on the phone's clock; "Monday night", rows TOMORROW; close stamped 10:00 pm EDT, items under Monday | Holds at 9:15 pm EDT | E line, UNDO 10 s | B line as usual | Nothing | DayPart reads the phone's hour, so 9 pm EDT is `.shutdown` (`NowRanker.swift:37`); label "Monday evening" (`HomeSpatialView.swift:679`) | wrong |
| SH13 | Sat Oct 31 to Sun Nov 1, 1:30 am PDT and 1:30 am PST | DST night, Saturday closed at 9:20 pm | Both 1:30 am opens read "Saturday night", hero "Pull A", ctx "tomorrow, first"; day turns once at 4:00 am PST | Opens twice | None; an UNDO window counts seconds, not the wall clock | Soul rests | Nothing | TesseraDay reads the wall hour, 25 h day (`TesseraDay.swift:3-5, 22-26`); roll keyed by day (`RollForward.swift:83-85`); windows are `Task.sleep` (`HomeQueue.swift:34`) | pass |
| SH14 | Thu 9:00 pm | Task "Change the gate code to 4417" left open | Row on his screen; after the close the hero, widget and Lock Screen read "Private task, tomorrow, first"; said "tomorrow first, wifi password is hunter2" becomes a private note, line empty | Keeps it, holds | "Private note, kept." (never echoes the word); close UNDO 10 s | B counts it as a task; Day log line and memory never name it | Nothing: no title, no line | Turnover skips secret lines (`TessMemory+Turnover.swift:67`); Claude wall (`ClaudeTessModel.swift:54`); Shutdown rows, hero and lead phrase not built (SH11) | not built |
| SH15 | Thu 9:00 pm | Day holds "paid rent 1450" and "weighed 81.4" | B line counts only: "Did 3 tasks, 1 workout." No amount, no weight on Home | Holds | E line, UNDO 10 s | Next morning's plan sends "task" for walled titles | Nothing: walled at the router and in the plan pack | Claude refuses walled text (`ClaudeTessModel.swift:54`, `PrivateFacts.swift:9-11`); plan pack "task" (`PlanWording.swift:36-38`); memory line screened (`TessMemory+Turnover.swift:104`) | pass |
| SH16 | Thu 9:06 pm, VoiceOver on | SH2 with VoiceOver | Rows read "Clean the oven, tomorrow"; the hold is an action "Close the day"; lines are announced | Moves a row, closes, then UNDO | Every UNDO 10 s, from one constant: swipe move, "Read, done.", close | Tess's line spoken once | Nothing | No VoiceOver read anywhere (no `isVoiceOverRunning`); 4 s and 10 s hard-coded (`HomeQueue.swift:34`), no `UndoWindow` | wrong |

**Counts:** 16 cases: 2 pass (SH13, SH15), 7 wrong (SH3, SH7, SH9, SH10, SH11, SH12, SH16), 1 miss (SH5), 6 not built
(SH1, SH2, SH4, SH6, SH8, SH14). Privacy holds on master: nothing in the evening reaches Claude, since Shutdown isn't built.

## Top gaps

1. **No Shutdown, no closed day** (SH1, SH2, SH7, SH8, SH10): the page, the rows, the hold, the closed mark and the 10 pm
   silent close. Builder B for the screens; Core for the closed mark, the silent-close write on next open and kept rows
   counting as rolls (`RollForward.swift:56-77`).
2. **Now after 9 pm is the wrong day** (SH9, SH10): `currentTask`'s 14 h to 12 h window (`AppModel.swift:476, 494-497`)
   puts Friday's task on Thursday night with no "tomorrow"; the `tomorrow:` look ahead (`HomeLines.swift:534`) has no
   caller. Builder B (wire it), Core (the 4 am filter in the schedule).
3. **Live workout hold** (SH4): nothing waits on Finish, and the finish view prints 24-hour times. Builder A for the hold
   and `WorkoutFinishView.swift:97`; Core for stamping the late close at 10:00 pm.
4. **Day label words** (SH1, SH11, SH12): "evening" until 10 pm and "night" at 4 am (`HomeSpatialView.swift:675-681`).
   Builder B.
5. **One UNDO constant with VoiceOver** (SH3, SH16): `HomeQueue.swift:34`; thing-first lines ("Pay the plumber,
   tomorrow."). Core for the constant, Builder B to wire it.
6. **Running cook is not Now, and its timer never rings** (SH5): Builder B (`NowPage.swift:41-42`), Core (CL6).
7. **Quiet hours end at 6 am in the soul** (SH11, `SoulRouter.swift:72`). Builder B.
8. **Secret word on the tomorrow hero** (SH14): the closed-day hero reaches the widget and Lock Screen. Core (title rule),
   Builder B.

## Questions for Product

1. 9 to 10 pm: is the hero "Shutdown" with "tomorrow, first" only after the close, or does "Pull A, tomorrow, first" stand
   from 9 pm and Shutdown sit under it? (12:35 pm "flips at 9 pm" vs `shutdown-flow.md` step 1 and m4-steers §7, which
   also still say "Thursday evening" and "this evening".)
2. A paused (not running) workout at 9 pm: does it hold Shutdown like a live one, or sit as a row (SH6 default)?
3. A running cook at 9 pm: does it hold Shutdown like a workout, or does Shutdown set in under it (SH5 default)?
4. A task with a secret word on the tomorrow hero, widget and Lock Screen: "Private task", or the title on Home only?
5. First Shutdown slot C: "Tap any to keep." (decisions 3:43 am) or "Tap any for later." (`shutdown-flow.md` step 4)?
6. On a trip, is the 10 pm stamp the phone's 10 pm (SH12 default) or home Pacific?
