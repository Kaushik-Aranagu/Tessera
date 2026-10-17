# Cook duration median fixtures (side line helpers, section 4)

Source rulings: Kitchen (the COOKS list shows every finished cook; the median cutoff is 6 hours, or twice the recipe's own `totalMinutes` when that is 6 hours or more) and decision 2:38 (overnight oats). Owner of the rule text: AI architecture, `docs/ai/side-line-helpers.md` section 4. Owner of the test: whoever lands the helper.

Times are cook durations. "Nil" means no median line is shown.

| # | Recipe totalMinutes | Cooks | Expected median | Test name |
|---|---|---|---|---|
| CD1 | 15 (pasta) | 12 min, 14 min, 18 min | 14 min | `medianOfThreeCooks` |
| CD2 | 15 | 12 min | nil (under 2 cooks) | `noMedianUnderTwoCooks` |
| CD3 | 15 | 12 min, 18 min | 15 min (two cooks give the mean) | `twoCooksGiveTheMean` |
| CD4 | 15 | 12 min, 14 min, 7 h | 13 min (7 h is past the 6 hour cutoff and is left out; two left give the mean) | `cookPastCutoffIsLeftOutOfTheMedian` |
| CD5 | 480 (overnight oats) | 6 h 55 min, 7 h 10 min, 6 h 40 min | 6 h 55 min, not nil | `overnightRecipeCooksSurviveTheCutoff` |
| CD6 | 480 | 6 h 55 min, 17 h | 6 h 55 min (17 h is past twice the total, 16 h, and is left out; one left is under 2 cooks, so nil) | `overnightCutoffIsTwiceTheTotal` |
| CD7 | 360 (exactly 6 h) | 6 h 10 min, 6 h 30 min | 6 h 20 min (cutoff is twice 6 h, so both count) | `totalOfExactlySixHoursUsesTheDoubleCutoff` |
| CD8 | 359 | 6 h 10 min, 6 h 30 min | nil (cutoff stays 6 h, both are past it) | `totalJustUnderSixHoursKeepsTheFlatCutoff` |
| CD9 | 15 | two cooks shared by one rows source | counts once | `sharedRowsCountOnce` |

Notes:
- CD6 and CD8 both end in nil by design. If AI architecture wants a different edge, rule it and I will change the row.
- The COOKS list itself is not cut by the cutoff: every finished cook shows. Only the median uses the cutoff.
- Placeholders only. No private data in any row.
