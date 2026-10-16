# Plan my day with Claude: the morning, step by step

For: Builder B (Now, ghost rows, Ask), Core (offer timing, `PlanPack`, ActionEngine), Design (m4-steers §6), Product (open questions). Research lab, board item 95, 2026-10-16. Updated for board item 98 the same day.
Inputs: `plan-my-day-prompt.md` (instructions, schema, V1 to V12), `plan-my-day-blind-read.md`, `claude-first-run.md` (step 8), `fixtures/plan-my-day-claude.md` (d01 to d23, builder checks), `claude-first-uses.md` (use 2), `settings-claude.md`, `tess-voice.md` (M1 to M58), `ask-lines.md`, `light-day.md`, `design/no-dots.md`, `design/m4-steers.md` §6, `product/decisions.md`, `product/ship-list-m4.md`.
**Master read:** `origin/master` at `e9f4a06` (Merge PR #233, Oct 15 8:27 PM PT), read with `git show`. Nothing was run and no key was used.
**m4-steers.** `design/m4-steers.md` is now in `tessera/design/` at `041a17d` ("Plan my day redrawn to Research 95 and Product's answers", Oct 15 8:45 PM PT), identical to the branch copy. Its §6 was rewritten to this doc's first version and to Product's 8:38 PM PT call. Every step below is checked against that §6.

> Refreshed Oct 16, 12:50 pm PT (Product item AA): undo lines take the thing-first comma ("Reply to landlord, taken back.", "Plan, taken back.", decisions 12:35 pm PT); UNDO windows come from one shared constant, 10 s for all under VoiceOver, paused in the background (12:39 pm and 12:45 pm PT, Product's branch). Master's `HomeQueue.say` gives every UNDO line 10 s (`Features/Home/HomeQueue.swift:32-34`), so step 12's 4 s row keep is open; see `fixtures/plan-my-day-pack.md` P29, G14 and Q3.

> Changed 2026-10-16 (board 98): D1 to D8 and G1 closed with Design's answers; Product's 8:38 PM PT defaults folded in (pull from 07:00, 10 s UNDO on "Plan kept", rows under "Rest day", no offer while a workout runs, a late reply dropped but its cost counted); Design's two differences taken (no sleep line at all before Health read; the timeout line is "Claude didn't answer in time. Here's your usual plan."); build list and open questions redone; 5 new small disagreements in section 3b.

## Bottom line

- The walk is **17 steps** from the 4 AM turnover to an accepted plan, plus **9 branches** for no key, offline, the cap and failed calls.
- **What exists on master:** the 4 AM day (`TesseraDay`), Now's precedence (running, timed task within 15 min, rest day, re-entry, rank), `ActionEngine.perform` with pending ops, `MoveTask`, the stroke word (`PaintKey`) and label words (`LabelActionStyle`), the $10 ledger with `reserve`, `TessUse.plan`, `TessVoice.violations`, a Settings: Claude section. **Not built:** the plan offer itself, `DayPlan`, `PlanPack`, `ProposePlan`, the validator, a Claude client for the plan, capture or question uses (only the key check calls Claude), the cloud mark, the ask ledger, a quiet-hours gate on Now, the 10 s UNDO, and a plan row that waits for a swipe. Master's `GhostRow` is declared and never used.
- **All 8 disagreements with the old §6 and the gap G1 are closed** (section 3a). Design and Product took every recommendation except two, where Design's answer now stands: no sleep line at all before Health read, and one timeout wording.
- **Still open:** 5 small new points (section 3b) and 6 questions (section 6). None blocks Builder B or Core from starting.

## 1. Rules this walk follows

| Rule | Source | On master |
|---|---|---|
| His day runs 4 AM to 4 AM | decisions 7:22 and 7:40 PM PT; `day-boundary.md` | `TesseraDay.startHour = 4`, `TesseraCore/.../Engine/TesseraDay.swift:10`; fold at `:22-24` |
| Quiet hours 11 PM to 7 AM | decisions 6:20 and 6:44 PM PT; fixture N1 | Only as the day stroke's scale, 7 am to 11 pm (`Features/Home/DayStrip.swift:6`). No gate on Now. Not built |
| One ask per 4 AM day, pushed asks in order, A3 Calendar at Plan my day | decisions 5:56 PM PT; `ask-lines.md` rules 1 to 5 | Not built: no ask ledger anywhere |
| Plan offered once per 4 AM day, 08:00 to 21:00, no notifications; pull from 07:00 | `ship-list-m4.md` Defaults; decisions 8:38 PM PT; §6 "When it shows", "Pulling it early" | Not built |
| Now precedence: running process, then an event or timed task within 15 min, then a planned rest day, then the plan, then re-entry, then the scored rank | decisions 3:37, 4:01 and 8:38 PM PT; §6 "When it shows" | Rungs 1 to 3, re-entry and the rank: `NowRanker.swift:112-141` (`TesseraCore/.../Tasks/`), header `NowPicker.swift:3-5`. Events are not read yet, so only timed tasks count. The plan rung is not built |
| Plan window 07:00 floor, ends 21:00 (Shutdown) | decisions 11:40 AM PT; fixture M-day | `DayLoad` counts free time to 23:00 (`Tasks/DayLoad.swift:23`). Plan window not built |
| Light day from C1 to C3 only, never Health or energy | decisions 5:41 and 5:48 PM PT; `light-day.md`; §6 Energy | Not built |
| No buttons with shapes; actions are stroke words and label words | decisions 12:00 PM PT; `no-buttons.md` | `DesignSystem/InkActions.swift:4-5`, `LabelActionStyle` `:47-49`; `PaintKey` `DesignSystem/Paint.swift:225-229` |
| No coloured dot or dab before or after a line of text | decisions 8:07 PM PT; `design/no-dots.md` rule 1; §6 rows | `GhostRow` still draws a cobalt `PaintDab` (`Features/Home/NowPage.swift:289-290`) |
| UNDO names the thing, then ", taken back."; 4 s, 10 s on destructive writes and on "Plan kept", 10 s for all under VoiceOver, from one shared constant (decisions 12:35 pm, 12:39 pm and 12:45 pm PT Oct 16) | `tess-voice.md` principle 8, M34, M35; decisions 8:38 PM PT | `TessVoice.say` holds every note 4 s (`Features/Home/HomeQueue.swift:28-37`). No 10 s path |
| Plan fallback: the rules plan plus one quiet line, at most one per plan | decisions 12:22 and 8:38 PM PT; M18, M22, M23; §6 | Not built |

## 2. The walk

The morning is Mon 2 Nov 2026 (PST), pack d01: Reply to landlord, Expense report (due 5 pm), Book physio; Standup 9:30 am, Design review 11 am, 1:1 Priya 3 pm; Push A at 6 pm. His key works, Use Claude is on, and the use 2 gate has passed (decisions 7:38 and 7:44 PM PT: 21 of 23 raw, 19 of 23 read). Every time is Pacific.

Each step gives what he sees and does, what master has, and the check against the new §6.

### Step 1. 4:00 am: the day turns over
- **Sees:** nothing. He is asleep.
- **Engine:** the logical day becomes Monday. The plan-offer flag and the day's ask slot both reset here, not at midnight. An open at 1:30 am still belongs to Sunday; its plan window is empty, so no pack is built (fixture builder check).
- **Master:** `TesseraDay.day(of:)` folds 00:00 to 03:59 into the day before (`TesseraDay.swift:22-24`). The offer flag and ask slot are not built.
- **§6:** "offered once per 4 AM day". Agrees.

### Step 2. 6:40 am: he opens the app in quiet hours
- **Sees:** Now as on any morning, ranked by master's ranker. No plan, no ask, no Claude call, and no **plan** value word on the Now line.
- **Why:** quiet hours run to 7 am, and the plan window opens at 07:00 at the earliest (fixture M-day, N1).
- **Master:** Now comes from `rank()` (`NowPage.swift:22-26`, `NowRanker.swift:99`). Not built: the quiet-hours gate.
- **§6:** pull "From 07:00". Agrees.

### Step 3. 7:00 to 7:59 am: he can pull the plan, nothing pushes it
- **Sees:** the Now line reads "this morning · **plan**", with **plan** as a value word (Body 21/600 ink). Tapping it, or saying or writing "plan my day", builds the plan at once with `window` starting at his open time.
- **If a workout is running:** the pull gets one Tess line, "Push A is under way, until about 8:05 am.", and Now stays the running workout. No pack, no Claude call (see 3b, N1).
- **Master:** not built. Ask has no "plan my day" phrase; the Now line has no value word.
- **§6:** "Pulling it early." Agrees (decisions 8:38 PM PT).

### Step 4. 8:00 am or his first open after it: is the plan allowed to take Now?
The plan offer is a new rung in the ranker, after the rest day and before re-entry:

1. **A running workout, cook or focus block** keeps Now. There is no offer while a workout runs. When it ends, the plan is offered the next time Home shows, without that workout (d20: a finished workout sends no block).
2. **A timed task (or event, once the calendar is read) within 15 minutes** keeps Now. The plan waits until it's done or past.
3. **A planned rest day:** "Rest day" stays the hero, with the next routine a tap away. The plan's rows and START WITH arrive under it in the queue window, with no hero sentence of their own. The pack carries `rest: true` (d21).
4. **The plan offer:** once per 4 AM day, 08:00 to 21:00, only when the rules plan has at least one task line (d14 sends no pack and shows no plan).
5. Re-entry, then the scored rank, as today.

- **Master:** rungs 1 to 3 are built: `if let running` (`NowRanker.swift:112-116`), `Weight.overrideWindow = 15` (`:93`, `:117-123`), the rest pick (`:124-132`). `RestDay` is nil while a workout is under way (`Training/RestDay.swift:23`, `:39-49`). Now's hero switch reads the same order (`NowPage.swift:31-40`). The plan rung is not built.
- **§6:** "When it shows" items 1 to 4. Agrees (D1 closed).

### Step 5. First morning only: the calendar ask
- **Sees, once ever:** Tess's line "Plan around your calendar? Times and titles only." (M45) with two label words under it, **CONNECT** and **NOT NOW** (Label 16/700, no shape).
- **Does:** taps CONNECT; the iOS calendar sheet follows at once (ask rule 2, a pulled ask).
- **One ask a day:** A3 uses today's slot. If the slot is already used (for example by a pulled ask earlier this morning), A3 is marked pending, the plan builds with `cal: false`, and no line says why (ask rule 4). If he denies, the plan says "Planned without your calendar. Settings" (M46), with SETTINGS as the word to tap.
- **Master:** not built. No calendar read, no `NSCalendarsFullAccessUsageDescription` (`ask-lines.md` A3: missing).
- **§6:** silent on the ask (3b, N5).

### Step 6. The rules plan draws at once
- **Sees** (§6 "The page"):
  - Now line "this morning".
  - Hero, the day in one sentence, Title 44/500. With the calendar: "Three meetings, four hours free". Without it: "Three tasks, Push A at 6 pm"; never free, clear or open.
  - Context line "slept 6h40" at 21/400 `inkSecondary`, **only once Health read has been granted from its own ask.** Before that, no line at all, and the plan never asks for Health.
  - Energy, optional: "Energy" and the rep drum (1 to 5). Logged for the Day log only; it never changes the plan, and Tess says nothing about it.
  - The day stroke: meetings as short ink segments at their times, only when the calendar is read.
  - Up to 3 plan rows in the queue window: the title in Body 21/500 wet cobalt, breathing (0.5 to 0.66), its time at the right as a value word. **No dab** before the words.
  - The one action at y 450: the label **START WITH** and, under it, "Reply to landlord" at Title 34 on the cobalt ink line.
- **The rows do not dry on a timer.** Nothing is written by drawing the plan (fixture M-ghost: 0 ops).
- **Master:** `HomeDayStrip` exists (`DayStrip.swift:77`). `RepsDrum` exists (`Features/Workout/Instruments/RepsDrum.swift:21`). The `PaintKey` hold is used for Finish (`NowPage.swift:114-124`). `GhostRow` is never instantiated (declared at `NowPage.swift:278`), draws a `PaintDab` (`:289-290`), commits on tap (`:316`), drops on a left swipe (`:317-323`), paints a 2 s drying stroke (`:327`) and reads "Saves in two seconds" to VoiceOver (`:331`). Capture ghosts are pending ops that dry in 2 s (`App/AppModel.swift:132-150`). None of that fits a plan row (decisions 8:38 PM PT: plan rows never use the "Saves in two seconds" line). Not built: the plan hero, rows, START WITH.
- **§6:** agrees (D2, D3, D4, D7 closed).

### Step 7. Claude is asked to word it
- **Sees:** the cloud mark rises off the soul (three cobalt wisps, `claude-settings.md`) while the call is out; VoiceOver "Sent to Claude" (M17). The plain words stay readable. Nothing else moves.
- **Engine:** `PlanPack` built from the rules `DayPlan`, birthdays dropped, handles not UUIDs, `light` and `cap` from C1 to C3. Pack hash checked: same pack as earlier today reuses the wording, no call. Cap check: `reserve` the worst case ($0.0125) before the await. Sonnet 5.5, effort low, `max_tokens` 1,024, 20 s timeout, one `proposePlan` structured reply, no tools.
- **Master:** `TessUse.plan` exists (`TesseraCore/Sources/TesseraTess/TessModel.swift:12-13`). `TessUsageLedger.capNano` is $10 (`TesseraTess/ClaudeKey.swift:87`); `canSpend` (`:113-114`) and `reserve` (`:127-128`) exist. Not built: a Claude client for the plan, `PlanPack`, `ProposePlan`, the validator, the cloud mark.
- **§6:** "Claude words it". Agrees (G1 closed).

### Step 8. The worded plan replaces the plain lines in place
- **Sees,** usually within 2 to 5 s: the words cross-fade in place (blur 4pt to 0, 420ms, house curve), through `withTesseraAnimation`. No partial stream; the reply must pass V1 to V12 first.
  - Start line under START WITH: "Landlord reply first, then physio, then the report."
  - Rows reorder inside the run (t1, t3, t2), sliding on the settle spring, each with Claude's line under its title at 21/400 `inkSecondary`: "15 min, a quick one to open with." / "20 min, while the morning is quiet." / "45 min, done before Standup. Due 5 pm."
  - **VIA CLAUDE** once, as a label word under the start line, tapping to the receipt. Each row's VoiceOver label ends "Via Claude".
  - Note: usually none. On a rest day the note "Rest day." is not shown, since the hero already says it.
- **Master:** `withTesseraAnimation` exists and is used on Now (`NowPage.swift:192`). Not built: everything else here.
- **§6:** agrees (G1 closed). One label for the whole plan, not a mark per row (3b, N3).

### Step 9. He edits one row: tap its words
- **Does:** taps "Book physio".
- **Sees:** a 1pt cobalt writing line draws under the row (260ms), the words blur out, the keyboard rises with the text ready. He types "Book physio 30 min" and taps Return.
- **Result:** the row stays a ghost with the new words, re-parsed so "30 min" becomes its length, and the run repacks. If it now runs into a fixed block, the last row in the run slides out as a skip. Claude is not called again.
- **Tess:** "Book physio, 30 min."
- **Master:** grammar exists (`TessGrammar.swift`); lengths parse for captures. Not built: in-place edit of a plan row, and a rename action for an accepted edit.
- **§6:** agrees (D5 closed; old Q6 answered).

### Step 10. He moves one row: tap its time
- **Does:** taps "08:15" on the Book physio row; the time drum opens; he turns it to 9:50 am.
- **Result:** the row keeps its ghost and takes the new time; the other rows don't move. The drum skips times inside fixed blocks. No Tess line.
- **Master:** row times print 24-hour via `Format.clock` (`App/AppClock.swift:47-50`), matching the Day log's time column (decisions 7:34 PM PT). Not built: a time drum.
- **§6:** agrees (old Q7 answered).

### Step 11. He drops one row: swipe left
- **Sees:** the row fades and the queue closes up (320ms). No line, no UNDO: nothing was written. The task stays where it was (Later or undated).
- **Master:** `GhostRow`'s left swipe calls `discardCapture()` (`NowPage.swift:317-320`, `AppModel.swift:213-223`), which discards a pending op. A plan row has no op. Not built.
- **§6:** agrees.

### Step 12. He keeps one row: swipe right
- **Sees:** the words dry from cobalt into ink, left to right (700ms clip sweep), the time 250ms later. The row's slot on the day stroke paints in at its time, wet in cobalt, and dries to ink over `Theme.Motion.dry`.
- **Writes:** one `MoveTask` with `to` = the row's start, through `ActionEngine.perform(_:by: .user)`. One op, his act, actor `.user` (fixture M-ghost). Claude never writes.
- **Tess:** "Reply to landlord, 8 am." with **UNDO** for 4 s.
- **Master:** `ActionEngine.perform(_:by:pending:)` (`TesseraCore/.../Actions/ActionEngine.swift:43-60`); `MoveTask` (`Tasks/Tasks.swift:89-100`); `TessVoice.say(_:undo:)` (`HomeQueue.swift:28-37`). Not built: the right swipe, the dry and the stroke slot.
- **§6:** agrees (D2 closed: no dab flies).

### Step 13. He takes it back: UNDO
- **Sees:** "Reply to landlord, taken back." (M34; thing first, decisions 12:35 pm PT Oct 16). The row goes back to a wet cobalt ghost, still swipeable. The task's `startsAt` is what it was before.
- **Writes:** `ActionEngine.undo` on that one record. Window 4 s.
- **Master:** `ActionEngine.undo(_:)` (`ActionEngine.swift:141`); `TessVoice` carries the op for UNDO (`HomeQueue.swift:16-19`). The Ask bar's `undoLastCapture()` sets no line (`AppModel.swift:226-237`; `claude-first-run.md` F10). Not built: returning the row to a ghost.
- **§6:** agrees.

### Step 14. He holds START WITH
- **Does:** holds "Reply to landlord" for 0.7 s, the same hold as Finish. The ink line empties to a 0.9pt trace at 35%, repaints left to right, and the bead swells at the tip.
- **Writes:** one named transaction: a `MoveTask` for each row he hasn't skipped or already kept; then the first item becomes Now. Making it Now is a ranker state, not a process start. If the first item is a workout (d18, Legs A at 8 am), it becomes Now's routine hero with its own Start word; the hold never starts a workout.
- **Sees:** the plan's hero lifts away and "Reply to landlord" rises into the hero.
- **Tess:** "Plan kept. Reply to landlord is up." with **UNDO for 10 s**. On UNDO: "Plan, taken back." The rows and START WITH return as ghosts.
- **Fixture N7** now reads "never committed without his tap or hold".
- **Master:** `PaintKey` hold (`Paint.swift:225-229`, `NowPage.swift:114-124`, 0.7 s at `:114`). Not built: the plan transaction, the lines, a 10 s window.
- **§6:** agrees (D6, D8 closed; old Q5 answered by Product).

### Step 15. The plan is now his day
- **Sees:** Now shows "Reply to landlord" with its Finish hold; the queue window shows the kept rows in ink at their times; the day stroke carries them.
- **Master:** today's Now (`NowPage.swift:86-125`) and queue (`HomeQueue.swift:73`). Built.
- **§6:** agrees.

### Step 16. Or: he skips the whole plan
- **Does:** swipes the plan's hero left.
- **Sees:** normal Today. No line, nothing written. The offer is spent until tomorrow's 08:00; only asking ("plan my day") brings it back today.
- **§6:** agrees (old Q2 answered).

### Step 17. 10:30 am: he opens the app again
- **Sees:** Now as ranked. No second offer. If he asks for the plan and the pack hash matches, the same wording comes back with no second call.
- **Master:** not built (no hash, no offer flag).
- **§6:** silent on a re-ask after the pack changes (Q12 below).

### Branches: when Claude can't word it

In every branch the rules plan from step 6 is already on screen and stays exactly as it is. Accept, skip, edit, move and START WITH work the same. Nothing is queued. The wisps go. At most one line per plan.

| # | Case | What he sees | Line | Master |
|---|---|---|---|---|
| B1 | No key, Use Claude off, or the use 2 gate not yet passed | Rules plan, no wisps | None | Settings: Claude exists (`Features/Settings/ClaudeSection.swift`); the gate is not built |
| B2 | Offline at open | Rules plan | "Here's your usual plan." (M23) | `ClaudeKeyCheck` maps offline `URLError`s (`ClaudeKey.swift:251-253`) for the key check only; no `NWPathMonitor` |
| B3 | Over the cap (or the $0.0125 reservation doesn't fit) | Rules plan; no call | "Claude paused until Dec 1. Here's your usual plan." (decisions 8:38 PM PT; how often: 3b, N2) | `canSpend`/`reserve` (`ClaudeKey.swift:113-128`); month from 00:00 on the 1st |
| B4 | No answer in 20 s | Rules plan; a later reply is dropped, its cost still counts | "Claude didn't answer in time. Here's your usual plan." (M18's plan variant; M18 itself is "Claude didn't answer in time.", 8:46 PM PT; `claude-settings.md` C15) | Not built |
| B5 | 429, 529 or 500 after one retry | Rules plan | "Claude is busy. Here's your usual plan." (M22) | Not built |
| B6 | Reply fails V1 to V12 | Rules plan; `TessCall` logged `invalid` with codes, never the text | "Here's your usual plan." (M23). Prompt-pack repairs still apply: a failing `note` alone is dropped; a light-day workout start line becomes "{title} at {time}."; a run in Claude's order with drifted times is repacked | Not built |
| B7 | 401 or 403 on the call | Rules plan; Use Claude switches off | "That key didn't work. Paste it again?" (M2, decisions 8:38 PM PT) | Key check maps 401 to `.badKey` (`ClaudeKey.swift:303`), and since #248 (`fdcaee4`) its line is M2 (`:318`). Closed (N4) |
| B8 | Anthropic account paused | Rules plan | "Here's your usual plan." | Key check only (`ClaudeKey.swift:305`, line `:324`) |
| B9 | He acts before the reply lands (any swipe, edit, time change, or the hold) | His plan stays as he touched it; the reply is dropped; its cost still counts | None | Not built |

## 3a. Closed: the old §6 disagreements

| # | Was | Design's answer in §6 (`041a17d`) | Status |
|---|---|---|---|
| D1 | "At 08:00 the plan becomes Now", no word on running, timed or rest | "When it shows" items 1 to 4: running keeps Now (no offer while a workout runs), timed within 15 min keeps Now, rest day keeps the hero with rows under it, otherwise the plan is Now | Closed |
| D2 | A dab flies to the day stroke on accept | No dab before the words; on keep the words dry cobalt to ink and the row's slot on the day stroke paints in wet, then dries | Closed |
| D3 | "four hours free" with no calendar | Without the calendar the hero counts tasks and the workout only, "Three tasks, Push A at 6 pm", never free, clear or open; meetings on the stroke only when the calendar is read | Closed |
| D4 | Energy re-flows the plan; "Short night. Two things, and a lighter top set." | Energy is logged for the Day log only, never changes the plan, and Tess says nothing; light days from C1 to C3 only | Closed |
| D5 | "Got it, 30 minutes." | "Book physio, 30 min." (name first) | Closed |
| D6 | Untouched rows count as accepted, against N7 | One named transaction, "Plan kept. Reply to landlord is up." with UNDO; N7 reads "tap or hold" | Closed |
| D7 | "slept 6h40" before Health read | No sleep line at all until Health read is granted; the plan never asks for Health. **Differs from this doc's first default** ("no sleep data"); Design's answer stands, confirmed by Product at 8:46 PM PT | Closed |
| D8 | 0.6 s hold | 0.7 s, the same hold as Finish, on the ink line | Closed |
| G1 | No Claude step in §6 | "Claude words it": wisps while out, cross-fade in place, rows reorder on the settle spring, Claude's line under each title, VIA CLAUDE once, late or touched replies dropped, one fallback line per plan | Closed |

The timeout line is the second place Design differs from this doc's first version: "Claude didn't answer in time. Here's your usual plan." (C15) replaces "Claude timed out. Here's your usual plan.". `tess-voice.md` M18 now reads "Claude didn't answer in time." (Product, 8:46 PM PT), and its plan variant keeps the full line above.

## 3b. Still open: new small disagreements

| # | Point | Against | Recommendation |
|---|---|---|---|
| N1 | §6: a pull while a workout runs gets "Push A is under way, until about 8:05 am." and leaves Now alone, so no pack is built | Fixture d22 sends a pack with `running: true` to Claude, and the prompt has a rule for it. Under §6 that pack can never be sent | Keep §6. The line becomes an engine template, "{workout} is under way, until about {startedAt + 60}." (8 words, passes). Keep d22 in the eval as a guard, and add a builder check: no pack while a workout runs |
| N2 | §6 and decisions 8:38 PM PT give the cap line, but not how often | `tess-voice.md` M10 is "once per month"; `settings-claude.md` S14 and S17 show "Here's your usual plan." on every later plan | The paused line on the first capped plan of the month, then "Here's your usual plan." (M23). Product to confirm in one line |
| N3 | §6: VIA CLAUDE once under the start line, not on each row | Decision 8:28 PM PT: "Every Claude ghost row keeps the cloud mark" (written for use 1 captures) | Keep §6 for the plan: one label for one reply, each row's VoiceOver says "Via Claude". Product notes the plan as the exception |
| N4 | B7 copy is M2 "That key didn't work. Paste it again?" (decisions 8:38 PM PT) | Closed by #248 (`fdcaee4`): `ClaudeKey.swift:318` now says M2 | None |
| N5 | §6 doesn't show the calendar ask (step 5) or M46 "Planned without your calendar. Settings" | `ask-lines.md` A3 fires at the first Plan my day | Design adds where the ask line and CONNECT · NOT NOW sit on the first morning (default: Tess's line in her corner, the plan drawn under it with `cal: false` until he answers) |

Also noted, not a disagreement: §6's page is labelled "Thu 15 Oct fixture d01", while d01 is Mon 2 Nov in the fixture. The content matches.

## 4. Every Tess line, checked against `tess-voice.md`

Checks: under 12 words (11 is the real limit, `TessCapturing.swift:91`), one line, no "!", no emoji, no banned words (`TessCapturing.swift:85` plus V10 and V12 for Claude's lines), name first, offers not orders, am/pm lowercase in sentences, no counts in Claude's lines.

| Step | Line | Source | Words | Result |
|---|---|---|---|---|
| 3 | Push A is under way, until about 8:05 am. | §6 pull while running (engine) | 8 | Pass |
| 5 | Plan around your calendar? Times and titles only. | M45 | 8 | Pass |
| 5 | Planned without your calendar. Settings | M46 | 5 | Pass |
| 6 | Three tasks, Push A at 6 pm (hero, no calendar) | §6 | 7 | Pass. Hero, not Tess; counts allowed on engine copy |
| 7 | Sent to Claude (VoiceOver) | M17 | 3 | Pass |
| 8 | Landlord reply first, then physio, then the report. | d01 start | 8 | Pass |
| 8 | 15 min, a quick one to open with. / 20 min, while the morning is quiet. / 45 min, done before Standup. Due 5 pm. | d01 ghosts | 8, 7, 7 | Pass. "5 pm" licensed by `due` |
| 8 | Rest day. (Claude's note, d21) | d21 | 2 | Pass, but not shown: the hero already says it |
| 9 | Book physio, 30 min. | §6 | 4 | Pass |
| 12 | Reply to landlord, 8 am. | §6 | 4 | Pass |
| 13 | Reply to landlord, taken back. | M34 | 4 | Pass |
| 14 | Plan kept. Reply to landlord is up. | §6 | 7 | Pass |
| 14 | Plan, taken back. | §6, M34 form | 3 | Pass |
| B2, B6, B8 | Here's your usual plan. | M23 | 4 | Pass |
| B3 | Claude paused until Dec 1. Here's your usual plan. | decisions 8:38 PM PT | 8 | Pass |
| B4 | Claude didn't answer in time. Here's your usual plan. | M18 plan variant, C15 | 9 | Pass |
| B5 | Claude is busy. Here's your usual plan. | M22 | 7 | Pass |
| B7 | That key didn't work. Paste it again? | M2 | 7 | Pass |
| VoiceOver | Proposed: Reply to landlord, 8 am. Via Claude. Hint: Swipe right to keep, left to skip. Actions: Keep, Skip, Edit, Change time | §6 | 7 | Pass. Replaces master's "Saves in two seconds" (`NowPage.swift:331`) |
| VoiceOver | Start with Reply to landlord. Hint: Touch and hold | §6 | 5 | Pass |

Silent on purpose: drawing the plan, a reply landing, a time change, a skipped row, skipping the plan, setting energy. M7 "Tess: $0.01 this month." does not show on plan keeps: the keep is his `.user` op with no Claude route, so the month shows in Settings and the receipt reads "8:00 am · Plan my day · Sonnet · 0.5¢".

Voice notes:
- **V2:** `TessVoice.bannedWords` (`TessCapturing.swift:85`) still lacks "undone", which `tess-voice.md`'s automatic checks list. Small Core fix.
- **V3:** Row times are "08:00" on screen, as in the Day log's time column; VoiceOver labels use "8 am" (`NowPage.swift:330` reads `Format.clock` today).
- The old flags on "Got it, 30 minutes.", "Short night ..." and M10's "On-device until then." for the plan are closed by §6 and decisions 8:38 PM PT.

## 5. Build list

### Builder B (UI: Now, ghost rows, Ask)
1. **Plan state on Now.** A `PlanHero` beside `RunningHero`, `RestHero` and the task hero in `NowPage.swift:31-40`: "this morning", the day sentence (Title 44/500; calendar and no-calendar forms), the sleep line only once Health read is granted, the optional energy line, then rows and START WITH. Read the ranker's plan pick (Core 1); don't decide precedence in the view.
2. **Rest-day form:** `RestHero` stays; rows and START WITH sit under it in the queue window; no plan hero sentence; Claude's "Rest day." note not shown.
3. **`PlanGhostRow`,** not master's `GhostRow`: no `PaintDab`, no 2 s stroke, no timer, no "Saves in two seconds". Title Body 21/500 wet cobalt breathing 0.5 to 0.66, time as a value word, Claude's line under it at 21/400 `inkSecondary`. Delete the unused `GhostRow` or fold it in.
4. **Gestures:** swipe right keeps (dry cobalt to ink 700ms, time 250ms after, the stroke slot paints in wet and dries over `Theme.Motion.dry`); swipe left skips (fade, close up, 320ms); tap words to edit (1pt writing line, 260ms); tap time for the time drum (skips fixed blocks). All through `withTesseraAnimation`; Reduce Motion as cross-fades.
5. **START WITH** as a `PaintKey` hold at Title 34 on the cobalt ink line, 0.7 s like Finish (trace 0.9pt at 35%, bead at the tip; no thickening or bead under Reduce Motion). On fire: the promotion motion into the hero; a workout becomes the routine hero, never started.
6. **Pull:** the **plan** value word on the Now line from 07:00, and "plan my day" in Ask. While a workout runs, show the engine line and leave Now alone.
7. **Re-word in place:** blur 4pt to 0 cross-fade, 420ms; rows reorder on the settle spring; drop the reply if he touched the plan (B9) or after 20 s.
8. **Cloud mark and VIA CLAUDE:** three cobalt wisps off the soul while out (none under Reduce Motion); VIA CLAUDE once under the start line, tapping to the receipt; each row's VoiceOver ends "Via Claude".
9. **Tess lines with UNDO:** row keep (4 s), "Plan kept" (**10 s**), edit confirm, each undo line "{name}, taken back." / "Plan, taken back.". Give `TessVoice.say` a duration (`HomeQueue.swift:28-37`). Also set the undo line in `undoLastCapture` (`AppModel.swift:226`).
10. **Calendar ask** as Tess's line with CONNECT and NOT NOW label words, and M46 with SETTINGS (placement per N5).
11. **Fallback lines,** one per plan: M23, M18 (new wording), M22, the cap line, M2. None for B1 and B9.
12. **VoiceOver** labels, hints and named actions from section 4; am/pm in labels.
13. **Whole-plan skip:** hero swipe left, no line, nothing written.

### Core (offer timing, pack, ActionEngine)
1. **Plan rung in the ranker,** after rest day, before re-entry (`NowRanker.swift:124-133`): not yet offered this 4 AM day, 08:00 to 21:00 for the offer (07:00 for a pull), outside 23:00 to 07:00, at least one task line, no workout running. On a rest day the rest pick stays first and the plan comes as a second, non-hero pick.
2. **Offer flag per logical day** (`TesseraDay.day(of:)`), set when the plan shows or is skipped, kept across relaunch, cleared at 4 AM.
3. **Ask ledger:** one ask per 4 AM day, priority A1, A3, A7, A9, A2, A10, pending queue, no fallback line for an unseen ask (`ask-lines.md` rules 1 to 5). The plan reads it for A3.
4. **Rules `DayPlan`** (slice 6): window 07:00 floor to 21:00, fixed blocks, runs, cap from C1 to C3 (`light-day.md`), never Health or energy.
5. **`PlanPack`:** sorted keys, handles, `cal`, `rest`, birthday drop, `due` dropped when placed after it, pack hash for reuse. Builder check: no pack while a workout runs (N1); keep `running` and d22 as a guard.
6. **Claude client for `TessUse.plan`:** Sonnet 5.5, effort low, 1,024 tokens, 20 s, structured `proposePlan`, `reserve` before the await (`ClaudeKey.swift:127`), settle after, and settle a dropped reply too (its cost counts). `TessCall` row titled "Plan my day" (`claude-first-run.md` F8).
7. **`PlanProposalValidator`** V1 to V12 plus M-fmt and M-light, with the three soft repairs.
8. **Keep path:** a kept row is one `MoveTask` by `.user` (`Tasks.swift:89`). START WITH is one named transaction of every untouched row's `MoveTask`, undone as one record, with a 10 s UNDO. An edited row adds a rename in the same transaction (needs a rename action; not on master).
9. **Typed fallback outcomes** (timeout, busy, offline, cap, invalid, badKey, paused, dropped) so the UI picks the line and never parses text. The cap outcome says whether it's the first capped plan this month (N2).
10. **Key-check copy:** done in #248 (`fdcaee4`, N4). Still open: add "undone" to `bannedWords` (V2).
11. **Run the eval** (`-planEval`) and the blind read before use 2 turns on; the gate is one bool the plan reads.

## 6. Open questions, each with a recommended default

Answered since the first version: Q1 pull from 07:00, Q2 only asking brings it back, Q4 Claude's line under the title, Q5 10 s on "Plan kept", Q6 the last row slides out, Q7 the drum skips fixed blocks, Q8 rows under "Rest day", Q9 no offer while a workout runs, Q11 late replies dropped with cost counted, Q13 the cap line, Q14 m4-steers landed.

| # | Question | Recommended default |
|---|---|---|
| Q3 | "Opt-in" (`ship-list-m4.md`): is there a switch? | No switch. Skipping is one swipe and the plan never notifies. Revisit after a week |
| Q10 | Re-entry morning (3 or more days away): plan or "Welcome back. Small on purpose"? | Plan. It is already small and skippable; re-entry shows if he skips it |
| Q12 | The pack changes later in the day (a new task). Call Claude again? | Only on an ask, only if he hasn't touched the plan, and at most 3 plan calls a day |
| Q15 | N1: how is d22 used now that no pack is sent while a workout runs? | Keep it as a guard in the eval; the "under way" line is engine copy |
| Q16 | N2: the cap line on every capped plan, or once a month? | Once a month, then "Here's your usual plan." |
| Q17 | N5: where do the calendar ask and M46 sit on Now? | Tess's line in her corner, CONNECT · NOT NOW under it, the plan drawn below with `cal: false` until he answers |
