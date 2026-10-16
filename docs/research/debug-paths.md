# Debug paths that can touch Kaushik's data

*Research, 2026-10-16. Checked against `origin/master` at `fee3606` (after #243). Read with `git show` and `git grep`
only. No Swift run, nothing installed. Builds on `settings-object.md` (the 22 launch flags) and `restore-drill.md`.*

## Why this matters

Kaushik's phone runs a **Debug** build, installed from Xcode on the free Personal Team. So `#if DEBUG` does not
protect him: every flag below that is "DEBUG only" still runs on his phone if the Xcode scheme he installs from has it
ticked (Edit Scheme, Run, Arguments), or if a test scheme is run with his iPhone as the destination. Nothing in the
app checks `targetEnvironment(simulator)` today: `git grep targetEnvironment origin/master` finds nothing.

## Builder A's launch-arg PR

**PR not found.** I checked the 25 most recently pushed branches (`git branch -r --sort=-committerdate`) and every
remote branch whose diff touches `TesseraApp.swift` or `DemoData.swift`. None changes the launch flags. The only hit
is the board branch `claude/project-thread-tjn3bv`, which lists the guard as Builder A's **Now** item ("gate them to
the simulator, or refuse a reset when user ops exist"). So every "after the PR" cell below says "PR not found", and
the checklist at the end is for QA to tick when it lands.

## Summary

| Risk | Count | Items |
|---|---|---|
| Data loss | 2 | `-resetDemo` (1), the TesseraUITests scheme run on his phone (2) |
| Data pollution | 9 | `-demo` (3), `-demoReview` (4), `-queueScript` (5), `-tessScript` (6), `-demoKitchen` (7), `-demoNotes` (8), `-demoTime` (9), `-backupFailure` (10), UserDefaults argument domain (11) |
| Harmless | 12 | `-theme` (12), `-fakeClaudeKey` (13), 8 screen swaps (14), `-homePage` (15), `-openLink` (16), `-pasteDemo` (17), hosted unit tests (18), `UITEST_SNAPS` (19), committed schemes (20), plus three launch paths that are not debug paths (21 to 23) |

Two items are worse than their flag suggests: `-demoReview` and `-queueScript` do not add demo rows, they **change his
own tasks** (mark them done, move them to later).

## The items

"Sim gate" means wrapped in `#if targetEnvironment(simulator)` (or an equivalent runtime check).

### Data loss

**1. `-resetDemo`**
- Trigger: launch argument `-resetDemo` (with or without `-demo`).
- Where: `App/TesseraApp.swift:29-31` calls `DemoData.prepare`; `Features/Demo/DemoData.swift:9-10` calls `reset`
  (`:22-28`), which calls `ObjectStore.resetUserData()` in
  `TesseraCore/Sources/TesseraCore/Engine/ObjectStore+Lifecycle.swift:53-71`.
- What it does: deletes **every object, every link, the whole op log and every user class**, saves, then reseeds the
  catalog and starter plan, then seeds six weeks of fake history. The op log goes too, so there is no undo. Settings
  that will live in the object graph (the settings object in `settings-object.md`) go with it.
- Backups: the empty-store guard (`TesseraBackup.swift:136-138`, merged) does not help, because the demo seeding right
  after the wipe writes `.user` ops, so the next background copy is a demo store. After 04:00 an existing day's copy is
  kept (`:140-149`), so his last 7 good days survive, but each new day pushes one out. A staged restore is also wiped
  if the next launch has `-resetDemo` (the trap in `restore-drill.md`).
- `#if DEBUG`: **no**. Sim gate on master: **no**. After Builder A's PR: PR not found.
- Risk: **data loss**.

**2. Running the TesseraUITests scheme with his iPhone as the destination**
- Trigger: choosing the `TesseraUITests` scheme (defined in `project.yml:126-133`) and pressing Test with his phone
  selected, or `xcodebuild test` with a device destination.
- Where: `TesseraUITests/ClaudeSettingsUITests.swift:12` and `TesseraUITests/HomeQueueUITests.swift:14` and `:28` launch
  the app with `-demo -demoTime 18:10 -resetDemo`. The UI test runner drives the real app, bundle id
  `com.kaushikaranagu.tessera`, the same app and the same store as his.
- What it does: the same full wipe as item 1, three times in one run. HomeQueueUITests then drags rows (writes).
- `#if DEBUG`: not applicable (test code; the app under test is a Debug build, so the flag is honoured). Sim gate on
  master: **no** (no `XCTSkip` on device). After Builder A's PR: PR not found.
- Risk: **data loss**. This is the most likely real-world path: one wrong destination in the Xcode toolbar.

### Data pollution

**3. `-demo`**
- Trigger: launch argument `-demo`.
- Where: `App/TesseraApp.swift:29-31`, `Features/Demo/DemoData.swift:8-20`, seeders `:42-58`, `:61-`, `:111-`,
  `:162-`.
- What it does, on every launch with the flag: if no routine is titled "Push Day A", adds a Push / Pull / Legs plan
  and six weeks of fake workouts and sets (`seedLibrary`); if today's schedule is empty, adds 8 fake tasks and a fake
  "Push Day A" workout for today (`seedToday`). These mix into his real history, PRs, e1RM trends and weekly sets, and
  then into every daily backup. Removing them by hand means finding each row.
- `#if DEBUG`: **no**. Sim gate on master: **no**. After Builder A's PR: PR not found.
- Risk: **data pollution** (heavy).

**4. `-demoReview`**
- Trigger: launch argument `-demoReview`, then opening Review.
- Where: `Features/Review/ReviewView.swift:322-339`, run from `:19-20`.
- What it does: if he has 3 or more open tasks and no notes, marks **his first two open tasks done**, moves **his third
  to later**, and adds a note "Deload next week on @Bench Press". All as `.user` actions.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution** (edits his own rows; each op is in the log, so it can be undone one by one if he notices).

**5. `-queueScript`**
- Trigger: launch argument `-queueScript`, then Home's queue on screen.
- Where: `Features/Home/HomeQueue.swift:290-292` and `:295-320`; the writes are `finish()` at `:427`
  (`SetTaskDone`) and `move()` at `:447` (`MoveTask`).
- What it does: after 2.5 s the first undone task row on Home finishes itself (**his real task marked done**); after 8 s
  a second row moves to tomorrow or next week.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution** (edits his own rows; undo shows briefly on screen).

**6. `-tessScript`**
- Trigger: launch argument `-tessScript`.
- Where: `Features/Command/BottomChrome.swift:81-85` and `:349-367`; commit via `dry()` at `:413-430`. `open()` at
  `:371-377` also clears the launch note.
- What it does: opens Tess, types "stretch at 21:30" and commits it: a real task is added to his day on every launch.
  It also clears any pending launch note (for example "Your data couldn't be read, so I started fresh"), so he could
  miss a real warning.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution**.

**7. `-demoKitchen`**
- Trigger: launch argument `-demoKitchen`, then opening Groceries or Recipes.
- Where: `Features/Groceries/GroceriesView.swift:707-758` (seed at `:745-756`), run from `:22-24` and
  `Features/Recipes/RecipesEntry.swift:24-25`.
- What it does: if he has no recipes, adds two recipes (carbonara, dal), puts them on the grocery list, and adds four
  grocery lines.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution**.

**8. `-demoNotes`**
- Trigger: launch argument `-demoNotes`, then opening Notes.
- Where: `Features/Notes/NotesView.swift:22-24` and `:28-45`.
- What it does: if he has no notes, adds three fake notes.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution** (small).

**9. `-demoTime HH:mm`**
- Trigger: launch argument `-demoTime 18:10` (any time).
- Where: `App/AppClock.swift:18-31`.
- What it does: shifts the app clock. Anything stamped with `AppClock.now` is wrong by the offset, for example a
  task moved from Home (`HomeQueue.swift:441-447`), the day a backup copy is filed under (`BackupKeeper.runDaily`,
  `BackupKeeper.swift:63`, called from `TesseraApp.swift` on background), the 04:00 day roll, rest timers and "today".
  A set logged at 07:00 under `-demoTime 18:10` can land on the wrong day.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution** (wrong times and days; clock change).

**10. `-backupFailure`**
- Trigger: launch argument `-backupFailure`, then opening Backups.
- Where: `Features/Backup/BackupKeeper.swift:53-59`, run from `Features/Backup/BackupView.swift:127-130`.
- What it does: records a fake "out of space" iPhone copy failure in UserDefaults (`BackupKeeper.swift:45-50`). This
  persists after the flag is gone, so Backups keeps saying a copy failed when it didn't. His data is untouched.
- `#if DEBUG`: yes. Sim gate on master: no. After Builder A's PR: PR not found.
- Risk: **data pollution** (device state, not his objects; low).

**11. UserDefaults argument domain (`-<key> <value>`)**
- Trigger: any launch argument shaped `-key value`. Foundation puts these in the argument domain, which every
  `UserDefaults` read sees first. This works in **Release builds too**; no flag needs to be read by the app.
- Keys it could hit: `tessera.launchNote` (`TesseraSchema.swift:99-112`, a fake launch line), `look.day`,
  `look.night`, `look.pinned` (`DesignSystem/Looks.swift:146-150` and `:191-209`; if he then changes a look,
  `save()` at `:314-321` writes the overridden values for real), the backup folder bookmark
  (`BackupKeeper.swift:94`; would need valid bookmark bytes, so unlikely), the backup failure list.
- `#if DEBUG`: no (it's Foundation). Sim gate: not possible in app code without clearing the domain. After Builder A's
  PR: PR not found.
- Risk: **data pollution** (settings only; low, needs a deliberate odd argument).

### Harmless

**12. `-theme <name>`**: `DesignSystem/Theme.swift:277-285`, pin in `Looks.swift:297-301`. Pins a look **in memory
only**; `save()` writes nothing while a demo pin is on (`Looks.swift:316-317`). Side effect: look changes he makes
during that launch are silently not kept. `#if DEBUG`: **no** (the comments say DEBUG, the code has no guard). Sim
gate: no. After PR: PR not found. Risk: harmless display.

**13. `-fakeClaudeKey`**: `Features/Settings/ClaudeSection.swift:40-48`. Swaps the Keychain for an in-memory one holding
a fake placeholder key. His real Keychain key is never read or written. Side effects: Settings shows a key that isn't
his; a real key he adds that launch lives in memory only and is gone on quit; Test would fail. `#if DEBUG`: yes. Sim
gate: no. After PR: PR not found. Risk: harmless (fake key, confusing).

**14. Screen swaps `-soulGallery`, `-notes`, `-review`, `-groceries`, `-looks`, `-backup`, `-recipe`,
`-pasteRecipe`**: `App/TesseraApp.swift:45-70`. Replace the root view with one screen. Writes only happen through his
own taps on that screen (`-backup` shows the real restore controls). `#if DEBUG`: yes. Sim gate: no. After PR: PR not
found. Risk: harmless display. Note that `-notes`, `-review` and `-groceries` run their seeders when paired with items
4, 7 and 8.

**15. `-homePage <page>`**: `Features/Home/HomeSpatialView.swift:51-60`. Opens Home on a page. `#if DEBUG`: yes. Sim
gate: no. Risk: harmless display.

**16. `-openLink <link>`**: `Features/Home/HomeSpatialView.swift:111-121`. Opens Notes, Recipes, Groceries or Review
after 1.5 s. `#if DEBUG`: yes. Sim gate: no. Risk: harmless navigation (but it triggers the seeders in 4, 7 and 8 when
those flags are also on).

**17. `-pasteDemo`**: `Features/Recipes/PasteRecipe.swift:137-144`. Fills the paste field with the dal recipe and
shows the preview (`read()` at `:159-`); saving still needs his tap on Save (`onSave` at `:102`). `#if DEBUG`: yes.
Sim gate: no. Risk: harmless (draft only).

**18. Unit tests (`TesseraTests`) run on his phone**: `project.yml:100-112` hosts them in the app (`TEST_HOST`), so the
app launches against his real store first (a normal launch). The tests themselves build in-memory containers
(`makeContainer(inMemory: true)`, for example `TesseraTests/AppModelTests.swift`) and don't touch `UserDefaults`,
`ThemeStore.shared`, the Keychain or backups (grep finds none). Risk: harmless.

**19. `UITEST_SNAPS` environment variable**: `TesseraUITests/HomeQueueUITests.swift:68`. Test-side only: where to save
screenshots. Risk: harmless. (No other `ProcessInfo.environment` read exists in the app; the `SPIKE_*` ones are in
`tools/storage-spike`, not the app.)

**20. Committed schemes**: `project.yml:125-140` defines `Tessera` and `TesseraUITests` with **no** launch arguments
and **no** environment variables. No `.xcscheme` is in git (`Tessera.xcodeproj` is gitignored).
`.mobilebuildmcp/config.yaml` and `scripts/test.sh` target the iPhone 17 simulator only. So any ticked flag is a local
edit in Xcode, not something a pull brings in. Risk: harmless as committed; the danger is a local scheme edit.

### Launch paths that are not debug paths (listed so the list is complete)

**21. Pending restore** (`TesseraSchema.swift:35-42`, `TesseraBackup.applyPendingRestore` at
`TesseraBackup.swift:259-`): replaces the store at launch, but only after he stages a restore in Backups, and it keeps a
Before-restore copy. Overwrite by design. Interacts badly with item 1 (a `-resetDemo` launch wipes what was just
restored).

**22. Damaged-store recovery** (`TesseraSchema.swift:48-72`): only a corrupt store is moved aside into Backups for a
fresh start; passing errors run from memory and leave files alone. Not debug, not flag-driven.

**23. Legacy SwiftData migration** (`TesseraApp.swift:22-26`, `TesseraLegacyStore/LegacySchema.swift:33-47`): merges
the old store once (merging, never replacing), moves the old files aside, retries on failure. No flag. Harmless. (The
catalog seed renaming Routine on each launch, `SystemCatalog.swift:312`, is a known op-log item in `oplog-health.md`,
not a debug path.)

No debug menu, hidden gesture, shake handler or settings row reaches any of the above: every debug path is a launch
argument.

## Recommended gate

1. **One helper, simulator only, for every flag that writes.** In the app, for example `App/LaunchFlags.swift`:

   ```swift
   enum LaunchFlags {
       /// Demo and test flags. Only honoured in a Debug build on the simulator; on a device they do nothing.
       static func has(_ flag: String) -> Bool {
           #if DEBUG && targetEnvironment(simulator)
               ProcessInfo.processInfo.arguments.contains(flag)
           #else
               false
           #endif
       }
   }
   ```

   Route these through it: `-resetDemo`, `-demo`, `-demoReview`, `-queueScript`, `-tessScript`, `-demoKitchen`,
   `-demoNotes`, `-demoTime`, `-backupFailure`. Grep afterwards: no `ProcessInfo.processInfo.arguments` read outside the
   helper, `Theme.configure`'s argument parse and the display-only flags.

2. **Belt and braces on the wipe.** `resetUserData()` refuses when the store has user ops that the demo did not
   write. Simplest rule: the demo seeder sets a marker (for example a `demo.seeded` UserDefaults key, or a demo
   actor on its ops); `-resetDemo` runs only when the marker is set or `userOps == 0`. Otherwise it logs "refused:
   this store has real history" and does nothing. Keep this even with the simulator gate, so a simulator holding a
   restored copy of his real data is safe too.

3. **UI tests skip on a device.** In each UI test `setUp`, `#if !targetEnvironment(simulator)` then
   `throw XCTSkip("UI tests wipe data; simulator only")`. With step 1 the flags are dead on a device anyway; this makes
   the skip visible instead of silently running against his data.

4. **Display-only flags can stay `#if DEBUG`**, but `-theme` should get the `#if DEBUG` its comment promises
   (`Theme.swift:277`). `-fakeClaudeKey`, the screen swaps, `-homePage`, `-openLink` and `-pasteDemo` are fine as they
   are; moving them behind the helper too is cheaper than remembering which is which.

5. **Say it out loud.** On a device launch that carries any demo flag, write one launch note: "Demo flags are ignored
   on this phone." Then a ticked scheme is noticed, not silent.

6. Leave the UserDefaults argument domain alone (item 11); it needs a deliberate odd argument. Optionally, never read
   `tessera.launchNote` or the look keys from `NSArgumentDomain` (read `UserDefaults.standard.persistentDomain`) if
   that ever matters.

## QA checklist for Builder A's PR

Tick each against the PR diff (code review is enough where no simulator is available).

- [ ] `-resetDemo` cannot run on a device: its check compiles to false unless `DEBUG && targetEnvironment(simulator)`
      (`TesseraApp.swift:29-31`, `DemoData.swift:9`).
- [ ] `-demo` cannot run on a device (same lines).
- [ ] `resetUserData()` refuses a store with real user ops (demo marker or `userOps == 0` rule), with a test: a store
      with one `.user` op not from the demo survives `DemoData.prepare` with `-resetDemo`.
- [ ] `-demoReview` (`ReviewView.swift:327`), `-queueScript` (`HomeQueue.swift:299`) and `-tessScript`
      (`BottomChrome.swift:82`) are simulator-only: these edit his real tasks.
- [ ] `-demoKitchen` (`GroceriesView.swift:746`) and `-demoNotes` (`NotesView.swift:33`) are simulator-only.
- [ ] `-demoTime` (`AppClock.swift:19`) is simulator-only.
- [ ] `-backupFailure` (`BackupKeeper.swift:56`) is simulator-only.
- [ ] `-theme` (`Theme.swift:277-285`) is inside `#if DEBUG` at least.
- [ ] Both UI test files skip on a device (`XCTSkip` when not the simulator).
- [ ] `git grep -n 'processInfo.arguments' ` on the PR branch shows no write-capable flag read outside the helper.
- [ ] `project.yml` schemes still carry no launch arguments or environment variables; no `.xcscheme` added to git.
- [ ] CLAUDE.md "Running the demo" says the demo flags are simulator-only.
- [ ] Optional: a device launch with a demo flag shows one launch note saying the flags were ignored.
- [ ] Simulator still works: `-demoTime 18:10 -resetDemo` reseeds the demo there, and `scripts/test.sh` ends
      "All green".

## After #244 (806b085)

*Addendum, 2026-10-16. Re-checked on `origin/master` at `fdcaee4`, which contains #244 (merge `806b085`, branch
`ios/demo-guard`). The sections above are unchanged and still describe `fee3606`.*

**Why the first sweep missed it:** #244 merged right after the scan. Master was at `fee3606` (#243) when I fetched,
and `ios/demo-guard` was not among the remote branches at that moment.

### What #244 does

- `Features/Demo/DemoData.swift:10-16` adds `DemoData.isAllowed`, which is `true` only under
  `#if targetEnvironment(simulator)` and is a compile-time `false` in a device build.
- `Features/Demo/DemoData.swift:18-21`: `prepare` takes `allowed: Bool = DemoData.isAllowed` and returns at once when
  it is false, before the `-resetDemo` check (`:22-24`) and the seeders (`:26-31`).
- `App/TesseraApp.swift:30` checks `DemoData.isAllowed` before it even looks at `-demo` / `-resetDemo`.
- `TesseraTests/DemoGuardTests.swift` (new): with `allowed: false`, a real task survives `["-demo", "-resetDemo"]` and
  no "Push Day A" routine appears.
- `CLAUDE.md:62` now says `-demo` and `-resetDemo` are simulator only.

### Items closed

- **Item 1, `-resetDemo`: closed on a device.** The only app caller of `resetUserData()` is `DemoData.reset`
  (`DemoData.swift:35-36`, private), and it is reachable only through `prepare` past the guard at `:21`. The other
  `DemoData.prepare` call outside tests is the `#Preview` in `App/RootView.swift:92-95`, which uses an in-memory store.
  The remaining `resetUserData()` calls are Core package tests on their own stores.
- **Item 2, the TesseraUITests scheme on his phone: the wipe is closed** (it went through item 1). It is not fully
  closed: see "Still open".
- **Item 3, `-demo`: closed on a device**, with the same guard (`TesseraApp.swift:30`, `DemoData.swift:21`).

Checklist lines #244 ticks:

- [x] `-resetDemo` cannot run on a device (`TesseraApp.swift:30`, `DemoData.swift:11-15, 21`). It is gated by
      `targetEnvironment(simulator)` alone, not `DEBUG &&`. That is fine, because the simulator gate is the stronger one.
- [x] `-demo` cannot run on a device (same lines).
- [x] `project.yml` schemes still carry no launch arguments or environment variables, and no `.xcscheme` was added.
      #244 touched only the four files above.
- [x] CLAUDE.md says the demo flags are simulator only (`CLAUDE.md:62`).
- [~] Simulator still works: by code review yes, because the simulator path through `prepare` is unchanged and
      `theTestsRunWhereDemoDataIsAllowed` asserts it. I did not run `scripts/test.sh` (no simulator here).

### Still open, for Builder A's next small PR

- [ ] **`XCTSkip` on a device in TesseraUITests** (`ClaudeSettingsUITests.swift:6-8`, `HomeQueueUITests.swift:7-9`). On
      a device the tests no longer wipe, but they still launch his real app with `-demoTime 18:10` (still honoured on a
      device) and drive it. The drag test looks for the demo row "Stretch & mobility", so on his data it should fail
      at the wait rather than finish one of his tasks. That is luck, not a guard.
- [ ] **One `LaunchFlags` helper, simulator only**, for `-queueScript` (`HomeQueue.swift:299`), `-tessScript`
      (`BottomChrome.swift:82`), `-demoTime` (`AppClock.swift:19-20`), `-demoReview` (`ReviewView.swift:327`),
      `-demoKitchen` (`GroceriesView.swift:746`), `-demoNotes` (`NotesView.swift:33`) and `-theme`
      (`Theme.swift:277-285`, still with no `#if DEBUG` at all). Add `-backupFailure` (`BackupKeeper.swift:56`) too. It
      only writes a fake failure line, but that line persists. All of these still run on his phone today.
      `-demoReview` and `-queueScript` still edit his real tasks.
- [ ] **`resetUserData()` refusing a store with real ops: not included.** `ObjectStore+Lifecycle.swift:53-71` is
      unchanged, and it is `public` (`:5`, `public extension ObjectStore`). This matters on the simulator: a simulator
      holding a restored copy of his real backup (the restore drill) is still wiped by `-resetDemo`.
- [ ] Optional, not included: a launch note on a device saying the demo flags were ignored.
- [ ] Checklist line "`git grep processInfo.arguments` shows no write-capable flag outside the helper": still fails;
      there is no helper yet.

### Things #244 does that look slightly off (none is a device data-loss path)

1. **There is no second line of defence in Core.** `resetUserData()` is a public, unguarded wipe of objects, links,
   the op log and user classes. #244 guards only its one caller. Any future caller in the app or an intent bypasses the
   guard. The fix is the refusal rule above, or `resetUserData` taking a "this is a demo store" proof.
2. **`prepare(_:arguments:allowed:)` takes `allowed` as an ordinary parameter.** It exists for the test, but any call
   site can pass `allowed: true` and seed or wipe on a device. A comment saying "tests only", or limiting the
   parameter to the test target (for example behind `#if DEBUG` plus a test-only overload), would close it.
3. **The guard is simulator-only, not `DEBUG &&` simulator.** A Release build on the simulator still honours
   `-resetDemo`. That is harmless for his phone and fine to leave, but the original recommendation was
   `#if DEBUG && targetEnvironment(simulator)`.
4. **The test file is in the hosted `TesseraTests` target** and uses an in-memory store, so running it on his phone is
   safe. `theTestsRunWhereDemoDataIsAllowed` would fail on a device, which is a fine signal that the tests are running
   in the wrong place.

**Bottom line:** both data-loss paths (items 1 and 2) are closed on his phone. Seven writing flags remain open on his phone:
`-queueScript`, `-tessScript`, `-demoReview`, `-demoKitchen`, `-demoNotes`, `-demoTime` and `-backupFailure`. The
argument-domain item stays as advised. `-theme` is also open (harmless, but still not inside `#if DEBUG`). The
UI test `XCTSkip` and the `resetUserData` refusal are still to do.
