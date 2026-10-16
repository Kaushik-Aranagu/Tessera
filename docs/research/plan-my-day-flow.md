# Plan my day with Claude: the morning, step by step

For: Builder B (Now, ghost rows, Ask), Core (offer timing, `PlanPack`, ActionEngine), Design (m4-steers §6), Product (open questions). Research lab, board item 95, 2026-10-16.
Inputs: `plan-my-day-prompt.md` (instructions, schema, V1 to V12), `plan-my-day-blind-read.md`, `claude-first-run.md` (step 8), `fixtures/plan-my-day-claude.md` (d01 to d23, builder checks), `claude-first-uses.md` (use 2), `settings-claude.md`, `tess-voice.md` (M1 to M58), `ask-lines.md`, `light-day.md`, `design/no-dots.md`, `product/decisions.md`, `product/ship-list-m4.md`.
**Master read:** `origin/master` at `e9f4a06` (Merge PR #233, Oct 15 8:27 PM PT), read with `git show`. Nothing was run and no key was used.
**Where m4-steers lives.** `design/README.md:18` lists `m4-steers.md`, but the file is not in `tessera/design/` and not on master. The only copy is on branch `origin/claude/project-thread-b3tu3f`, last changed in `c0c5c06` ("Plan my day and Shutdown redrawn without buttons", Oct 15 12:46 PM PT). This doc checks against that copy of §6. Design should land it in `tessera/design/` so Builder B reads the same text.

## Bottom line

- The walk is **17 steps** from the 4 AM turnover to an accepted plan, plus **9 branches** for no key, offline, the cap and failed calls.
- **What exists on master:** the 4 AM day (`TesseraDay`), Now's precedence (running, timed task within 15 min, rest day, re-entry, rank), `ActionEngine.perform` with pending ops, `MoveTask`, the stroke word (`PaintKey`) and label words (`LabelActionStyle`), the $10 ledger with `reserve`, `TessUse.plan`, `TessVoice.violations`, a Settings: Claude section. **Not built:** the plan offer itself, `DayPlan`, `PlanPack`, `ProposePlan`, the validator, a Claude client for the plan, capture or question uses (only the key check calls Claude), the cloud mark, the ask ledger, a quiet-hours gate on Now, the 10 s undo, and a ghost row that waits for a swipe. Master's `GhostRow` is declared and never used.
- **8 disagreements with m4-steers §6** (section 3). The three that change the build: §6 makes the plan Now at 08:00 with no word on a running workout, a timed task or a rest day; §6 flies a dab on accept, which the no-dots call (Kaushik, 8:07 PM PT) removes; §6 re-flows the plan from the energy drum and says "Short night", which the light-day call (5:41 PM PT) and the prompt's V10 and V12 rule out.

## 1. Rules this walk follows

| Rule | Source | On master |
|---|---|---|
| His day runs 4 AM to 4 AM | decisions 7:22 and 7:40 PM PT; `day-boundary.md` | `TesseraDay.startHour = 4`, `TesseraCore/.../Engine/TesseraDay.swift:10`; fold at `:22-24` |
| Quiet hours 11 PM to 7 AM | decisions 6:20 and 6:44 PM PT; fixture N1 | Only as the day stroke's scale, 7 am to 11 pm (`Features/Home/DayStrip.swift:6`). No gate on Now. Not built |
| One ask per 4 AM day, pushed asks in order, A3 Calendar at Plan my day | decisions 5:56 PM PT; `ask-lines.md` rules 1 to 5 | Not built: no ask ledger anywhere |
| At most one Tess suggestion a day; Plan my day opt-in, no notifications, on Now from 08:00 | `ship-list-m4.md`, Defaults taken | Not built |
| Now precedence: running process, then an event or timed task within 15 min, then a planned rest day, then re-entry, then the scored rank | decisions 3:37 and 4:01 PM PT | `NowRanker.swift:112-141` (`TesseraCore/.../Tasks/`), header `NowPicker.swift:3-5`. Events are not read yet (no calendar), so only timed tasks count |
| Plan window 07:00 floor, ends 21:00 (Shutdown) | decisions 11:40 AM PT; fixture M-day | `DayLoad` counts free time to 23:00 (`Tasks/DayLoad.swift:23`). Plan window not built |
| Light day from C1 to C3 only, never Health or energy | decisions 5:41 and 5:48 PM PT; `light-day.md` | Not built |
| No buttons with shapes; actions are stroke words and label words | decisions 12:00 PM PT; `no-buttons.md` | `DesignSystem/InkActions.swift:4-5`, `LabelActionStyle` `:47-49`; `PaintKey` `DesignSystem/Paint.swift:225-229` |
| No coloured dot or dab before or after a line of text | decisions 8:07 PM PT; `design/no-dots.md` rule 1, row "Now's ghost rows" | `GhostRow` still draws a cobalt `PaintDab` (`Features/Home/NowPage.swift:289-290`) |
| UNDO names the thing plus "taken back"; 10 s on destructive writes | `tess-voice.md` principle 8, M34, M35 | `TessVoice.say` holds every note 4 s (`Features/Home/HomeQueue.swift:28-37`). No 10 s path |
| Plan fallback: the rules plan plus one quiet line | decisions 12:22 PM PT; M18, M22, M23 | Not built |

## 2. The walk

The morning is Mon 2 Nov 2026 (PST), pack d01: Reply to landlord, Expense report (due 5 pm), Book physio; Standup 9:30 am, Design review 11 am, 1:1 Priya 3 pm; Push A at 6 pm. His key works, Use Claude is on, and the use 2 gate has passed (decisions 7:38 and 7:44 PM PT: 21 of 23 raw, 19 of 23 read). Every time is Pacific.

Each step gives what he sees and does, what master has, and a check against m4-steers §6 ("§6 agrees", or a numbered disagreement from section 3).

### Step 1. 4:00 am: the day turns over
- **Sees:** nothing. He is asleep.
- **Engine:** the logical day becomes Monday. The plan-offer flag and the day's ask slot both reset here, not at midnight. An open at 1:30 am still belongs to Sunday; its plan window is empty, so no pack is built (fixture builder check).
- **Master:** `TesseraDay.day(of:)` folds 00:00 to 03:59 into the day before (`TesseraDay.swift:22-24`). The offer flag and ask slot are not built.
- **§6:** silent on the boundary. No conflict.

### Step 2. 6:40 am: he opens the app in quiet hours
- **Sees:** Now as on any morning, ranked by master's ranker. No plan, no ask, no Claude call.
- **Why:** quiet hours run to 7 am, and the plan window opens at 07:00 at the earliest (fixture M-day, N1).
- **Master:** Now comes from `rank()` (`NowPage.swift:22-26`, `NowRanker.swift:99`). No quiet-hours gate exists, but none is needed today because no offer exists. Not built: the gate.
- **§6:** silent. No conflict.

### Step 3. 7:00 to 7:59 am: he can pull the plan, nothing pushes it
- **Sees:** Now as usual. If he asks for it ("plan my day" in Ask, or a pull on Now; the pull gesture is Design's), the plan builds at once with `window` starting at his open time.
- **Why:** Product's offer time is 08:00 (`ship-list-m4.md` slice 6 and Defaults). The fixture plans from 07:00 (d22 opens at 7:40 am). Reading both: pushed at 08:00, pulled any time from 07:00.
- **Master:** not built. Ask on master has no "plan my day" phrase.
- **§6:** "At 08:00 the plan becomes Now." Agrees on the push. Open question Q1 covers the pull.

### Step 4. 8:00 am or his first open after it: is the plan allowed to take Now?
The plan offer becomes a new rung in the ranker. It goes in after the rest day and before re-entry:

1. **A running process** (his workout, a cook, a focus block) keeps Now. The plan waits. When the workout ends, the next time Home shows, the plan is offered, without the finished workout (d20: a finished workout sends no block).
2. **A timed task (or event, once the calendar is read) within 15 minutes** keeps Now. The plan waits until that task is done or its end has passed.
3. **A planned rest day** keeps the hero: "Rest day", with the next routine a tap away. The plan still arrives, under it, in the queue window (step 7). The pack carries `rest: true` (d21).
4. **The plan offer**, once per 4 AM day, from 08:00 to 21:00, outside quiet hours, only when the rules plan has at least one task line (d14 sends no pack and shows no plan).
5. Re-entry, then the scored rank, as today.

- **Master:** rungs 1 to 3 are built: `if let running` (`NowRanker.swift:112-116`), the 15-minute window `Weight.overrideWindow = 15` (`:93`, `:117-123`), the rest pick (`:124-132`). `RestDay` is nil while a workout is under way (`Training/RestDay.swift:23`, `:39-49`). Now's hero switch reads the same order (`NowPage.swift:31-40`). Rung 4 is not built.
- **§6:** says only "At 08:00 the plan becomes Now." **Disagreement D1.**

### Step 5. First morning only: the calendar ask
- **Sees, once ever:** Tess's line "Plan around your calendar? Times and titles only." (M45) with two label words under it, **CONNECT** and **NOT NOW** (Label 16/700, no shape).
- **Does:** taps CONNECT; the iOS calendar sheet follows at once (ask rule 2, a pulled ask).
- **One ask a day:** A3 uses today's slot. If the slot is already used (a Health write ask after last night's workout cannot be today's, but a pulled ask earlier this morning can), A3 is marked pending, the plan builds with `cal: false`, and no line says why (ask rule 4). If he denies, the plan says "Planned without your calendar. Settings" (M46), with SETTINGS as the word to tap.
- **Master:** not built. No calendar read, no `NSCalendarsFullAccessUsageDescription` (`ask-lines.md` A3: missing).
- **§6:** silent on the ask. No conflict.

### Step 6. The rules plan draws at once
- **Sees** (§6 layout, Now on Home, no card, no sheet):
  - Now line "this morning".
  - Hero, the day in one sentence: "Three meetings, four hours free". With `cal: false` the hero must not say "free", "clear" or "open" (fixture N5). Proposed: "Three tasks, Push A at 6 pm".
  - Context line "slept 6h40", or "no sleep data".
  - The day stroke: events painted as short ink segments at their times; free time stays dashed.
  - Up to 3 ghost rows in the queue window: the task's title in wet cobalt, breathing, and its time at the right as a value word. **No dab** before the words (no-dots rule 1).
  - The one action at y 450: the label **START WITH** and, under it, "Reply to landlord" at Title 34 on a cobalt stroke word.
- **The rows do not dry on a timer.** Nothing is written by drawing the plan (fixture M-ghost: applying a proposal writes 0 ops).
- **Master:** `HomeDayStrip` exists (`DayStrip.swift:77`). The `PaintKey` hold is used for Finish (`NowPage.swift:114-124`). `GhostRow` exists but is never instantiated (only its declaration at `NowPage.swift:278`), draws a `PaintDab` (`:289-290`), commits on tap (`:316`), drops on a left swipe (`:317-323`), paints a 2 s drying stroke (`:327`) and reads "Saves in two seconds" to VoiceOver (`:331`). Capture ghosts are pending ops that dry in 2 s (`App/AppModel.swift:132-150`). None of that fits a plan row. Not built: the plan hero, the plan rows, START WITH.
- **§6:** agrees on layout. **Disagreement D2** on the dab, **D3** on "free" with no calendar.

### Step 7. Claude is asked to word it
- **Sees:** the cloud mark on Tess's bloom while the call is out; VoiceOver "Sent to Claude" (M17). The rules wording stays readable underneath. Nothing else moves.
- **Engine:** `PlanPack` built from the rules `DayPlan`, birthdays dropped, handles not UUIDs, `light` and `cap` from C1 to C3. Pack hash checked: same pack as earlier today means reuse the wording, no call. Cap check: `reserve` the worst case ($0.0125) before the await. Sonnet 5.5, effort low, `max_tokens` 1,024, 20 s timeout, one `proposePlan` structured reply, no tools.
- **Master:** `TessUse.plan` exists (`TesseraCore/Sources/TesseraTess/TessModel.swift:12-13`). `TessUsageLedger.capNano` is $10 (`TesseraTess/ClaudeKey.swift:87`); `canSpend` (`:113-114`) and `reserve` (`:127-128`) exist. Not built: any Claude client for a use other than the key check, `PlanPack`, `ProposePlan`, the validator, the cloud mark.
- **§6:** written for "rules only"; it has no Claude step. Gap, not a conflict (G1 in section 3).

### Step 8. The worded plan replaces the plain lines in place
- **Sees,** typically within 2 to 5 s: the plain words cross-fade to Tess's words through `withTesseraAnimation`. No partial stream; the reply must pass V1 to V12 first.
  - Start line under START WITH: "Landlord reply first, then physio, then the report."
  - Rows, reordered by Claude inside the run (t1, t3, t2), each title with Claude's line under it: "15 min, a quick one to open with." / "20 min, while the morning is quiet." / "45 min, done before Standup. Due 5 pm."
  - Note: usually none.
  - Each worded row carries the small cloud mark (decision 8:28 PM PT: every Claude ghost row keeps it).
- **Master:** `withTesseraAnimation` exists and is used on Now (`NowPage.swift:192`). Not built: everything else here.
- **§6:** silent on rewording. G1.

### Step 9. He edits one row: tap its words
- **Does:** taps "Book physio".
- **Sees (§6):** a 1pt cobalt writing line draws under the row (260ms), the words blur out, the keyboard rises with the text ready. He types "Book physio 30 min" and taps Return.
- **Result:** the row stays a ghost with the new words, re-parsed through the grammar, so "30 min" becomes its length. The rest of the run repacks back to back. If the run now runs into Standup, the last row in the run slides out (Q6). Claude is not called again: once he has touched the plan, the wording is his.
- **Tess:** §6 says "Got it, 30 minutes." Proposed instead: "Book physio, 30 min." (**D5**).
- **Master:** grammar exists (`TessGrammar.swift`), lengths parse for captures. Not built: in-place edit of a plan row, a rename action for an accepted edit.
- **§6:** agrees on the gesture.

### Step 10. He moves one row: tap its time
- **Does:** taps "08:15" on the Book physio row; the time drum opens; he turns it to 9:50 am.
- **Result:** the row keeps its ghost and takes the new time; the other rows don't move. The drum skips times inside fixed blocks (Q7). No Tess line: the row shows the change (rule 7).
- **Master:** a drum exists for reps (`Features/Workout/Instruments/RepsDrum.swift:21`). Row times print 24-hour via `Format.clock` (`App/AppClock.swift:47-50`), which matches the Day log's time column ("07:10", decisions 7:34 PM PT). Not built: a time drum.
- **§6:** "The time on the right is a value word that opens the time drum." Agrees.

### Step 11. He drops one row: swipe left
- **Sees:** the row fades and the queue closes up (320ms). No line, no UNDO: nothing was written. The task stays where it was (Later or undated).
- **Master:** `GhostRow`'s left swipe calls `discardCapture()` (`NowPage.swift:317-320`, `AppModel.swift:213-223`), which discards a pending op. A plan row has no op to discard. Not built.
- **§6:** "Swipe left skips it." Agrees.

### Step 12. He keeps one row: swipe right
- **Sees:** the words dry from cobalt into ink, left to right (700ms clip sweep), the time 250ms later (no-dots row "Now's ghost rows"). The row joins the day stroke at its time.
- **Writes:** one `MoveTask` with `to` = the row's start, through `ActionEngine.perform(_:by: .user)`. One op, his tap, actor `.user` (fixture M-ghost). Claude never writes.
- **Tess:** "Reply to landlord, 8 am." with **UNDO** beside it for 4 s.
- **Master:** `ActionEngine.perform(_:by:pending:)` (`TesseraCore/.../Actions/ActionEngine.swift:43-60`); `MoveTask` (`Tasks/Tasks.swift:89-100`); `TessVoice.say(_:undo:)` (`HomeQueue.swift:28-37`). Not built: the right swipe and the dry motion.
- **§6:** "Swipe right accepts a line: it dries into ink and its dab flies to its slot on the day stroke." **D2** (no dab).

### Step 13. He takes it back: UNDO
- **Sees:** "Reply to landlord taken back." (M34). The row goes back to a wet cobalt ghost in the queue, still swipeable. The task's `startsAt` is what it was before.
- **Writes:** `ActionEngine.undo` on that one record.
- **Window:** 4 s. A plan accept is not destructive under the 5:14 PM PT definition (delete a note, finish the shop), so 10 s does not apply (Q5 asks about step 14).
- **Master:** `ActionEngine.undo(_:)` (`ActionEngine.swift:141`); `TessVoice` carries the op for UNDO (`HomeQueue.swift:16-19`). The Ask bar's `undoLastCapture()` sets no line (`AppModel.swift:226-237`; `claude-first-run.md` F10). Not built: returning the row to a ghost.
- **§6:** silent on undo. No conflict.

### Step 14. He holds START WITH
- **Does:** holds the stroke word "Reply to landlord" (§6: 0.6 s; master's Finish hold is 0.7 s). The stroke empties to a 20% trace, repaints left to right, and the tip blooms.
- **Writes:** one transaction: a `MoveTask` for each row he didn't skip and hasn't already kept, then the first item becomes Now. Making it Now is a ranker state, not a process start: for a task, Now's hero; for a workout (d18, Legs A at 8 am), Now's routine hero with its own start word, so a hold never starts a workout by itself.
- **Sees:** the plan's hero sentence lifts away and "Reply to landlord" rises into the hero.
- **Tess (new line, Design to confirm):** "Plan kept. Reply to landlord is up." with **UNDO**. On UNDO: "Plan taken back." The rows return as ghosts, START WITH returns.
- **Master:** `PaintKey` hold (`Paint.swift:225-229`, `NowPage.swift:114-124`). Not built: the plan transaction, the plan line, a 10 s window.
- **§6:** "Rows untouched when you start count as accepted." Agrees in substance; **D6** on the wording of "untouched" against fixture N7.

### Step 15. The plan is now his day
- **Sees:** Now shows "Reply to landlord" with its Finish hold; the queue window shows the kept rows in ink at their times; the day stroke carries them.
- **Master:** this is today's Now (`NowPage.swift:86-125`) and queue (`HomeQueue.swift:73`). Built.
- **§6:** "That's the end; the whole flow is under a minute." Agrees.

### Step 16. Or: he skips the whole plan
- **Does:** swipes the plan's hero left.
- **Sees:** the plan drops back to normal Today. No line, nothing written. The offer is spent for this 4 AM day; it doesn't come back until tomorrow's 08:00. A pull (step 3) still works if he changes his mind (Q2).
- **§6:** "Skipping the whole plan: swipe the hero left ... until tomorrow." Agrees.

### Step 17. 10:30 am: he opens the app again
- **Sees:** Now as ranked. No second offer. If he pulls the plan, the same wording comes back when the pack hash matches; no second Claude call.
- **Master:** not built (no hash, no offer flag).
- **§6:** silent. No conflict.

### Branches: when Claude can't word it

In every branch the rules plan from step 6 is already on screen and stays. Accept, skip, edit, move and START WITH work the same. Nothing is queued: a plan worded later would be stale (`claude-first-uses.md`, Offline). The cloud mark goes away.

| # | Case | What he sees | Line | Master |
|---|---|---|---|---|
| B1 | No key, Use Claude off, or the use 2 gate not yet passed | Rules plan, plain lines, no cloud mark | None (rule 7; `settings-claude.md` "Rules plan with its plain lines, no fallback line") | Settings: Claude exists (`Features/Settings/ClaudeSection.swift`); the gate is not built |
| B2 | Offline at open | Rules plan | "Here's your usual plan." (M23) | `ClaudeKeyCheck` maps offline `URLError`s (`ClaudeKey.swift:251-253`) for the key check only; no `NWPathMonitor` |
| B3 | Over the cap (or the $0.0125 reservation doesn't fit) | Rules plan; no call is made | First blocked use this month: "Claude paused until Dec 1. Here's your usual plan." (proposed plan form of M10, **D-voice V1**). After that: "Here's your usual plan." | `canSpend`/`reserve` (`ClaudeKey.swift:113-128`); month = calendar month from 00:00 on the 1st |
| B4 | No answer in 20 s | Rules plan; the reply, if it lands later, is dropped | "Claude timed out. Here's your usual plan." (M18) | Not built |
| B5 | 429, 529 or 500 after one retry | Rules plan | "Claude is busy. Here's your usual plan." (M22) | Not built |
| B6 | Reply fails V1 to V12 | Rules plan; `TessCall` logged `invalid` with codes, never the text | "Here's your usual plan." (M23). Exceptions from the prompt pack: a failing `note` alone is dropped and the rest shown; a light-day workout start line is replaced with "{title} at {time}."; a run in Claude's order with drifted times is repacked by the engine | Not built |
| B7 | 401 or 403 on the call | Rules plan; Use Claude switches off | "That key didn't work. Paste it again?" (M2) over the plan (`claude-first-uses.md`) | Not built for uses. The key check maps 401 to `.badKey` (`ClaudeKey.swift:303`) and its line is now "That key didn't work. Check it, or paste it again?" (`:318`), which no longer matches M2 (V4) |
| B8 | Anthropic account paused | Rules plan | "Here's your usual plan." (`settings-claude.md` S12 row) | Key check only (`ClaudeKey.swift:305`, line `:324`) |
| B9 | He acts before the reply lands (any swipe, edit, drum, or the START WITH hold) | His plan stays as he touched it; the reply is dropped when it lands; the call still counts in the ledger | None | Not built |

## 3. Disagreements with m4-steers §6

| # | §6 says | Against | Recommendation |
|---|---|---|---|
| D1 | "At 08:00 the plan becomes Now." | Now's order (decisions 3:37 and 4:01 PM PT; `NowRanker.swift:112-132`): running, timed within 15 min, rest day first | The plan is rung 4 (step 4). §6 adds one sentence: "unless a workout is running, something timed starts within 15 minutes, or it's a rest day" |
| D2 | Accepting: "its dab flies to its slot on the day stroke" | No-dots (Kaushik, 8:07 PM PT): no dab on ghost rows; accept dries the words cobalt to ink | Use no-dots' dry motion. Optional: the time word, not a dab, settles onto the stroke |
| D3 | Hero "Three meetings, four hours free" | Fixture N5 and the prompt: with no calendar, never call the day free, clear or open | Hero without a calendar counts tasks and the workout only: "Three tasks, Push A at 6 pm" |
| D4 | Energy drum re-flows the plan at 2 or below; Tess says "Short night. Two things, and a lighter top set." | Light comes from C1 to C3 only, never sleep or energy (5:41 and 5:48 PM PT; `light-day.md` "Never an input"); "night" (N3) and "lighter" (V10) are banned in plan lines | Energy is logged for the Day log only and never changes the plan. Drop the line. If Design wants a line on a light day: none (rule 7), since two rows already say it |
| D5 | Edit confirms with "Got it, 30 minutes." | Voice principle 1 (name it, then what happened, then the number) and "No greeting ... no sign-off" | "Book physio, 30 min." |
| D6 | "Rows untouched when you start count as accepted." | Fixture N7: no ghost line committed without his tap | Keep §6's behaviour, since the hold is his act, but make it one named transaction with its own line and UNDO (step 14), so N7 reads "without his tap or hold" |
| D7 | Context line "slept 6h40" under the hero | Not a conflict with Claude (sleep is never packed), but `ask-lines.md` A2 (W3 sleep read) is a floating ask that may not have fired yet | Show "no sleep data" until Health read is granted; never ask for it from the plan |
| D8 | Hold time 0.6 s | Master's Finish hold is 0.7 s (`NowPage.swift:114`) and Kaushik asked for a thinner PaintKey stroke (8:25 PM PT) | One hold time for Now's stroke words; Design picks. Default 0.7 s |
| G1 | (no Claude in §6; it is "rules only") | Slice 6b, decisions 11:41 AM PT | Design adds the cloud mark on the bloom and on worded rows, the in-place re-word, and where Claude's per-row line sits (Q4) |

## 4. Every Tess line, checked against `tess-voice.md`

Checks: under 12 words (11 is the real limit, `TessCapturing.swift:91`), one line, no "!", no emoji, no banned words (`TessCapturing.swift:85` plus V10 and V12 for Claude's lines), name first, offers not orders, am/pm lowercase in sentences (6:37 PM PT), no counts in Claude's lines.

| Step | Line | Source | Words | Result |
|---|---|---|---|---|
| 5 | Plan around your calendar? Times and titles only. | M45 | 8 | Pass |
| 5 | Planned without your calendar. Settings | M46 | 5 | Pass |
| 6 | Three tasks, Push A at 6 pm (hero, no calendar) | Proposed (D3) | 7 | Pass. Hero, not Tess; counts allowed on engine copy (principle 2) |
| 7 | Sent to Claude (VoiceOver) | M17 | 3 | Pass |
| 8 | Landlord reply first, then physio, then the report. | d01 start | 8 | Pass |
| 8 | 15 min, a quick one to open with. / 20 min, while the morning is quiet. / 45 min, done before Standup. Due 5 pm. | d01 ghosts | 8, 7, 7 | Pass. "5 pm" licensed by `due` (V11) |
| 8 | Rest day. (note, d21) | d21 | 2 | Pass. Suppress it when the hero already reads "Rest day" so it isn't said twice |
| 8 | Push A is under way, until about 8:05 am. (d22) | d22 | 8 | Pass. Only shown if the plan is pulled while a workout runs (step 4 rung 1) |
| 9 | Got it, 30 minutes. | §6 | 4 | **Fails principle 1** (D5) |
| 9 | Book physio, 30 min. | Proposed | 4 | Pass |
| 12 | Reply to landlord, 8 am. | `claude-first-uses.md` accept form | 4 | Pass. Matches the capture form "Dentist, Thursday 3 pm." |
| 13 | Reply to landlord taken back. | M34 | 4 | Pass |
| 14 | Plan kept. Reply to landlord is up. | Proposed, new | 7 | Pass. Design and Product to confirm |
| 14 | Plan taken back. | Proposed, M34 form | 3 | Pass |
| 6 (§6) | Short night. Two things, and a lighter top set. | §6 | 9 | **Fails** N3 ("night") and V10 ("lighter"); light is never from sleep (D4) |
| B2, B6, B8 | Here's your usual plan. | M23 | 4 | Pass |
| B3 | Claude paused until Nov 1. On-device until then. | M10 | 8 | **Wrong for plan:** plan wording never runs on-device (model-layer §5), so "On-device until then" is untrue here (V1) |
| B3 | Claude paused until Dec 1. Here's your usual plan. | Proposed plan form of M10 | 8 | Pass |
| B4 | Claude timed out. Here's your usual plan. | M18 | 7 | Pass |
| B5 | Claude is busy. Here's your usual plan. | M22 | 7 | Pass |
| B7 | That key didn't work. Paste it again? | M2 | 7 | Pass. Asks a question, so it offers |
| VoiceOver | Proposed: Reply to landlord, 8 am. Via Claude. Hint: Swipe right to keep, left to skip. Actions: Keep, Skip, Edit, Change time | Proposed | 7 | Pass. Replaces master's "Saves in two seconds" (`NowPage.swift:331`), which is untrue for a plan row |
| VoiceOver | Start with Reply to landlord. Hint: Touch and hold | Proposed, master's Finish pattern (`NowPage.swift:123-124`) | 5 | Pass |

Silent on purpose (rule 7): drawing the plan, a move by the drum, a dropped row, skipping the whole plan, the successful Claude reply. M7 "Tess: $0.01 this month." does not show on plan accepts: the accept is his `.user` op with no Claude route (fixture M-ghost), so no receipt reads "via Claude". The month shows in Settings, and the receipts list reads "8:00 am · Plan my day · Sonnet · 0.5¢".

**Voice notes found on the way.**
- **V1:** M10's "On-device until then." is only true for capture. Plan needs its own form (above).
- **V2:** `TessVoice.bannedWords` (`TessCapturing.swift:85`) still lacks "undone", which `tess-voice.md`'s automatic checks list. Small Core fix.
- **V4:** Master's key-check line for a bad key reads "That key didn't work. Check it, or paste it again?" (`ClaudeKey.swift:318`, 9 words, passes), while M2 and `claude-first-uses.md` keep "That key didn't work. Paste it again?". Pick one; the plan's B7 line should match Settings. Default: master's line, and update M2.
- **V3:** The plan uses "8 am" in sentences and "08:00" in the row's time column. That matches the Day log rule (7:34 PM PT), but VoiceOver on master would read the row as "08:00" (`NowPage.swift:330`). Use the am/pm form in labels.

## 5. Build list

### Builder B (UI: Now, ghost rows, Ask)
1. **Plan state on Now.** A `PlanHero` beside `RunningHero`, `RestHero` and the task hero in `NowPage.swift:31-40`: "this morning", the day sentence, the context line, then rows and START WITH. Read the ranker's new plan pick (Core 1); don't decide precedence in the view.
2. **`PlanGhostRow`**, not master's `GhostRow`: no `PaintDab`, no 2 s stroke, no timer. Title in wet cobalt breathing at 0.5 to 0.66, time as a value word, Claude's line under it (Q4), the small cloud mark when worded. Delete the unused `GhostRow` or fold it in.
3. **Gestures:** swipe right keeps (dry cobalt to ink, 700ms, time 250ms after), swipe left skips (fade, close up, 320ms), tap words to edit (1pt writing line, 260ms), tap time for the time drum. All through `withTesseraAnimation`, Reduce Motion as cross-fades.
4. **START WITH** as a `PaintKey` hold stroke word at Title 34, cobalt paint, one hold time with Finish (D8). On fire: the promotion motion into the hero.
5. **Re-word in place:** cross-fade rules words to Claude words when the reply lands; drop the reply if he has touched the plan (B9).
6. **Cloud mark** on the bloom while the call is out, and on worded rows; VoiceOver "Sent to Claude" and "Via Claude" (M17).
7. **Tess lines with UNDO:** row accept (4 s), plan kept (Q5), edit confirm. Make `TessVoice.say` take a duration (`HomeQueue.swift:28-37`) so 10 s exists for destructive writes. Set the line on undo ("{name} taken back."), which `undoLastCapture` doesn't (`AppModel.swift:226`).
8. **The calendar ask** as Tess's line with CONNECT and NOT NOW label words, and M46 with SETTINGS.
9. **Fallback lines** M18, M22, M23, M2 and the plan form of M10, one at a time, over the rules plan.
10. **Ask:** "plan my day" pulls the plan (step 3); the time drum for a plan row.
11. **VoiceOver** labels, hints and named actions from section 4; am/pm in labels.
12. **Whole-plan skip:** hero swipe left, no strike, no line.

### Core (offer timing, pack, ActionEngine)
1. **Plan rung in the ranker:** after rest day, before re-entry (`NowRanker.swift:124-133`). Conditions: today's 4 AM day not yet offered, now from 08:00 (pushed) or 07:00 (pulled) to 21:00, not in 23:00 to 07:00, at least one task line. On a rest day, the rest pick stays first and the plan comes back as a second, non-hero pick.
2. **Offer flag per logical day** (`TesseraDay.day(of:)`), set when the plan shows, cleared at 4 AM. Store it so a relaunch doesn't re-offer.
3. **Ask ledger**, one ask per 4 AM day, priority A1, A3, A7, A9, A2, A10, pending queue, no fallback line for an unseen ask (`ask-lines.md` rules 1 to 5). Plan reads it for A3.
4. **Rules `DayPlan`** (slice 6): window 07:00 floor to 21:00, fixed blocks, runs, cap from C1 to C3 (`light-day.md`), never Health or energy.
5. **`PlanPack`:** sorted keys, handles, `cal`, `rest`, `running`, birthday drop, `due` dropped when placed after it, pack hash for reuse.
6. **Claude client for `TessUse.plan`:** Sonnet 5.5, effort low, 1,024 tokens, 20 s, structured `proposePlan`, `reserve` before the await (`ClaudeKey.swift:127`), settle after, `TessCall` row titled "Plan my day" (`claude-first-run.md` F8).
7. **`PlanProposalValidator`** V1 to V12 plus M-fmt, M-light, with the three soft repairs (drop a bad note, the light workout line, repack in Claude's order).
8. **Accept path:** a kept row is one `MoveTask` by `.user` (`Tasks.swift:89`). START WITH is one transaction holding every untouched row's `MoveTask`, undone as one record. An edited row adds a rename in the same transaction (needs a rename action; not on master).
9. **Fallback outcomes** returned as a typed result (timeout, busy, offline, cap, invalid, badKey, paused), so the UI picks the line and never parses text.
10. **Run the eval** (`-planEval`) and the blind read before use 2 turns on; the gate state is one bool the plan reads.

## 6. Open questions, each with a recommended default

| # | Question | Recommended default |
|---|---|---|
| Q1 | Can he pull the plan before 08:00? | Yes, from 07:00 (end of quiet hours). The push stays at 08:00 |
| Q2 | After he skips the whole plan, can he pull it again that day? | Yes, by asking. It never pushes again until tomorrow |
| Q3 | "Opt-in" (`ship-list-m4.md`): is there a switch? | No switch. Skipping is one swipe and the plan never notifies. Revisit after a week |
| Q4 | Where does Claude's per-row line sit? | Under the title, 21/400 in the context colour, for every row. At most 3 rows, so 6 lines plus START WITH |
| Q5 | Does "Plan kept" (up to 3 tasks moved) get 10 s UNDO? | Yes. Not destructive by the 5:14 PM PT definition, but it moves several things at once and is slow to redo by hand. Product to confirm |
| Q6 | An edit makes the run overrun the next fixed block. | Repack; the last row of that run slides out as a skip (no line). It stays in Later |
| Q7 | Can the time drum put a row inside a meeting? | No: times inside fixed blocks are skipped on the drum |
| Q8 | On a rest day, does the plan take the hero? | No. "Rest day" stays the hero; rows and START WITH arrive under it; Claude's note "Rest day." is not shown twice |
| Q9 | A workout is running at 08:00. | No offer until it ends; then the plan is offered on the next Home view, without the workout |
| Q10 | Re-entry morning (3 or more days away): plan or "Welcome back. Small on purpose"? | Plan. It is already small and skippable; re-entry shows if he skips it |
| Q11 | A Claude reply that lands after 20 s, or after he touched the plan. | Drop it; still record its cost |
| Q12 | The pack changes later in the day (a new task). Call Claude again? | Only on a pull, only if he hasn't touched the plan, and at most 3 plan calls a day |
| Q13 | M10 for plan says "On-device until then." | Use "Claude paused until {reset}. Here's your usual plan." for plan only |
| Q14 | Where is m4-steers? | Design copies the `c0c5c06` version into `tessera/design/` with this doc's D1 to D8 applied or answered |
