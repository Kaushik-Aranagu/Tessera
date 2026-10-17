# scripts/test.sh audit

Read from `scripts/test.sh` and the test layout. Costs are **inferred** from the script and test counts, not measured; time one clean run on the Mac before trusting any number.

Test inventory: `TesseraCore/Tests/TesseraCoreTests` has 72 files and about 438 `@Test` (one target, macOS 27 / iOS 27 platforms). `TesseraTests` (app) has 24 files and about 137 `@Test`.

## Stages

| # | Stage | Command | Needs | Rough cost (inferred) |
|---|---|---|---|---|
| 1 | Engine package tests | `cd TesseraCore && swift test` | Mac with a Swift toolchain that has the macOS 27 SDK. No simulator. | Cold: SwiftPM resolves GRDB and compiles the package, a few minutes. Warm: tens of seconds to 1-2 min. ScaleTests run at 200 workouts by default. |
| 2 | 5-year scale (only `--scale`) | `TESSERA_SCALE=1500 swift test --filter "ScaleTests\|OnDiskTests"` | Same as 1 | Rebuilds nothing if stage 1 ran; run time grows with 7.5x the workouts (about 37,500 sets). Minutes. |
| 3 | xcodegen | `xcodegen generate` | Mac with XcodeGen | Seconds. Needed because the project is gitignored. |
| 4 | App build + tests | `xcodebuild -scheme Tessera ... test` | Mac, full Xcode, iOS 27 simulator "iPhone 17" (boots a sim) | The dominant cost. Cold: full app + GRDB build, then sim boot, then 24 test files. Likely 5-15 min cold, 2-5 min warm (DerivedData is kept at `.build/DerivedData`, which helps). |

Stage 4 also compiles TesseraCore a second time (as a dependency for iOS), independent of stage 1's macOS build.

## Docs-only diffs

**No diff base, no skipping:** a run with no diff base (an exact-SHA release gate run, or any run where the merge base is unknown) always runs the full suite. The skip rules below apply only to a PR run against a known base.

Stages 1-4 all test code. For a diff that touches only docs, none of them can fail from the change.

Safe skip rule (all must hold, computed from `git diff --name-only origin/master...HEAD`):
1. Every changed path matches `docs/**`, `*.md`, `docs/recordings/**`, or `scripts/ops/**`.
2. No changed path is under `App/`, `DesignSystem/`, `Features/`, `TesseraCore/`, `TesseraTests/`, `Widgets*`, or is `project.yml`, `Package.swift`, `Package.resolved`, `.swiftlint.yml`, `.swiftformat`, or `scripts/test.sh`.
3. When in doubt (renames, deleted files, an unknown path), do not skip.

A docs-only PR then runs nothing in test.sh; run only `swiftformat --lint` or a markdown link check if wanted. Also skippable on a diff touching only `TesseraTests/`: stage 1. On a diff touching only `TesseraCore/Sources` with no app-facing API change: stage 4 is still required (app compiles against it).

## Parallelism

- Stage 1 (macOS package build) and stage 4's compile are independent and use different build dirs (`TesseraCore/.build` vs `.build/DerivedData`). They can run together; CPU-bound, so gains depend on core count. Today they are sequential.
- Stage 2 must follow stage 1 (shares build products) but can run concurrently with stage 4 if cores allow.
- Stage 3 is needed only before 4; it can run during stage 1.
- Stage 4 itself must not run twice concurrently against one simulator or one DerivedData; see `lane-lock.md`.

## Five speedups, ranked by expected gain

1. **Skip all stages for docs-only diffs** (rule above). Saves 100% on those PRs, which are frequent.
2. **Run stage 1 and stage 4 concurrently** (`&` + `wait`, separate logs). Wall time drops from sum to max, roughly the cost of stage 1 saved.
3. **Build once, test twice for the app**: split `xcodebuild build-for-testing` (can start while stage 1 runs) from `test-without-building`, and keep one booted simulator (`xcrun simctl boot` once, leave it up) so every run skips boot.
4. **Package-only when the diff is `TesseraCore/` tests/sources and the PR is not yet at review**: use `--package-only` during iteration, and `swift test --filter <Suite>` for the suite you touch; keep the full run for the final pre-PR gate.
5. **Cache and pin**: keep `.build/DerivedData` and `TesseraCore/.build` between runs (never `rm -rf` as a habit); add `-skipPackageUpdates` / `-disableAutomaticPackageResolution` to xcodebuild so GRDB is not re-resolved; run `swift test --parallel` for the package (Swift Testing already parallelises within a process; verify no test shares on-disk state first, since OnDiskTests exist).

Not a speedup but a correctness note: stage 4 greps log for `TEST SUCCEEDED` only indirectly (exit code decides); a crashed simulator can look like a failure, so rerun once before treating it as red.
