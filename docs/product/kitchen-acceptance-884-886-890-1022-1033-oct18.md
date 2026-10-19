# Kitchen acceptance of #884, #886, #890, #1022, #1033: static read

Static only, against origin/master fdc75400 (nothing built or run). Diffs read with `git diff <merge>^1 <merge>`; "covering test" means a test whose assertion I read, not one I ran. Merge SHAs: #884 2f839063, #890 278f796e, #886 7cb1a668, #1022 8eac04b0, #1033 e8509b28. All five are TesseraCore or PantryLedger changes; none adds a new screen.

## Per PR

| PR | Clause | Verdict | Where | Covering test |
|---|---|---|---|---|
| #884 | Phrases past 600 characters never go to Claude; answer "That's too long to send. Say it shorter." as a refusal, not logged as a miss (G423 cap) | PASS (engine) | ClaudeTessModel.swift new `maxPhraseCharacters` guard | ClaudeRouteTests (new, 27 lines) |
| #884 | A phrase about a timer, or any phrase while a cook runs, is read on the phone or not at all (G423 cook gate) | PASS (engine) | TessModel.swift:83-95 `TessRouter.staysOnPhone` (the router and the offline inbox drain both ask it; QA low on #1069) | ClaudeRouteTests |
| #884 | "dinner at 7.30" is a clock, not money, unless a money word is present; "eleven stone four" is a body weight | PASS | PrivateFacts.swift `clockless`, `spokenNumbers` | MoneyWallTests (+66 lines) |
| #886 | "30-Minute Dal", "7 Layer Dip", "3 eggs benedict" stay titles; "1. Preheat", "200g flour", "2 Tbsp butter" are not titles (G94) | PASS | RecipeParser.swift `startsWithAmount` | RecipeTests (+36 lines) |
| #890 | One private-title check for receipts, UNDO, Tess lines, screens and export (G105); "Rent car" stays raw, "Dr Pepper" and "blood orange" stay raw | PASS | ObjectPrivacy.swift `isPrivateTitle`, `titleWords`; PrivateWords.swift now delegates | PrivacyParityTests (+54), PrivateWordsTests |
| #890 | Groceries, Lists and capture "already on Groceries" all ask `isPrivateWord` | PASS | Groceries.swift, Lists.swift, TessCaptureEngine.swift | PrivacyParityTests |
| #1033 | A private cook's step lines, timer alert and "Nth time this month" read "Private recipe" / "Timer" (G139 cook half) | PASS (engine) | Cooking.swift `isPrivateCook`, `stepLine`; TimerAlerts.swift `hidesLabel`; NowPicker.swift | TimerAlertsTests (+66) |
| #1022 | A private cook's ingredients mask in Pantry (G139, G184); EditNote runs the same check as CreateNote (G607) | PASS (code); screen not walked | PantryLedger.swift, Notes.swift, ObjectPrivacy.swift | PantryLedgerTests (+17), PrivacyParityTests (+83) |

## What this closes and what it does not

- G94, G105 (code), G139 and G184 (code), G423 (cap and cook gate), G607 are in code on master. The index still says CLOSED IN CODE: none; that line is stale for these rows and Research's next index pass should flip them.
- The 600-character refusal and the cook gate exist only in the engine. No screen shows the refusal line yet; the Ask slot (G434) still reads its line and UNDO from two places.
- Still open from the index and not touched by these five: G406 (three private-text checks: PrivateWords.swift:21, ObjectPrivacy.swift:91, Notes.swift:132; #890 points PrivateWords at the one function, and #1022 changed Notes.swift, but I did not check that the Notes check now shares it), G196 (export leaks Pantry state) and the notification list G451-G460.
- Not run: no build, no test run on the simulator. The Mac is locked, so these rows stay static until a Mac lead runs test.sh on the exact head.
