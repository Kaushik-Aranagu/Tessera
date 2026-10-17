# Pantry fixtures against sheet 78

For: Kitchen lead, Core, Builder B
Date: 2026-10-17 (Research lab)
Inputs: Design's `pantry.md` (sheet 78) and `builder-briefs-77-78.md` at commit 9190a48, `research/fixtures/pantry-sheet-77.md` (BV, 38 rows), `product/pantry-acceptance.md`.

Sheet 77 itself is still unread. Sheet 78 is the Pantry sheet and answers every [S77?] and [S77 side] row. Anything the sheet does not give is marked **unknown**. Pantry facts never leave the phone and money never goes to Claude, so "Leaves phone" is **nothing** on every row. Owner: Builder B for the screens, index and receipts; Core for state, `lastBoughtAt`, the shared dry-run count and the side's lines through the walls (the briefs give Core the model work). Times: lowercase 12-hour, no "at" before a time.

## 1. Reconciliation of BV rows

| BV row | Verdict | What sheet 78 shows (exact line or label) |
|---|---|---|
| W1 | change | Hero "Nothing out" (known, none out or low), not "0 out, 0 low". In things are not listed on the front: no "milk, bought Sat" there. "bought Sat" moves to the side's lines, and only out and low lines appear on the side. Engine half (state in, `lastBoughtAt`) keeps. |
| W3 | keep | Hero "2 out, 3 low" in digits. The out and low lines sit under OUT and LOW, one Body line per thing. |
| W8 | change | The cycle is on the front: tap the state word, in, low, out, in. Receipt "Limes, in." (thing first), UNDO 10 s (a change). Ingredient page copy: unknown. |
| W9 | change | Left swipe on an out or low line adds a ghost row. Receipt "Milk, in Groceries." with UNDO, not "Cilantro, on Groceries." The line stays on the page. UNDO length not stated; assumed 4 s (a new add). |
| W10 | keep, copy unknown | Hero stays digits. "0 out, 3 low" is not drawn; the sheet gives only "Nothing out" for none out or low. Assumed "0 out, 3 low". |
| W11 | change | Milk "bought Sat" is not on the front. In stays off the page. USUALLY HAVE may still name milk. |
| W13 | change | Label is USUALLY HAVE (not USUALLY), the third group after OUT and LOW. Names in ink. A tap on a name joins Groceries ("Milk, in Groceries.", UNDO). |
| W14 | change | Up to three names as is; from four "Rice, coffee and 2 more" (two named, then the count; "and 2 more" at 55%). Cap 4 stays. For five due, assumed the cap shows four, so the same text. |
| W15 | keep | The key text ADD 6 TO GROCERIES is the same dry run as the recipe peek. Receipt for the recipe key is not on this sheet: unknown. |
| Z1 | change | Hero "Nothing yet", then "Clear a shop or finish a cook and this fills in." at 55%. Tess: `Say "out of milk" and I'll keep it.` (not "nothing known yet"). |
| Z6 | keep | "Never a notification, a badge, a Home offer or 'running out'." |
| Z8 | keep | "no nutrition appears anywhere on Pantry." |
| N1 | keep | "no money or body fact appears here." |
| N4 | change | Side line value is "bought Sat" or "bought Tue" for out and low lines only. Chicken shows one date, never "6 lb". Which date when bought three times: unknown, assumed the newest `lastBoughtAt`. |
| N5 | change | Rice is in, so it is on neither the front nor the side. No "7 kg", no "3 kg left". |
| N12 | keep | Hero counts are of states ("4 out, 2 low"), and "6 to buy" is the key's own line count, not an amount. |
| N13 | change | One swipe adds one line ("Milk, in Groceries."). The side key add reads "Pantry, 6 added." Assumed "Pantry, 3 added." for three lines; no weight or money in either. |
| N6, N9 to N11, N14 | no change | Not on sheet 78. |
| W5 to W7, W12, N2, N3 | no change | Not on sheet 78. |

## 2. New rows for what sheet 78 draws

