# Home done-pack walls audit

Read-only audit of the Sonnet done-job pack (docs/ai/home-lines-job.md 2a to 2c; scripts/ai/home_lines_eval.py `pack_for`, `guard_pack`, `SYSTEM_DONE`) against the walls in TesseraCore. Paths are under /home/claude/Tessera. Master checked out; nothing was changed.

## Headline

1. **The routine title and exercise names reach the pack with no wall in code.** `HomeFact.title` is "as he wrote it" (HomeLines.swift:18). `fact(done:)` copies `summary.title` (HomeLines.swift:481) and `records` through `ExerciseWords.short` (HomeLines.swift:483), which only shortens known names. Nothing in the done path calls `SecretWords` or `PrivateFacts`.
2. **The title is not walled at creation or rename either.** `CreateRoutine.apply` (Actions/PlanActions.swift:16-21) trims and checks empty only. The 2:06 PM Oct 16 decision ("one wall at the engine") names CreateRoutine, but the 4:46 PM entry moves "Routines' Name it" to a follow-up after the rider and keeps `RenameObject` exempt. So both paths are open on master (unverified whether the 0ai rider has landed; the grep finds no check in CreateRoutine).
3. **The only backstop named is `ClaudeClient`, which I could not find.** `grep ClaudeClient` over *.swift returns no file. HD16 and the job doc (section 5) both lean on it. Also absent from code: `HomeLinesPack`, `TessLineCheck`. `ClaudeTessModel.swift:54` has the SecretWords and isWalled check, but only on `request.text`, not on a Home pack. Treat the pack-level wall as **unverified, probably not built yet**.
4. **The eval's `guard_pack` is weaker than the real walls.** It tokenizes the JSON and matches a fixed HEALTH and MONEY word set plus `$ £ €` (home_lines_eval.py:610-621). It has no secret-word check, no number-shaped test ("182.4"), and no `PrivateFacts.isBodyShaped` logic. A title "Weigh in 182.4 lb" is caught only because "weigh" and "lb" are in HEALTH. A title "Locker code 4417" is not caught at all. The doc says Core copies only `SYSTEM_DONE`, so this is the wrong guard to port.

## 1. Field table

Pack shape per 2c item 2: routine title, finish clock word, `dayLabel`, bests, `sinceLastDays`, rules line, plus handle and the counts (exercisesDone, exercisesPlanned, sets) and `numbers`/`names`.

| Field | Source in code | User free text? | Can carry private words, money, body fact, secret? | Check that stops it |
|---|---|---|---|---|
| Routine title (`title`, also first of `names`) | HomeLines.swift:19 (`HomeFact.title`), set at :481 from `WorkoutSummary.title`; the workout title is copied from the routine at PlanActions.swift:124; routine title set at PlanActions.swift:21 and ObjectRecord rename (Transaction.swift:77, TrainingActions.swift:507) | Yes, fully. "as he wrote it" | Yes: any of the four | **None: gap.** `isPrivateTitle` (PrivateFacts.swift:12) exists but no caller on this path. Only the unbuilt `ClaudeClient` wall (unverified) would catch it at send time. |
| Exercise names (`records` / `bests`, and `names`) | HomeLines.swift:32, :483 via `ExerciseWords.short` (HomeLines.swift:607+, a table plus kit shortening) | Yes for custom exercises; library names are fixed text | Yes for custom ones ("Bench pin 4417", "Weigh-in 182.4") | **None: gap.** `short` shortens only; unknown names pass through unchanged (unverified for the fallthrough branch; I read the table, not the whole function). |
| Finish clock word ("6:40 pm") | `endedAt` from the summary (HomeLines.swift:487); rules context is formatted from it | No | No. Digits are a clock time; `PrivateFacts.hasAmount` strips times (PrivateFacts.swift:126) | Structural: a Date formatted by the phone. |
| `dayLabel` | Features/Home/HomeLineHero.swift:96-100 (`DayLabel`, 04:00 turnover) | No, a fixed weekday plus part-of-day vocabulary | No | Structural. The pack builder is unbuilt; the label must come from this view's logic, not a string the user touched (unverified). |
| `bests` count / `records` (see exercise names) | HomeLines.swift:32 | Names only (row above) | Via names | Same as exercise names |
| `sinceLastDays` | HomeLines.swift:36, :484 via `daysSinceLastRun` (HomeLines.swift:593) | No, an Int | No | Structural |
| Counts: exercisesDone, exercisesPlanned, sets | HomeLines.swift:28-30 | No, Ints | A count could equal a body number by coincidence, which is not a leak | Structural |
| Rules line (context, detail) | HomeLines.swift:124-130, :246-249 builds from `fact.title` and `records[0]` | Indirect: it **embeds the title and the best name verbatim** ("\(fact.title) done. \(records[0]) best.") | Yes, through the title | **None: gap.** The rules line is a second route for the same text, and it is sent as `rules`. |
| `numbers` | HomeLines.swift:77-84, :171 (`factNumbers` plus `HomeLines.digits(in:)` of context and detail) | Digits parsed from the rules words, so digits in the title count | Yes: "Weigh in 182.4" puts 182 and 4 in `numbers`, and C6 would then allow Claude to repeat them | **None: gap.** Allowed-number set grows with the title. |
| `names` | HomeLines.swift:71-73 (`[title] + [exercise] + records`) | Yes | Yes | None; also widens the C-check name allowlist, so a leaked name is also a permitted name. |
| Handle (`h1`) | job doc section 1 | No | No | Structural. |
| Workout note | Not in `HomeFact`; HD16 says "No note field exists in the pack shape" | Yes, but not packed | No | Structural. Verified: `HomeFact` has no note field (HomeLines.swift:6-43). |

