# Capture-miss route eval plan: phrases the grammar cannot read, sent whole to Claude

Research lab, Oct 17 2026. Written only: nothing here was run, no API call was made, no key was read, nothing was committed.
Subject: the route Kaushik chose with "All but the key" (his tap, Oct 17 2:32 AM PT; code in PR #860, commits `0b8459b` route and `1eb36a4` masks, docs `709773e`).
Code read: `origin/master` at `47365b0`. (Another session moved the shared working tree to a different branch while I worked, so every source file was re-checked against `origin/master`: `TesseraCore/Sources` and `docs/research/fixtures` are identical to it.)
Files read: `TessModel.swift` (`TessRouter`; there is no separate TessRouter file), `TessCaptureEngine.swift`, `TessModelCapture.swift`, `ClaudeTessModel.swift`, `TessInbox.swift`, `TessTools.swift`, `ClaudeKey.swift` (price table, ledger), `ClaudeKeyGuard.swift`, `PrivateFacts.swift`, `SecretWords.swift`, `EngineWall.swift`, `CaptureMissLog.swift`, `TessGrammar.swift` and `+Privacy`, `+Kitchen`; fixtures `capture-all-but-key.md`, `grammar-miss-claude.md`, `grammar-regression.md`, `grammar-regression-group-n.md`, `claude-facts-eval.md`, plus `suite-recount-oct-16.md` and `docs/ai/architecture.md` section 7.
Marks: **[T]** traced, read in code. **[I]** inferred, not read as one path.
No key, key prefix or key-looking text is in this file. Key shapes are described in words and built in the harness from two halves, as `capture-all-but-key.md` does.
No em-dashes. Clock for every row: Thu 15 Oct 2026 18:10 America/Los_Angeles (-07:00) unless the row says otherwise.

## 0. How the route works now (what every claim below rests on)

1. `TessRouter.run` [T, `TessModel.swift:86-123`]. First, a text that looks like a Claude key returns `TessRouter.keyLine` ("That looks like a Claude key. It goes in Review, under Claude.", source none) before any route and before any availability check. Then models run in order: grammar, on-device model (if available), Claude.
2. The only wall left on a capture is this skip [T]: Claude is skipped when the phrase is secret-worded or walled **and** the grammar already answered with a question or refusal (`asked?.source == .grammar`). A grammar `nil` (miss) is never a reason to skip Claude any more.
3. `GrammarTessModel` returns `.asked` only for a plain-line ask; set-count and dated-lift asks are `.handled` [T]. A grammar `.handled` ends the loop, so Claude never sees it.
4. `OnDeviceTessModel` is tried before Claude when Apple's model is available, and a capture that wrote records ends the loop [T]. In real use a phrase reaches Claude only if the on-device model also did nothing. The eval harness skips this step (section 3), so it measures Claude, not the share of phrases that arrive.
5. `ClaudeTessModel.isAvailable` [T]: capture use, key in Keychain, "Misses go to Claude" on, no "Not today" pause. `run` also returns `.missed` for a commit-immediately context (Siri, Shortcuts) and re-checks the key shape on the phrase and on the system prompt.
6. What Claude receives [T, `system()` and `send()`]: the phrase whole as the user turn, the house instructions with a "today is ..." line, the current exercise and last set (or "no workout in focus" if the exercise name is itself walled), and the 11 tool definitions (`logSet`, `createTask`, `completeTask`, `rescheduleTask`, `addGroceries`, `addToList`, `createList`, `createNote`, `createRecipe`, `answerQuery`, `startShop`). Model `claude-haiku-5-5`, `max_tokens` 512, up to 3 rounds, tool choice auto. No effort or thinking field is sent. The pack holds no open tasks, no cook state, no people, no notes, no body weight.
7. What comes back is written by the phone through the same typed actions, pending, as Tess, with at most 10 records per phrase [T]. Claude's task and note titles then pass `EngineWall` [T, doc comment and `task(...)`]: an amount is stripped from a to-do, a fact becomes a private note, a medicine becomes "Private task".
8. What is not spoken back [T, `1eb36a4`]: for a secret-worded or walled phrase, Claude's own line is dropped for the record receipt, and the one-time notice reads "Sent that to Claude. Turn this off in Settings: Claude." without the phrase. For an unwalled phrase the first notice quotes the phrase.
9. What is not stored [T]: a secret or walled phrase is not written to the miss log (`TessCaptureEngine.swift:59-61`) and not queued in the retry inbox (`TessInbox.add`, `readWaiting`). A key-shaped phrase is never logged anywhere. The ledger row (`tessCall`) holds tokens, cost, latency, outcome and request id, no text.

## 1. MISSES FIRST: 60 phrases that miss today and now go whole to Claude

### 1.0 Where the 60 come from

- Source: `grammar-regression.md` (900 to 913 rows, statuses at bases `1d0833c` to `7f1feb7`), corrected by `suite-recount-oct-16.md` (`0eca9bb`: 913 rows, 745 pass, 87 wrong write, 81 miss) and `grammar-regression-group-n.md`. Rows whose expected parse is "nil, the model reads it" and pass are also misses for routing, and are used for the money group.
- **Wrong-write rows cannot be in this list.** The grammar claims them and writes something (the 87 to 99 rows), so `GrammarTessModel` returns `.handled` and the router never reaches Claude [T]. They were scored on Claude only through the gate harness bypass (`grammar-miss-claude.md`, "Wrong-write rows reach Claude only in the eval"). I took 60 of the miss and nil-by-design rows instead.
- **Statuses are hand traces on older bases**, 50 or more grammar commits ago for some rows (the money-verb guard, `d8048c3`, `2655872` and the privacy follow-ups all landed after the recount). Stage 0 of the run plan re-confirms each row is still `nil` with a free local run before a cent is spent. Read "grammar today" below as "per the suite, to be reconfirmed".
- Groups by cause (suite root-cause codes in brackets): time forms RC11 (15), times that trip the money wall (4), relative times and reminder leads RELT/LEAD (5), reschedule shapes RC13 (9), set plus errand RC6 (4), "out of X" and bare groceries RC17/18/ADD (5), hyphenated exercise alias ALIAS (3), people plan PLAN (1), cook timers RC15 (6), money phrases the phone cannot place (8).

### 1.1 Pass bars used in the table

- **PB-TASK**: exactly one `createTask` (or `rescheduleTask` for a move), title is the said words minus the time and lead words, `startsAt` is the expected minute with the -07:00 offset (a day-only cell grades the day), nothing else written. The op is pending, actor tess, route claude, model `claude-haiku-5-5`. The phone-made ghost line passes `TessVoice.violations`. 3 of 3 runs.
- **PB-ASKOK**: as PB-TASK, but a no-write reply that asks for the missing fact also passes; a write on the wrong day or hour fails. Used where the capture pack does not carry what the answer needs (open tasks).
- **PB-MASK**: PB-TASK or the row's own bar, plus: the line shown is the phone's receipt, not Claude's words and not the phrase; no plain note or task holds the amount; the phrase is absent from the miss log.
- **PB-NOWRITE**: zero write calls in 3 of 3 runs. Any record is a failure.

### 1.2 Time forms the grammar cannot read (RC11, 15 rows)

All: grammar today `nil` (suite: `parseTask` does not read the form). Route now: Claude whole [T]. Not walled: no digit pair with two decimals, no secret word, no money or body word [T by reading the three checks].

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P01 | `call mom 7 pm` (A091) | createTask "Call mom", Thu 15 19:00 | PB-TASK; fail on 07:00 |
| P02 | `call mom half 7` (A092) | createTask "Call mom", Thu 15 19:30 | PB-TASK; fail on 07:30 or 06:30 |
| P03 | `call mom at half 7` (A093) | createTask "Call mom", Thu 15 19:30 | PB-TASK |
| P04 | `call mom 7.30pm` (C407) | createTask "Call mom", Thu 15 19:30 | PB-TASK; not walled [I: the "pm" strip leaves "7." so the two-decimal test does not fire] |
| P05 | `call mom half past 7` (C412) | createTask "Call mom", Thu 15 19:30 | PB-TASK |
| P06 | `call mom quarter past 7` (C413) | createTask "Call mom", Thu 15 19:15 | PB-TASK |
| P07 | `call mom half 6` (C414) | createTask "Call mom", Thu 15 18:30 | PB-TASK |
| P08 | `call mom half 5` (C415) | createTask "Call mom", Fri 16 17:30 (17:30 has passed, so tomorrow, C5) | PB-TASK; fail on a past time today |
| P09 | `call mom this evening` (C420) | createTask "Call mom", Thu 15 19:00 | PB-TASK |
| P10 | `gym in the morning` (C421) | createTask "Gym", Fri 16 09:00 | PB-TASK |
| P11 | `call mom at seven` (C426) | createTask "Call mom", Thu 15 19:00 | PB-TASK |
| P12 | `call mom this afternoon` (C434), clock 09:00 | createTask "Call mom", Thu 15 14:00 | PB-TASK |
| P13 | `call mom half 11` (C436), clock 23:30 | createTask "Call mom", Fri 16 11:30 | PB-TASK; fail on a time before the 4 AM day edge |
| P14 | `call mom midnight` (C439), clock 23:30 | createTask "Call mom", Fri 16 00:00 | PB-TASK |
| P15 | `move pay rent to sat morning` (C390), tasks store | rescheduleTask "Pay rent", Sat 17 09:00 | PB-ASKOK; "pay" and "rent" are money words but there is no amount, so not walled [T, W4 rule in `isMoneyShaped`] |

### 1.3 Times that trip the money wall (4 rows)

The two-decimal rule in `isMoneyShaped` ([T, last return line]: any word matching digits, a dot, two digits) reads a clock time like `7.30` as an amount. The grammar misses these today (RC11, and C410 is nil by design). Route now: walled but not grammar-asked, so Claude whole [T]; the miss log skips them; the notice and line are masked. This group shows what a wall false positive costs now.

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P16 | `dinner at 7.30` (A094) | createTask "Dinner", Thu 15 19:30 | PB-MASK; title must not carry "7.30" (a title with it would become a private note by `EngineWall` [T]) |
| P17 | `call mom at 7.30` (C409) | createTask "Call mom", Thu 15 19:30 | PB-MASK |
| P18 | `dentist at 4.15` (C411) | createTask "Dentist", Fri 16 16:15 (16:15 today has passed) | PB-MASK |
| P19 | `dinner 7.30` (C410) | createTask "Dinner", Thu 15 19:30; an ask is acceptable (suite: "a bare H.MM stays a number") | PB-MASK or PB-ASKOK |

### 1.4 Relative times and reminder leads (RELT, LEAD, 5 rows)

Grammar today `nil`. Route now: Claude whole [T], not walled.

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P20 | `call mom in 2 hours` (C422) | createTask "Call mom", Thu 15 20:10 | PB-TASK; the minute is computed from the "today is ..." line, which has no zone [T]; fail without the -07:00 offset |
| P21 | `call mom in 20 mins` (C423) | createTask "Call mom", Thu 15 18:30 | PB-TASK |
| P22 | `call mom in 2 hours` (C438), clock 23:30 | createTask "Call mom", Fri 16 01:30 | PB-TASK; open point: quiet hours (section 5) |
| P23 | `ping me in 5` (J742), Fri 17:40 | createTask "Reminder", Fri 16 17:45 | PB-TASK; "ping" must not appear in the title |
| P24 | `set a reminder for 6 to call mom` (J748), Fri 17:40 | createTask "Call mom", Fri 16 18:00 | PB-TASK |

### 1.5 Reschedule shapes (RC13, 9 rows)

Grammar today `nil` (the reschedule shape matched but no task resolved, or the shape is not read). Route now: Claude whole [T], not walled. The capture pack carries no open tasks [T], so Claude cannot know the task's own day or time; the phone resolves the name in `call.task(named:)` [I, not read further]. These rows test whether Claude asks or guesses.

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P25 | `move dentist to 7` (A127) | rescheduleTask "Dentist", Sat 17 07:00 (bare hour on its own day) | PB-ASKOK; a guessed 19:00 fails |
| P26 | `move dentist to 3` (C374) | rescheduleTask "Dentist", Sat 17 15:00 | PB-ASKOK |
| P27 | `move haircut to 7` (C380) | rescheduleTask "Haircut", Thu 15 19:00 | PB-ASKOK |
| P28 | `push dentist to next week` (C388) | rescheduleTask "Dentist", Sat 24 10:00 | PB-ASKOK |
| P29 | `push dentist to later` (C391) | reschedule to Later with no date | PB-NOWRITE: `rescheduleTask.startsAt` is required, so no tool can express Later [T]; any invented date fails |
| P30 | `can you move the dentist to friday` (C395) | rescheduleTask "Dentist", Fri 16 10:00 | PB-ASKOK |
| P31 | `move dentist to fri please` (C396) | rescheduleTask "Dentist", Fri 16 10:00 | PB-ASKOK; "please" not in a title |
| P32 | `move bins out to 11` (C404), clock 23:30 | rescheduleTask "Bins out", Fri 16 11:00 | PB-ASKOK |
| P33 | `move the call mom reminder to 7` (J768), Fri 17:40, alert on | rescheduleTask "Call mom", Fri 16 19:00, alert kept | PB-ASKOK |

### 1.6 A set plus an errand in one phrase (RC6, 4 rows)

Grammar today: `nil` for the errand part with no day (suite and recount). Route now: Claude whole [T], not walled (set notation is stripped before the money and body tests [T]).

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P34 | `get protein and do legs` (A060) | addGroceries ["protein"]; createTask "Do legs" Later accepted | no logSet, nothing on Groceries named legs; 2 writes at most |
| P35 | `bench 80x8 then call mom` (A160) | logSet Bench Press 80 x 8 x 1 kg, createTask "Call mom" Later | exactly those 2 writes; "bench" not in the task title |
| P36 | `bench 80x8, call mom` (A161) | as P35 | as P35 |
| P37 | `80x8 then call mom` (A168), workout in focus | logSet Bench Press 80 x 8 (pack names the current exercise [T]), createTask "Call mom" Later | as P35; no second Bench entry is a separate known gap (gate hook 2) |

### 1.7 "Out of X" and bare groceries (RC17, RC18, ADD, 5 rows)

Grammar today `nil`. Route now: Claude whole [T], not walled.

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P38 | `out of milk` (A271) | addGroceries ["milk"] | exactly one addGroceries; no task |
| P39 | `need eggs` (A272) | addGroceries ["eggs"] | as P38 |
| P40 | `we're out of coffee` (A273) | addGroceries ["coffee"] | as P38 |
| P41 | `3 lemons` (A276), workout in focus | addGroceries ["3 lemons"], never a set | no logSet (3 reps is the trap; the pack names Bench Press [T]) |
| P42 | `Add 2 tins of chickpeas` (B334), cook running | addGroceries ["2 tins of chickpeas"] | as P38; Claude has no cook context [T] |

### 1.8 Hyphenated exercise alias (ALIAS, 3 rows)

Grammar today `nil` (`resolveExercise` drops the hyphen, TG:424-457 per the recount). Route now: Claude whole [T].

| ID | Phrase (suite row) | Ideal result | Pass bar |
|---|---|---|---|
| P43 | `pull-ups 8` (K907), workout in focus, bodyweight lift | logSet Pull-Up, weight 0, reps 8, sets 1 | one logSet; the exercise name must be one the phone resolves, else the tool errors and nothing is written [T]; weight must not be 8 |
| P44 | `pull-ups 3x8` (K976) | logSet Pull-Up, weight 0, reps 8, sets 3 | one logSet, sets 3 reps 8 (fail on 3 kg or 24 reps) |
| P45 | `chin-ups 3x8` (K977) | logSet Chin-Up, weight 0, reps 8, sets 3 | as P44, or no write if the phone has no Chin-Up [I: catalog not read] |

### 1.9 People plan (PLAN, 1 row)

| ID | Phrase (suite row) | Grammar today | Route now | Ideal result | Pass bar |
|---|---|---|---|---|---|
| P46 | `lunch with ravi` (F531), people store | `nil`: no day and no lead, so `parseTask` returns nil (suite note at `1183d35`) | Claude whole [T]; "ravi" is a name, not a wall word | createTask "Lunch with ravi" Later, about Ravi, no question | PB-TASK with `startsAt` null; "planning or done?" ask fails (P800) |

### 1.10 Cook timers (RC15, 6 rows): no tool exists

Grammar today `nil` outside a recognised timer shape (suite: cook timers need the word "timer"). Route now: Claude whole [T]. Claude has no timer, stop or cook-step tool [T, the 11 tools], and the pack says nothing of the cook [T]. `docs/ai/architecture.md` section 7 says cook timers never leave the phone, but no cook wall exists in the route code [T, `grep cook` in `TessModel.swift` and `ClaudeTessModel.swift` finds nothing]. The honest ideal is "stays local"; these rows measure what a wasted send does.

| ID | Phrase (suite row), cook 18:00 | Ideal result | Pass bar |
|---|---|---|---|
| P47 | `8 mins` (A189) | timer "Simmer" 8, linked (on the phone, not Claude) | PB-NOWRITE; any task or note fails (N2, N4) |
| P48 | `pasta 10` (A190) | timer "Pasta" 10 | PB-NOWRITE |
| P49 | `finished cooking` (A191) | FinishCooking | PB-NOWRITE |
| P50 | `how long left` (D461) | read-only timer answer | PB-NOWRITE |
| P51 | `stop the rice` (D457) | StopKitchenTimer(Rice) | PB-NOWRITE |
| P52 | `step 3` (D467) | GoToCookStep(2) | PB-NOWRITE; a task "Step 3" fails |

### 1.11 Money phrases the phone cannot place (8 rows)

These are where the decision bites. Grammar today `nil`: Money is not built, and a spend phrase with no day falls to the miss line (TG:133-141: `isMoney` plus a spend verb returns `parsePrivateLog`, which is nil without a past day [T]). Route now for P53 to P59: walled by money [T], not grammar-asked, so Claude whole [T]. The miss log skips them [T]. Output side: `EngineWall` makes any note or task Claude writes with the amount a private note [T, doc comment; `task(...)` read], and the line shown is the masked receipt [T].

Ideal for all: Money is not built, so the phone has nothing right to write. Acceptable: one `createNote`, which the phone stores as a private note, or no write. Not acceptable: a task, a grocery line, a list item, any plain-looking object carrying the amount.

| ID | Phrase (suite row) | Walled | Pass bar |
|---|---|---|---|
| P53 | `refund 12.40 amazon` (H632) | yes (refund plus amount, two decimals) [T] | PB-MASK; at most 1 write, createNote only |
| P54 | `12.40 refund from amazon` (H633) | yes [T] | as P53 |
| P55 | `spent 12.40 lunch and 3 coffee` (H635) | yes [T] | as P53 |
| P56 | `lunch with sam was 23 quid` (H607), people store | yes (amount plus "quid") [T]; the fixture note "people must not bind" applies | as P53; no link to a person named Sam |
| P57 | `paid will back 15` (E506), people store | yes (paid plus amount) [T] | as P53; "will" not read as the word or a person |
| P58 | `Lunch was £10` (B350) | yes (currency sign) [T] | as P53 |
| P59 | `spent 20 chf taxi` (H604) | yes (spend verb plus amount) [T] | as P53 |
| P60 | `Eleven stone four` (B319) | **no**: a body weight said in words has no digit, so `isBodyShaped` needs-a-number test does not fire [T] | PB-NOWRITE or one createNote; shows a body fact outside the wall reaching Claude with its words quoted in the first notice [T] |

Count check: 15 + 4 + 5 + 9 + 4 + 5 + 3 + 1 + 6 + 8 = 60.

Body and health phrases are not in this list on purpose. The grammar's `parseBodyFact` claims any body-shaped phrase that is not "something to do" as a private note before the miss path [T, `TessGrammar.swift:150-157`], so a body fact almost never misses; the tests that cover it ("182.4 lb this morning", "slept 5 hours", "took 2 advil") are grammar-claimed and stay on the phone [T, `PrivacyFollowupTests`]. P60 is the one spelled-out case I found. Hunting for more is a Stage 0 task.

## 2. Twenty phrases that must NOT go to Claude

Each row is a request that must build zero Claude requests (N16 and N17 build one and fail at transport, noted). Key text is built from two halves in the harness and never written here.

| ID | Case | Exact local outcome |
|---|---|---|
| N01 | The key prefix followed by 40 filler characters, nothing else | `TessRouter.keyLine`: "That looks like a Claude key. It goes in Review, under Claude.", source none, no records. No route's `run` is called. Not in the miss log [T: `TessModel.swift` first guard; `TessCaptureEngine.swift:59` and `CaptureMissLog.record` both check] |
| N02 | The same, upper-cased | Same line [T: the key regex is case-insensitive] |
| N03 | "my key is " plus a key plus " thanks" | Same line [T: first match anywhere in the text] |
| N04 | "call mom", a line break, then a key | Same line [T: no anchors; whitespace is matched] |
| N05 | The prefix with spaces around each dash | Same line [T: `\s*` around the dashes in `keyPrefix`] |
| N06 | The prefix with its last dash missing, a digit following within eight letters | Same line [T: the lookahead branch of `keyPrefix`] |
| N07 | The prefix with a typographic dash (U+2010 to U+2014 or the minus sign) | Same line [T: the dash class in `keyPrefix`] |
| N08 | A key typed with "Misses go to Claude" off and no key saved | Same line, not "Didn't catch that." [T: the key guard runs before any `isAvailable`] |
| N09 | `wifi password is tacocat` (placeholder value) | Grammar `parseSecret` makes a private note: "Private note, kept.", source grammar, one pending record. The loop ends on `.handled`, so Claude is never asked [T: `parseSecret` runs first in `parse`; `TessCaptureEngine.swift:341`] |
| N10 | `my pin is 4417` | As N09 [T] |
| N11 | `note: gym locker combo 4417` | As N09, never a plain note [T] |
| N12 | `remember the wifi password is hunter2` | Private note, remembered: "Private note, kept. I don't keep passwords." [T, `TessCaptureEngine.swift:341`] |
| N13 | `what's the wifi password?` | Grammar ask "It's in your private notes.", nothing written, source grammar [T, `parseSecret` question branch] |
| N14 | `remember my rent is 2100` | Grammar ask "I don't keep sums of money.", nothing written. Walled and grammar-asked, so Claude is skipped by the router condition [T: `parseRememberedMoney`; router skip] |
| N15 | `password reset email friday` | Grammar task "Password reset email", Fri 16, no time. A secret word with no value and a task shape stays a task, on the phone [T: `parseSecret` hands to `parseTask`] |
| N16 | A Siri or Shortcuts capture that the grammar misses (`commitImmediately` true), e.g. `call mom half 7` | Claude's `run` returns `.missed` before any request is built; the router ends with "Didn't catch that." [T, first guard in `run`] |
| N17 | A normal miss (`call mom half 7`) with the phone offline | One request is attempted and fails at transport. Outcome `offline` is written to the ledger (zero tokens), the phrase goes to the retry inbox, and the line is "No connection. Saved it for Claude." with no records [T: `Failure.offline`, `TessInbox.add`] |
| N18 | A walled miss (`spent 12.40 lunch`) offline | The inbox refuses a walled phrase, so the line is "No connection, so Claude didn't see that." Nothing queued, nothing logged [T: `TessInbox.add` guards; fall-through to `failure.line`] |
| N19 | Any miss with "Misses go to Claude" off, or no key saved, or "Not today" on | `isAvailable` is false, the router skips Claude, no request. Line "Didn't catch that." with " Try “80 × 8”." in a workout or " Try “milk, eggs”." on a groceries run; source none. An unwalled phrase is logged to the miss log, a walled one is not [T] |
| N20 | A miss when the month is at the $50 cap | `ledger.reserve` returns nil, no request. `.asked`: "Claude paused until Nov 1." (the end of the phone's calendar month, month and day in abbreviated form), no records [T: `ClaudeTessModel.swift:62-67`; the date text itself is [I], I did not run the formatter] |

A bad or revoked key is not on this list: that case sends one request and gets the line "Claude didn't take the key. Check it in Settings: Claude." from a 401 or 403 [T]. See section 5 for the "spent-key" wording.

## 3. Run plan

**Nothing runs without Kaushik's own yes in the running thread.** Not Stage 0 builds with a key, not Stage 1, not Stage 2. A yes to one stage is not a yes to the next. The runner is `--dry` by default and must refuse to read a key without an explicit live flag, as `plan_my_day_eval.py` and `claude_facts_eval.py` do.

### Prices and model [T]

`TessUsageLedger.prices` (`ClaudeKey.swift:93`), nano-dollars per token: `claude-haiku-5-5` input 100, output 500, cache read 10, cache write 125 (so $0.10 and $0.50 per million tokens); `claude-sonnet-5-5` 2000, 10000, 200, 2500. Capture uses `claude-haiku-5-5` (`ClaudeTessModel.model`). The cap is `capNano` = 50,000,000,000 n$, $50 a month, resetting on the 1st in the phone's calendar.

### Cost per call [T for the formula, I for the size]

The ledger's pre-call reservation is `((bytes / 4) + 10) * 100 + 512 * 500` n$ per round, times 3 rounds. The request is the system prompt (about 1,000 bytes), 11 strict tool definitions (about 4,000 to 5,000 bytes, I did not measure) and the phrase, so about 1,500 input tokens: 150,000 n$ in and 256,000 n$ of reserved output per round, about 406,000 n$ a round, **about $0.0012 reserved per call** (3 rounds). A typical call is two rounds (tool use, then a one-line reply) at about 150 output tokens: **about $0.0006**, the figure `grammar-miss-claude.md` gave for the same pack. Real usage is read from the response, so Stage 1 reports it.

### Stages

| Stage | What | Key | Calls | Typical | Worst (reserved) |
|---|---|---|---|---|---|
| 0, free | A Swift Testing suite on Mac with the stub transport (`RouteStub`) and spy models. (a) Run the grammar on all 80 phrases and assert the 60 return nil and the 20 produce the section 2 outcomes. (b) Run the 80 through `TessRouter`: each of the 60 reaches the Claude spy once with the exact text; each negative reaches it zero times; no request body or system prompt holds key-shaped text; no walled phrase appears in the miss log, the inbox, the notice or the line. (c) Build every request body with `--dry` and check size and fields. (d) Hunt for more body-fact misses. | none | 0 | $0 | $0 |
| 1, paid | Python harness in `scripts/ai/` in the house shape (`--dry` default, `--live` to send, `--runs` capped at 3, key from the environment only, host `api.anthropic.com` only, redirects refused, no retries, results appended to `docs/ai/` with the usual header, $1 stop before each call). Sends the 60 positives, 3 runs each, with the **production request shape**: no effort field, as `send()` builds it [T]. Negatives are asserted at zero requests. | his key | 180 | $0.11 | $0.22 |
| 2, paid, optional | Real route on the simulator with his key: 12 phrases (P01, P08, P20, P25, P29, P35, P38, P43, P47, P53, P56, P60), once each, to see the real ghost rows, the masked receipts, the ledger rows and an empty miss log for walled phrases. Also N17 to N20 by hand (airplane mode, switch off, cap forced in a test store). | his key | 12 | $0.01 | $0.02 |
| **Total** | | | **192** | **about $0.12** | **about $0.24** |

Against the $50 monthly in-app cap that is 0.5 percent at worst. Stage 1 runs outside the app, so it does not appear in the in-app ledger but is real spend on his key; Stage 2 does appear, as 12 `tessCall` rows. The harness stop is $1, four times the worst case.

### Pass bar

- **Positives (Stage 1).** At least 54 of 60 rows (90 percent) pass their bar in 3 of 3 runs. Zero must-not hits in all 180 calls: a write on a no-write row; a wrong tool, target or extra call; a time without the offset or in UTC; a day off by the 4 AM rule or by "a passed time today lands tomorrow"; a set or errand mixed up; a line that claims an action no tool did.
- **Walled rows (P16 to P19, P53 to P59).** 3 of 3 each. No plain task, list item or grocery line carries an amount; the line shown is never Claude's words and never the phrase.
- **Cook rows (P47 to P52).** 0 writes in 18 calls. A pass here means "wasted money, no harm"; the recommendation is a local stop (section 4, risk 6).
- **Pack rows that need open tasks (P25 to P28, P30 to P33).** Pass on exact or on a sound ask; report the ask rate separately.
- **Negatives (Stage 0 and 2).** 20 of 20 produce the exact outcome in section 2 with zero Claude requests (N17 and N18: one attempted request, zero tokens).
- **Kaushik's read.** On the Stage 2 ghost rows he finds none he would take back.

## 4. Risks in the route itself

1. **Money, body, health and secret words now reach Claude whole when the grammar misses.** That is the decision, so it is not a defect, but the walls that remain are narrow: the key (router and Claude route, both [T]); a walled phrase the grammar already asked about; Siri and Shortcuts; the pack's content (no notes, body weight, people, tasks or money [T]); the exercise name if walled [T]. Nothing else stops a phrase.
2. **The wall flag now only controls local display, and it is wrong both ways.** False positives: a clock time written `7.30` or `4.15` is "money" (P16 to P19), so a harmless task gets a masked line, no miss log entry and, if Claude puts the time in the title, a private note [T]. False negatives: a fact the wall does not see is quoted back raw in the first notice (P60, "Eleven stone four"; also `12 50 at tesco` and `lunch was a tenner`, which have no digit pair with two decimals and no amount beside a money word [I from the regexes]). The first notice of the app's life quotes the phrase [T].
3. **Secret words are almost always claimed first, which is the safe part.** `parseSecret` runs first and turns any secret-worded phrase into a private note or a task, so a secret value does not miss [T]. The exception is a line that starts "buy", "get", "grab", "pick up" or "add" with a secret word and no value: it returns nil there and can now reach Claude if nothing else reads it (for example "get the garage code from dad"). I traced `parseSecret` for it but not what the rest of the grammar does next [I]. A secret value without a secret word ("alarm 9981") has no wall at all.
4. **Key-shaped text is caught by one regex.** It handles case, spaces around the dashes, a missing last dash and typographic dashes [T]. It cannot catch a key read out by voice letter by letter, a key with its prefix split across two lines inside the letters, or a key pasted without its prefix [I]. The harness should add those as boundary rows (report, not necessarily fix).
5. **Claude's writes are walled on the output side, but the title is Claude's.** `EngineWall` strips amounts from a to-do and turns facts into private notes [T], so a task "Pay rent 1850" lands as "Pay rent". It does not stop a groceries line or a list item carrying a number; whether `AddGroceries` and `AddToList` run the price wall for a Claude write is written in comments only [T for the comment, not run].
6. **Cook-timer phrases leave the phone although the docs say they never do.** `architecture.md` section 7 lists cook timers under "never leaves the phone"; the route has no cook check [T]. Claude has no timer tool, so each send is wasted money and can only produce a wrong write (P47 to P52). A cheap local stop when a cook process is running is the fix.
7. **Pack gaps make some rows unanswerable.** The capture pack has no open tasks, so a reschedule to "7" cannot know the task's day (P25 to P33). The gate design (`grammar-miss-claude.md` section 1) added "pack adds" fields; production did not [T, `system()`]. Rows will mostly be asks or guesses until the pack carries the named task.
8. **Date handling relies on the prompt's "today is ..." line, which has no zone** [T, `TessModelCapture.today`]. The tool schema asks for ISO 8601, and a time with no zone is read in his calendar [T, comment in `Call`], so an offset-less answer is survivable, but a wrong offset is not caught. The fixture's earlier gate named a date-parser hook for this (hook 3); I did not check whether it landed.
9. **The eval harness and production differ.** The older harness sends `effort: low` and goes straight to the Claude route [fixtures]; production sends no effort field and goes through the on-device model first [T]. Stage 1 must use the production shape, and its result is "how well Claude reads a miss", not "how many misses reach Claude".
10. **Retry inbox is the one place that still keeps walls**, so an offline walled phrase is dropped with a line instead of waiting [T]. That is the safe choice, but the user loses the phrase; the line says so.
11. **Docs contradict the code.** `architecture.md` section 7 has both the new "capture misses carry everything but the key" bullet and the old "a money-shaped capture never reaches `ClaudeTessModel`" bullet, and the Settings promise ("Titles and counts only. Never notes, places, health or money.") is still the copy. Also `capture-all-but-key.md` section 3 says KS06 and KS07 (spaced and dash-less prefix) are not caught; the code now catches both [T, `ClaudeKeyGuard.swift:16`]. The fixture is stale there.
12. **Cost is bounded but not by phrase length.** The cap, the reservation and 3 rounds limit spend [T]; a long pasted capture raises the input estimate and could be refused at reserve near the cap. No phrase length limit was found on this path [I].
13. **A model line can still be spoken for an unwalled phrase.** Claude's one-liner is used if it passes `TessVoice.violations` [T]; it is not checked for facts not in the pack (the gate's N6 rule). It is dropped only for a walled phrase.

## 5. What I could not trace

- **Today's grammar result for each of the 60 rows.** There is no Swift toolchain here. Statuses come from suite hand traces at older bases; some rows may now be claimed (the money-verb and privacy commits came after the recount). Stage 0 (a) settles it.
- **Whether the on-device model is available on his phone** and what it does with these phrases. If it writes a record, Claude is never asked (section 0, item 4).
- **Actual token counts.** The tool JSON size is an estimate; the typical $0.0006 is the earlier gate's figure for the same pack. Whether Haiku 5.5 emits thinking tokens with no thinking field sent is not known from code (a comment at `reserve` says it may).
- **What "spent-key line" means in the request.** I read it as the line for a key typed into the Ask bar (N01 to N08, the key line). If you meant a saved key that was rejected or an account that has run out, the lines are "Claude didn't take the key. Check it in Settings: Claude." (401 and 403) and "Claude is busy right now." (429 and 5xx) [T]; both cost one request, so they are not on the zero-request list.
- **Quiet hours on a Claude-written time.** Commit `55bc156` moves a time Tess picks out of 23:00 to 07:00 but keeps a time he says. I did not trace whether a Claude `createTask` for "in 2 hours" at 23:30 (P22) is moved. The ideal in P22 is the fixture's 01:30.
- **The date text "Nov 1" in N20.** The format string is `.dateTime.month(.abbreviated).day()`; I did not run it.
- **`resolveExercise` for "Pull-Up" and "Chin-Up"**, and `call.task(named:)` for "dentist": not read. P43 to P45 and P25 to P33 depend on them.
- **Whether `AddGroceries` and `AddToList` apply a price wall to a Claude write**, and whether the engine accepts a date-only task (N1) for rows that expect "no time".
- **What the op log stores for a Claude-handled walled capture** (the phrase as the capture's source text goes into backups; `architecture.md` F2 mentions the capture op carries the words). Not traced.
- **The "What was sent" screen** that `architecture.md` says stays: I found no code for it (`grep` for the name and for "Last sent" finds nothing), so I cannot say whether a walled phrase would show there.
- **Siri's own path.** N16 covers the Claude route's guard only; the Siri parity tests were read by title, not run.
