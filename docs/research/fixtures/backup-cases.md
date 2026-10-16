# Backup cases (Core item 0e)

For: Core (tests), QA (review). Research lab, Product board item M, 2026-10-16, read at origin/master e10b698 (12:17 PM PT).
Sources on master: `Notes.swift`, `SecretWords.swift`, `ClaudeKeyGuard.swift`, `TessModel.swift`, `TesseraBackup.swift`,
`TesseraSchema.swift`, `TesseraDatabaseSchema.swift`, `SystemCatalog.swift`, `TessMemory.swift`, `BackupKeeper.swift`,
`BackupView.swift`. Not on master at this commit: `docs/qa/review-backups.md`, board item 0e in `core.md`, and the
12:12 PM PT entry in `decisions.md`, so the expected results below follow the brief; check them against those once merged.

**Key-shaped text.** `KEY` means a string with the Claude key prefix and a key-length body. Tests build it at run time
from pieces (for example `printf '%s%s' "$P1" "$P2"` or Swift string joins of parts, as `claude-key-test.md` and
`ClaudeKeyTests.swift:63` do) and never store it as one literal. `PART` is the first 3 characters of the prefix plus a
short word. `SHORT` is the whole prefix plus a 6-character body (shorter than any key). Other secrets: hunter2, tacocat, 4417.

**The key line** (Ask bar, `TessModel.swift:60`): "That looks like a Claude key. It goes in Review, under Claude."

Status: **pass** (master does it; a test exists or the code is plain), **fail** (built, wrong), **not built**.

## B1. Key-shaped notes are refused with the key line

Expected for every refused row: no note made or changed, no op written, the key line returned, and no `KEY` bytes in a copy written after.

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| B1-1 | Empty store | `CreateNote(body: KEY)` | Refused, key line | fail: no guard in `CreateNote.apply`, Notes.swift:101-120 |
| B1-2 | Plain note "router in the hall" | `EditNote(body: KEY)` | Refused, body unchanged | fail: Notes.swift:150-176 |
| B1-3 | Plain note | `EditNote(title: KEY)` | Refused, title unchanged | fail: Notes.swift:173-175 |
| B1-4 | Empty store | Create with body "gym bag\nKEY\nbananas" | Refused (multi-line) | fail: Notes.swift:101 |
| B1-5 | Empty store | Create "my key is KEY thanks" | Refused (KEY inside other text) | fail: Notes.swift:101 |
| B1-6 | Empty store | Create "  KEY  ", "\nKEY\n", "\tKEY" | Refused (spaces, line breaks around) | fail: Notes.swift:102 trims, then saves |
| B1-7 | Empty store | Create KEY in upper case | Refused (any case, as `ClaudeKeyGuard.swift:6`) | fail: Notes.swift:101 |
| B1-8 | Empty store | Create "wifi password is tacocat KEY" | Refused, never saved as a private note | fail: Notes.swift:107 makes it private and saves it |
| B1-9 | Private note "door code 4417" | `EditNote(body: "door code 4417 KEY")` | Refused, body unchanged | fail: Notes.swift:156-167 |
| B1-10 | Empty store | Create "PART" and "bought PART today" | Allowed, note saved as said | pass (no guard; the shared guard also lets it through) |
| B1-11 | Empty store | Create "SHORT" | Allowed, note saved (only starts the same way, too short) | pass on notes today; **would fail** if notes reuse `looksLikeClaudeKey`, which refuses any prefix (ClaudeKeyGuard.swift:6); key store uses `count > 12` (ClaudeKey.swift:212) |
| B1-12 | Empty store | Ask bar "note: KEY" | Refused, key line, no route runs | pass: TessModel.swift:69-71, ClaudeKeyTests.swift:103 |
| B1-13 | B1-1 to B1-9 run | Write a copy, scan bytes for KEY and the prefix | Neither found | fail on the note path (follows B1-1); pass for the Ask bar (ClaudeKeyTests.swift:88-115) |

## B5 and B6. Newer copies, odd values

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| B5-1 | Store with a migration id this build lacks | Launch (`makeContainer`) | Refused with a line saying it was "made by a newer version"; store untouched, no migration runs, nothing moved aside | not built: TesseraSchema.swift:43 opens it and the migrator runs over unknown ids; no such line exists |
| B5-2 | Copy with an unknown migration id | `inspect`, then pick in Backups | `newerSchema`; "That copy is from a newer Tessera. Update first." | pass: TesseraBackup.swift:209-211, BackupView.swift:256-257, BackupTests.swift:66 |
| B5-3 | Copy with known migrations, system classes at `packageVersion` 10 (build ships 9) | `inspect` | Refused as newer, same line as B5-2 | not built: `inspect` checks migrations only (TesseraBackup.swift:209-211); catalog version at SystemCatalog.swift:350 |
| B5-4 | B5-3 copy staged, app updated down a build | Launch (`applyPendingRestore`) | Set aside as rejected, store as it was, launch note | not built: :270 calls `inspect`, which misses catalog |
| B6-1 | Copy whose `backupInfo.createdAt` is text "yesterday" | `inspect`; also staged, then launch | Throws `damaged`, no crash; at launch the copy is set aside | likely fail (crash): non-optional `row["createdAt"]` at TesseraBackup.swift:215; GRDB traps on a failed conversion; runs at launch via :270 |
| B6-2 | Store with an object, link or class `createdAt` of "abc" | Launch | Opens; that row gets now (the `?? .now` fallback) | likely fail (crash): `row[column] as Double?` at TesseraDatabaseSchema.swift:155 (used :166, :206, :224); also TrainingIndexBuilder.swift:120 |
| B6-3 | `restored-at` marker holds "abc" | Launch, write a copy | No crash; `restoredAt` nil | pass: TesseraBackup.swift:35-36 |
| B6-4 | `fieldDef.kind` = "rating2" (unknown) | Launch, save, reopen | Kind still "rating2"; value kept; field shows read-only | fail: coerced to `.text` at TesseraDatabaseSchema.swift:183 |
| B6-5 | Object values with an entry this build can't decode | Load, edit another field, save | Unknown entry written back as it was | pass: FieldValue.swift:83-88 |