Two more routes worth naming. A routine named "Private note" is harmless. A secret *routine* routed through `Notes.swift:115` becomes a note titled "Private note", but that path is for captured lines, not routine names.

## What the walls actually catch (verified by reading)

- `SecretWords.mentions(text)` (Notes/SecretWords.swift:34): whole-word match on password, passcode, pin, code, combo, passphrase, pw, pwd (and plurals), plus "wifi" before ":" or "is". No value is needed, the word alone triggers it. So "Locker code" and "Pin press" are both flagged (the second is a false positive, which fails closed).
- `PrivateFacts.isMoneyShaped`: currency sign, money word with an amount, or an amount with exactly two decimals. Training notation (82.50 x 8, "80 for 8") is exempt (PrivateFacts.swift:31-36, :136).
- `PrivateFacts.isBodyShaped`: weigh words, body units (lb, kg), vitals, medicines, symptoms. Per decisions 4:46 PM, `lastWeightKg` is being added so a bare number matching his last weigh-in is walled. Whether that has landed: **unverified** (the PrivateFacts.swift I read shows `isBodyShaped(_ phrase:)` with no `lastWeightKg`).
- Known soft spots for a title: "Bench 182.4" has no weigh word, so it passes `isBodyShaped` as bar weight; "Weigh in 182.4 lb" is walled; "Morning 82.2" is walled only if the lastKg lookup lands and matches.

## 2. Ranked gaps and fixes

1. **Title and best names are unwalled (critical).** Fix: in `HomeLinesPack.build`, run `SecretWords.mentions(x) || PrivateFacts.isWalled(x, lastWeightKg:)` on the title and on each best name. If **any** field trips, make **no call at all** (do not mask: a masked title still leaves the rules line, which embeds it). Keep the rules line on screen. Log nothing from the text.
2. **Rules line and `numbers`/`names` carry the same text (critical).** Fix: build `rules`, `numbers` and `names` only after gap 1 passes; compute `numbers` from facts only (`factNumbers` plus clock digits), never from `HomeLines.digits(in:)` of a string containing the title. Test that the digit set equals the fact set.
3. **No wall at the source.** Fix: land the 0ai engine wall for CreateRoutine, the Routines Name it field and RenameObject (RenameObject is exempt today by decision, so for it keep the wall at pack time instead of changing the ruling). Either way the pack check in gap 1 must not depend on the source being clean, because old titles already exist.
4. **`ClaudeClient` backstop is unverified.** Fix: do not rely on it. Add a final scan over the encoded request body (system + messages) with `SecretWords.mentions` and `PrivateFacts.isWalled` on the title and bests fields individually, plus a digit-with-decimal test, before send. Fail closed: no request.
5. **Eval `guard_pack` is a word list, not the wall.** Fix: Core must not port it. Add a note in home-lines-job.md section 2c that `guard_pack` is eval-only. Optional: add `SecretWords` words to the script so Research fixtures catch secrets too.
6. **Free-text exercise names pass through `ExerciseWords.short`.** Fix: send a custom exercise name only if it is in the library table or passes gap 1; otherwise drop the best from the pack (keep the count "1 new best" in the rules line and send `bests: []` is wrong, since gate counts it: so keep the call and send count only, name masked as "a lift").
7. **Bare numbers in titles that match no unit.** "Bench 182.4" or "Morning 82.2" is not provably a body fact. Fix: also refuse any title or best name containing a number with a decimal point, or three-plus digits, unless the training-notation pattern matches. Cheap, fail closed, and routine names rarely need such digits ("5x5", "Push B" pass).
8. **False positives refuse a harmless call.** "Pin press" or "Code red conditioning" would silence Claude for that routine forever. Acceptable (fail closed, one cached no-call); document it and show nothing to the user.
9. **Spec ambiguity.** 2c says "masked" nowhere; 2 says "Nothing else". State plainly: wall hit means **no call**, not a partial pack. This avoids half-masked titles inside the rules line.

