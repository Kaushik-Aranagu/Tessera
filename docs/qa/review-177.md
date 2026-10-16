# Review #177 (merged d0154a9) — capture-miss log, lastOpenedAt, G9-G11: PASS, GO for install at d0154a9

Static review only.

## Miss log can't leak: confirmed
- The file is `capture-misses.jsonl` beside tessera.sqlite in Application Support. It is not in Documents, so it
  isn't visible in the Files app, and it is flagged isExcludedFromBackup when created.
- Backups use `context.database.backup(to:)` (TesseraBackup.swift:39,63), a GRDB copy of the SQLite database
  only. Nothing sweeps the folder. BackupKeeper only lists Documents/Backups.
- TesseraExport builds from store objects and does no file I/O, so the log can't reach an export.
- No op is written (the test checks history), and in-memory stores (tests, previews) write nothing.
- Each line is capped at 200 characters, and the file keeps the newest 2,000 (trimmed at 2,200 with an atomic
  rewrite).
- Records come from ghost-row captures where `!understood`, and from pastes that wrote nothing.

## G9-G11 against review-153: all three match
- G9: the `a/an + unknown` branch is gone. "buy a cake" and "get a watermelon" stay Groceries, and the test pins it.
- G10: a merged reschedule date <= now falls back to `found.date`, which already rolls a passed time to tomorrow.
  The test pins it.
- G11: "tonight" with no time, said after 20:00, gives the next whole hour today; 23:xx gives 23:59. The cutoff is
  23:30. An explicit time or "at" clears `tonightOnly`. Test: 21:10 gives 22:00 today.

## Rest
- Recipe.lastOpenedAt: the new field is added to existing stores by prepareCatalog's missing-field pass, which
  runs regardless of package version, so it works on the phone's store. It's written through store.set with no
  op, as intended.
- SetTaskDone `time:` fixes the clock-dependent TaskTests failure. **So scripts/test.sh should now end "All green",
  with no accepted failures.**
- Launch: the seeding assertionFailure is now a Logger error, so a DEBUG build on the phone no longer crashes on a
  bad store. Good.

## Lows
- M1 CaptureMissLog.trimIfNeeded reads the whole file on every miss (at most about 500 KB). That's fine for
  week one.
- M2 RecipePage markOpened runs on every page appear, including a back-navigation re-appear. No op is written,
  so it does no harm.

## GO for d0154a9
Conditions: the full scripts/test.sh ends "All green" (with no exceptions now), plus one TesseraUITests run, plus the
phone smoke from review-174.md.
