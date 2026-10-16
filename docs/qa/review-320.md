# Review 320: SettingsStore wiring, "Tess asks Claude" (M1), empty wrap-up UNDO (L2)
PR #320 at 7af4026, base f1bf709 (an ancestor of master 7cae550). Trial merge onto 7cae550 clean. 12 files, app side only (TesseraCore, `project.yml` untouched). Static review, Oct 15 PT. Recording `settings-store.mp4`: 590×1282, 60 fps, 46 s.

**Verdict: FIX FIRST** on F1 (fails open, and can lose his "no", when the store opens in memory). M1 itself is right.

## M1: migrate every launch, "no" wins: PASS
- `AppModel.swift:96-100` runs `migrateAtLaunch` on every non-demo launch. Core's `migrate` (TesseraSettings.swift:111-113) ANDs the old key into the field, so an old "no" wins; `migrateAtLaunch` then removes `tess.missesGoToClaude` only if migrate succeeded (AppModel.swift:629-632). A later yes can't be outvoted, and a failed migrate keeps the key for the next launch.
- One field: the toggle (`ClaudeSection.toggleMisses`, `load`) and the router's gate (`AppModel.swift:110-112`) both read/write `missesGoToClaude` through `SettingsStore`. `@AppStorage` is gone.
- `update` writes only on change, so launches don't add ops. `TessAsksClaudeTests` covers no → on/off/on with double relaunches, and a fresh install.

## F1 (must fix): the gate fails open on an in-memory store, and the migration can eat his "no"
`read()` returns all-nil settings when the settings object isn't there, so `sendsMissesToClaude` is `true`. That's Product's default for a fresh install, but it's also what the gate sees when the store fell back to memory (G2, `TesseraSchema.lastOpenOutcome == .inMemoryFallback`) or the catalog failed to seed:
1. Misses go to Claude even though he said no (the key is in the keychain, which doesn't fall back).
2. Worse, on the launch that carries this migration, `migrateAtLaunch` succeeds against the throwaway in-memory store and **deletes the legacy key**. His "no" is gone for good; the next normal launch reads nil = yes.
Fix (small): in `AppModel.init`, when `TesseraSchema.lastOpenOutcome != .opened` (or `classes[.settings] == nil`), skip `migrateAtLaunch` and don't wire `capture.claude` (or make the gate return `false`). TesseraApp.swift:24 already checks `.inMemoryFallback` the same way. Test: an in-memory-fallback launch with the old key set to false leaves the key in place and the gate closed.

## F2 (should fix): a failed toggle write shows the wrong word
`ClaudeSection.toggleMisses` flips the word first, then `_ = try? update`. If the write throws, the screen says "no" while the router still sends. Re-read after the write: `missesGoToClaude = SettingsStore(...).read().sendsMissesToClaude`.

## Demos: PASS
`demo` covers `-demo`, `-resetDemo`, `-theme`, `-fakeClaudeKey`, all through `LaunchFlags.has` (simulator-only), so on his phone it's always false and Claude is wired; in demos it never is, and a fake key never reaches the network. The recording is the `-fakeClaudeKey` path ("…a1B2 · not checked"), so it can't show a real send. The toggle and BackupKeeper's folder-name write skip on `-demo`.

## Plan my day and link-fetch L3: can use the same field, not wired yet
Neither `ClaudePlanWording` nor `ClaudeRecipeReader` has an app call site in this PR. Both take an `allowed`/`sendsMisses` closure (PlanWording.swift:409 already names `sendsMissesToClaude`). When they're wired, pass the same closure; better, one `AppModel.tessAsksClaude` property (with F1's guard inside) that all three read.

## Key, LaunchFlags, migrations: PASS
- Key: `SystemKeychain()` read per call by `ClaudeTessModel`; no key, last four or bookmark goes into settings, logs or the op log. Only copy changes around the key.
- No raw `ProcessInfo` argument reads; no new flags.
- Migrations additive: no schema or catalog change. Settings ride as `writeSettings` ops; BackupView's restore hint ignores them (C4).

## L2 (empty wrap-up UNDO): PASS
`tidyNotes` gives each line its own `undo`; only the "no sets, not saved." line carries one, and BottomChrome passes it with the line and clears both together, so UNDO sits under the line it undoes and leaves with it. `anEmptyWrapUpCanBeTakenBack` undoes it and the workout returns.

## Lows
- L1: ClaudeSection.swift:59 comment says the old key is "still written for one release"; nothing writes it now.
- L2: the line reads "Misses go to Claude: yes." Settings copy is "Tess asks Claude: yes." as the CLAUDE section's first line (settings-place.md); Design's call whether this PR or the ClaudeSection PR changes it.
- L3: BackupKeeper writes the folder name as `.user`. Harmless now (C4 excludes `writeSettings`), but `.system` matches the migration.
- Recording: 60 fps, shows the -fakeClaudeKey path, the key Remove → UNDO → "Claude key is back.", and the restore hint. Visual changes (context → inkSecondary, the "today" context line, the wrapping voice line) are Design's.

## Install-day checks to add
1. Review > Claude shows "yes" after install (his old answer if it was "no"); toggle no, relaunch, still no; toggle yes, relaunch, still yes.
2. With yes and a key, a capture the phone can't read shows "Asking Claude." and a receipt; with no, it stays on the phone.
