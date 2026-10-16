# Review #244: demo guard (806b085, head 0443e6b)

Builder A. 4 files, +41/-3. Static review (no Swift toolchain here).

**Verdict: PASS.** `-demo` and `-resetDemo` can no longer touch his phone. I found no other path that deletes his data. But several other launch arguments still *write* to the store on a device Debug build (G1), and one launch fallback moves the store aside on any non-SQLite error (G2). Neither is a wipe; both are worth closing.

## The guard
- `DemoData.isAllowed` is `#if targetEnvironment(simulator)`: a compile-time check, so a device build has `false` baked in, whatever the scheme's arguments say.
- It's checked twice: in `TesseraApp.init` (App/TesseraApp.swift:30) and again inside `prepare` (`guard allowed`), so no caller can skip it.
- The only other caller is RootView's `#Preview` (App/RootView.swift:95), on an in-memory container. Previews run in the simulator runtime, so they still get demo data, and they never touch the real store.
- `reset` (the only caller of `ObjectStore.resetUserData()`, DemoData.swift:35-36) is private and reached only through `prepare`.
- `DemoGuardTests` checks that `prepare(allowed: false)` with both flags keeps a real task and seeds nothing. ✓

## Nothing else deletes his data (checked on master 806b085)
- **`resetUserData` / `deleteAll`:** the only caller is DemoData.reset.
- **Staged restore:** `applyPendingRestore` runs only if a restore was staged from the hold "Replace" key. The replaced store goes to Documents/Backups first, and the 3 newest Before-restore copies are kept (#211).
- **Launch fallback** (`TesseraSchema.open`): a damaged store is *moved aside* to a dated folder, never deleted; if the fresh open also fails it's moved back. See G2.
- **Backups:** pruning only removes `Tessera-*.tessera` copies past 7, and since #239 never with an empty store.
- **Export import:** inserts records; it doesn't clear anything first.

## G1 (should-fix, small): other launch arguments still write on a device Debug build
The phone build is a Debug build, so `#if DEBUG` doesn't keep these off it. If one is left ticked in the scheme when he installs:
- **`-queueScript`** (HomeQueue.swift:299): strikes his **first real task** done and slides another to Tomorrow. That's a real write to his data.
- **`-tessScript`** (BottomChrome.swift:82): plays scripted captures, which create real records.
- **`-demoTime HH:mm`** (AppClock.swift:18-31): shifts the app clock. Every op, set and task he logs that day gets a shifted time. Backups are named and dated by the shifted clock, which can trip the clock-behind logic (#211, #239).
- **`-demoKitchen`, `-demoNotes`:** seed recipes, groceries and notes, but only into an empty book or list, so they're low risk.
- **`-fakeClaudeKey`:** the Settings section uses an in-memory key, so his real Keychain key is untouched. Harmless. `-theme`, `-openLink`, `-homePage`, `-backupFailure` and the page flags only change what's shown.

**Fix:** route every launch argument through one helper that is false off the simulator (for example `LaunchArgs.has("-queueScript")`, returning `DemoData.isAllowed && arguments.contains(...)`). `AppClock.configure` should check `DemoData.isAllowed` too. One small PR covers it; Research item 99's sweep can confirm the list.

## G2 (note, for Core): any non-SQLite error at launch counts as damage
`TesseraSchema.isDamaged` returns `true` for any error that isn't a `DatabaseError` (TesseraSchema.swift:76-77). So a Swift error thrown while loading rows would move his store aside and start him fresh, with the line "Your data couldn't be read, so I started fresh." That could be a decode bug in a future build, or a migration that throws its own error.
- Nothing is lost: the files are in the dated backup folder, and the daily copies are there too.
- But it would look like a wipe on his phone. Treating only the four SQLite codes as damage (and everything else as "passing", which runs from memory and leaves the files alone) would be safer.
