# Review: #504 core/best-word (Core 0w)

QA, Oct 16 2026, ~1:20 PM PT. Head **7f37de8**, one commit, merges cleanly onto master. Static review.

## Verdict: PASS
- DayStory.swift:225 writes ", best" instead of ", PR" on the top set of a workout that beat a best. The VoiceOver doc example is updated (:39).
- ReviewWeek.swift:174-175 matches on ", best." so Review still finds the day's best line. The result reads the same as before ("Bench best").
- DayStoryTests and WeekFactsTests expect ", best." everywhere.
- Grep at 7f37de8: no "PR" string reaches the screen from App, Features or TesseraCore sources. The four hits left are code comments: TrainingLedger.swift:81, SystemCatalog.swift:160, DayStory.swift:536, WorkoutSession+Prefill.swift:41. ReviewWeek.swift:141 still also accepts "record" and " pr" when it reads lines. That only widens what it reads and shows nothing.
- No stored text changes. The Day log is built when it's shown, so older days read "best" too.

## What he sees (for Design)
- Day log workout line: "Push A, 40 min. Bench 80 × 8, best." (was ", PR."). VoiceOver: "... Bench 80 by 8, best."
- Review's week day line is unchanged ("Bench best").
