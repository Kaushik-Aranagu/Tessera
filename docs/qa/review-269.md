# QA review 269: launch flags (#269), the Oct 22 install target

Merge 444e72b, head 2634f5d, 26 files (+132/-63). Static review; no toolchain here.

**Verdict: PASS. Safe to install on his phone.** No reverts against the first parent. No blockers. One check for the Mac before the install (I1).

## Every flag is simulator-only
- `LaunchFlags.allowed` is `#if targetEnvironment(simulator)` (App/LaunchFlags.swift:8-14), not `DEBUG`, so a Debug build from Xcode on the phone reads no flags. `has` and `value(after:)` both check `allowed` first.
- I grepped App, Features, DesignSystem, Shared, Widgets and TesseraCore/Sources. No `ProcessInfo...arguments` read, `arguments.contains` or `firstIndex(of: "-…")` is left outside LaunchFlags, except three `arguments:` parameters, and each of them only feeds LaunchFlags:
  - `AppClock.configure` passes its arguments to `LaunchFlags.value`.
  - `Theme.configure` does the same.
  - `DemoData.prepare` reads `-resetDemo` from them only after `guard allowed, LaunchFlags.allowed` (DemoData.swift:18). A test can narrow this but never widen it.
- 22 flags go through it: -demo, -resetDemo, -demoTime, -theme, -queueScript, -tessScript, -openLink, -homePage, -fakeClaudeKey, -backupFailure, -soulGallery, -notes, -review, -groceries, -looks, -backup, -recipe, -pasteRecipe, -pasteDemo, -demoKitchen, -demoNotes and -demoReview.
- **This closes review-244 G1:** -queueScript, -tessScript and -demoTime no longer write on a device.
- `-fakeClaudeKey` returns an `InMemoryKeychain` only behind the gate, inside `#if DEBUG` (ClaudeSection.swift:40-47). On the phone, the real Keychain is always used.

## resetUserData can't run on a phone
`ObjectStore.resetUserData()` is `#if os(iOS) && !targetEnvironment(simulator) return` (ObjectStore+Lifecycle.swift:55-56), whoever calls it. Its only caller is `DemoData.reset`, which is already gated twice. `swift test` on the Mac is macOS, so the package tests still exercise the wipe.

## The UI test skip really runs (the coordinator's question)
- `SimulatorOnlyTestCase.setUpWithError()` throws `XCTSkip` off the simulator (TesseraUITests/SimulatorOnly.swift).
- All three UI test classes inherit it.
- ClaudeSettingsUITests and HomeQueueUITests override `setUp()`, not `setUpWithError()`. That's fine: XCTest calls `setUpWithError()` and `setUp()` as two separate methods, `setUpWithError()` first, so the base class's throw still happens.
- Their `setUp()` only sets `continueAfterFailure`, and every `app.launch()` is in a test body, so nothing touches the app before the skip.
- The skip compiles into the UI test bundle, which is built for the same destination, so it is true on a phone.

## Rollback: a catalog-v4 master database opened by an older build
I traced this against b19fb4a (on his phone, or the pending install) and e7a5be4 (the fallback). **No crash and no data loss.**
- **Database schema:** master is still on migrations v1-v3; nothing has been added since #225.
  - GRDB 7.11.1's `migrate` ignores migrations it doesn't know. It reads all applied ids, runs only the unapplied known ones, and its only `fatalError` is for `migrate(upTo:)` below an applied known migration, which never happens here (DatabaseMigrator.swift:615-645).
  - So b19fb4a (v1-v2) opens a v3 file without throwing. Its `isDamaged` (review-244 G2) never sees an error, and the store is never moved aside.
  - No build sets `eraseDatabaseOnSchemaChange` or calls `erase()`.
  - The old build rewrites ops without `zone`, as review-225 said.
- **Catalog v4:**
  - Old `SystemCatalog.existing` skips the unknown `settings` key (`guard let key … else { continue }`).
  - `needsRefresh` is `packageVersion < package.version`, and 4 < 3 is false, so an old build never re-specs the v4 classes.
  - `upgradeExpression` only replaces formulas listed as retired.
  - The Settings class just sits unused. Moving forward again, v4 sees packageVersion 4 and doesn't re-seed.
- **No settings ops exist yet:** `SettingsStore` / `WriteSettings` are never called from App or Features at 444e72b (`migrate()` isn't wired), so an old build meets no unknown op.
- **Caveat, as before:** an old build refuses to restore a backup made by a newer one ("made by a newer build"). After a rollback, don't restore with the old build.

## Other changes
- **Closes review-266:**
  - B1: `PleinGround.nightGround` is named, and the Paint.swift comment is fixed.
  - B2: the "92%" comment.
  - B3: decided differently. The rest Lock Screen is now Kaushik's Cobalt sky in every look (`RestPalette.cobaltSky`, RestLiveActivity.swift:107), so it is never light on white. `LookTableDriftTests` still pins the five base palettes.
- **LiveTessCorner** gets 12 pt of trailing room so Undo clears the soul's done splash (Design A2).
- **LaunchFlagsTests** cover `has` and `value(after:)` with a present flag, a missing flag and a missing value.

## Before the install
- **I1 (Mac, a minute):** `scripts/test.sh` builds only the Tessera scheme, so the TesseraUITests target was never compiled by the green run (287 package, 111 app). Run `xcodebuild -scheme TesseraUITests -destination 'platform=iOS Simulator,name=iPhone 17' build-for-testing` once.
  - The point is to confirm the `@MainActor` test classes compile on a nonisolated `SimulatorOnlyTestCase` base. Swift 6 allows this for a non-Sendable superclass (SE-0434), and XCTestCase is non-Sendable, so I expect it to pass.
  - It doesn't affect the app on his phone either way.
- The install rules still hold: empty scheme arguments and no UITests with his phone as the destination. The flags are now harmless on the phone, but a device test run still reinstalls the Debug app.

## Still open elsewhere
- **review-244 G2** (`isDamaged` treats any non-SQLite error as damage) is unchanged, with Core (T11). The rollback above never reaches it.
