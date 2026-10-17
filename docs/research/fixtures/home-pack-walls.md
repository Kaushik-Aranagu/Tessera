# Home done-pack wall fixtures (W1 to W16)

Research worker, Oct 17, 2026. Written from `docs/ai/home-pack-walls-audit.md` (section 3) and item 9 of section 2c in `docs/ai/home-lines-job.md`, both read from origin/master (bf33474, Oct 16, 2026, 7:28 pm). Nothing here was run and no call was made. All values are made up.

## How to read the table

- **Wall holds** means no Claude call at all for that finish (item 9: a partial mask would still leak through the rules line). The Home line is the rules line, and nothing wet redraws.
- **Line allowed** means the pack is built and one call is made. The rules line still shows first. Claude's words replace it only if they pass the phone's checks (C1 to C15 and the caps).
- **Line shown** is the rules line the phone draws, built from the routine title and the first best: "<title> done. <best> best." (HomeLines.swift:124-130, as the audit reads it). The detail slot wording was not read, so only the context slot is quoted.
- **Hard-fail** is the full fixture token that must be absent from the captured request body, all roles, tool schema included. Always the full token (`$40`, `heart rate day`, `sick, bp`, `Locker code`), never a bare `$`, `heart`, `sick` or `Locker`, because the system prompt lists the forbidden word classes and a bare word can appear in a correct request. The scan covers the user-controlled fields (title, bests, names, numbers) plus the encoded body for the full token. A "no call" row passes only if no request is made at all. W14 is the one exception: its column names digits that must be absent from the `numbers` array, and its title is expected in the body.
- Every row is a finished workout with a best or a gap of 4 or more days, so the gate would otherwise call. Test names are Swift Testing functions in TesseraCore. Owner "Core 0al" is the pack builder (`HomeLinesPack.build`); "AI WALLS" is the follow-up items for the engine wall, the Routines "Name it" field and the open rulings.

## Fixtures

