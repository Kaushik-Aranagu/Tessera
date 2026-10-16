# Review #221: look storage, sheen, leftovers (87bd157, head 29fcaaf)

Builder A. 21 files, +129/-67, no file deletions. I read the code; I didn't run it, because there's no Swift toolchain here.

**Verdict: PASS.**
- ClaudeKey and the day-boundary code are untouched on master.
- Nothing references the removed symbols any more.
- W8 is closed, and so is W9.
- Two lows (W10, W11) and one item for Product or Design (W12).

## Nothing reverted
- #221 changes 21 files. None of them is in TesseraCore, and none is a #218 or #219 file.
- `git diff 15f2d86 origin/master` (c5d7193) is empty for ClaudeKey.swift, ReviewPage.swift, AppModel.swift and DayStrip.swift.

## Removed symbols: nothing still uses them (checked on master c5d7193)
- `Theme.Colors.progress`, `palette.progress` and the `progress:` palette field: no hits. Best e1RM now uses `Theme.Colors.ink` (A31).
- `SoulPalette.light`, `.dark` and `forScheme`: no hits. TessSoul uses `look`/`workout` only, since #215.
- The widget's `Color(hex:)`: no hits in Widgets/ or Shared/. The extension uses `Color(rgb:)` from LookTable.
- `Paint.sheen` in LiveSetStrokes resolves through `private typealias Paint = WorkoutPaint`, and `WorkoutPaint.sheen` is now computed.
- PlansView's `.cobalt` → `Theme.Colors.routines[3]` is in range: `[live, health, now, context]`, so index 3 is context (violet).

## W8: closed
`ThemeStore.paintLook` is `workoutHeld == nil ? current : (pin ?? night)`. Every paint token now reads it: `soulBlend`, `halo`, `sheen`, `sheenBlend` and `ActionBloom`.

While the workout is open:
- Pages pushed inside it are forced dark, and their `ThemedBackground` draws `pair.night`, or the pin. Their paint tokens now match that.
- The pages underneath the cover also read the night look, but they're hidden until the cover closes, and `release` restores `current`.

Tested by `paintResolvesAgainstTheWorkoutsPages`.

## W9: closed
`LookTableDriftTests` checks all five `RestPalette`s against `Look.workout` (ground, ink, signal, rest, tess) and `Look.context`, plus the `forState` fallbacks.

## App Group
- The entitlement `group.com.kaushikaranagu.tessera` is on the app and the widget. `CODE_SIGN_ENTITLEMENTS` was added for the widget in project.yml; the app already had one.
- Builder A says a device build signed under the free team, so I'm taking that as verified.
- `sharedDefaults` copies `look.day`, `look.night` and `look.pinned` from standard defaults into the group once, and never overwrites a value already in the group.
- If the group were unavailable, `UserDefaults(suiteName:)` would still return a store, so there's no crash.

## Lows
- **W10:** with a light look pinned, the workout's own glints use the pinned look's sheen.
  - What happens: `WorkoutPaint.sheen` is `Theme.Colors.sheen`, which reads `paintLook = pin ?? night`. With Porcelain pinned, the set-stroke `GlintIf`, ExerciseStrip's sweep and the rest glint are #F0A500 at 60% on the dark workout.
  - What the sheet says: "Obsidian, Lacquer, and every workout: #FFE2A8, plus-lighter".
  - It's only visible with a pinned light look.
  - Fix: `WorkoutPaint.sheen = Color(hex: 0xFFE2A8)`, or the dark sheen of `workoutLook`, and leave page glints on `paintLook`.
- **W11:** `adoptRestored(day:night:pinned:)` has no caller yet.
  - TesseraBackup doesn't write the look into `backupInfo`, and the restore path doesn't read it.
  - Research's T24 (fresh install, restore a backup that was on a Lacquer pin, expect Lacquer) is still not built.
  - The API and its "only if never chosen" rule are right and tested. Wire it when Core adds look columns to `backupInfo`.

## For Product or Design (not a bug)
- **W12:** the navigation veil (InkActions.swift:127) changed from `.ultraThinMaterial` to a flat `Theme.Colors.raised` fill. WorkoutGlass also changed from material to `Workout.raised`.
  - CLAUDE.md says "Liquid Glass on the navigation layer only". The veil is that layer, so this removes the last material there.
  - If this was one of Design's audit rows, it's fine. If not, Design should confirm it from the recording (26-soul-in-looks.mp4).
