# QA review: #638 (Core, wall follow-ups after #627)

Head: e971db8. Merge-tree clean on master e149e66. Real delta vs master: 12 files, +84/-24 (three-dot shows #627/#637 history; read two-dot).

## Verdict: FIX FIRST (1 medium), rest PASS

### Medium: exerciseWords can erase a real weigh-in
BodyWeight.swift exerciseWords adds every word (>2 letters) of every exercise name to the set that makes kilograms(in:) return nil. The seeded library has "Good Morning" and "BB Good Morning" (ExerciseLibrary.swift), so "morning" is an exercise word. Then "82 kg this morning", the standard weigh-in phrasing, hits `guard !words.contains(where: exercises.contains)` and returns nil. lastKg skips every such note, falls back to an older weigh-in or nil, and the bare-number wall ("how's 76 looking?") loses its baseline. Privacy degradation, silent.
Fix: build the exercise set minus PrivateFacts.dayWords, bodyWords and bodyUnits (and "weigh*" words). Add a test: seed the library, log private note "82 kg this morning", expect lastKg == 82. Same cheap guard covers liftWords "set", "clean", "press", "row" beside a real weigh word; low, optional: a weigh word ("weigh", "weighed", "weight") plus a unit should win over a lift word only if the lift word is not adjacent to the number.

### Passes
- Receipt by stored title: TessCaptureEngine and CreateTaskIntent now test only the stored title (label or still private). Raw-title check dropped safely: secret goes to SecretWords.title, walled amounts to EngineWall outcomes first. S18 case ("refill lexapro 40 dollars friday") asserted in SiriParityTests.
- Medicine: EngineWall.health drops startsAt, so medicine is a private task with or without a time. Test updated to two "Private task".
- isCountNoun: >3 letters, plural, not body word/unit/day word. "80 stickers", "order 76 envelopes" pass; "82.4 good?" still walled; "this", "pounds", "kilos" are exempt via dayWords and bodyUnits.
- 0-set workouts filtered in daySummaries; V1GapTests logs a set first and adds the 0-set test. Check: the filter runs after the cache key; fine.
- ReviewWeek.dayName pinned en_US_POSIX; list summary thing-first ("Private item, added to Errands"), receipts unchanged.

### Lows (not blocking)
1. isCountNoun treats any 4+ letter word ending in s as a count: "is 82 less?" or "82 gross" would skip the bare-weight wall. Rare; tighten to a noun list only if it shows up.
2. Wrapped comment in TessCaptureEngine ("its amount\n// gone") reads oddly; reflow.
3. ReviewWeek.dayName has no test; add one with a non-US locale.

## Re-verify at 9cc8a7a5: PASS
Medium closed: exerciseNames matches whole phrases and drops names made only of day/body/weigh words (plus good, bb, db, kb), so "Good Morning" no longer hides "82 kg this morning"; weighWords, ClassResolver.isSubclass and ExerciseLibraryInstaller.install all exist. Test seeds the library, logs the morning weigh-in (lastKg 82), a "romanian deadlift 100 kg" note is skipped, "how's 76 looking?" and "is 82 less?" stay walled. Lows closed: notNouns list, comment reflowed, dayName via TesseraDay.weekdayName with a fr_FR calendar test. Low (new, optional): fixed notNouns list still lets other non-noun s-words through; fine until one shows up. Merge-tree clean.
