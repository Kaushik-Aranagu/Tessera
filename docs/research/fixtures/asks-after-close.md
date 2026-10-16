# Asks after the day closes (board item 135)

For: Core. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Traced by hand against master `0bff60b` and Design's branch (`origin/claude/project-thread-b3tu3f`), not run.

**Sources.** Product's ruling (decisions, 3:34 AM PT Oct 16): AQ6 holds, AQ1, AQ15. `asks-one-list.md` (A1 to A21,
AQ1 to AQ17). Design `one-ask.md`, `shutdown.md`, `evening-on-now.md`. Research `shutdown-daylog-copy.md`,
`habits-first-use.md`. Fixed rules: day turns at 04:00 (`TesseraDay`), Shutdown at 21:00, the silent close at 22:00,
quiet hours 23:00 to 07:00, Plan my day 07:00 to 21:00, no yes/no ask in a live workout, an ask writes nothing until
answered, one ask at a time, never an ask over an UNDO.

**Words.** *Shown*: in Tess's slot now. *Held*: kept, not shown, comes back later. *Expired*: gone for good, nothing
written. *His*: something he started (his phrase, his timer). *App ask*: anything he didn't start in this open Tess turn.

## The evening: Thursday, Oct 22, Pacific (path A: Shutdown held at 9:10 pm)

He started Push A at 19:40. Bench's last set is 80 × 8. The Read habit has no reading record yet today. Tacos are
planned for Friday dinner, and Groceries has an open "Scallions" row.

