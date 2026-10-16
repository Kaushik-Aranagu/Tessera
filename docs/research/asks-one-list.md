# Every ask, one list (board item 131)

For: Design, Core. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Traced by hand against master `21f406d` and Design's branch (`origin/claude/project-thread-b3tu3f`), not run.

**Sources.** Code in `TesseraCore/Sources/TesseraTess/` and `Features/Command/BottomChrome.swift`. Product's
`decisions.md` (as of 3:24 AM PT Oct 16, plus tonight's MU2). Design 35 `one-ask.md`, 47 `groceries-tess.md`,
49 `tess-knows.md`, 53 `plan-home.md`, `m4-steers.md`. Research `ask-lines.md`, `habits-first-use.md`,
`fixtures/money-us.md`, `claude-first-uses.md`.

**The one-ask rules used for the check** (`one-ask.md`, decisions Q10, 8:58 PM, 6:20 PM, 5:56 PM):
- **UNDO:** an ask never shares Tess's slot with an UNDO. It waits until the UNDO goes.
- **Workout:** no yes/no asks in a live workout. A choice ("KG · REPS") or an open ask is allowed. Statements
  ("Say the set, like 85 × 8.", "Skip is on the workout screen.") are lines, not asks. App asks never show there.
- **Quiet:** an app ask (one he didn't start) never shows 23:00 to 07:00. No ask ever notifies.
- **One:** only one ask shows. His phrase first, then a live-workout ask, then app asks. At most one permission or
  one-time ask per 04:00 day.
- An ask writes nothing until answered. Leaving is NOT NOW.

Marks: **ok**, **conflict** (see AQ), **n/a**. "Built" is master today.

## The asks

| # | Ask | Trigger | Exact words | Two ink words | Source | Built | UNDO | Workout | Quiet | One |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 | Set count | Live workout, bare "N x M", N ≤ 6 and under half the last weight | "2 × 10: 2 sets, or 2 kg?" | 2 SETS · 2 KG (drawn inside the line today) | `TessSetCountAsk.swift:36`, `TessGrammar+Live.swift:139-157`; decision 7:53 PM | yes | conflict (AQ2) | ok, a choice (AQ1) | ok, his phrase | ok |
| A2 | Set count, bodyweight | Live workout, bodyweight lift, any bare "N x M" | "5 × 5: 5 sets, or +5 kg?" | 5 SETS · +5 KG | same; decision 9:40 PM | yes | conflict (AQ2) | ok, a choice | ok | ok |
| A3 | Dated set | A lift with a past weekday or "yesterday": "bench 80x8 mon" | "Bench 80 × 8 for Monday?" | LOG · NOT NOW | `TessSetCountAsk.swift:101`, `TessGrammar+Dated.swift:7-37`; decision 8:36 PM | yes | conflict (AQ2) | **conflict** (AQ3) | ok | ok |
| A4 | Weightless lift | A named lift with sets and reps, no weight: "bench 3x8" | "Bench 3 × 8 at what weight?" | none yet; Design wants Core's two likeliest ("80 KG · 82.5 KG") | `TessGrammar+Lift.swift:59-79`, `+Live.swift:149`; decision 9:50 PM | line only | conflict (AQ2) | ok, open | ok | ok |
| A5 | Bare weight | Live, a number that may be a weight: "81", "81 kg" | "81 for how many reps?" / "81 kg for how many reps?" | none yet ("8 · 10") | `TessGrammar.swift:174,392`, `+Live.swift:70,130` | line only | **conflict** (AQ2) | ok, open | ok | ok |
| A6 | Kg or reps | Live, a number near the last weight, or no last set | "8: 8 kg, or 8 reps?" / "8: kg, or reps?" / "8 reps: at what weight?" | none yet (KG · REPS) | `+Live.swift:60,69` | line only | ok | ok, a choice | ok | ok |
| A7 | Fail at N | Live, "fail at 6" | "Fail at 6: rep 6, or 6 reps?" | none yet | `+Live.swift:134` | line only | ok | ok, a choice | ok | ok |
| A8 | Money, word-first spend | A money phrase the phone can't place (MU2) | "$212.37 at Costco?" | LOG · NOT NOW | decisions MU2 (3:24 AM PT); `money-us.md` | no | ok if queued | **conflict** (AQ4) | ok | ok |
| A9 | Money, tip / tax / card bill | "dinner 64 tip 20%", "tax 3.10", "paid apple card 1,240.18" | "Dinner 64 plus 20% tip, 76.80?" / "3.10 tax, its own spend?" / "Apple Card bill, 1,240.18. Log it as a spend?" | LOG · 64 ONLY / LOG · NOT NOW / LOG · NOT A SPEND | `money-us.md` M-US12, 14, 25 | no | ok | conflict (AQ4) | ok | ok |
| A10 | Money, open | "$12.99/mo" | "$12.99 a month, for what?" | none given | `money-us.md` M-US28 | no | ok | conflict (AQ4) | ok | **conflict** (AQ5) |
| A11 | Shop total | A shop ended (app raised), or a receipt photo | "Groceries total?" / "Costco, 212.37?" | a dial, no words | `money-us.md` lines 12, 23, M-US3; decision 19:07 | no | ok | ok, "no workout runs" | conflict (AQ6) | conflict (AQ5) |
| A12 | Habits check-in | Not given anywhere. RF18 says it is "skipped on a day that already has a reading record" | not given | not given | decision RF18; `habits.md:57` bans catch-up prompts | no | ? | ? | ? | ? (AQ7) |
| A13 | Radiators | First Upkeep open of a 04:00 day, Oct 1 to Nov 30 (first run: after Keep N or SKIP). Offered, never assumed: he may have none in the US Pacific | "Radiators to bleed this autumn?" | KEEP IT · NO RADIATORS | decisions 9:35 PM, 9:01 PM, 9:40 PM | no | ok | ok, page | **conflict** (AQ6) | conflict (AQ8) |
| A14 | Plan offer | Once per 04:00 day, 08:00 (or first open after) to 21:00, at least one task, never while a workout runs | Hero "Four hours free", key "START WITH REPLY TO LANDLORD" | not an ask: hold keeps, swipe left skips | `m4-steers.md:10-16`, `plan-home.md` | partly (PlanWording) | ok | ok | ok | conflict (AQ9) |
| A15 | Calendar | First open of Plan my day, calendar not decided | "Plan around your calendar? Times and titles only." | CONNECT · NOT NOW | `ask-lines.md` A3; decision 8:50 PM | no | ok | ok | ok | conflict (AQ9) |
| A16 | Groceries link (Claude) | Claude matches a row to a planned recipe | "Scallions, for the tacos?" (copy pass: "Scallions, for tacos?") | KEEP · NOT NOW | `groceries-tess.md:25-30`; `copy-one-voice.md:81` | no | ok | ok, "never in a workout" | conflict (AQ6) | ok, "one at a time" |
| A17 | Claude remember (miss) | Claude's `remember` tool on a missed phrase | ghost row, line not given | KEEP · NOT NOW | `tess-knows.md:74`; `ai/ship-list.md` AI-8 | no (`RememberFact` writes on apply) | ok | conflict (AQ10) | conflict (AQ6) | ok |
| A18 | Claude miss failures | A miss with Claude on: bad key, timeout with a guess, two matches | "That key didn't work. Paste it again?" / "Claude timed out. Call mom?" / "Not sure which bench. Flat or incline?" | none | `ClaudeKey.swift:319`; `claude-first-uses.md:41,51` | key line yes | ok | conflict (AQ11) | ok | ok |
| A19 | Weigh-in ghost | A bare 30 to 250 with nothing running | "82.4 kg as today's weight?" | LOG · NOT NOW | `one-ask.md` (Answering); `body-weight-page.md` | no | ok | ok, never shown | ok | ok |
| A20 | Focus halfway | Halfway through a focus block | "Still on the deck?" | Yes (ink) · Switch (vermilion) | `m4-steers.md:103` | no | ok | n/a | **conflict** (AQ12) | ok |
| A21 | Permission asks | First in-app finish; first training morning after W3; day 2 backup; W4 | "Save workouts to Apple Health? Heart rate too." / "Add last night's sleep from Health?" / "Keep copies in iCloud Drive too? They survive deleting the app." | SAVE · NOT NOW / the line is the tap / PICK A FOLDER · NOT NOW | `ask-lines.md` A1, A2, A9, A10; decision 5:56 PM | no | ok | ok, after finish | ok | conflict (AQ13) |

**Not asks** (lines with no ink words, by decision 8:58 PM): "Say the set, like 85 × 8.", "Say the set, like 80 × 8.",
"Skip is on the workout screen." (`TessGrammar+Live.swift:115-127`). The mic and camera lines (`ask-lines.md` A4, A6)
show while the system alert is up and are not Tess asks either.

**A1 is inside a workout, and that is allowed.** Q10 bans yes/no asks, not choices. A1 and A2 ask about the set
being logged, name both answers, and write nothing until one is picked. `one-ask.md` "In a live workout" lists
"10 × 8: 10 SETS · +10 KG" by name. So the rule reads: in a workout, only a choice or an open ask about the set
in focus; never a yes-or-later ask (LOG · NOT NOW), never an app ask.

## What the code does today (traced)
- **One at a time: holds in the engine.** `TessCaptureEngine.capture` clears `pendingAsk` and `pendingDatedLift`
  before it reads a new phrase (`TessCaptureEngine.swift:33-46`), so at most one is pending. The view holds two
  states (`setAsk`, `liftAsk`, `BottomChrome.swift:21,47`), both cleared on open (`:434-436`).
- **UNDO under an ask: happens.** `BottomChrome.swift:206-209` draws UNDO under whatever is in the slot,
  ask included. `canUndo` is `model.lastCapture != nil` (`:727-732`), live for 4 s after a capture dries
  (`AppModel.swift:270-275`). Two paths show it: (1) "80 for 8, 81" logs 80 × 8 and puts "81 for how many reps?"
  in the same line (`TessCaptureEngine.swift:176-178`), so the ask sits over that set's UNDO; (2) an A1 or A3 said
  within 4 s of a dried set shows over the old set's UNDO, and a tap undoes the old set.
- **Dated set in a workout: asks there.** `parseDatedLift` (`TessGrammar.swift:96`) has no check for an open
  workout, so "bench 80x8 mon" mid-workout shows LOG · NOT NOW in the live corner. Design wants it held to Today.
- **Leaving:** a tab change or the app going to the background does not fold `setAsk` or `liftAsk`. Only a new
  open, a new phrase or the workout ending (`:104-107`, set ask only) clears them.
- **Quiet hours:** no app ask is built, so none can fire at night today. No ask notifies.
- **UNDO length:** capture UNDO is 4 s in code; radiators 4 s; Tess-knows, Groceries KEEP and plan kept 10 s.
  `one-ask.md` says "waits for the UNDO to go (or for the 10s to end)".

## Conflicts

| # | Conflict | Proposed default | Owner |
|---|---|---|---|
| AQ1 | "Never in a workout" vs A1/A2 living in the workout | Not a conflict once worded: in a workout only a choice or open ask about the set in focus. Write that sentence into decisions next to Q10 | Product |
| AQ2 | UNDO shows under an ask (`BottomChrome.swift:206`), including the K874 "logs, then asks" line | The ask waits for the UNDO to go. For K874, Tess says the logged line with UNDO first, then the ask takes the slot when UNDO ends (4 s). A tap on UNDO while an ask waits drops the ask | Builder B (queue), Core (split the K874 line from its ask) |
| AQ3 | A3 asks LOG · NOT NOW mid-workout | Core holds a dated set said with a workout open and raises it on Today when the workout finishes (`one-ask.md`). Until then, a line: "Monday's set waits till after the workout." | Core |
| AQ4 | Money asks (A8 to A10) are yes-or-later; a money phrase can be said mid-workout | In a workout a money phrase gets no ask; it waits like A3 and asks on Today after the finish. "Exercise names and the live guard still win" (MU1) stays | Core, Product |
| AQ5 | "Always exactly two" ink words vs open asks with none (A10) and the shop-total dial (A11) | A10 offers two likeliest answers from his own spends, or NOT NOW plus one; A11's dial is the answer, with NOT NOW as the one word under it. Design to say if a dial counts as "two" | Design |
| AQ6 | App-raised asks at night: radiators on an Upkeep open at 23:30, Claude's Groceries link or remember arriving late, the shop total after a late shop | Every app ask is held 23:00 to 07:00 and comes back by its own rule. Product to say if Shutdown (21:00) also starts the hold; default no, quiet hours only | Product, Core |
| AQ7 | Habits check-in ask is named in RF18 but has no trigger, words or ink words anywhere; `habits.md:57` bans catch-up prompts | Strike it: habits come from logs and dab taps. RF18's "skipped on a day with a reading record" then has nothing to skip | Product |
| AQ8 | Radiators and the "one ask a day" budget (5:56 PM) | Radiators count as a one-time ask and yield to a permission ask that day; they come back the next day in the window | Product |
| AQ9 | Plan offer, the calendar ask and Claude's plan sentence all want Tess's band on the first plan | Calendar ask first, before any Claude call; Claude's sentence after it is answered. The plan offer is a Home state, outside the ask rules | Design, Builder B |
| AQ10 | A17 KEEP for a new record vs "every ask that writes a record uses LOG" | Keep KEEP here: the told fact is "kept" in Tess's voice ("Kept. You rest on Sundays."). Add it next to the radiators as the named exception. Never shown in a workout; the ghost waits on the page | Design |
| AQ11 | Claude failure lines end with "?" and no ink words; "Claude timed out. Call mom?" is a yes/no that could reach a workout | Lines that are not asks drop the "?": "That key didn't work. Paste it in Settings." A timeout guess becomes a ghost row or LOG · NOT NOW, outside a workout only | Research (copy), Design |
| AQ12 | A20 "Still on the deck?" uses Yes and a vermilion Switch, and can fire past 23:00 | Ink words in ink only, the doing word first: STILL ON IT · SWITCH. A block past 23:00 skips the halfway ask | Design |
| AQ13 | A21 Health sleep ask has one ink word ("the line is the tap") | Two words: ADD · NOT NOW | Design, Research |
| AQ14 | Leaving does not fold A1/A3 today (tab change, background) | Fold on leaving; write nothing; Tess says nothing (`one-ask.md` Leaving) | Builder B |
| AQ15 | UNDO lengths differ (4 s capture, 4 s radiators, 10 s elsewhere); the ask queue says "or 10s" | Queue waits for "the UNDO in the slot to go", whatever its length; no fixed 10 s | Design |
| AQ16 | A1's answers sit inside the line; `one-ask.md` moves them under it | Move them under, 2 SETS · 2 KG, to match every other ask | Builder A/B |
| AQ17 | Groceries wording: "Scallions, for the tacos?" vs copy pass "Scallions, for tacos?" | Use the row line's form, "Scallions, for tacos?" | Design |

**Top three.** AQ2 (UNDO under an ask, built today, and a tap can undo the wrong set). AQ3 (the dated set asks
yes-or-later mid-workout, built today). AQ6 (no quiet-hours hold is written for the app asks coming next).
