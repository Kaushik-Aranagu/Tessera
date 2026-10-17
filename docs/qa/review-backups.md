# Backups and restore review (origin/master, static)

Scope: Features/Backup/*, TesseraCore Export/TesseraBackup.swift, Model/TesseraSchema.swift (launch restore),
TessMemory forget log / reapplyForgetsIfRestored, App/TesseraApp.swift + AppModel.swift launch path. No toolchain: read-only.

## What checks out
- Left out of the copy: the Claude key (Keychain only, ClaudeKey.swift), the folder bookmark, failures, launch note and miss
  flags (all UserDefaults), the capture-miss log (`capture-misses.jsonl` file beside the store). The `.tessera` file is
  only the SQLite DB plus `backupInfo`. Settings holds the folder's display name and nothing else (SystemCatalog.swift:235).
- The restore is staged, then applied in `makeContainer` before the store opens (TesseraSchema.swift:38). A Before-restore
  copy is written first, and if that fails the restore is skipped (TesseraBackup.swift:286-301). If the move aside fails or a -wal is left over,
  everything is put back (:306-315). A staged file that won't pass the check goes to `restore-rejected.sqlite` (:270-275). A crash between
  move-aside and the swap recovers on the next launch.
- A backup with newer DB migrations is refused at pick time and at launch (`appliedIdentifiers` includes unregistered ones).
- The forget log sits outside the store, holds hashes only and uses `.completeFileProtection`. It is re-applied once for each
  restore marker. A line said again after its forget is kept (TessMemory.swift:610-632).
- 4 AM: rolling names come from `TesseraDay` (:125). `BackupCopy.fileDay` / `local` / `failure` also use TesseraDay.
- Destructive writes are covered: Replace is a hold PaintKey, "Stop using it" has a 10 s UNDO, and "Cancel restore" destroys nothing.
- Rolling write is atomic (partial + replaceItemAt). Empty stores are never copied. A clock that runs behind never prunes.
- Private notes ride in his backups on purpose (SecretWords.swift:5, Q1).

## Findings

**B1 (high): a Claude key pasted into a note lands in the store, then in every backup and the iCloud copy.**
- `TesseraCore/Sources/TesseraCore/Notes/Notes.swift:101` (CreateNote.apply) and `:150` (EditNote.apply). Callers
  `Features/Notes/NotesView.swift:40,109` and `Features/Notes/NoteEditor.swift:149` have no guard. `TesseraBackup.write` (:56) does not scan either.
- Scenario: he copies his key from the console and pastes it into Notes ("Write" field or the editor). No secret word
  matches, so it saves as a plain note titled with the key (`firstLine`). The op log keeps it too. The next background writes it to
  Documents/Backups and iCloud Drive/Tessera, and "Save a copy" hands it to the share sheet. ClaudeKeyGuard.swift:3 says
  every writer checks `looksLikeClaudeKey`, but the Notes path never does.
- Fix: refuse in CreateNote/EditNote (throw `invalidArguments`, as TessMemoryScreen does) so every caller is covered.
  The Notes UI clears the field and says the key goes in Settings. Add a test.
- Owner: Core

**B2 (medium): "Save a copy" put in the backup folder is later deleted silently by the 7-copy prune, and its name is the calendar day.**
- `Features/Backup/BackupKeeper.swift:166-170` names it `Tessera-<calendar yyyy-MM-dd>`. `TesseraBackup.swift:130,164-169`
  treats every `Tessera-*.tessera` in the folder as a rolling copy.
- Scenario A: he taps Save a copy and keeps it in iCloud Drive/Tessera, the folder he already picked. Seven daily copies
  later, `kept.dropFirst(keep)` removes it. A file he saved by hand is gone, and nothing tells him.
- Scenario B: he saves at 01:30 Wednesday. The file is named Wednesday, but his day is still Tuesday. At Wednesday's first background after 04:00
  the rolling copy finds that file, `exists` is true and the hour is ≥ 4, so it returns nil. Wednesday's "daily copy" in that folder is
  the 01:30 file and holds none of Wednesday's activity.
- Fix: rolling copies get their own mark, e.g. a `backupInfo.kind = 'daily'` column (or a `Tessera-daily-` prefix), and only
  those are pruned or matched. Manual copies are named `Tessera-copy-<TesseraDay>`.
- Owner: Core (format, prune), with Builder B (name in copyForSaving)

**B3 (medium): after a reinstall, a restore brings back lines he forgot after that copy was made.**
- `TessMemory.swift:333-347` keeps the log in Application Support, which is deleted with the app. `:624-632` re-applies only from that log.
- Scenario: the Monday 05:00 copy goes to iCloud. Monday 20:00 he forgets "I see a therapist on Thursdays". Tuesday he deletes and
  reinstalls the app (free signing) and restores Monday's copy, which is the flow "Reinstalled? Restore…" invites (BackupView.swift:74).
  The log is gone and the store predates the forget, so the line is back. It shows on What Tess knows and is packed for Claude.
- Fix: when a folder is picked, also write the hash-only `tess-forgotten.json` into it on every forget. On "Choose it again"
  after a restore, merge that file into the local log and run `reapplyForgets()`. Hashes only, so no words leave the phone.
- Owner: Core (log merge), with Builder B (BackupKeeper folder write / pick hook)

**B4 (medium): a forgotten noticed-rule line returns after a restore if its numbers changed between the copy and the forget.**
- `TessMemory.swift:610-619` matches only exact text hashes. `suppressedRules()` (:389-393) needs the deleted object, which
  a copy from before the forget doesn't have. Rule lines are rewritten in place each Sunday (Turnover.swift:120-175).
- Scenario: Saturday's copy has "You train about 4 days a week." (rule `training.perWeek`). Sunday's recompute changes it
  to "5 days", and he forgets it that evening (hash of the "5 days" text). He restores Saturday's copy: the "4 days" hash isn't
  in the log, so the line stays and is packed. If the next Sunday computes 6, the line is written back in place for good.
- Fix: also log a hash of each forgotten line's `rule` (ForgetLog `rules`). `reapplyForgets` redacts any live line with
  that rule, and `suppressedRules` unions the logged rules.
- Owner: Core

**B5 (medium): an older build that opens a newer store loses the newer columns on every write.**
- `TesseraContext.swift:48` runs `migrator.migrate` with no `hasBeenSuperseded` check. Rows are saved with `INSERT OR REPLACE`
  naming only today's columns (TesseraDatabaseSchema.swift:77-118).
- Scenario: v10 ships migration `v4` that adds a column, e.g. `object.archivedAt`. He reinstalls an older build from Xcode
  (free signing). It opens the store, and each edited object is deleted and re-inserted without `archivedAt`. The data is lost without a word.
- Fix: in `TesseraContext.init`, if `try migrator.hasBeenSuperseded(db)`, throw a dedicated error. `TesseraSchema.open` maps it
  to the in-memory fallback with "Your data is from a newer Tessera. Update to open it." The files stay untouched.
- Owner: Core

**B6 (medium): the restore check ignores the catalog version and the backup format version, so a v10 copy restores onto v9.**
- `TesseraBackup.swift:204-216` never reads `backupInfo.version` or class `packageVersion`. Also `:215` decodes `createdAt`
  as non-optional, and GRDB fatal-errors on NULL or non-numeric.
- Scenario: v10 bumps the catalog with no DB migration, say a new FieldKind on a shipped field. The v9 build accepts the copy. Load maps
  the unknown kind to `.text` (TesseraDatabaseSchema.swift:183, Models.swift:234,241), and any later write of that FieldDef
  (a rename, markUserModified) saves `kind = "text"` for good. Separately, a future format that stores `createdAt` as text
  would crash at launch (`applyPendingRestore` → `inspect`, :270) and on the Backups screen (`latestLocal`).
- Fix: throw `.newerSchema` when `version > TesseraBackup.version` or when any classDef row with packageID 'system' has
  packageVersion > `SystemCatalog.package.version`. Decode `createdAt` as `Double?` and map nil to `.damaged`. Keep an unknown
  `kindRaw` on load instead of collapsing it to text.
- Owner: Core

**B7 (low): a restored file that fails to open leaves the old store moved aside and a misleading note.**
- `TesseraSchema.swift:38-45,57-67`. Applying the restore never opens the restored file as a trial run.
- Scenario: the staged copy passes quick_check, but the open fails during migrate. On a full disk the result is the in-memory fallback, and
  `setLaunchNote` overwrites "Restored…" with "Your history is untouched", while the old store now sits in
  Backups/<stamp>. If it fails with a damage code, the restored file is moved aside too and he gets an empty store. The data
  still exists only as Before-restore and is never put back automatically.
- Fix: in applyPendingRestore, open a `TesseraContext` on the pending file (it's a copy) before the swap. If the open fails, reject
  it. Otherwise, after a post-swap open failure, move the old store back from its folder.
- Owner: Core

**B8 (low): a private memory says "on this phone only", but the daily copy puts it in iCloud Drive.**
- `TessMemory.swift:51,264` and `SystemCatalog.swift:264` ("Stays on this phone"). `BackupKeeper.swift:99-104` copies the whole store.
- Scenario: he says "remember my shoulder surgery". The receipt says "Kept, on this phone only." The next background copies
  it into iCloud Drive/Tessera, and Save a copy shares it too.
- Fix: Kaushik decides. Either reword to "never sent to Claude" (Builder B copy), or keep these lines out of folder and
  shared copies (Core). Private notes are in backups by design (Q1), so the wording should match that.
- Owner: Core (decision/format), Builder B (copy)

**B9 (low): after "Stop using it", the screen speaks as if a restore had happened.**
- `BackupView.swift:92-93`. `BackupKeeper.forget()` (:142-146) leaves `backupFolderName` set.
- Scenario: he taps Stop using it, and the sentence becomes "Your copies were kept in iCloud Drive/Tessera. Choose it again."
  It should read "Also keep them in a folder you choose."
- Fix: clear `backupFolderName` in the forget (the UNDO puts it back), or show `rememberedSentence` only when `restoredAt` is set.
- Owner: Builder B

**B10 (low): opening the Backups screen runs `PRAGMA quick_check` on every copy, on the main actor, on every render.**
- `BackupView.swift:33` → `BackupKeeper.latestLocal` (:155-161) → `inspect` → quick_check (TesseraBackup.swift:206). Up to
  7 daily plus 3 Before-restore files, run again on each `refresh` bump (say/stage/cancel).
- Scenario: with a 5-year history (`scripts/test.sh --scale`), each tap on the Backups screen hitches for the length of a full
  scan of about 10 files.
- Fix: read `createdAt` from `backupInfo` without quick_check (or use the file names), cached in @State. Keep quick_check for pick and stage.
- Owner: Builder B, with Core (`inspect(quick:)` option)

**B11 (low): after a restore, the only pre-restore copy lives on the phone, and the iCloud copies are replaced.**
- `TesseraBackup.swift:142-150` skips the "never fewer actions" guard after a restore. The Before-restore copy goes only to
  Documents/Backups (:285).
- Scenario: he restores the wrong (older) copy and keeps using the app for a week. Pruning replaces every iCloud copy with
  post-restore data. If he then deletes the app, his pre-restore history is gone.
- Fix: write the Before-restore copy into the picked folder too, on the first `runDaily` after a restore, under its own name
  that is never pruned.
- Owner: Core, with Builder B (BackupKeeper)
