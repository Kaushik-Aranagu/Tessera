# Siri body weight fixture (R2, "Body weight logged.")

For Core (`TesseraCore`, `Intents.swift`) and the next release that touches `TesseraIntents/Intents.swift`. Research lab, docs only. Task BX. Date: 2026-10-17.

**Master read:** `origin/master` at `ab7d3bf` (Merge PR #583), read through `git show origin/master:...` in the scratchpad worktree. Nothing was run; no Swift toolchain here, so every current line is a hand trace of the code on master. "Current" is what Siri says today; "expected" is the R2 target.

**Gate:** master has no body weight action (no `BodyWeight` class, no `LogBodyWeight`), so "Body weight logged." needs the Body weight slice (see `body-weight.md`, M3 slice 1) to land first. Until then, a weigh-in is a private note and the rule below still holds: the number is never spoken back.

**Rules used:** a receipt names the thing first. A body weight says "Body weight logged." and never the number. A lift set and a kitchen weight never get that line. A private note is "Private note, kept." and never its words.

## Where the paths are

| path | file:line on master | what it does today |
|---|---|---|
| Add a Task | `TesseraCore/Sources/TesseraIntents/Intents.swift:133-178` | runs `TessGrammar.privateParse`; a private note answers `"\(SecretWords.title), kept."` at `:169`; an ordinary task is said back with its title and time at `:173-175` |
| Tell Tess | `Intents.swift:181-203` | runs `runtime.tess.capture`; a private phrase with a saved entry answers `"Saved."` at `:201` (hidden check at `:199-200`) |
| Log a Set | `Intents.swift:9-36` | logs a lift set; the reply is the logged summary at `:34` |
| Log Next Set | `Intents.swift:39-59` | no workout at `:55`; otherwise the summary at `:57` |
| Undo Last Set | `Intents.swift:67-87` | `"No set to undo."` at `:81`; `"Set N taken back."` at `:85` |
| Start a Workout / Finish Workout | `Intents.swift:89-131` | `:108`, `:129` |
| Private body test | `TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift:61` (`weighWords`), `:62` (`bodyUnits`), `:77` (`kitchenUnits`), `:81-109` (`isBodyShaped`) | `weigh`, `weighed`, `weigh-in`, `bw` count as body with a number; `weight` is not in the list |
| Privacy grammar | `TesseraCore/Sources/TesseraTess/TessGrammar+Privacy.swift:18-41` | body-shaped phrase becomes `.privateNote` at `:30-31` |
| Grammar order | `TesseraCore/Sources/TesseraTess/TessGrammar.swift:132-141`, `:143` | walled body fact is read before lifts and kitchen |
| Capture private note line | `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:312` | `"Private note, kept."`; miss log skips walled phrases at `:59-60` |

Gap found: `weighWords` (`PrivateFacts.swift:61`) has `weigh`, `weighed`, `weighing`, `weigh-in`, `bw`, `scale`, but not `weight`. So "log my weight 82.4" is not body-shaped and reaches the task path (see case 7).

## 1. Cases

Made-up values only. "Current" = what master says (hand trace). "Expected" = the R2 target.

| # | phrase said to Siri | surface | current line on master (file:line) | expected line | why |
|---|---|---|---|---|---|
| 1 | "weighed 82.4 this morning" | Add a Task | "Private note, kept." (`Intents.swift:169`; body shape at `PrivateFacts.swift:101-103`, `TessGrammar+Privacy.swift:30-31`) | "Body weight logged." | Body weight with a day word; no number |
| 2 | "weighed 82.4 this morning" | Tell Tess | "Saved." (`Intents.swift:201`, hidden by `:199-200`) | "Body weight logged." | Same phrase through the capture path |
| 3 | "weighed 82.4 yesterday" | Tell Tess | "Saved." (`Intents.swift:201`) | "Body weight logged." | Dated weigh-in (BP2); the day replaces that day's entry, the line stays the same |
| 4 | "weigh-in 82.4" | Add a Task | "Private note, kept." (`Intents.swift:169`; `weigh-in` at `PrivateFacts.swift:61`) | "Body weight logged." | Hyphenated word is kept by `words()` (`PrivateFacts.swift:115`) |
| 5 | "bw 82.4" | Tell Tess | "Saved." (`Intents.swift:201`; `bw` at `PrivateFacts.swift:61`) | "Body weight logged." | Short prefix; with no reps it is a weigh-in (BP4) |
| 6 | "181 lb" | Tell Tess | "Saved." (`Intents.swift:201`; unit at `PrivateFacts.swift:62`, `:106-108`) | "Body weight logged." | Unit said wins over the setting (BP3); the line never gives the value |
| 7 | "log my weight 82.4" | Add a Task | "Log my weight 82.4." (`Intents.swift:173-175`) | "Body weight logged." | Worst case: `weight` is not in `weighWords`, so the number is spoken back as a task title |
| 8 | "bench 80 x 8" | Tell Tess | the set receipt in `capture.line` (`Intents.swift:201`) | never "Body weight logged." | A lift set is the bar, not his body (`PrivateFacts.swift:135-138`) |
| 9 | Log a Set: Bench Press, 80 kg, 8 reps | Shortcuts or Siri | the logged summary plus "." (`Intents.swift:34`) | never "Body weight logged." | Lift intent; the weight is the bar |
| 10 | Log Next Set, with a workout running | Lock Screen or Siri | the logged summary plus "." (`Intents.swift:57`); "No workout running." at `:55` | never "Body weight logged." | Set, never a body weight |
| 11 | "weigh the flour 500 g" | Tell Tess | the kitchen receipt (`TessGrammar.swift:143`) | never "Body weight logged." | Kitchen unit makes it not body-shaped (`PrivateFacts.swift:77`, `:102`) |
| 12 | "weigh the flour 500 g" | Add a Task | "Weigh the flour 500 g." (`Intents.swift:173-175`) | never "Body weight logged." | Same kitchen phrase on the task path |
| 13 | "what did I weigh monday" | Tell Tess | the task or miss path via `capture.line` (`Intents.swift:201`) | never "Body weight logged." and no body weight written | A question with no number is not a weigh-in |
| 14 | "82,4" | Tell Tess | no body line (not body-shaped: no `.`, `PrivateFacts.swift:105-108`) | never "Body weight logged." | Comma decimal is not a weigh-in until BP1 lands |
| 15 | Undo Last Set, with a set logged | Lock Screen or Siri | "Set 3 taken back." (`Intents.swift:85`); "No set to undo." at `:81` | never "Body weight logged." | Undo never reports a body weight |
| 16 | Finish Workout, with a workout running | Siri | "Finished. N of M exercises." (`Intents.swift:129`) | never "Body weight logged." | Workout receipt only |

Rule for every row: the number from the phrase is never in the spoken line, on Siri, the Lock Screen or Live Activity. Cases 1 to 7 need the Body weight slice before the expected line can be said.

## 2. Swift Testing names

Suite: `SiriBodyWeightTests` (in `TesseraCore/Tests/TesseraCoreTests/`, next to `SiriParityTests.swift`). One `@Test` per case, named so Core can paste it.

```swift
@Test func siriWeighedThisMorningSaysBodyWeightLoggedInAddATask() async throws { /* case 1 */ }
@Test func tellTessWeighedThisMorningSaysBodyWeightLogged() async throws { /* case 2 */ }
@Test func tellTessWeighedYesterdaySaysBodyWeightLogged() async throws { /* case 3 */ }
@Test func addATaskWeighInSaysBodyWeightLogged() async throws { /* case 4 */ }
@Test func tellTessBwNumberSaysBodyWeightLogged() async throws { /* case 5 */ }
@Test func tellTessPoundsSaysBodyWeightLoggedWithoutValue() async throws { /* case 6 */ }
@Test func addATaskLogMyWeightSaysBodyWeightLoggedNotTheNumber() async throws { /* case 7 */ }
@Test func tellTessLiftSetNeverSaysBodyWeightLogged() async throws { /* case 8 */ }
@Test func logASetNeverSaysBodyWeightLogged() async throws { /* case 9 */ }
@Test func logNextSetNeverSaysBodyWeightLogged() async throws { /* case 10 */ }
@Test func tellTessKitchenWeighNeverSaysBodyWeightLogged() async throws { /* case 11 */ }
@Test func addATaskKitchenWeighNeverSaysBodyWeightLogged() async throws { /* case 12 */ }
@Test func tellTessWeighQuestionWritesNoBodyWeight() async throws { /* case 13 */ }
@Test func tellTessCommaDecimalIsNotAWeighIn() async throws { /* case 14 */ }
@Test func undoLastSetNeverSaysBodyWeightLogged() async throws { /* case 15 */ }
@Test func finishWorkoutNeverSaysBodyWeightLogged() async throws { /* case 16 */ }
```

Each body asserts the expected line with `#expect(line == "...")` and, for cases 1 to 7, that the spoken line has no digits (`#expect(!line.contains(where: \.isNumber))`).

## 3. Note for the owner (Core, Intents.swift)

R2 cannot ship as a wording change alone. Add `weight` to `PrivateFacts.weighWords` (`PrivateFacts.swift:61`) so case 7 is body-shaped, then give the Siri paths a body weight branch: `CreateTaskIntent.add` (`Intents.swift:166-169`) and `TellTessIntent.perform` (`Intents.swift:197-201`) should return "Body weight logged." for a weigh-in, and never "Private note, kept." or "Saved." for it. Both need the Body weight action from the M3 slice (no `LogBodyWeight` exists on master), so the wording waits for that slice; the number stays out of every line. Kitchen weights (cases 11 and 12) and lift sets (cases 8 to 10) must keep their current lines. Ship the fixture's `@Test` names with the change and run them in `TesseraCore`'s `swift test`.