## B2. Cleanup deletes only daily copies

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| B2-1 | Picked folder with 8 daily copies | `writeRolling(keep: 7)` | Oldest daily goes, 7 kept | pass: TesseraBackup.swift:164-169, BackupTests.swift:69 |
| B2-2 | A "Save a copy" file saved into the picked folder 8 days ago | 8 more daily runs | The saved copy is still there | fail: it is named `Tessera-YYYY-MM-DD.tessera` (BackupKeeper.swift:170), the same pattern cleanup prunes (TesseraBackup.swift:165-168) |
| B2-3 | Saved copy renamed by Files to `Tessera-2026-10-09 2.tessera` | Daily runs | Kept | fail: matches the `Tessera-` prefix at :165 |
| B2-4 | "Save a copy" today into the picked folder, before tonight's 00:00 to 04:00 refresh | Late-night run | Saved copy untouched; the daily copy is a separate file | fail: same name, replaced at :158-159 |
| B2-5 | `Before-restore-*.tessera` and an unrelated file in Documents/Backups | Daily runs | Both untouched by daily cleanup | pass: prefix filter :165; befores keep 3 at :290-296 |

Fix note: mark daily copies by something cleanup can trust (a `kind` column in `backupInfo`, or a name "Save a copy" never uses), not the date prefix alone.

## Forget log survives a restore

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| F-1 | Remember "I train after work", copy it, forget it | Restore that copy, relaunch | Line gone, words redacted, `reapplyForgetsIfRestored` returns 1 | pass in a unit test (TessMemoryTests.swift:248-258, AppModel.swift:338); no end-to-end test through `applyPendingRestore` |
| F-2 | As F-1 | Look in Application Support/Tessera after the restore | `tess-forgotten.json` still there (not moved to `Backups/<date>/`) | pass by reading: only `tessera.sqlite*` moves (TesseraSchema.swift:137) |
| F-3 | Any forget | Write a copy, scan for the forget log | Not inside the copy; the log holds hashes only, no words | pass: TessMemory.swift:333-346, TessMemoryTests.swift:259 |
| F-4 | Forget all (12 lines), restore an older copy | Relaunch | All 12 stay forgotten | pass by reading (TessMemory.swift:610-630); no test |

## Private memories and secret-word notes stay out of the iCloud copy

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| I-1 | A private memory "left shoulder is sore" | Daily copy to the picked folder; scan its bytes | Words absent | fail: the whole store is copied (BackupKeeper.swift:100, TesseraBackup.swift:62) |
| I-2 | Private note "door code 4417" | Same | "4417" absent | fail: same; SecretWords.swift:5 and decisions.md Q1 still say it rides |
| I-3 | Both | Local copy in Documents/Backups | Both present (this phone only) | pass: BackupKeeper.swift:81 |
| I-4 | iCloud copy without them, private rows on the phone | Restore that copy | Open question: private rows kept or lost? | not built |

## Backups never hold the key, the bookmark or flags

| # | Setup | Action | Expected | Master today |
|---|---|---|---|---|
| K-1 | KEY saved in the Keychain, Test run | Write a copy; scan for KEY and the prefix | Neither found | pass: ClaudeKeyTests.swift:88-115 |
| K-2 | Folder picked (bookmark saved) | Write a copy; scan for the bookmark bytes and `tessera.backupFolderBookmark` | Neither found; only the folder's display name rides | pass by reading (UserDefaults, BackupKeeper.swift:16, :130-137); no test |
| K-3 | A failed copy, a launch note, a capture miss | Write a copy; scan | Failure log, launch note and `capture-misses.jsonl` absent | pass by reading: BackupKeeper.swift:46, TesseraSchema.swift:100, CaptureMissLog.swift:31; no test |
| K-4 | Launch with `-theme <name>` or `-demoTime 18:10` | Write a copy | No look or clock value from a flag in the settings object | unsure: AppModel.swift:119 treats `-theme` as demo; no test |

## Counts

39 cases: 16 pass (4 of them by reading only: F-2, F-4, K-2, K-3), 18 fail or likely fail (B1 10, B6 3, B2 3, iCloud 2),
4 not built (B5-1, B5-3, B5-4, I-4), 1 unsure (K-4).
