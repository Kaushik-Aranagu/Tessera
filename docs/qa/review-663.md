# Review #663 (Builder B: no "at" before a time)

Head 23629b6c, merge-tree clean against master. Static review. Design is checking the spoken forms.

**Verdict: QA PASS at 23629b6c.**

- Touches HomePlan hero ("3 tasks, Push A, 6 pm"), NowPage.contextLine ("next, half past five"), SpokenTime.when ("tonight, nine", "tomorrow, half past seven", "Friday, nine"). Four files, 12 lines of source.
- Whole-tree grep for another "at" before a clock in strings (` at \(`, "tomorrow at", "evening at", digit-am-pm): none left in source or tests. Existing assertions were updated; nothing else expected the old forms.
- The new test covers contextLine and three `when` forms with both a " at " check and an `\bat \d` check. It does not cover the HomePlan hero string; low, add one assert on PlanWords.
- Lows: stale comments mention the old copy at HomeSpatialView.swift:646 ("this evening at six") and NowPage.swift:79 ("Push A at 7 pm"). Cosmetic. The "this evening, six" form reads like a list item; Product ruled it, Design is reviewing it.
