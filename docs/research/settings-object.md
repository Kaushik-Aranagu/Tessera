# The settings object: every preference outside the database, and what moves in (board item 96)

*Research, 2026-10-16. Checked against `origin/master` at `fc31605` (after #239, the empty-store guard, and #240). No Swift run, nothing installed.
Builds on `restore-walk.md` (fix list 3b, 4 and 5 all wait on this object) and `resign-day.md`.*

**The answer in one line.** Master keeps eight UserDefaults keys, one Keychain item and nine kinds of plain file
outside the GRDB database, plus 22 launch flags. Only four values belong in the new settings object: the three look
keys and "Misses go to Claude". A fifth value, the backup folder's display name, is new and goes there too, and so
does a sixth, `restWeekday` (added after Core's 8:58 PM PT design, see the design rules). Everything
else is device-only and stays out, and five of those must never travel in a backup.

**Search used.** `git grep` on `origin/master -- '*.swift'` for `AppStorage`, `SceneStorage`, `UserDefaults`,
`suiteName`, `forKey:`, `containerURL`, `appGroup`, `SecItem`, `kSec`, `bookmarkData`, `resolvingBookmarkData`,
`applicationSupportDirectory`, `documentsDirectory`, `cachesDirectory`, `temporaryDirectory`, `write(to:`,
`createFile`, `FileManager.default`, `Data(contentsOf`, `ProcessInfo.processInfo.arguments`, `ActivityAttributes`,
`WidgetCenter`, `NSUbiquitous`. Test files were read only to confirm patterns. There is no `@SceneStorage`, no
`cachesDirectory`, no `NSUbiquitousKeyValueStore`, no `WidgetCenter` and no Home Screen widget on master. The
widget extension (`Widgets/`) holds only the rest Live Activity and touches no UserDefaults.

## Verdicts in short

| Verdict | Count | What |
|---|---|---|
| **MOVE** into the settings object | 4 existing + 2 new | `look.day`, `look.night`, `look.pinned`, `tess.missesGoToClaude`; new: backup folder display name, `restWeekday` (decisions.md 8:58 PM PT) |
| **KEEP OUTSIDE** | 13 stored things + 22 launch flags | Folder bookmark, backup failures, launch note, his Claude key, capture-miss log, `restored-at`, `restore-pending.sqlite`, the `.tessera` copies (Documents/Backups and the picked folder), moved-aside stores, the legacy `default.store`, temp share copies, the Live Activity's look names, and the App Group mirror of the look; all DEBUG and demo flags |
| **DROP** | 3 keys (one group) | The pre-#221 look keys in standard UserDefaults, after one release |

## Never in a backup

These must never be written into the settings object, any object, the op log, a `.tessera` copy or an export:

1. **His Claude key** (Keychain). Not its last four characters either. Those are drawn from the Keychain each time.
2. **The backup folder bookmark** (`tessera.backupFolderBookmark`). A security-scoped bookmark only works on the
   device that made it, and it holds a full on-device path. Only the display name ("iCloud Drive/Tessera") may travel.
3. **The capture-miss log** (`capture-misses.jsonl`). By design it never leaves the phone, and it may hold raw text he
   typed.
4. **Device-only state**: backup failure notes, the launch note, `restore-pending.sqlite`. Each describes this phone at
   this moment. Restored onto another phone, or onto this phone a week later, it would be false.
5. **Launch flags**, above all `-fakeClaudeKey`, `-demo`, `-resetDemo` and `-theme`. They are never persisted today and
   must stay that way.

`restored-at` is a special case: it is carried into every later copy on purpose, as `backupInfo.restoredAt`
(`TesseraBackup.swift:68-73`). It should stay a file and not go into the settings object (see row F2).

## UserDefaults and the App Group

### U1. `look.day`, `look.night`, `look.pinned` (App Group suite)

- **Where.** Suite `group.com.kaushikaranagu.tessera` (`DesignSystem/Looks.swift:141`), opened by
  `ThemeStore.sharedDefaults` (`:143-152`). The keys are in `ThemeStore.Key` (`:191-195`).
- **Type and default.** String (a `Look` name such as "Porcelain"; `Look.named` ignores case, `:126-128`). Read at
  `:207-209`. If unset, day falls back to `.porcelain`, night to `.obsidian` and pinned to nil.
- **Written.** `save()` (`:314-321`, writes at `:318-320`) after `cycleDay`, `cycleNight`, the back steps,
  `cyclePinned`, `togglePin` and `adoptRestored`. It is never written while a `-theme` demo pin is on (`:316-317`).
- **Read elsewhere.** `wasEverChosen` (`:155-157`) checks whether day or night is set. `adoptRestored` (`:160-167`)
  applies a restored look only when `wasEverChosen` is false. **It has no caller on master** (gap 4 in
  `restore-walk.md`).
- **What it does.** His look: one by day, one by night, or one pinned for both.
- **Verdict: MOVE**, and keep a device copy. It is his choice, so it should come back with a restore.
- **Keep a device copy.** The App Group copy stays as a mirror, for two reasons:
  1. `ThemeStore.shared` is a static that the first frame reads. `Theme.configure()` runs in `TesseraApp.init`
     (`App/TesseraApp.swift:18`) before `TesseraSchema.makeContainer()` opens the database (`:20`). The look must be
     readable without the database, so the mirror stays as the launch-time read.
  2. A future Home Screen or Lock Screen widget can only read the look from the group. **Today no extension reads the
     App Group.** The rest Live Activity gets the look names through its `ContentState` (`lookDay` and `lookNight`,
     `Shared/RestActivityAttributes.swift:33-34`, filled at `Features/Workout/LiveActivity/RestActivityController.swift:112`)
     and draws them from a compiled-in table, "with no App Group" (`Shared/LookTable.swift:3-5`). Keep the group
     anyway: it costs nothing, and `resign-day.md` already checked it on the free team.
- **Rule.** The settings object is the record that travels. The mirror is a cache, written in the same `save()`.

### U2. `look.day`, `look.night`, `look.pinned` (standard UserDefaults, before #221)

- **Where.** These are the same keys from before the App Group existed. `sharedDefaults` copies each one into the group
  once, when the group doesn't have it yet (`Looks.swift:146-150`). After that, nothing reads or writes them.
- **Verdict: DROP**, after one release. Leave the copy loop in for the release that adds the settings object, so a
  phone that skipped #221 still keeps its look. Delete the loop and the three standard keys after that.

### U3. `tess.missesGoToClaude` (standard)

- **Where.** `@AppStorage("tess.missesGoToClaude")` in `Features/Settings/ClaudeSection.swift:59`.
- **Type and default.** Bool, default `true`.
- **Written.** The yes/no value word (`:172`). Read for the label and accessibility value (`:172-181`).
- **What it does.** Line 3 of the CLAUDE section: whether captures the phone can't read go to Claude.
- **Surprise: nothing acts on it yet.** No other file reads the key. `TessCaptureEngine.router`
  (`TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:45-51`) runs only the grammar and the on-device model, so
  the switch is stored and shown but routes nothing on master. When Claude joins the capture router, it has to read
  this value from Core. That is one more reason to keep it in a Core object rather than in SwiftUI `@AppStorage`.
- **Verdict: MOVE.** It is a privacy choice. If he set "no", a restore must not quietly turn it back to "yes" (gap 5).

### U4. `tessera.backupFolderBookmark` (standard)

- **Where.** `Features/Backup/BackupKeeper.swift:16`.
- **Type and default.** `Data` (a security-scoped bookmark). Absent means no folder picked.
- **Written.** `pick` (`:107-116`, set at `:114`). Refreshed when stale in `pickedFolder` (`:93-104`, set at `:100`).
  Removed in `forget` (`:118-120`). **`forget` has no caller on master.**
- **Read.** `pickedFolder` (`:94`), the "picked but won't resolve" check in `runDaily` (`:73`), and
  `Features/Backup/BackupView.swift:28` through `pickedFolder`.
- **What it does.** It lets the daily copy write into his folder outside the app (iCloud Drive/Tessera).
- **Verdict: KEEP OUTSIDE. Never in a backup.** A bookmark only resolves on the device that made it and holds a full
  on-device path. Fix 3b instead stores the **display name** in the settings object (new field `backupFolderName`).

### U5. `tessera.backupFailures` (standard)

- **Where.** `BackupKeeper.swift:30`.
- **Type and default.** `Data`, a JSON `[Failure]` (`place`, `at`, `reason`, `:23-28`). Default empty.
- **Written.** `note` (`:39-51`, set at `:49`), from every `runDaily` (`:63-89`) and from DEBUG
  `-backupFailure` (`:55-58`).
- **Read.** `failures` (`:34-37`). `BackupView.swift:29` uses it for "Kept on this iPhone" and the quiet failure
  line (`:48`, `:66`).
- **What it does.** It remembers which daily copy failed last time, so Backups doesn't look safe while nothing is being
  written.
- **Verdict: KEEP OUTSIDE.** It describes this phone's disk and this phone's folder access. Restored somewhere else it
  would be false, and the reason text can hold on-device paths.

### U6. `tessera.launchNote` (standard)

- **Where.** `TesseraCore/Sources/TesseraCore/Model/TesseraSchema.swift:99`. Read at `:103-105`, set at `:107-109`,
  cleared at `:111-113`.
- **Type and default.** String?, default nil.
- **Set by.** Failed store opens (`TesseraSchema.swift:58`, `:66`, `:70`), restores (`TesseraBackup.swift:269`,
  `:293`, `:307`, `:317`, `:325`) and the waiting legacy move
  (`TesseraCore/Sources/TesseraLegacyStore/LegacySchema.swift:40`).
- **Cleared by.** Opening the Ask bar (`Features/Command/BottomChrome.swift:372-375`) and a finished legacy move
  (`LegacySchema.swift:45`).
- **Read.** `App/AppModel.swift:101`, shown in the Ask bar (`BottomChrome.swift:108`).
- **What it does.** One calm line about what happened to the store at launch.
- **Verdict: KEEP OUTSIDE.** It has to be writable exactly when the database can't be opened, so it can never live in
  the database. It is also a one-shot note.

## Keychain

### K1. His Claude key

- **Where.** `SystemKeychain` in `TesseraCore/Sources/TesseraTess/ClaudeKey.swift:22-55`. A generic password with
  service `com.kaushikaranagu.tessera.anthropic` and account `api-key` (`:23-24`). It has
  `kSecAttrSynchronizable` false (`:30`) and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (`:48`).
- **Read.** Through `ClaudeSection.defaultKeys` (`Features/Settings/ClaudeSection.swift:40-48`) in `load()`
  (`:247-257`), which keeps only the last four characters in `@State`. Saved and removed through the same protocol.
- **Default.** None (absent).
- **Verdict: KEEP OUTSIDE. Never in a backup, the settings object, the op log, an export or a log.** This is already
  the stated rule (`ClaudeKey.swift:7-9`), and `ClaudeKeyTests.swift:94` scans UserDefaults for it. The key-check
  outcome ("works", "not allowed") is already in the database as `tessCall` rows (`ClaudeSection.swift:253-256`). That
  is correct: an outcome is not a secret, and it needs no settings field.

## Plain files

Container paths: Application Support is `Library/Application Support`. Documents is shown in Files, because
`project.yml:33-34` sets `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`.

| # | File | Where defined, written, read | What it does | Verdict | Why |
|---|---|---|---|---|---|
| F0 | `Application Support/Tessera/tessera.sqlite` (+ `-wal`, `-shm`) | `TesseraSchema.swift:20-24` | The database itself | n/a | Listed only so the list is complete: this is where the settings object will live |
| F1 | `Application Support/Tessera/capture-misses.jsonl` | `TesseraCore/Sources/TesseraCore/Diagnostics/CaptureMissLog.swift:29-33`. Appended in `record` (`:36-59`), which sets `isExcludedFromBackup` (`:49-52`). Read by `all()` (`:62-67`). Trimmed to the newest 2000 (`:69-75`). Written from `TessCaptureEngine.swift:33-35` | One JSON line per capture or paste that wrote nothing, for reading Kitchen week one | **KEEP OUTSIDE. Never in a backup** | It holds raw typed text and is diagnostic. By design it never leaves the phone (`:1-5`) |
| F2 | `Application Support/Tessera/restored-at` | `TesseraBackup.swift:30-32`, read at `:34-38`, written at `:321` | When the last restore was applied. It goes into each later copy's `backupInfo.restoredAt` (`:68-73`, `:92-97`) | **KEEP OUTSIDE** | It describes this store file's life. If it were in the database, a restore would bring back the backup's own older value and undo the marker. Fixes 2 and 4 read it as "a restore just happened" |
| F3 | `Application Support/Tessera/restore-pending.sqlite` | `TesseraBackup.swift:225-227`. Staged at `:231-237`, checked at `:241-245`, cancelled at `:249-251`, applied in `applyPendingRestore` (`:259-`) | A checked backup waiting for the next launch | **KEEP OUTSIDE. Never in a backup** | A one-shot launch hand-off |
| F4 | `Documents/Backups/Tessera-YYYY-MM-DD.tessera` (7 kept) and `Before-restore-*.tessera` (3 kept) | `BackupKeeper.swift:18-20`, `TesseraBackup.swift:107-109`, `:280-290`. Written by `writeRolling` (`:120-168`) | The daily copies on the iPhone, and what a restore replaced (for undo) | **KEEP OUTSIDE** | These are the backups. They carry the settings object inside them |
| F5 | `.tessera` copies in his picked folder | `BackupKeeper.runDaily` (`:77-88`) | The copy that survives deleting the app | **KEEP OUTSIDE** | These are the backups, outside the container |
| F6 | `Application Support/Tessera/Backups/<stamp>/` | `TesseraSchema.moveStoreAside` (`:121-`) | A damaged store, or the moved legacy store, kept untouched | **KEEP OUTSIDE** | Recovery files for this device |
| F7 | `Application Support/default.store` (SwiftData, from before GRDB) | `TesseraCore/Sources/TesseraLegacyStore/LegacySchema.swift:8-10`, moved aside after migrating (`:44`) | Read once to move old data into GRDB | **KEEP OUTSIDE** (drop the importer some day, not the file) | Legacy input, not a setting |
| F8 | Temp copies: `tmp/Tessera-<day>.tessera` and the copy made for the picker | `BackupKeeper.swift:138`, `BackupView.swift:219-221`, removed at `:248` | Hands a copy to the share sheet or file exporter | **KEEP OUTSIDE** | Transient |

## State that isn't persisted, for completeness

| # | What | Where | Verdict | Why |
|---|---|---|---|---|
| S1 | Live Activity `lookDay` and `lookNight` | `Shared/RestActivityAttributes.swift:31-34`, filled at `RestActivityController.swift:112` | **KEEP OUTSIDE** | The extension has to draw without the database. It already gets the names in the activity's state. Keep feeding it from `ThemeStore` (whose values now come from the settings object) |
| S2 | `ThemeStore.demoPin` and `workoutHeld` | `Looks.swift:173-177`, `:298-312` | Not stored | Memory only, by design. `demoPin` must never be saved (`:316-317`) |
| S3 | Home's remembered page | `Features/Home/HomeSpatialView.swift:45-56`, `:128` | Not stored | A static for this session only. No `@SceneStorage`. Leave it |
| S4 | `Format.unit` (kg or lb) | `App/AppClock.swift:36`, "kg until Kaushik picks" | Not stored yet | **A future MOVE.** When a unit picker ships, it belongs in the settings object (the reserved `massUnit` field below) |
| S5 | `ExerciseLibraryInstaller.chosenShape` | `TesseraCore/Sources/TesseraCore/Catalog/ExerciseLibraryInstaller.swift:26` | A constant | Not a preference |

## Launch flags (all KEEP OUTSIDE: never persisted, never in a backup)

All of these are read from `ProcessInfo.processInfo.arguments`. None is written anywhere.

| Flag | Where read | DEBUG-guarded? |
|---|---|---|
| `-demo`, `-resetDemo` | `App/TesseraApp.swift:29-31`, `Features/Demo/DemoData.swift:8-10` | **No** (see surprises) |
| `-theme <name>` | `DesignSystem/Theme.swift:277-285`, which pins in memory (`Looks.swift:298-301`) | **No.** The comment says DEBUG, but `Theme.configure` has no `#if DEBUG` |
| `-demoTime HH:mm` | `App/AppClock.swift:18-30` | Yes |
| `-soulGallery`, `-notes`, `-review`, `-groceries`, `-looks`, `-backup`, `-recipe`, `-pasteRecipe` | `App/TesseraApp.swift:46-63` | Yes |
| `-homePage <page>` | `HomeSpatialView.swift:46-55` | Yes |
| `-openLink <link>` | `HomeSpatialView.swift:104-112` | Yes |
| `-tessScript` | `Features/Command/BottomChrome.swift:81-84` | Yes |
| `-queueScript` | `Features/Home/HomeQueue.swift:284-290` | Yes |
| `-demoKitchen` | `Features/Groceries/GroceriesView.swift:745-747` (called from `:23` and `Features/Recipes/RecipesEntry.swift:25`) | Yes |
| `-demoNotes` | `Features/Notes/NotesView.swift:32-34` | Yes |
| `-demoReview` | `Features/Review/ReviewView.swift:326-327` | Yes |
| `-pasteDemo` | `Features/Recipes/PasteRecipe.swift:138-141` | Yes |
| `-backupFailure` | `BackupKeeper.swift:55-58`, called at `BackupView.swift:129` | Yes |
| `-fakeClaudeKey` | `ClaudeSection.swift:41-46` (an in-memory key, never the Keychain) | Yes |

That is 22 flags. The settings object must never be written while a demo flag is in force. The same rule already
stops `-theme` from saving a look.

## Proposed settings object

One system class in `SystemCatalog`, `system.settings`, holding exactly one object with a fixed id. The catalog
package goes from version 3 to version 4 (`SystemCatalog.swift:300`). Every field is optional, and **nil means "never
set on any phone"**. Defaults are applied by the reader, not stored. That keeps `ThemeStore.wasEverChosen` and
`adoptRestored` meaningful: a stored "Porcelain" means he chose it, nil means he never did.

```swift
// TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift
case settings   // systemKey "system.settings"

ClassSpec(key: .settings, name: "Settings", parent: .thing, symbol: "gearshape", colorRole: "neutral", fields: [
    FieldSpec(key: "lookDay",          name: "Look by day",          kind: .text),  // nil -> "Porcelain"
    FieldSpec(key: "lookNight",        name: "Look by night",        kind: .text),  // nil -> "Obsidian"
    FieldSpec(key: "lookPinned",       name: "Pinned look",          kind: .text),  // nil -> none
    FieldSpec(key: "missesGoToClaude", name: "Misses go to Claude",  kind: .bool),  // nil -> true
    FieldSpec(key: "backupFolderName", name: "Backup folder",        kind: .text),  // nil -> never picked
    FieldSpec(key: "backupFolderPickedAt", name: "Folder picked",    kind: .date),  // nil -> never picked
    FieldSpec(key: "restWeekday",      name: "Rest day",             kind: .number),  // nil -> the engine places it
    // Reserved, not built yet: FieldSpec(key: "massUnit", name: "Unit", kind: .choice) // nil -> "kg"
])

// Core API (TesseraCore/Sources/TesseraCore/Engine/Settings.swift)
public struct TesseraSettings: Equatable, Sendable {
    public var lookDay: String?              // a Look name; text, not choice, so an older build keeps a newer look's name
    public var lookNight: String?
    public var lookPinned: String?
    public var missesGoToClaude: Bool?       // read as `missesGoToClaude ?? true`
    public var backupFolderName: String?     // display name only, e.g. "iCloud Drive/Tessera"; never a path or URL
    public var backupFolderPickedAt: Date?
    public var restWeekday: Int?             // 1 to 7, Calendar weekday numbering (Sunday = 1); nil: the engine decides
}

@MainActor public struct SettingsStore {
    public static let objectID = SystemCatalog.stableID("settings")
    public init(store: ObjectStore, classes: ClassResolver)
    public func read() -> TesseraSettings                       // creates nothing; all nil if no object yet
    public func update(_ change: (inout TesseraSettings) -> Void) throws  // one op through ObjectStore
}
```

The design rules, briefly:

- **Exactly one object.** It is created on the first write, with the fixed id, so seeding twice can't make two.
- **Hidden.** Keep it out of lists, search, object pages, Tess's context pack and the grammar. It is a system record,
  not one of his things.
- **Writes are ops through `ObjectStore`.** That puts them in the op log, so they ride in every copy and export.
  Cycling the look by tapping writes one op per tap. That is fine at this size. If it ever gets noisy, write when the
  look settles.
- **Settings ops must not count as "his actions" for the rolling copy.** #239 made `writeRolling` skip a store with no
  user ops, counted as `actor != 'system'` (`TesseraBackup.swift:133-136`, `:173-175`). If a look tap or the migration
  on a fresh install counted, a store holding nothing but a look would pass that guard. A new day's empty copy could
  then push a good copy out of his folder, which is restore-walk gap 1 again. So the migration writes as `system`, and
  `userOps` leaves out ops whose object is the settings object, whoever made them.
- **`backupFolderName` is a display name only.** Use `BackupCopy.folderName(url)` (`BackupView.swift:331-337`), never
  the URL or the path: on-device paths include container ids. Set it with `backupFolderPickedAt` in
  `BackupKeeper.pick`. Clear both if `forget` ever gets a caller.
- **`resetUserData` (`ObjectStore+Lifecycle.swift:53-71`) wipes all objects, so `-resetDemo` resets settings to nil.**
  That is right for a demo reset. Say so in a test.
- **Look after a restore.** At the first launch with a newer `restored-at` (F2), Builder A calls
  `ThemeStore.adoptRestored(day:night:pinned:)` with the restored object's three look fields. Its rule already keeps a
  look chosen on this phone. If the phone's look wins, write it back into the object so the database and the mirror
  agree.
- **"Misses go to Claude" after a restore.** The restored value wins, as everything else in a restore does. A value
  that was nil reads as yes, which is today's behaviour.
- **`restWeekday`** (Core, decisions.md 8:52 and 8:58 PM PT Oct 15; `week-two.md` Q4).
  - **Key and type.** `restWeekday`, an optional Int from 1 to 7 in Calendar weekday numbering (Sunday = 1, Monday =
    2, Saturday = 7), stored as `.number`. It lives here, not on the Plan, and there is one value, not a list.
  - **Empty.** Nil means "the engine decides": the floating rest day on master today (`PlanRhythm.perWeek`, 6 a week
    for PPL x2, spread by `TrainingLedger.week`). Nil never means Sunday. Any value outside 1 to 7 reads as nil.
  - **Written.** Only by his answer to Monday's (Oct 19) rest-day question: one op with UNDO ("Rest day: Sunday."),
    skipped if the field is already set; "Any" leaves it nil. `StarterContent` and the migration never write it.
  - **Read by.** Now (`NowPicker.restDay`, through NowPage), Review (`ReviewPage` and `week()`) and Plans (PlanData,
    MonthPage). SQLite's `%w` counts Sunday as 0, so a copy read matches `wd` = restWeekday - 1.
  - **After a restore.** The restored value wins, like the other fields.

## Migration

The release that adds the object, at launch once the store has opened (not in `TesseraApp.init`, because the look
mirror is read before that):

1. **Read the old keys once.** Do this if the settings object doesn't exist yet, or exists with a field still nil:
   - `look.day`, `look.night`, `look.pinned` from the App Group suite, falling back to standard UserDefaults as
     `sharedDefaults` does today.
   - `tess.missesGoToClaude` from standard UserDefaults.
   - The folder name from `BackupKeeper.pickedFolder` through `BackupCopy.folderName`, if a bookmark resolves.
2. **Write them into the object in one update.** Copy only keys that are actually present (`object(forKey:) != nil`),
   so "never chosen" stays nil and a default never gets frozen into the object. Never overwrite a field the object
   already has. That object may have just come back from a restore.
3. **For "Misses go to Claude", "no" wins** during migration. If the old key says false and the object says true or
   nil, write false. A privacy choice should only fail toward "no".
4. **Keep the old keys, and keep writing them, for one release.** `ThemeStore.save()` and the Claude toggle write both
   the object and the old key. Readers use the object first and fall back to the old key when a field is nil. This
   matters for rollback: `resign-day.md` keeps older builds (b19fb4a, d0154a9) as fallbacks, and they only know the
   old keys.
5. **The release after.** Stop reading and writing `tess.missesGoToClaude` and the standard look keys (DROP U2). Keep
   the App Group look keys as the mirror (U1).

Never migrate: the bookmark, the failures, the launch note, his Claude key, or any file.

## Tests for Core (Swift Testing, `TesseraCore/Tests/TesseraCoreTests/SettingsTests.swift`)

- `settingsReadIsAllNilBeforeAnyWrite`
- `settingsFirstWriteCreatesOneObjectWithFixedID`
- `settingsSecondSeedAndSecondWriteNeverDuplicate`
- `settingsObjectIsHiddenFromListsSearchAndTessContext`
- `settingsWriteIsOneOpInTheLog`
- `settingsOpsDontCountAsUserOpsForRollingCopy` (a fresh store with only a look change still writes no copy)
- `missesGoToClaudeReadsTrueWhenNil`
- `unknownLookNameSurvivesRoundTrip` (text, not choice: a newer build's look is not erased by an older one)
- `settingsRideInRollingBackupCopy` (write, `writeRolling`, open the copy, the fields are there)
- `settingsComeBackAfterStageAndApplyRestore` (stage, `applyPendingRestore`, reopen, the restored values win)
- `settingsSurviveExportAndImport` (`TesseraExport` round trip)
- `resetUserDataClearsSettingsToNil`
- `backupFolderNameRejectsPathsAndURLs` (no `/`-rooted path, no `file://`, no `/private/var`, no container id)
- `settingsAndBackupNeverHoldClaudeKeyOrBookmark` (follows `ClaudeKeyTests.swift:94`: scan the settings values, the op
  log and a written `.tessera` copy for the in-memory test key and for bookmark bytes)
- `migrationCopiesOnlyPresentOldKeysOnce` (an injected `UserDefaults(suiteName:)`, as `ThemeStoreTests.swift:8-10`
  does)
- `migrationNeverOverwritesAFieldAlreadySet`
- `migrationNoWinsForMissesGoToClaude`
- `fallbackReadsOldKeyWhileFieldIsNil`
- `restWeekdayNilKeepsEnginePlacement` (nil gives today's floating rest day; 1 makes Sunday rest; 0 and 8 read as nil;
  UNDO of the write returns to nil)

## Surprising things found

1. **"Misses go to Claude" is stored but routes nothing.** Only `ClaudeSection` reads it. The capture router has no
   Claude step on master (`TessCaptureEngine.swift:45-51`). When it gets one, it must read this value from Core.
2. **No extension reads the App Group.** The look was moved into the group "so widgets read the same choice"
   (`Looks.swift:139-140`), but the only extension, the rest Live Activity, gets its look through `ContentState`, and
   `LookTable.swift:3-5` says "with no App Group". The group copy is still worth keeping, as the launch-time mirror.
3. **`-demo`, `-resetDemo` and `-theme` are not inside `#if DEBUG`** (`TesseraApp.swift:29-31`, `Theme.swift:277-285`,
   `DemoData.swift` has no guard). CLAUDE.md calls them DEBUG. A Release build launched with `-resetDemo` would run
   `resetUserData`, which wipes his history and, once this ships, his settings too. Launch arguments only come from an
   Xcode scheme or a UI test, so the risk is a scheme left with `-resetDemo` ticked on a Run to his phone. Worth
   wrapping in `#if DEBUG`.
4. **`adoptRestored` and `BackupKeeper.forget` both have no caller.** The first is gap 4, waiting on this object. The
   second means a picked folder can only be replaced, never cleared.
5. **The look is read before the database opens** (`TesseraApp.swift:18` before `:20`), so the look can never live
   only in the database. A device mirror is required, not optional.
6. **#239's empty-store guard and the settings object can conflict.** The guard counts every non-`system` op as one of
   his actions, so it needs the exclusion described under the design rules. Without it, the settings object would
   reopen gap 1.
