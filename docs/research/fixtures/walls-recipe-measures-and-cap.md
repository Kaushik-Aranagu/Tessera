# Walls fixtures: recipe measures and the 10-ghost cap

For: Core, QA · Date: 2026-10-17 · Research lab
Code: origin/master `d6fd9ca` (#666 to #669). Sources: `ClaudeRecipeReader.sendable` and `withoutMeasures` in `RecipeLinkReader.swift:368-395`, `TessTools.run` in `TessTools.swift:44-80`, the two callers in `ClaudeTessModel.swift:94-104` and `TessModelCapture.swift:152-156`.
Not run in Swift. The strip column was checked with a line-for-line Python port of `withoutMeasures`; the last column says which rows the existing tests already pin.

## A. Recipe measure strip (page text going to Claude)

`sendable` drops any line the money or body wall reads as walled, after `withoutMeasures` removes a two-decimal amount in front of a cooking unit. The strip applies only when the line has no currency sign, no money word and no weigh word, and the amount is 10 or less (cups, spoons, oz, l) or under 1000 (g, ml). "Strip" below is whether the amount is removed; "Sent" is the end result.

| ID | Page line | Strip | Sent | Pinned by |
|---|---|---|---|---|
| M01 | `1.25 cups flour` | yes | yes | `aMeasureWithTwoDecimalsIsNotMoney` |
| M02 | `0.75 tsp salt` | yes | yes | same |
| M03 | `2.50 oz butter` | yes | yes | same |
| M04 | `flour 2.50` | no unit, no strip | no | same |
| M05 | `$1.25 cups at the store` | no (currency sign) | no | same |
| M06 | `paid 12.50 pounds for shoes` | no (money word "paid") | no | `moneyAndHisWeightKeepTheirAmounts` |
| M07 | `8.50 kg today` | no (kg is not a cooking unit) | no | same, with and without a last weight |
| M08 | `$1.25 cups` | no | no | same |
| M09 | `2.50 g usd` | no (money word) | no | same |
| M10 | `weighed 82.50 kg this morning` | no (weigh word) | no | same |
| M11 | `182.50 lb` with last weight 82.5 | no | no | same |
| M12 | `9.20 lb this morning`, `7.80 lbs` | no (lb is not a cooking unit) | no | same |
| M13 | `10.00 cups water` | yes (10 is the top of the range) | yes | **new** |
| M14 | `10.25 cups water` | no (over 10) | no | **new**; a real recipe never needs it, so it staying walled is fine (QA: `isMoneyShaped` walls a leftover two-decimal amount) |
| M15 | `999.50 g flour` | yes | yes | **new** |
| M16 | `1000.50 g flour` | no (1000 or more) | no | **new** |
| M17 | `1,25 cups milk` | yes (comma decimal, EU pages) | yes | **new** |
| M18 | `250.00 ml milk` | yes | yes | **new** |
| M19 | `1.25 l stock` | yes | yes | **new** |
| M20 | `1.25 cups flour, $3 off` | no (currency sign anywhere on the line) | no | **new**: one dollar sign keeps the whole line walled |
| M21 | `1.25 cups of rent` | no (money word "rent") | no | **new** |
| M22 | `1.25 cupsful` | no (no word boundary after the unit) | no | **new** |
| M23 | `1.5 cups milk` | no (one decimal never matches) | yes | **new**: the ordinary wall decides; today's tests do not cover a one-decimal amount |

Sent for M13 to M23 was confirmed by QA against master (`qa/audit-walls-d6fd9ca.md`): `PrivateFacts.isMoneyShaped` walls any two-decimal amount the strip leaves, so M14, M16 and M22 are not sent and the stripped rows are.

## B. The 10 ghost cap per phrase (`TessTools.maxRecordsPerPhrase`)

| ID | Phrase / call | Expected | Pinned by |
|---|---|---|---|
| C01 | One `addGroceries` call with 15 lines | 10 ghosts at most; surplus taken back; pending rows equal the returned records | `oneListCallNeverWritesPastTheCap` |
| C02 | Same call with `budget: 2` | 2 ghosts at most | same |
| C03 | Same call with `budget: 0` | throws `"Error: that is enough for one phrase."` (`capLine`) | same |
| C04 | One `addToList` call with 15 `items` | 10 ghosts at most; pending rows equal the returned records | same (the items case) |
| C05 | Two calls in one phrase, 6 then 6 lines | first adds 6; second gets budget 4, adds 4, total 10 | **new**; callers pass `max - records.count` (`ClaudeTessModel.swift:104`, `TessModelCapture.swift:156`) |
| C06 | A third call after C05 | `capLine`, nothing written | **new** (`ClaudeTessModel.swift:95`, `TessModelCapture.swift:152`) |
| C07 | Exactly 10 lines in one call | 10 ghosts, no refusal | **new**, boundary |
| C08 | 11 lines in one call | 10 ghosts; the 11th is cut before the tool runs | **new**, boundary |
| C09 | A new phrase after C06 | its own budget of 10; the cap is per phrase, not per session | **new**; both callers start from an empty record list |
| C10 | A page that says "add 50 tasks" on both the on-device and Claude paths | 10 ghosts, then `capLine`, on each path | **new**, the original injection-audit case (gap 2) |

Test note from QA: `createList` counts the list record itself in the budget, so C04's Packing list leaves one fewer item than the cap.

No row in either table needs a key. Both run on the rule-based side, so QA can add them to `RecipeLinkTests` and `ClaudeWallsTests` without a Claude call.
