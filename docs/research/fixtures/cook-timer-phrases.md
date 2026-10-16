# Cook timer phrases: what he says at the stove

For: Core, grammar batch, RC15 (cook timers). Board item 18. Research lab. Date: 2026-10-15.

**Master read:** `origin/master` at `6cc61ec5d7f29c90336778a5347c6ce2c3decb14` (merge of PR #150). The grammar files last changed in `ae0d936` (Grammar hotfix, QA on #115). This is a static read: there is no Swift toolchain here, so every "master" cell is traced by hand. Nothing was run.

## Files read

- `TesseraCore/Sources/TesseraTess/TessGrammar.swift` ("G:"): parse order, question guard (G:62, leads at G:97), the cook branch of the process rule (G:109-112), relative sets (G:163, full shape G:178), lifts (G:235, guard G:245), tasks (G:352), `TessDates` (time words G:420, passed-time roll G:431, `parseTime` G:465).
- `TesseraCore/Sources/TesseraTess/TessGrammar+Kitchen.swift` ("K:"): the `remind` stop (K:33), the timer call behind `!hasDate` (K:36), `parseTimer` (K:74-92), `parseCook` (K:96), `hasDate` (K:160).
- `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift` ("E:"): the timer line and cook link (E:142-147), step and finish lines (E:158-167), the error line.
- `TessModel.swift`, `TessModelCapture.swift`, `TessTools.swift`: a nil parse goes to the on-device model; with no model the router says `Didn't catch that. Try "bench 80 x 8".` The model has no timer tool (Product 19:12: "Tick-off, timers and open-list stay without a tool"), and its instructions carry no timer state.
- `TesseraCore/Sources/TesseraCore/Kitchen/Cooking.swift`: `StartKitchenTimer` (1 to 1440 min), `StopKitchenTimer`, `FinishCooking` (stops every timer linked to the cook), `CookLog.finishLine`.
- `docs/product/cook-mode-acceptance.md` and `docs/product/cook-mode-script.md` (same on master and in `product/`), `docs/research/fixtures/cook-mode-scenarios.md`, `research/fixtures/grammar-misfires.md` (rows 186 to 195, RC15), `research/fixtures/m5-parse-order.md`, `research/fixtures/spoken-normaliser.md`, `product/decisions.md` (4:10 PM parse order, 4:26 PM grammar calls and later), `product/kitchen-phrases.md`.

**Builder A's cook mode screen is not on master.** There is no CookMode view, no `CookTimerAttributes`, no pause or extend action. `RecipePage.swift:13` still says "Until cook mode (screen 12) lands, the page starts the cook itself". The only cook code is the engine in `Kitchen/Cooking.swift` and the grammar above. So every row here is about what the Tess bar does during a cook, which is the only spoken or typed path today.

## Setup

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London, as in the other grammar fixtures.

**Recipe.** Weeknight dal (the `-demoKitchen` seed text): 3 steps. Step 1 "Soften the onion, garlic and ginger for 8 minutes." Step 2 "Add the lentils ... simmer for 20-25 minutes." Step 3 "Stir in the coconut milk ...".

**Modes.**
- **C** (cook running): Weeknight dal is the running process (`context.process` is the Cook), on step 2 (resume index 1). No entry in focus. Two timers run, both linked to the cook: **Rice** (started 17:58, ends 18:10, 10 min left) and **Simmer** (started 18:00, ends 18:20, 20 min left).
- **C+F**: C, plus **Soften** (8 min, ended 17:59:30, not stopped, so it is flared).
- **C3**: C, but on step 3, the last step.
- **I** (no cook): nothing running.
- **W** (workout): the workout is the running process; Bench Press is the entry in focus with 3 sets, the last 80 x 8.

**Spoken rows.** There is no spoken normaliser on master (`spoken-normaliser.md` is still a spec), so a spoken row is the dictation text exactly as it arrives. iOS dictation usually writes durations as digits ("Pasta 9 minutes"); small counts can arrive as words ("Two minutes").

**Verdicts.**
- **OK**: master does the expected thing, or hands to the model when nothing should be written.
- **MISS**: master writes nothing and hands to the model, but this is a timer, stop, extend or finish phrase. The model has no timer tool, so it can only answer in words or misuse a task, note or grocery tool. With no model he sees `Didn't catch that. Try "bench 80 x 8".`, a lift hint at the stove.
- **WRONG WRITE**: master writes the wrong thing, or the right object with a wrong field.

**Tess lines.** Master's timer line is `"\(label), \(TessVoice.number(minutes)) min."` (E:147). The expected lines keep that shape. Other copy comes from the acceptance doc ("Stopped simmer.", 7b) and the scenarios (ASSUMED-6 "Rice, paused at 10 min"). Minutes left round up, as in the scenarios (6.5 shows as 7).

## Phrase rows

The Rule column names a rule from the next section. Flagged rows are bold in the Verdict column.

| # | Phrase | Said | Mode | Master parse today | Expected parse or action | Exact Tess line (expected) | Verdict | Rule |
|---|---|---|---|---|---|---|---|---|
| 1 | pasta 9 minutes | spoken | C | No "timer" word, so `parseTimer` never runs (K:36, K:75). Lift: weight 9, no reps (G:245). Model | `.timer("Pasta", 9)`, linked to the cook | Pasta, 9 min. | **MISS** | T2 |
| 2 | 9 min | typed | C | Same as row 1 (misfires row 189). Model | `.timer("Timer", 9)`, linked | Timer, 9 min. | **MISS** | T1 |
| 3 | pasta 10 | typed | C | Model (misfires row 190) | `.timer("Pasta", 10)`, linked | Pasta, 10 min. | **MISS** | T3 |
| 4 | eggs 6 | spoken | C | Lift: weight 6, no reps. Model | `.timer("Eggs", 6)`, linked | Eggs, 6 min. | **MISS** | T3 |
| 5 | pasta for 9 minutes | spoken | C | Lift skips `for`, no reps. Model | `.timer("Pasta", 9)`, linked | Pasta, 9 min. | **MISS** | T2 |
| 6 | 9 minutes on the pasta | spoken | C | Model | `.timer("Pasta", 9)`, linked | Pasta, 9 min. | **MISS** | T2 |
| 7 | oven 25 | typed | C | Model | `.timer("Oven", 25)`, linked | Oven, 25 min. | **MISS** | T3 |
| 8 | timer for the oven 25 | spoken | C | `.timer("The oven", 25)`: `parseTimer` strips `for`, `a`, `of`, `set` but not `the` (K:88-90). Linked to the cook | `.timer("Oven", 25)`, linked | Oven, 25 min. (master says "The oven, 25 min.") | **WRONG WRITE** (label) | T6 |
| 9 | oven 180 for 25 minutes | spoken | C | Lift reads weight 180, reps 25, words "oven minutes"; no exercise resolves, so nil. Model | `.timer("Oven", 25)`, linked; 180 is the temperature and is dropped | Oven, 25 min. | **MISS** | T4 |
| 10 | lamb 1 hour | spoken | C | Lift: weight 1, no reps. Model | `.timer("Lamb", 60)`, linked | Lamb, 60 min. | **MISS** | T2 |
| 11 | timer 1 hour 30 | spoken | C | `parseTimer` takes the first number and unit only: "1 hour" is 60 min, and the leftover "30" becomes the label. `.timer("30", 60)` | `.timer("Timer", 90)`, linked | Timer, 90 min. (master says "30, 60 min.") | **WRONG WRITE** (label and length) | T6 |
| 12 | timer 2:30 | typed | C | `hasDate` sees "2:30" as a clock time (G:420), so the timer branch is skipped (K:36). The time has passed today, so it rolls to tomorrow (G:431). `parseTask`: task "Timer", Fri 02:30 | `.timer("Timer", 2.5)`, linked; `M:SS` after `timer` is a length | Timer, 2.5 min. (master says "Timer, tomorrow 2:30 am.") | **WRONG WRITE** (task) | T6 |
| 13 | simmer 20-25 | typed | C | "20-25" is not a number to the lift. Model | `.timer("Simmer", 20)`, linked; a range takes its lower bound (ASSUMED-2) | Simmer, 20 min. | **MISS** | T5 |
| 14 | two minutes | spoken | C | No digits anywhere. Model | After the normaliser's number words (step 7): `.timer("Timer", 2)`, linked | Timer, 2 min. | **MISS** | T1 |
| 15 | set a timer for 5 minutes | spoken | C | `.timer("Timer", 5)`: `set`, `a`, `for` all stripped. Linked | Same | Timer, 5 min. | OK | T6 (guard) |
| 16 | another 2 | spoken | C+F | Lift: weight 2, no reps. Model | Extend Soften (the flared one) by 2 min from now: ends 18:02 | Soften, 2 more min. | **MISS** | X1, X2 |
| 17 | add 30 seconds | spoken | C | Lift skips `add`, no reps. `add to groceries` needs those words (K:40). Model | Extend Rice (no flared timer, so the soonest) by 0.5 min: ends 18:10:30 | Rice, 30 more sec. | **MISS** | X1, X2 |
| 18 | add 2 minutes to the rice | spoken | C | Model | Extend Rice by 2 min: ends 18:12 | Rice, 2 more min. | **MISS** | X1 |
| 19 | stop the rice | spoken | C | No grammar for stop. Model | `StopKitchenTimer(Rice)` | Stopped rice. | **MISS** | S1 |
| 20 | cancel the simmer timer | spoken | C | Has "timer" but no number, so `parseTimer` returns nil. Model | `StopKitchenTimer(Simmer)` | Stopped simmer. | **MISS** | S1 |
| 21 | stop | spoken | C+F | Model | `StopKitchenTimer(Soften)`: the flared timer | Stopped soften. | **MISS** | S2 |
| 22 | stop timer | typed | C | Model | `StopKitchenTimer(Rice)`: none flared, so the soonest; the ghost row names it, Undo brings it back | Stopped rice. | **MISS** | S2 |
| 23 | how long left | spoken | C | Question guard (G:62, "how"). Model, which cannot see timers | Read-only answer, no write | Rice, 10 min left. Simmer, 20 min left. | **MISS** (no answer) | Q1 |
| 24 | is the rice done | spoken | C | "is" is not a lead word (G:97). No rule binds. Model, which has write tools and no timer state | Read-only answer, no write (4:26 PM call 4: "is" phrases are questions) | Rice, 10 min left. | **MISS** (the model could write) | Q1 |
| 25 | pause | spoken | C | Model | 12b: pause the soonest running timer (Rice). Before 12b: no write | 12b: Rice, paused at 10 min. Before 12b: Pause isn't here yet. Stop or add time. | **MISS** (12b) | P1 |
| 26 | remind me in 20 minutes to take the chicken out | spoken | C | Kitchen stops on `remind` (K:33). `parseTask`: explicit, drops "remind me", "in" is not "to", no date: task "In 20 minutes to take the chicken out", Later | `.timer("Take the chicken out", 20)`, linked | Take the chicken out, 20 min. (master says "In 20 minutes to take the chicken out, in Later.") | **WRONG WRITE** (task) | R1 |
| 27 | done | spoken | C+F | Cook step word (G:110): `FinishCooking`. The cook ends on step 2 of 3 and all three timers stop | `StopKitchenTimer(Soften)`; the cook keeps going | Stopped soften. (master says "Weeknight dal, done.") | **WRONG WRITE** (finishes the cook) | F2 |
| 28 | finished cooking | spoken | C3 | Not in the step words (G:110; misfires row 191). Model | `FinishCooking` | Weeknight dal, first time this month. | **MISS** | F1 |
| 29 | next | spoken | C | `.cookStep(next: true)`: `GoToCookStep(2)` | Same | Step 3. | OK | guard |
| 30 | step 3 | spoken | C | Lift: weight 3, no reps. Model | `GoToCookStep(2)`. Never a timer called "Step" | Step 3. | **MISS** (look-alike) | L1 |
| 31 | serves 4 | typed | C | Model | No timer. Model (or later, the cook's size) | Model's line; with no model: Didn't catch that. Try "bench 80 x 8". | OK | L1 |
| 32 | pasta 500g | spoken | C | "500g" is one token, not a number. Model | No timer: grams. Model | As row 31 | OK | L2 |
| 33 | pasta 500 | typed | C | Model | No timer: a bare number over 120 with no unit is not minutes. Model | As row 31 | OK | L2 |
| 34 | 2 onions | spoken | C | Lift: weight 2, no reps. Model | No timer (the number leads). Under RC18, groceries ["2 onions"]; see open question 6 | 2 onions, on the list. | **MISS** (RC18, not RC15) | L3 |
| 35 | 3x10 | typed | C | Lift: weight 3, reps 10, no words, so nil (G:245). Model | No timer, no write. Model | As row 31 | OK | L4 |
| 36 | 3x10 | typed | W | Relative set, full shape (G:178): a 3 kg x 10 set on Bench | No set: no weight was said, and 3 kg is not a bench weight. Model | Model's line. (master says "Set 4. 3 x 10.") | **WRONG WRITE** (not RC15) | L4 |
| 37 | 9 min | typed | I | Model | No write: outside a cook a bare length is not a timer | Model's line; with no model: Didn't catch that. Try "bench 80 x 8". | OK | T0 |
| 38 | 9 min | spoken | W | Workout branch needs `rest` or `timer` first (G:117). Lift: no reps. Model | No write: the rest timer is the workout screen's | As row 37 | OK | T0 |
| 39 | timer pasta 10 | typed | I | `.timer("Pasta", 10)`, no cook to link | Same | Pasta, 10 min. | OK | guard |
| 40 | timer 10 | spoken | W | Workout branch: `.ignoredInWorkout`, which throws | Same | Didn't save that. The rest timer lives on the workout screen. | OK | guard |

**Counts.** 40 rows: 35 in a cook (C, C+F, C3) and 5 outside one (rows 36 to 40: 2 idle, 3 in a workout). 28 are spoken and 12 typed. By verdict: 24 MISS, 6 WRONG WRITE, 10 OK.

- **Wrong writes (6):** rows 8, 11, 12, 26, 27, 36. Rows 11, 12, 26 and 27 matter most: a 60-minute timer when he said 90, a task at 2:30 am in place of a 2.5-minute timer, a task in place of a timer, and "done" finishing the whole cook (and stopping two running timers) while one timer rings. Row 36 is outside RC15 but was found here.
- **Misses (24):** rows 1 to 7, 9, 10, 13, 14, 16 to 25, 28, 30, 34. Row 25 waits for slice 12b. Row 34 belongs to RC18.
- **Look-alikes that must stay as they are:** rows 31, 32, 33, 35, 37, 38 (no timer), and the guards 15, 29, 39, 40.

## Rules (RC15, revised)

grammar-misfires.md's RC15 proposes two shapes in the cook branch: `/^(\d+(?:\.\d+)?)\s*(?:m|min|mins|minutes)$/` and `/^(\p{L}+) (\d+)$/` (not `step`, not `serves`). That fixes rows 2 and 3 only. As written it also turns `pasta 500` into a 500-minute timer (master allows up to 1440) and, because the process rule runs before lifts, turns `bench 80` said during a cook into a timer called "Bench". The rules below replace it.

All of T, X, S, Q, P, F, L and R live in the cook branch of `parseForProcess` (G:109), step 4 of the agreed M5 order, so they run before reading, money, people, lifts and kitchen. They bind only when `context.process` is a Cook. Q1 is the one exception: it must run before the question guard (step 3).

**Duration (D).** After the normaliser:
- `N h|hr|hrs|hour|hours`, optionally followed by `N` or `N m|min|mins|minute|minutes` ("1 hour 30", "1h30", "1 hr 15 min");
- `N m|min|mins|minute|minutes`;
- `N s|sec|secs|second|seconds`;
- `half an hour` is 30;
- `M:SS` with M from 0 to 59, only after the word `timer` or in a cook phrase with no day word;
- a range `N-M` or `N to M` with a unit or a label takes N (ASSUMED-2).

**Label (L).** One to three letter words. Drop a leading `the`, `my`, `a`, and the words `for`, `on`, `set`, `timer`. Title case the first letter. A label may not be `step`, `steps`, `serves`, `serving`, `servings`, `page`, `p`, `pg`, `set`, `sets`, `rest`, `x`, and may not resolve to an exercise (`resolveExercise(label) != nil` passes, so `bench 80` stays the lift rule's).

- **T0.** Outside a cook nothing new binds. A bare `D` with no `timer` word goes to the model, idle or in a workout (rows 37, 38).
- **T1.** `^D$` in a cook is `.timer("Timer", D)` (rows 2, 14).
- **T2.** `^L (for )?D$` and `^D (on|for) (the )?L$` give `.timer(L, D)` (rows 1, 5, 6, 10).
- **T3.** `^L N$` with a bare whole N from 1 to 120 gives `.timer(L, N)` (rows 3, 4, 7). Over 120 with no unit, pass (row 33).
- **T4.** When a phrase has one D with a unit and another bare number, the D wins and the bare number is dropped (an oven temperature, row 9).
- **T5.** A range takes its lower bound (row 13).
- **T6.** Fixes to `parseTimer` (K:74), for all modes: try the timer shape before `hasDate`, so `timer 2:30` is a length (row 12); read the second part of `1 hour 30` and `1h30` (row 11); drop a leading `the` or `my` from the label (row 8).
- **X1.** Extend: `^(another|add|plus) (N|D)( (to|on) (the )?L)?$`, `^N more( unit)?$`, `^one more minute$`. A bare N here is minutes. Needs an `ExtendKitchenTimer` action (slice 12b).
- **X2.** Target when no label is said: the flared timer (ended, not stopped); else the only running timer; else the soonest. A flared timer restarts from now for the added time; a running one moves its `endsAt`.
- **S1.** Stop by name: `^(stop|cancel|kill|turn off)( the)? L( timer)?$` and `^L off$` give `StopKitchenTimer` for the timer whose label matches L (whole words, singular, as `recipe(named:)` does). No match: pass.
- **S2.** `^(stop|cancel)( the| that)?( timer)?$` uses the X2 target.
- **Q1.** In a cook, `how long( left| on (the )?L)?`, `time left`, `is (the )?L done`, `what's left on (the )?L` return a read-only answer built from `CookLog.timers`, with no write. It runs before the question guard, which today sends every one of these to a model that cannot see the timers.
- **P1.** `pause`, `pause (the )?L`, `resume`, `carry on` bind once slice 12b ships pause. Until then: no write, and the line says so.
- **F1.** Add `finished cooking`, `done cooking`, `all done` to the finish words (G:110).
- **F2.** While a timer is flared, bare `done`, `stop` and `ok` stop the flared timer; they do not finish the cook. With nothing flared, `done` finishes, as now.
- **L1.** `step N` goes to `GoToCookStep(N-1)` (see open question 4); `serves N` passes.
- **L2.** A number glued to a kitchen unit (`500g`, `400ml`) or followed by one (`500 g`, `2 tbsp`) is never a duration.
- **L3.** A phrase that starts with a number and has no time unit is never a timer (`2 onions`).
- **L4.** A set shape `N x M` is never a timer. Separately, in a workout, a bare `N x M` with N of 10 or less and no unit should pass to the model rather than log N kg (row 36; same family as RC12 (c)).
- **R1.** In a cook, `remind me in D to X` gives `.timer(X, D)`. Outside a cook it stays a task, as `spoken-normaliser.md` row 50 expects (today 18:20 once `TessDates` reads `in N min`).

## Conflicts found

1. **The finish line has three versions.** Master's capture says "Weeknight dal, done." (E:167). The acceptance doc, step 8, says "Weeknight dal, first time." `CookLog.finishLine` and scenario S11 say "Carbonara, third time this month." Rows 27 and 28 use `finishLine`.
2. **Extend and pause are in 12b, but RC15 needs them.** The acceptance doc moves Pause and Extend to slice 12b (ASSUMED-6). Rows 16, 17, 18 and 25 cannot be fixed by grammar alone in the grammar batch: there is no action to call.
3. **Every miss is a dead end.** The model has no timer tool (Product, 19:12) and no timer state in its instructions, so the model cannot recover any of the 24 misses. At best it says something; at worst it makes a task or note. With no model the line is a bench hint.
4. **grammar-misfires RC15 as written breaks two things:** `pasta 500` becomes a 500-minute timer, and `bench 80` during a cook becomes a timer, because the process rule runs before lifts. The cap in T3 and the exercise check in L fix both.
5. **"remind me in 20 minutes to ..."** `spoken-normaliser.md` row 50 expects a task today 18:20. The kitchen code says "a timer never has a day" and blocks `remind` from kitchen (K:31-35). Row 26 proposes a timer only while cooking; Product should confirm.
6. **"done" while a timer rings.** Master finishes the cook (row 27). The acceptance doc (7b) stops a finished timer only by tapping the flared stack. F2 makes spoken "done" match that tap.
7. **Steps by voice.** ASSUMED-4 says "Swiping is the only way to change step" (in the context of a timer ending), but master already moves steps on spoken "next". Row 30 assumes voice may move steps.
8. **No cook mode screen on master.** Decisions 3:50 PM moved the cook mode screen to Builder A; it has not landed. The acceptance and phone script cannot run yet, and none of their steps uses the Tess bar, so nothing in them tests these phrases.

## Open questions

1. **A bare length in a cook (rows 2, 14).** Label "Timer", or the current step's first verb ("Simmer"), as ASSUMED-2 does for step keys?
2. **Which timer when none is named (X2, S2).** Flared first, then the soonest, with Undo. Or should Tess ask "Rice or simmer?" when two run? The 4:26 PM call says Tess never asks about times; is that true here too?
3. **A second timer with a running label.** "rice 12" while Rice runs: a second Rice, or restart Rice at 12?
4. **`step 3` by voice.** Allowed (row 30), or does ASSUMED-4 mean only swipes and "next" move steps?
5. **The bare-number cap (T3).** Is 120 minutes right? A slow braise is 180. With a unit (`3 hours`) there is no cap below the engine's 1440.
6. **`2 onions` while cooking (row 34).** Groceries (RC18), or nothing? He may be saying he is out of onions, or reading the recipe aloud.
7. **"done with that"** is a finish word on master (G:110). Should it mean "this step is done" (next step) instead?
8. **Seconds copy.** "Timer, 1.5 min." (master) or "Timer, 90 sec."? Row 17 uses "30 more sec.".
9. **Q1 and Rule 2.** Q1 answers before the question guard. It writes nothing, so it keeps the rule's spirit; does Product agree it may run ahead of the guard?

## Swift Testing stubs

In `TesseraCore/Tests/TesseraCoreTests/GrammarRulesTests.swift`, a parameterized table like grammar-misfires.md's `misfireRows`, with three new contexts (`.cooking`, `.cookingFlared`, `.cookingLastStep`) built on one Weeknight dal fixture with Rice and Simmer timers.

```swift
@Suite("Cook timer phrases (RC15)") struct CookTimerPhraseTests {
    @Test(arguments: cookTimerRows) func cookTimerPhrase(_ row: CookTimerRow)
    @Test func bareLengthInCookIsTimer()                 // rows 2, 14
    @Test func labelAndLengthInCookIsTimer()             // rows 1, 5, 6, 10
    @Test func labelAndBareNumberInCookIsTimer()         // rows 3, 4, 7
    @Test func bareNumberOver120IsNotTimer()             // row 33
    @Test func ovenTemperatureIsDropped()                // row 9
    @Test func rangeTakesLowerBound()                    // row 13
    @Test func timerLabelDropsLeadingThe()               // row 8
    @Test func timerReadsHoursAndMinutes()               // row 11
    @Test func timerColonIsLengthNotClockTime()          // row 12
    @Test func anotherExtendsFlaredTimer()               // row 16
    @Test func addSecondsExtendsSoonestTimer()           // row 17
    @Test func addToNamedTimerExtendsIt()                // row 18
    @Test func stopByNameStopsThatTimer()                // rows 19, 20
    @Test func bareStopStopsFlaredElseSoonest()          // rows 21, 22
    @Test func howLongLeftAnswersWithoutWriting()        // rows 23, 24
    @Test func pauseWritesNothingBefore12b()             // row 25
    @Test func remindInMinutesWhileCookingIsTimer()      // row 26
    @Test func doneWhileFlaredStopsTimerNotCook()        // row 27
    @Test func finishedCookingFinishes()                 // row 28
    @Test func stepNumberIsNeverTimer()                  // row 30
    @Test func servesNumberIsNeverTimer()                // row 31
    @Test func gramsAreNeverTimer()                      // rows 32, 34
    @Test func benchNumberDuringCookStaysLift()          // conflict 4
    @Test func setShapeIsNeverTimer()                    // row 35
    @Test func bareSetShapeInWorkoutDoesNotLogKilos()    // row 36
    @Test func bareLengthOutsideCookWritesNothing()      // rows 37, 38
    @Test func existingTimerPhrasesUnchanged()           // rows 15, 29, 39, 40
}
```
