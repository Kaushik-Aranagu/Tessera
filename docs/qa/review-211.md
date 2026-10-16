# Review #211: backups by his 4 AM day (157f882, head 8dcfd23)

Core. 6 files, +251/-26. I checked it against research/backup-logical-day.md (rules 1-6, T1-T12). This is a static review: there's no Swift toolchain here, so I traced the code by hand rather than running it.

**Verdict: PASS.** All 12 timelines trace to the expected files. Three items are lows or phone checks; none blocks.

## Timelines (writeRolling, TesseraBackup.swift:121-157)
**Rule 1, the file name:** `TesseraDay(calendar:).day(of: now)` sets the key, formatted y-m-d in the calendar passed in. BackupKeeper passes the default, which is `.current`, so the name follows whatever zone the phone is in.

| | Result | How |
|---|---|---|
| T1 | ✓ | The day's file exists and it's past 04:00, so it skips. Tested. |
| T2 | ✓ | Between 00:00 and 04:00, an existing key file is replaced through `replaceItemAt`. At 04:00 a new key starts. Tested, including the copy's `createdAt`. |
| T3 | ✓ | No backfill, because there's no loop over days. No test, but it's trivial. |
| T4 | ✓ | A first copy at 01:10 is named for the 19th (tested). BackupCopy.local says "today" and "yesterday" by `TesseraDay`. |
| T5 | ✓ | A 10:10 background after a restore skips. A `restored-at` marker beside the store goes into every later copy's `backupInfo.restoredAt`. `inspect` reads it and handles older copies, which have no column. The 3 newest Before-restore copies are kept, and the one just written is never dropped. Tested. |
| T6 / T7 | ✓ | `hour < 4` reads wall-clock time, so both fall-back 01:30s and the spring-forward 03:10 replace the previous day. I checked the test's epochs: 01:30 PDT and 01:30 PST on 1 Nov. |
| T8 | ✓ | The key follows the zone in force. Late-night replaces happen both in New York and back home. Tested by swapping the calendar between calls. |
| T9 | ✓ | Clock behind: it writes only a missing day, without pruning or replacing (8 files). Back on time, the 7 newest stay. A late-night run behind the newest copy writes nothing. Tested. |
| T10 | ✓ | The 7 newest days by name, gaps allowed. The file just written is never pruned. Before-restore copies and `.partial` files aren't counted. Tested with gaps. |
| T11 | ✓ (code) | A saved bookmark that won't resolve is now a folder failure, and Backups says "The folder you chose can't be reached, so copies are only on this iPhone. Choose it again." The app-side test is Core's follow-up, as agreed. |
| T12 | ✓ | A stray `.partial` from any day is removed on the next write, and replacement is atomic. Tested. |

The existing `rollingKeepsOnePerDayAndSeven` now uses a fixed LA calendar, as Research asked. The move-aside folder name gets a `-2`, `-3` suffix on a same-second collision.

## Lows and phone checks
- **B8 (low):** `forget()` (BackupKeeper.swift) doesn't clear the folder failure.
  - If he stops using a folder that had a failure, Backups keeps showing "The folder you chose can't be reached… Choose it again" until he next leaves the app. The `folder == nil` branch now reads every remembered folder failure that way.
  - Fix: clear the `.folder` failure in `forget()`.
- **B9 (phone check, not verified):** a folder deleted in Files may still resolve.
  - iCloud Drive moves a deleted folder to Recently Deleted, and the bookmark can still resolve to it. Copies would then land in the trash silently, and Backups would look fine.
  - Research's on-phone T11 steps cover this: delete Tessera-QA in Files, then leave the app. Check whether the line appears or a file shows up in Recently Deleted.
  - If it lands in the trash, refuse a resolved URL inside a trash or Recently Deleted container.
- **B10 (low, as specified):** a clock set *forward* suspends pruning and late-night replace.
  - Example: a copy dated 1 Dec, then the clock goes back to automatic in October. Every write is then "behind" the newest copy until real time passes it. Copies pile up (one a day) and the late tail isn't refreshed.
  - This follows rule 5, so I'm only noting it. A cap (say, ignore a newest `createdAt` more than 2 days ahead) would bound it.
- **Cost note:** every write opens the newest copy (`inspect`) to read its `createdAt`. That's cheap locally. For an iCloud placeholder that isn't downloaded, it fails open (`try?`): not behind.
- `replaceItemAt` on a File Provider folder (iCloud Drive) isn't verified on the phone. If it throws, the old copy stays, a folder failure is noted, and the partial is cleaned on the next write. Safe.

## Research's open questions, as built
| Question | Built as |
|---|---|
| Q1 | Replace only from 00:00 to 04:00 |
| Q3 | restoredAt marker added |
| Q4 | Write-missing-only |
| Q5 | No backfill |
| Q6 | Keep 3 Before-restore copies |

Q2 (Siri, Lock Screen and widget writes don't trigger a copy) is still open.