## 3. Fixtures for Research

All values made up. Each case is a finished workout with a best or a gap of 4+ days, so the gate would otherwise call. "Hard-fail" is the string that must be absent from the captured request body (all roles, tool schema included).

| # | Routine title / exercise (best) | Expected | Hard-fail string |
|---|---|---|---|
| W1 | "Weigh in 182.4 lb" / Bench | **No call.** Rules line stays. | `182.4` |
| W2 | "Push B" / custom best "Locker code 0000" | **No call** (best name secret). | `Locker` and `0000` |
| W3 | "Pull A" / Deadlift, workout note "wifi is tacocat" | **Call**; note never packed. | `tacocat` |
| W4 | "Gym pin 1234 day" / Squat | **No call.** | `1234` |
| W5 | "Legs" / "Pin press" (library-like name, secret word) | **No call** (false positive, fail closed). | `Pin press` |
| W6 | "Rent 1850 day" / Press | **No call** (money-shaped). | `1850` |
| W7 | "Push B $40 club" / Bench | **No call.** | `$` |
| W8 | "Morning 82.2" / Row, last weigh-in 82.2 kg | **No call** once `lastWeightKg` lands; until then **unverified, expected gap**. Record the actual result. | `82.2` |
| W9 | "Bench 182.4" / Bench | **No call** under proposed gap 7; today it would send. Records the gap. | `182.4` |
| W10 | "Push B" / "Press", `sinceLastDays` 3 | **Call.** Control: pack holds title, bests, counts only. | none (assert pack equals the expected JSON) |
| W11 | "Legs", note "sick, bp 120/80" / Squat | **Call**; note never packed. | `120/80`, `sick` |
| W12 | "Pull A" with 0 sets, title "Door code 4417" | **No call** (fixed, no sets); title also walled. | `4417` |
| W13 | Title "Heart rate day 5x5" / Row | **Call** or **no call** per Product ruling: "heart" is a HEALTH word in the eval guard but a vital only with a number context in `isBodyShaped`. Mark **unverified**; Research to ask Product. | `heart` (if ruled walled) |
| W14 | "Push B" / Bench, `numbers` check: title contains "5x5 80 for 8" | **Call**; `numbers` must equal fact numbers plus clock only, not 5, 80, 8 | digits `80` in `numbers` |

## 4. Tests Core should write

Package tests (Swift Testing, TesseraCore), one function each:

- `homeDonePackSkipsCallWhenTitleHasSecretWord`
- `homeDonePackSkipsCallWhenTitleIsMoneyShaped`
- `homeDonePackSkipsCallWhenTitleIsBodyShaped`
- `homeDonePackSkipsCallWhenBestNameHasSecretWord`
- `homeDonePackSkipsCallWhenCustomExerciseNameHasDecimal`
- `homeDonePackNeverIncludesWorkoutNote`
- `homeDonePackNumbersComeFromFactsAndClockOnly` (W14)
- `homeDonePackRulesLineNeverSentWhenTitleWalled`
- `homeDonePackFieldsAreExactlyTheListedFields` (decode the body; assert the key set: handle, kind, title, state, exercisesDone, exercisesPlanned, sets, bests, sinceLastDays, dayLabel, rules, numbers, names; no `now`, no `partOfDay`)
- `homeDonePackControlCaseSendsTitleAndBests` (W10, so the wall is not over-eager)
- `homeDoneRequestBodyScanRefusesWalledTextEvenIfPackBuilderWrong` (final scan, gap 4)
- `homeDoneSecretFalsePositiveFailsClosedAndCachesNoCall`
- `createRoutineWallsSecretMoneyBodyTitles` (once the 0ai rider covers it)
- `renameObjectOnRoutineStillReachesPackWallWhenSourceUnwalled`
- `homeDonePackWallCoversFixturesW1ToW14` (table-driven from Research's file)

App tests: one UI run per W1, W2, W6 that checks the Home line is the rules line and no wet redraw appears.

## Unverified list

- `ClaudeClient` and its SecretWords/money wall: no source file found (job doc and HD16 describe it).
- `HomeLinesPack`, `TessLineCheck`: not in the repo, so no code to audit; findings are from the spec and the script.
- Whether the 0ai rider (engine wall, `lastWeightKg`) has landed: PrivateFacts.swift shows the older signature.
- `ExerciseWords.short` fallthrough behavior for unknown names (read the table only).
- Whether `DayLabel` output feeds the pack unchanged.
