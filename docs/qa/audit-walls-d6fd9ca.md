# Audit: walls and gates on every Claude path, master d6fd9cac

Static, end to end. The five files that talk to Claude (matched on api.anthropic.com, ClaudeKeyCheck.base, x-api-key and anthropic-version, non-test Swift) are ClaudeKey, ClaudeTessModel, HomeDoneWording, PlanWording and RecipeLinkReader. The memory screen, grammar and lists make no Claude call.

## Redirects
All five Claude requests pass `NoRedirects.shared` (ClaudeKey.swift:301, ClaudeTessModel.swift:262, HomeDoneWording.swift:267, PlanWording.swift:605, RecipeLinkReader.swift:466). The only `delegate: redirects` is the recipe page fetch (RecipeLinkReader.swift:197), which carries no key. HouseRulesTests enforces both.

## Per path
| Path | Walled before the call | asksClaude gate | Verdict |
|---|---|---|---|
| Capture (ClaudeTessModel) | key shape, secret words, money and body (PrivateFacts) in the router and again in `run`; the pack sends only the exercise name (walled via HomeDonePack.isWalled) and the last set; Siri/Shortcuts never reach it; tool answers use the countable allow-list; per-phrase ghost budget | `isAvailable` and `run` both check `sendsMisses()`, wired to asksClaude (AppModel.swift:197) | Clean. Place, care and people words are not walled here (see note 1) |
| Recipe reader | per line: secret cut, key shape, PrivateFacts (with the measure strip fixed in #669); output check drops unsafe replies | `allowed()` is asksClaude | Clean |
| Home done words | HomeDonePack.isWalled: health, money, place, care and people words, secrets, key shape, body, steering phrases; pack fields are counts, bests and names only; line check C1-C15 on the reply | `allowed()` is asksClaude, plus 80 percent of the cap and 40 a day | Clean |
| Plan wording | secret words, money and body on task titles; events go as "busy" | `allowed()` is asksClaude, and `planWordingReady` is false (AppModel.swift:64) so no call is made today | **FIX before it is switched on** |
| Key check | fixed test body, no user text | user action in Settings, ledger-recorded | Clean; Result carries no part of the key (#660) |

## FIX (before Plan my day's Claude wording is turned on)
1. `PlanPack.isPrivate` (TesseraCore/Sources/TesseraTess/PlanWording.swift:37) checks only secret words and PrivateFacts. A task title such as "Physio at 5", "Call mom about the lawyer", "Dentist" or "Pay Dr Lee" goes to Claude verbatim. Use the same wall as the Home pack (`HomeDonePack.isWalled`, which adds the health, money, place, care and people words) in `isPrivate`, and add the rows to PlanWordingTests. Not live today because of `planWordingReady`.

## Notes (not FIX)
1. Capture phrases that name a person or place ("call mom at 7", "meet Dr Lee at 3") are sent when the grammar misses, by design: the ruling is money, body and secrets. If Product wants care and people words walled there too, the check belongs in `TessRouter` next to PrivateFacts (TessModel.swift:91). Needs a Product call.
2. `TessToolError("\(error)")` (TessTools.swift:107) puts an arbitrary engine error's description into a tool result sent to Claude. Today's errors echo the model's own arguments; worth an explicit allow-list if an error ever carries a title.
3. Demo flags (-demo, -fakeClaudeKey) are simulator-only (LaunchFlags) and the Home cache is off under them; with a real key saved in the simulator, a demo run could still make a Claude call. Not a phone risk.

## Research #670 rows (walls-recipe-measures-and-cap.md), traced against master d6fd9cac
Rule behind the table: `PrivateFacts.isMoneyShaped` walls any word that is a two-decimal amount (`\d+\.\d{2}` or `\d+,\d{2}`), so an amount the strip leaves in place is walled; an amount the strip removes leaves only the unit and the rest of the line.

Section A, the open rows (Sent column):
| Row | Result I get | Matches table? |
|---|---|---|
| M13 `10.00 cups water` | strips to "cups water"; no amount, no body fact: **sent** | yes |
| M14 `10.25 cups water` | no strip (over 10); "10.25" is a two-decimal amount: **not sent** | yes (the note's "expected to be sent" is wrong for this row) |
| M15 `999.50 g flour` | strips (under 1000) to "g flour": **sent** | yes |
| M16 `1000.50 g flour` | no strip; two-decimal amount: **not sent** | the note is wrong for this row |
| M17 `1,25 cups milk` | strips (comma decimal) to "cups milk": **sent** | yes |
| M18 `250.00 ml milk` | strips to "ml milk": **sent** | yes |
| M19 `1.25 l stock` | strips to "l stock" (the alternation backtracks correctly for "liters" and "grams"): **sent** | yes |
| M22 `1.25 cupsful` | no strip (no word boundary after "cups"); two-decimal amount: **not sent** | the note is wrong for this row |
| M23 `1.5 cups milk` | one decimal never matches; "cups" is an otherUnit so no bare weight; last body branch fails on "cups milk": **sent** | yes |
Closed rows M01 to M12, M20 and M21 also trace as the table says ("rent" is in TessMemoryScreen.moneyWords, so M21's guard fires).

**Correction for Research:** the sentence under table A says M13 to M19, M22 and M23 are expected to be sent. M14, M16 and M22 are **not** sent (they stay walled by the two-decimal rule); the other seven are sent. The Sent column should read: M14 no, M16 no, M22 no, M13/M15/M17/M18/M19/M23 yes.

Section B, C01 to C10: all trace. C05 gets budget 10 then 4 (items cut to 4), C06 hits the loop guard on both paths, C07 and C08 are exact (a call with 10 is untouched, 11 is cut to 10), C09 is a fresh budget in both callers, C10 stops at 10 then `capLine` on each path (createTask has no array, so the loop guard does it). C03 throws `TessToolError("Error: that is enough for one phrase.")`. One caveat for the test author: `createList` with items counts the list record itself, so a 10-item list returns 10 records with the last item taken back.