| Time | What happens | Pending | Held | Shown in Tess's slot | Notes |
|---|---|---|---|---|---|
| 20:28 | In Push A he says "bench 80x8 wed" (he forgot Wednesday's set) | none | dated set (A3), "Bench 80 × 8 for Wednesday?" | the line "Wednesday's set waits till after the workout." | AQ3: no yes-or-later ask in a workout. A line, no ink words. Today it asks at once (CL5) |
| 20:30 | He says "2x10" | set ask (A1) | dated set | "2 × 10: 2 sets, or 2 kg?" with 2 SETS · 2 KG | A worded choice (Q10, AQ1). Writes nothing. A new phrase must not drop the held dated set (C5) |
| 20:38 | He taps Finish without answering | none | dated set | the finish line | The set ask **expires** with the workout. No set logged (C4). Today the engine keeps it (CL1) |
| 20:41 | He goes to Kitchen, not Today | none | dated set | nothing | The dated set waits for Today with an empty slot (C5) |
| 20:45 | He starts "rice", 12 min, on the cook page | none | dated set | "Rice, 12 min." with UNDO (4 s) | His timer, not an ask. Ends 20:57 |
| 20:50 | The habits check-in comes due (A12; trigger and words not set, CL10) | check-in (app ask) | dated set | nothing | He is on Kitchen. An app ask waits for an empty slot on its own page |
| 20:57 | Rice timer ends | same | same | his timer fires (C14) | Today nothing fires at all (CL6) |
| 21:00 | Shutdown sets in on Now | check-in | dated set | Shutdown's opener | No ask shows over the Shutdown page (C7) |
| 21:10 | He holds "Shutdown complete" | none | dated set | "Closed. Your line is waiting at 08:00." with UNDO (10 s) | Day closed: the hold starts now (ruling). The check-in **expires**: a closed day never asks, and habits never catch up (C6) |
| 22:30 | Claude's Groceries pass links "Scallions" to Friday's tacos | none | dated set, Groceries link (A16) | nothing | App ask on a closed day: **held**, not applied (C13) |
| 22:33 | He types "i never train on sundays", Tess misses it, it goes to Claude, he locks the phone | none | same | nothing | |
| 22:34 | Claude's `remember` reply lands after he left | none | dated set, link, remember ghost (A17) | nothing | He left the turn, so it is an app ask: **held**. The ghost does not dry (C13, CL7) |
| 22:50 | He says "timer tea 20" | none | same | "Tea, 20 min." with UNDO (4 s) | His phrase on a closed day still works (C3). Ends 23:10 |
| 23:00 | Quiet hours start | none | same | nothing | Nothing changes: the close hold already runs to 07:00 |
| 23:10 | Tea timer ends | none | same | his timer fires | Quiet hours don't hold his timer (C14, CL9) |
| 00:40 | He opens the app in bed. His day is still Thursday | none | same | late-night closed day: "Thursday night", hero "Reply to the landlord" | Opening the app releases nothing (C2) |
| 00:41 | He types "read 20 pages" | none | same | "Read, 3 of 5 this week." with UNDO (4 s) | Counts for Thursday (before 04:00). His capture, so allowed |
| 00:42 | He types "2 sets" (half asleep) | none | same | "Didn't catch that." or the usual read | The set ask is gone (C4). Today it logs 2 sets into the finished Push A at 00:42 (CL1) |
| 04:00 | Turn to Friday | none | dated set, link, remember ghost | nothing | Each held ask is re-checked (C8). All three are still true, so all stay held |
| 07:00 | Asks may come back | none | same, now eligible | nothing | Nothing notifies. They wait for his first open (C9) |
| 07:25 | First open, Friday morning | dated set | link, remember ghost | "Bench 80 × 8 for Wednesday?" with LOG · NOT NOW | First: it came from his phrase (C10). He taps LOG: "Bench 80 × 8 logged for Wednesday." UNDO 4 s |
| 07:25 + 4 s | UNDO goes | link | remember ghost | "Scallions, for tacos?" with KEEP · NOT NOW | Second: its moment ends soonest (tacos tonight). KEEP changes a row: UNDO 10 s (AQ15) |
| 07:25 + 14 s | UNDO goes | remember ghost | none | the remember ask with KEEP · NOT NOW | Third. He locks the phone: that is NOT NOW. The ghost waits on What Tess knows (AQ10), never asked again (C12) |
| 08:00 | His tomorrow line is up | none | none | none | Now's hero is "Reply to the landlord". The plan offer (A14) is a Home state, not an ask |

**Path B: he skips Shutdown, the day closes by itself at 22:00.**

| Time | Difference from path A |
|---|---|
| 21:00 to 22:00 | The Shutdown page stays up. No ask shows over it, so the check-in and the dated set wait |
| 22:00 | Silent close: no Tess line, no UNDO, CLOSE THE DAY until 04:00. The hold starts now. The check-in **expires** |
| 22:20 | If he taps CLOSE THE DAY and holds Shutdown complete, nothing about the asks changes: the day was already closed |
| after | Same as path A from 22:30 on |

**Path C: he never taps Finish.** Push A stays open past the close. The set ask **expires** at the close (21:10 or
22:00), and no set is logged. The workout stays his, open, and is never finished by the app. The dated set stays
held: it shows on Today after he finishes, or at 07:00, whichever comes first.

**Path D: he takes Shutdown back.** UNDO within 10 s at 21:10 reopens the day. The close hold lifts. Held asks may
show again when the slot is empty, after Shutdown's page is gone, and before 23:00.

## Rules for Core

| # | Rule | Source |
|---|---|---|
| C1 | App asks hold 23:00 to 07:00, and from the close (Shutdown complete, or the 22:00 close) to 07:00 | Ruled (AQ6) |
| C2 | Opening the app, or a tab, during a hold releases nothing. Only 07:00 (or path D's UNDO) ends a hold | Proposed |
| C3 | His own phrase still gets its line and its ask on a closed day and in quiet hours. "A closed day never asks" covers app asks only | Proposed, Product to confirm (CL11) |
| C4 | A set ask (A1, A2) expires when its workout ends (finish or discard) or at the close, whichever is first. It never logs and never returns. The engine drops it, not only the view | Proposed |
| C5 | A dated set said in a workout is held, not shown. A later phrase does not drop it. It shows on Today once the workout is finished and the slot is empty. If the day closes first, it is held to 07:00 | AQ3 plus proposed |
| C6 | A day-bound app ask (the habits check-in, anything about "today") expires at the close. It never comes back as a catch-up | Proposed; `habits.md:57` |
| C7 | No ask shows over the Shutdown page (21:00 until held or 22:00) or under Shutdown's 10 s UNDO | Proposed; never an ask over an UNDO |
| C8 | At 04:00 each held ask is kept only if still true. Dated set: that exercise has no set on that day yet, and the day is 6 or fewer days back. Link: the row is still open and the recipe still planned. Remember: the fact is not already known. Anything else expires | Proposed |
| C9 | From 07:00 nothing notifies. Held asks show on his first open, one at a time, never in a live workout | Ruled plus `one-ask.md` |
| C10 | Return order: held asks from his own phrase first, then app asks by whose moment ends soonest, then oldest raised | Proposed |
| C11 | Each next ask waits for the UNDO in the slot to go: 4 s after a new capture (LOG), 10 s after a change (KEEP on a link) | Ruled (AQ15) |
| C12 | A held ask that was shown and then left is NOT NOW. It returns only by its own rule (radiators next day, calendar on the next Plan my day) | `one-ask.md` Leaving |
| C13 | A held ask writes nothing while held. Claude's link is not applied, and a remember ghost does not dry | Ruled ("writes nothing until answered") |
| C14 | His timer is his, not an ask. It fires at its end at any hour, on a closed day and in quiet hours: on Now in the app, and as a notification when the app is away | Proposed; words and sound for Design |

## Where the code differs

| # | Gap | Where | Owner |
|---|---|---|---|
| CL1 | The set ask outlives its workout. The view drops `setAsk` when the session ends, but the engine keeps `pendingAsk`. A later "2 sets" resolves it, and `LogSet` has no finished-workout check, so two sets land in the finished Push A at 00:42 | `BottomChrome.swift:103-107`; `TessCaptureEngine.swift:34-39, 63, 103-116`; `TrainingActions.swift:60` | Core |
| CL2 | No closed-day state. `DayPart` knows 21:00 to 22:00 as `.shutdown` and later as `.late`, but nothing stores "Shutdown complete". Shutdown itself isn't built | `NowRanker.swift:30-39`; no Shutdown in `Features/` | Core, Builder B |
| CL3 | No hold gate. No check for 23:00 to 07:00 or the close exists. No app ask is built yet, so this bites with the first one (A13, A16, A17) | none | Core |
| CL4 | No place to hold an ask. The engine has one `pendingAsk` and one `pendingDatedLift`, and any new phrase drops both | `TessCaptureEngine.swift:34-46, 63-66` | Core, Builder B |
| CL5 | A dated set asks LOG · NOT NOW at once in a live workout (AQ3) | `TessGrammar.swift:96` | Core |
| CL6 | His timer never fires. `StartKitchenTimer` only stores `endsAt`. Timers are read only for a running cook's Now line, so "rice 12" with no cook isn't on Now. The repo has no `UNUserNotificationCenter` | `Cooking.swift:155-195, 50`; `NowPicker.swift:53-67` | Core (fire), Builder B (Now), Product (first notification) |
| CL7 | Claude's reply lands whenever it arrives, with no check of the clock or the close. A remember ghost is pending and dries after the grace, so it would commit unanswered | `TessCaptureEngine.swift:5-6, 45`; `TessMemory.swift:161-162` | Core, AI |
| CL8 | Leaving doesn't fold a shown ask (AQ14). Only a new open clears the view's asks | `BottomChrome.swift:433-436` | Builder B |
| CL9 | `shutdown.md` "Never": no haptic after 23:00 except under his finger. C14 fires his tea timer at 23:10 | Design branch `docs/design/shutdown.md` | Design, Product |
| CL10 | The habits check-in (A12) has no trigger and no words (AQ7). This fixture assumes an evening app ask | decisions RF18 | Product |
| CL11 | "A closed day never asks" can read as "no asks at all", which would block his own "bench 80x8 wed" at 00:40 | decisions AQ6 | Product |

**Top three.** CL1 (a wrong write into a finished workout, built today). CL6 (his own timer never fires, day or
night). CL2 with CL3 (no closed-day state and no hold gate, needed before the first app ask ships).
