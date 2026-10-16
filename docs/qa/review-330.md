# Review 330: app icon, soul at 0.65, the 04:00 test fix
PR #330 (ios/app-icon) at 38c2ed7, base master 450a0c0. Trial merge clean. 9 files: SoulFrame.swift, the AppIcon set (Contents.json + 3 PNGs), ExerciseAndPlansTests.swift, `project.yml` (1 line), recordings 35/36. Static review, Oct 16 PT.

**Verdict: PASS.** Safe to ride with #320's fixes on the next phone build.

## Install-gate checks: PASS
- `project.yml`: the only change is line 68, `ASSETCATALOG_COMPILER_APPICON_NAME: "" → AppIcon`. `PRODUCT_BUNDLE_IDENTIFIER: com.kaushikaranagu.tessera` and the team are untouched; no scheme args, entitlements or targets change. `Resources` is already a source path (project.yml:53) and `Assets.xcassets` already exists on master, so the set is picked up after `xcodegen generate`.
- No raw `ProcessInfo` reads, no LaunchFlags, no UI tests, no migrations, no catalog or store changes. Nothing writes data.

## Icon: PASS
- The three PNGs are byte-identical to Design's masters at 90ca9db (`docs/design/icon/tessera-icon{,-dark,-tinted}-1024.png`, the 65% spread).
- `Contents.json` matches app-icon.md step 1 exactly: universal 1024 light, dark luminosity, tinted luminosity.
- All three are 1024×1024 8-bit RGB with no alpha, so there's no alpha warning on the light icon. If Xcode warns about the opaque dark or tinted slot, app-icon.md:28 names the `-clear` versions to swap in. Design's call, not a blocker.

## Soul at 0.65: PASS (code); the look is Design's
`SoulFrame.swift`: only the `home` offsets go through `tightened`, which pulls each one toward (0, −1), the centroid of the three main dabs ((−14,−8), (14,−8), (0,13)). It scales them by `spread = 0.65`. Bloom, carry, drip, sizes and paints are unchanged, as the PR says. `static let` order is fine (static lets are lazy).

## Test fix: PASS
`ExerciseAndPlansTests.swift:146-148` matches "today" against `TesseraDay(calendar: .current).day(of: now)`, his 04:00 day. That's the fix review-318 named, so between 00:00 and 04:00 it no longer picks tomorrow's `.planned` row. Builder A reports it green at 00:20 PT, inside that window.

## Install-day checks to add
1. Home Screen shows the new icon by day, in Dark mode and in Tinted. If the old blank icon persists after the over-the-top install, restart the phone (iOS caches icons); never delete the app.
2. The soul on Home and in Tess reads tighter, and bloom, carry and the drip still play.
