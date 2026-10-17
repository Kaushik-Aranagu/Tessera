# QA review: #451 MU2 money and body wall, plus A2, CA6, CA7 (Core)

Head checked: `09a11cb` (core/money-wall, 2 commits: 8415af7, 09a11cb). `git merge-tree` against master is clean. Static review only; Core reports 449 package tests and 137 app tests green.

**Verdict: PASS.**

## Pin checklist items
1. **One router check before `isAvailable`: money, body and health.** Yes. TessModel.swift:75-80: `PrivateFacts.isWalled` (money or body) skips the `.claude` route inside the same `where` clause as the secret-word rule, before any `isAvailable` result is used. Health falls under "body" in `PrivateFacts.isBodyShaped` (PrivateFacts.swift:44-86). Rows MB18-MB23 are in `moneyAndBodyRowsNeverReachClaude` (MoneyWallTests.swift), and I traced each one through the code:
   - "bp 128/82" (vitals and a number)
   - "resting hr 58"
   - "slept 5 hours" ("slept" and a number)
   - "took 2 advil" (medicine and a number)
   - "10mg lexapro" (the `\d mg` regex)
   - "migraine since noon" (a symptom, no number needed)

   Body weight is covered by "182.4 this morning", "182.4 lb this morning" and "weighed in at 83 kg". The on-device model still reads each of these, and the test checks that.
2. **Claude's own route refuses secret, money and body.** Yes, at ClaudeTessModel.swift:52-54. The check comes right after the Siri guard and before the system pack, the estimate or any reserve, so a direct caller or the inbox gets `.missed` with no ledger row.
3. **The inbox screens at add, and the drain drops old items (A2, CA7).**
   - Add: TessInbox.swift:29-30 refuses a secret or a walled phrase.
   - Drain: TessInbox.swift:64-68 removes a walled item unread, and that comes before the `isAvailable` loop body.
   - The test `phrasesQueuedBeforeTheWallsNeverLeave` (ClaudeRouteTests.swift) seeds a secret, a spend and a weigh-in. It shows that none of them appears in any sent body and that the inbox ends empty.
4. **The answerQuery allow-list (CA6) is in.** TessTools.swift:230-247: answerQuery counts only workout, exerciseEntry, set, routine, exercise, task, note, list, listItem, recipe, cook and ingredient. A class he made himself ("Spend"), settings, Tess memory and Tess calls all throw. Tests are in TessToolsTests.
5. **No catalog change.** Nothing under Catalog/ or Model/ is touched, and no FieldSpec is added. The pin stays at v9.
6. **Data safety.** The PR has no App/, Features/ or UITests changes, and no ProcessInfo, CommandLine or `#if DEBUG`.

**Tess's lines:** unchanged. A walled phrase that nothing on the phone catches gets the existing "Didn't catch that." Design has nothing to pass. The MU2 one-ask ("$212.37 at Costco?" with LOG and NOT NOW) is not in this PR; it rides MU1 or a later PR.

## Lows (non-blocking; all fail safe toward the phone, or are false negatives outside the decided rows)
- L1, false negatives: health stated with no number still reaches Claude. Examples: "slept badly", "couldn't sleep", "knee hurts", "sore shoulder", "feeling sick". So do body facts the lists don't name: "body fat 18%", "bmi 24". architecture.md §7 says "health values, sleep": the values are walled, and the words alone are not. Product decides whether sleep and pain words with no number join the wall. Research 138's rows don't ask for it.
- L2, false positives (safe: the phrase stays on the phone): a clock time with a dot ("meet at 6.30", "alarm 7.45") reads as money through the two-decimal rule, and "bench 82.50" with no reps does too. The grammar takes most of these first. The cost is a "Didn't catch that." where Claude might have helped.
- L3: `isTraining` lets any phrase with "N for M" or "N reps" past both walls, for example "paid 20 for 2 tickets". A spend word with set notation is rare; a test row would pin the choice.
