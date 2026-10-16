# Stale asks: every way a pending ask can outlive its screen (Product board item N)

For: Core, Builder A, Builder B. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Traced by hand against master `e10b698` (#467 merged), not run.

**Sources.** Board item 0g (`dropAsks`: clear `pendingAsk` and `pendingDatedLift`; Builder A calls it from `askLeft`).
QA on #467 (`docs/qa/review-467.md` on QA's branch, not yet on master; the finding is its **L1**, and #467 itself fixed
QA #402 L5). QA I5 (`review-intents-health.md:70-77`) and T2 (`review-tess-processes.md:60-72`).
`TessCaptureEngine.swift`, `TessSetCountAsk.swift`, the live workout (`WorkoutModeView.swift`, `TessGrammar+Live.swift`),
`BottomChrome.swift`, and `asks-after-close.md` (C1 to C14, CL1 to CL11).

**The asks.** *Set ask* (SQ8): "2 × 10: 2 sets, or 2 kg?", stored as `pendingAsk`, answered by "sets", "2 sets", "kg",
"2 kg", "+2 kg", "kilos" (`TessSetCountAsk.swift:50-61`). *Dated ask*: "Bench 80 × 8 for Monday?", stored as
`pendingDatedLift`, answered by "log", "log it", "yes", "yep", "yeah", "not now", "no", "nope" (`:111-117`). *Line
ask*: "Bench 3 × 8 at what weight?" ("bench 3 sets of 8" with no weight), "80: kg, or reps?", "Say the set, like 80 × 8."
These are never stored (`TessCaptureEngine.swift:224-225`), so a bare "80" after one is always read fresh.

**How the engine reads a phrase** (`TessCaptureEngine.swift:34-45`): before anything else, it checks the phrase against
`pendingAsk`, then `pendingDatedLift`. A match answers the ask; anything else drops it. Nothing else ever clears either
one. The view's `setAsk` and `liftAsk` (`BottomChrome.swift:20, 46`) are cleared in five places; none of them reach the
engine. So whenever the screen ends and the engine doesn't, the next "kg", "sets", "log" or "yes" answers an ask he no
longer sees, and writes.

## The table

| # | Pending ask | What ends its screen | Follow-up that must answer nothing | What it should do instead | Master today | Owner |
|---|---|---|---|---|---|---|
| S1 | Set or dated ask beside the soul on Home | The live workout opens (full-screen cover; BottomChrome leaves) | "kg", "sets" (set); "log", "yes" (dated), said in the live field | Its own live parse. "yes" and "no" answer nothing in a workout: "Say the set, like 80 × 8." (`TessGrammar+Live.swift:122-126`) | **Gap.** `askLeft` clears the view only (`BottomChrome.swift:112, 537-542`). The live field goes through `model.ask` (`WorkoutModeView.swift:273-278`, `AppModel.swift:207-211`), and the engine answers first (`TessCaptureEngine.swift:34-45`): "yes" logs Monday's bench from inside today's workout | Core (`dropAsks`), Builder A (call it in `askLeft`) |
| S2 | Set or dated ask beside the soul | He taps the soul (Ask opens, the ask is hidden), then closes Ask with nothing sent (veil tap, swipe down, Escape) | "kg", "sets", "log", "yes", typed minutes later | Its own parse. Opening Ask to type the answer is fine; closing it with nothing sent drops the ask | **Gap.** `opened()` clears the view (`BottomChrome.swift:433-437`); `close()` (`:449-454`) never brings it back or drops it. The engine keeps both | Builder B (call `dropAsks` on an empty close), Core |
| S3 | Set ask said in the live workout ("2x10") | The live corner's line fades after 4 s (`WorkoutModeView.swift:279-284`) | "sets" or "kg" ten minutes later, after more sets | Either the line stays while the ask waits, or the ask drops with the line. Product to pick (unsure) | **Gap.** The line goes, the ask stays. Live has no answer taps, so a late "sets" logs N sets at whatever the last weight is by then | Builder A, Product |
| S4 | Set ask, any screen | The workout ends: Finish, discard, or Core's 6-hour wrap-up | "2 sets", "kg", any time later that day or night | Nothing. The set ask expires with its workout (C4) | **Gap (CL1).** The view drops `setAsk` (`BottomChrome.swift:106-110`; wrap-up at `AppModel.swift:340-345`); the engine resolves into the finished workout's entry (`TessCaptureEngine.swift:104-117`) | Core, Builder A (call `dropAsks` on finish) |
| S5 | Either ask | The app backgrounds and returns soon (phone in pocket between sets) | none: the ask is still on screen | Keep it. He sees it, so "kg" or "log" is a real answer | OK. `BottomChrome` stays mounted; the engine keeps it (`TesseraApp.swift:80-94` touches neither) | none |
| S6 | Either ask | The app backgrounds and returns after a long time (proposal: past the idle limit `tidyProcesses` already uses, rest plus 10 min, `AppModel.swift:318`) | "kg", "sets", "log", "yes" | Its own parse. Drop both on that foreground (the view and the engine) | **Gap.** Nothing on foreground looks at asks (`TesseraApp.swift:85-89`). A killed process loses them (in memory only), which is right | Core (`dropAsks`), Builder B (call it on foreground) |
| S7 | Dated ask ("bench 80x8 fri", said Thursday, 6 days back); set ask in a workout running past 04:00 | The 04:00 day turn | "log", "yes" after 04:00 | Dated: re-check it (C8); if the day is now more than 6 back, or "Friday" now reads as today, it expires. Set: stays only while its workout runs | **Gap.** `day` is a fixed noon and `dayName` a fixed word (`TessSetCountAsk.swift:89, 91`; `TessGrammar+Dated.swift:28-36`). Nothing checks the day at answer time. "log" at 04:10 Friday logs to last Friday, asked as "for Friday?" | Core |
| S8 | Set ask | A second ask replaces it ("bench 80x8 mon" next) | "kg" or "sets" for the first | Nothing. One ask at a time | OK. The engine drops the first (`TessCaptureEngine.swift:35, 41`) and stores the second (`:48-53`). In a workout the dated ask should be held, not asked (C5, CL5, `TessGrammar.swift:96`) | Core (CL5) |
| S9 | Set ask, dated ask, or a line ask | A line ask replaces it ("bench 3 sets of 8" asks "at what weight?") | "80" | Its own parse: "80" is never the weight for the line ask, and never the answer for the dropped ask | OK. The phrase drops the stored ask (`:34-45`); the line ask is not stored (`:224-225`); "80" reads fresh (`TessGrammar+Live.swift:56-71`) | none |
| S10 | Either ask | Shutdown opens (21:00 on Now) | "kg", "log", "yes" (yes matters: the habits check-in "Read today?" runs inside Shutdown) | Set ask: expires with its workout or the close (C4). Dated ask: held, not shown, back at 07:00 (C5, C7). Either way, "yes" in Shutdown answers Shutdown, never the dated ask | **Not built.** No Shutdown in `Features/` (CL2). When it lands, opening it must call `dropAsks` (or hold) first | Builder B, Core |
| S11 | Set or dated ask raised by Siri "Tell Tess" | Siri's dialog ends; Siri can't take the answer (I5) | "kg", "sets", "log", "yes" in the app later | Siri doesn't store the ask at all; the dialog says to open Tessera | **Gap (I5).** `TellTessIntent` runs the same engine (`Intents.swift:162`); the engine stores asks even with `commitImmediately` (`TessCaptureEngine.swift:46-53`) | Core |
| S12 | Set ask on the entry in focus | A Siri or Lock Screen action logs or takes back a set on that entry (`LogNextSetIntent`, `Intents.swift:45-50`; `UndoLastSetIntent`, `:61`; `LogPlannedSetIntent`, `RestIntents.swift:29-38`) | "sets" | Its own parse. A write to the ask's entry from outside Tess drops the set ask | **Gap.** Nothing links them. "sets" then logs N sets at the Lock Screen set's weight (`TessCaptureEngine.swift:114`), not the one he was asked about | Core |
| S13 | Either ask | A timer fires: the rest ends, or his kitchen timer ends | none: a timer is not an answer | The timer's line takes the slot (C14); the ask comes back under it after, or drops if its workout ended | **Partly.** Rest end leaves the ask alone (fine). Kitchen timers never fire (CL6, `Cooking.swift:155`), so nothing yet competes for the slot | Core, Builder B |
| S14 | Either ask | A process note shows beside the soul on foreground (04:00 roll, a wrap-up) | none | One thing in the slot: the note waits for the ask, or (if the ask's workout was wrapped up) the ask drops first | **Gap (low).** `voice.say` runs whatever the ask (`BottomChrome.swift:135-140`), so the note and the ask can show together | Builder B |

Not a leave: pushing a page from Home keeps `BottomChrome` mounted (QA on #467), so the ask is still on screen and its
answer is real. A kill or relaunch loses both asks (in memory), which is right.

## What `dropAsks` needs (item 0g)

| # | Rule | Owner |
|---|---|---|
| D1 | `TessCaptureEngine.dropAsks()`: sets `pendingAsk` and `pendingDatedLift` to nil, writes nothing, says nothing | Core |
| D2 | `AppModel.dropAsks()` passes it through, like `answer` does (`AppModel.swift:220-236`) | Core |
| D3 | Called from `askLeft` (S1), the empty Ask close (S2), workout end (S4), the long foreground (S6), Shutdown (S10) | Builder A (S1, S4), Builder B (S2, S6, S10) |
| D4 | Engine-side, no view needed: never store an ask under `commitImmediately` (S11); drop the set ask when its entry gets a set from outside Tess (S12); re-check the dated ask's day at answer time (S7) | Core |
| D5 | Once held asks exist (CL4), "drop" for a dated ask said in his own phrase means "hold" (C5), not "expire". Until then, drop | Core |

**Tests to add (Core):** for each of S1, S2, S4, S6, S11, S12: raise the ask, end its screen, then say the follow-up
and expect no write. One row for S1 with "yes" in a live workout expecting "Say the set, like 80 × 8."

## Counts and top gaps

14 rows: 10 gaps (S1, S2, S3, S4, S6, S7, S11, S12, S14, plus S10 not built), 3 OK (S5, S8, S9), 1 partly (S13).
**Top three:** S1 ("yes" in a workout logs a dated lift from Home: a wrong write, live today). S4 (CL1: sets land in a
finished workout). S12 (an answer logs at a weight he never saw).

**Unsure.** Item 0g is not on master's `docs/ops/board/core.md` (no "0g" or "dropAsks" there yet). The #467 finding
is QA's L1, not L5. S3 and S6's time limit need Product.