| # | Input | Expected line | Swift Testing name | Owner |
|---|---|---|---|---|
| P1 | 4 out, 2 low, last shop Saturday | Context "since Saturday's shop" (21 characters); hero "4 out, 2 low" | `frontShowsContextAndCountsHero` | Builder B |
| P2 | Known, none out or low | Hero "Nothing out" | `frontQuietHeroNothingOut` | Builder B |
| P3 | Nothing known | Hero "Nothing yet" | `frontQuietHeroNothingYet` | Builder B |
| P4 | Groups present | Order OUT, LOW, USUALLY HAVE; ring on out lines only; no cards or pills; nothing red | `frontGroupsOrderAndRingOnOutOnly` | Builder B |
| P5 | Limes out, tap word | "Limes, in."; one op; digits change, no count-up; line leaves the page | `stateTapReceiptNamesThingFirstAndLineLeaves` | Builder B |
| P6 | Tap a low line to out | Line moves to OUT group; hero updates | `stateTapMovesLineToGroup` | Builder B |
| P7 | UNDO after a tap | Row returns; Tess's line "Tacos took the cilantro and limes." returns; UNDO 10 s | `undoRestoresRowAndTessLine` | Builder B |
| P8 | Tap a name | Opens its Ingredient page | `tapNameOpensIngredientPage` | Builder B |
| P9 | Left swipe on USUALLY HAVE name | Skips it until its next gap | `usuallySwipeSkipsUntilNextGap` | Builder B |
| P10 | Tap USUALLY HAVE name "Milk" | "Milk, in Groceries." with UNDO | `usuallyTapJoinsGroceries` | Builder B |
| P11 | Last cook used cilantro and limes | Tess line only in 736 to 820: "Tacos took the cilantro and limes." | `frontTessLineIsLastCookFact` | Builder B |
| P12 | 4 out, 2 low | Side glance: label OUT AND LOW, "4" with "out", "2 low", "6 to buy", foot ALL OF THEM | `sideGlanceShowsCountsAndToBuy` | Builder B |
| P13 | Full side | Context "6 to buy" with PANTRY at right; OUT lines then LOW lines, value "bought Sat" or "bought Tue"; one key ADD 6 TO GROCERIES; no state words | `sideFullOrderAndKey` | Builder B |
| P14 | Tap the key | Receipt "Pantry, 6 added.", UNDO 4 s (10 s under VoiceOver) | `sideKeyAddsAllOutAndLow` | Builder B |
| P15 | Key number | Key N equals glance "to buy" (out plus low lines) | `sideKeyCountEqualsGlanceToBuy` | Builder B and Core |
| P16 | 0 out, 0 low | Context "Nothing out.", no key | `sideAtZeroHasNoKey` | Builder B |
| P17 | 3 or more buys of milk | Tess line (glance and full, same): "You buy milk about every 7 days." | `sideTessRhythmAfterThreeBuys` | Builder B |
| P18 | Fewer than 3 buys | Tess side line empty | `sideTessRhythmEmptyBeforeThreeBuys` | Builder B |
| P19 | Reduce Motion | 150 ms crossfade into the side; `.selection` once at the full side, none at the glance | `sideReduceMotionCrossfadeAndSelection` | Builder B |
| P20 | Empty pantry | Tess line `Say "out of milk" and I'll keep it.` | `emptyStateTessLine` | Builder B |
| P21 | Private note exists | Pantry shows nothing of it; a private note elsewhere is only "Private note" | `pantryShowsNoPrivateNote` | Builder B |
| P22 | Index with 4 out, 2 low | Five rows REVIEW, TODAY, TRAINING, KITCHEN, PANTRY; Pantry line "4 out, 2 low" (32 characters or fewer) | `indexPantryRowIsHero` | Builder B |
| P23 | Index quiet | "Nothing out" or "Nothing yet" | `indexPantryRowQuietForms` | Builder B |
| P24 | Side lines built | Names only through the walls; unknown how it is enforced | `sideLinesCarryNamesOnly` | Core |
| P25 | Dynamic Type largest | One column, nothing under 16 pt | `frontDynamicTypeOneColumn` | Builder B |

## 3. Conflicts with standing rulings, and what I assumed

1. **Time with "at".** Sheet 78 keeps the index line "Tacos at 7 pm" (thing plus time, copy-pass rule 6), while the briefs say never "at 7 pm" before a time. Assumed: no Pantry row asserts the KITCHEN line; Kitchen lead to rule.
2. **Never sums.** "6 to buy" and "4 out, 2 low" are counts of lines and states. Assumed allowed as counts, not amounts; no amount, weight, money or nutrition sum anywhere. "Every 7 days" is a rhythm, not a total.
3. **Count rolls 260 ms** (briefs, Builder B acceptance) versus "the digits just change (nothing counts up)" (sheet). Assumed the sheet wins, as the briefs state.
4. **Receipts.** BV used "Milk, on Groceries."; sheet uses "Milk, in Groceries." Both are thing-first. Assumed the sheet.
5. **Opening and back word.** `pantry-acceptance.md` opens Pantry from KITCHEN with back word KITCHEN; sheet 78 makes it a tab-level area with no back word. Assumed the sheet.
6. **"best".** The sheet says no best on Pantry; no row uses "best" or "record".
7. **Lowercase 12-hour am/pm.** No time shows on Pantry; only "bought Sat" and "bought Tue" appear. Nothing to assume.
8. **Em-dashes.** None in the sheet or briefs as read. Rows here use none.
9. **Label amounts (N7, N8)** stay PARKED; sheet 78 shows no label amount.
10. **Sheet number.** The sheet itself notes the 5:47 PM decision called Pantry 78 and the sides 77; section 6 of `kitchen-sides-acceptance.md` was not on master, so the side follows the coordinator's summary.