| id | Input | Expected | Line shown | Hard-fail | Suggested test name | Owner |
|---|---|---|---|---|---|---|
| W1 | Title "Weigh in 182.4 lb"; best Bench | Wall holds (body-shaped title) | Weigh in 182.4 lb done. Bench best. | `182.4` | `homeDonePackSkipsCallWhenTitleIsBodyShaped` | Core 0al |
| W2 | Title "Push B"; custom best "Locker code 0000" | Wall holds (secret word in a best name) | Push B done. Locker code 0000 best. | `Locker code`, `0000` | `homeDonePackSkipsCallWhenBestNameHasSecretWord` | Core 0al |
| W3 | Title "Pull A"; best Deadlift; workout note "wifi is tacocat" | Line allowed; the note is never packed | Pull A done. Deadlift best. | `tacocat` | `homeDonePackNeverIncludesWorkoutNote` | Core 0al |
| W4 | Title "Gym pin 1234 day"; best Squat | Wall holds (secret word) | Gym pin 1234 day done. Squat best. | `1234` | `homeDonePackSkipsCallWhenTitleHasSecretWord` | Core 0al |
| W5 | Title "Legs"; best "Pin press" | Wall holds (false positive, fails closed) | Legs done. Pin press best. | `Pin press` | `homeDoneSecretFalsePositiveFailsClosedAndCachesNoCall` | Core 0al |
| W6 | Title "Rent 1850 day"; best Press | Wall holds (money-shaped) | Rent 1850 day done. Press best. | `1850` | `homeDonePackSkipsCallWhenTitleIsMoneyShaped` | Core 0al |
| W7 | Title "Push B $40 club"; best Bench | Wall holds (currency sign) | Push B $40 club done. Bench best. | `$40` | `homeDonePackSkipsCallWhenTitleIsMoneyShaped` (second case in the same test) | Core 0al |
| W8 | Title "Morning 82.2"; best Row; last weigh-in 82.2 kg | Wall holds | Morning 82.2 done. Row best. | `82.2` | `homeDonePackSkipsCallWhenTitleIsBodyShaped` (second case; add the last-weigh-in variant once `lastWeightKg` lands) | Core 0al, AI WALLS for `lastWeightKg` |
| W9 | Title "Bench 182.4"; best Bench | Ruled (decisions 7:31): wall holds for the Home pack only. A decimal or 3-plus digit number in a title or best name means no call unless it is training notation (N x M, 5/3/1). Today: line allowed | Bench 182.4 done. Bench best. | `182.4` | `homeDonePackSkipsCallWhenCustomExerciseNameHasDecimal` (title variant needed) | Core 0al |
| W10 | Title "Push B"; best Press; `sinceLastDays` 3 | Line allowed (control: the wall must not be over-eager). Assert the pack equals the expected JSON: title, bests, counts only | Push B done. Press best. | none | `homeDonePackControlCaseSendsTitleAndBests` | Core 0al |
| W11 | Title "Legs"; best Squat; note "sick, bp 120/80" | Line allowed; the note is never packed | Legs done. Squat best. | `120/80`, `sick, bp` | `homeDonePackNeverIncludesWorkoutNote` (second case) | Core 0al |
| W12a | Title "Door code 4417"; 0 sets; best none | Expected: no call (skip). Ruled (decisions 7:31): a done workout with no sets or no best is skipped before the wall runs. Assert the skip path: no call, and the wall function is never reached | Door code 4417 done. (no best, so no best clause; the exact fixed wording is the phone's own) | `4417` | `homeDonePackSkipsBeforeWallWhenWorkoutHasNoSets` | Core 0al |
| W12b | Title "Door code 4417"; 1 or more sets; best Bench | Expected: no call (wall holds, secret word). This is the wall path: the workout is not skipped, so the wall must run and trip | Door code 4417 done. Bench best. | `4417` | `homeDonePackWallHoldsWhenTitleHasSecretWordAndWorkoutHasSets` | Core 0al |
| W13 | Title "Heart rate day 5x5"; best Row | Ruled (decisions 7:31): "heart rate" walls a title even beside "5x5", so no call. Core changes the predicate | Heart rate day 5x5 done. Row best. | `heart rate day` | `homeDonePackSkipsCallWhenTitleHasHeartRateBesideNotation` | Core 0al (predicate change) |
| W14 | Title "Push B 5x5 80 for 8"; best Bench | Ruled (decisions 7:31): a passing title may carry its notation numbers, and any wall hit means no call. Line allowed; `numbers` must equal the fact numbers plus clock digits only (not 5, 80 or 8) | Push B 5x5 80 for 8 done. Bench best. | Not in the `numbers` array: `5`, `80`, `8`. The title string "Push B 5x5 80 for 8" is expected in the body | `homeDonePackNumbersComeFromFactsAndClockOnly` | Core 0al |
| W15 | Routine title shaped like an API key (described in words only; the fixture never holds a key-shaped string); best Bench | Wall holds (the key-shaped title must never reach the pack; `looksLikeClaudeKey` and `withoutClaudeKeys` are the wall). Use a made-up non-key phrase as the stand-in in test data and build the key-shaped value in code from pieces, never as a literal | Not quoted (the title is key-shaped). The rules line is the phone's own | The whole key-shaped title, and the Claude key prefix, absent from the body | `homeDonePackSkipsCallWhenTitleIsKeyShaped` | Core 0al |
| W16 | Routine "Push B" created clean, then renamed to "Gym pin 1234 day" after it was created (RenameObject is exempt at the engine); best Squat | Wall holds: the pack wall runs at pack time and does not trust the source. Expected: no call | Gym pin 1234 day done. Squat best. | `1234` | `renameObjectOnRoutineStillReachesPackWallWhenSourceUnwalled` (A2 section 4) | Core 0al |

Table-driven umbrella test for the whole file: `homeDonePackWallCoversFixturesW1ToW16`. Also see the audit's section 4 for the other tests Core should write (request-body scan, key-set check, `createRoutineWallsSecretMoneyBodyTitles`, `renameObjectOnRoutineStillReachesPackWallWhenSourceUnwalled`).

W3 and W11 use placeholder secret and body text that must never appear anywhere in the body. W12a, W12b, W4 and W16 use the placeholders 4417 and 1234.

## Status on master today (found by reading the code)

Master is bf33474. The key fact: **there is no pack builder yet.** A search of origin/master for `HomeLinesPack`, `TessLineCheck` and `ClaudeClient` finds no Swift file, and nothing in the done path (`HomeFacts.fact(done:)`, HomeLines.swift:479) calls `SecretWords` or `PrivateFacts`. So no "wall holds" row can pass as an end-to-end test today. What can be decided is whether the wall predicate Core is told to use (`SecretWords.mentions(x) || PrivateFacts.isWalled(x)`, item 9) returns the right answer for each input:

| id | Predicate on the title or best name | End-to-end today |
|---|---|---|
| W1 | Right: walled (weigh word with a number, no kitchen unit) | Fails: no builder, title reaches the rules line and `names` unwalled |
| W2 | Right: walled (`SecretWords.mentions`, "code") | Fails: no builder |
| W3 | Right: not walled | Passes by construction: `HomeFact` has no note field (HomeLines.swift:6-43) |
| W4 | Right: walled ("pin") | Fails: no builder |
| W5 | Right: walled ("pin") | Fails: no builder |
| W6 | Right: walled (money word "rent" with an amount) | Fails: no builder |
| W7 | Right: walled (currency sign) | Fails: no builder |
| W8 | Right: walled today even without `lastWeightKg`: a bare decimal with only the day word "morning" is body-shaped (`unitOrDecimal` and `dayWords` in PrivateFacts.swift) | Fails: no builder. The audit's "unverified" is resolved for the predicate: it does not depend on `lastWeightKg` for this input. A title with a decimal and a word outside `dayWords` still does not wall (see W9). |
| W9 | Wrong against the proposal: not walled ("bench" is not a day word, so the decimal reads as bar weight) | Fails: no builder, and the predicate also lets it through. Needs the gap 7 rule. |
| W10 | Right: not walled | Cannot pass: there is no pack to compare to the expected JSON |
| W11 | Right: the title is not walled; the note is not packed | Passes by construction (no note field) |
| W12a, W12b | Right: walled ("code"). Separately, a done workout with no sets is fixed and not packed per section 2 | W12a: unverified whether the no-sets fixed path skips the pack; no builder to read. W12b: fails, no builder |
| W13 | Not walled: "5x5" is training notation, and `isBodyShaped` returns false early on training notation, so "heart rate" never gets checked | Undecidable, see below |
| W14 | Right for the wall (training notation, not walled). The failure is in `numbers` | Fails by reading: the audit finds `numbers` takes the digits of the rules context and detail (`HomeLines.digits(in:)`), and the rules line embeds the title, so 5, 80 and 8 would join the allowed set. I did not run it. |

| W15 | Cannot be judged from the predicate alone: the key check is `looksLikeClaudeKey`, not read here | Fails: no builder |
| W16 | Right: walled ("pin") | Fails: no builder, and the rename path is exempt at the engine |

Rows that pass today by construction: W3, W11. Everything else is blocked by the missing builder, and W9 also needs the gap 7 rule (ruled, Core 0al).

## Rows that were undecided

All three were ruled by Product at 7:31 pm (decisions 7:31, boarded on Core): W13 walls "heart rate" even beside "5x5" and needs a predicate change, W9 adopts gap 7 for the Home pack only, and W12 is skipped before the wall runs. No row is open. W13 is expected to fail on master until Core changes the predicate.
