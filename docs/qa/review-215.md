# Review #215 — Themes 2b (862ed68, head 838fee2)

Builder A. 10 files, +214/-73. Static review only: there is no Swift toolchain here, so nothing was built or run.

**Verdict: PASS.**
- W6 and W7 are closed by code. The W7 path can no longer leave the app on the night look. One phone smoke step is still worth doing.
- The Live Activity palettes match the look sheet.
- There are two lows.

## W7: traced from the code
The flow is: Light phone, unpinned, start a workout, push an exercise page from it, close the workout, go Home.

1. `WorkoutModeView` sets `.environment(\.tracksAppearance, false)` on the workout's NavigationStack (WorkoutModeView.swift:34).
2. Pages pushed inside that stack (`navigationDestination` → `ObjectPage` / `ExercisePage`) inherit the flag. Their `ThemedBackground` reaches `onChange(of: colorScheme, initial: true)` and returns at `guard tracksAppearance` (ThemeLayers.swift:19). This happens even though the cover forces `.dark`.
3. The only code that writes `systemIsDark` is that `onChange` (ThemeLayers.swift:20) and `ThemeStore.init` (Looks.swift:164). The root's `ThemedBackground` (RootView) keeps the default `true` and follows the phone.
4. The only forced schemes are the workout cover (WorkoutModeView.swift:137, WorkoutParts.swift:338, both inside the flagged stack) and the root pin (TesseraApp.swift:75).
   - While a look is pinned, `current` is the pinned look, so `systemIsDark` doesn't matter.
   - When he unpins, the root's scheme returns to the phone's. That fires the root `onChange`, which corrects `systemIsDark`.

**Result:** nothing inside the cover can set `systemIsDark`, so Home after the workout is the day look. This rests on SwiftUI passing the environment from a NavigationStack to its destinations, which is standard behaviour.

**Phone smoke, one step:** Light phone, unpinned. Start a workout, tap into an exercise page, close the workout, then check Home. It should be white, with no halo or glow on the soul, the seam or the bloom.

## W6
`onWorkoutGround` now sits on `WorkoutContent` only (WorkoutModeView.swift:20).
- The ask sheet and `WorkoutFinishView` are inside it, so they still get workout ink.
- Pushed pages get page ink again, so "Log a set" shows on a white page when a light look is pinned. **Closed.**

## Live Activity
- `ContentState` carries `lookDay` and `lookNight` from `pair`. That means the same name twice when a look is pinned, and it follows the demo pin.
  - Both fields are optional, so older states still decode.
  - The extension picks a palette by its own `colorScheme`: Porcelain when Light, Obsidian when Dark, if the names are missing.
  - The Dynamic Island is fixed to Obsidian (RestLiveActivity.swift:52).
  - This closes fixtures 16–18 and C7.
- `Shared/LookTable.swift`: I checked all five `RestPalette`s against `Look.workout` and `Look.context` in Looks.swift (ground, ink, signal, rest, tess, context). **All 30 values match.**
- `Shared` is in the Widgets target's sources (project.yml:92), so the new file needs no project change. `Color(rgb:)` doesn't clash with the app's `Color(hex:)`.
- Fixture 19, partly: a look change only reaches a running Live Activity on its next `update` (the next set, +15s, Skip or end). This matches themes.md ("follows on its next update").

## Soul, flood, glint, glow
- `TessSoul` takes its palette from the look: the page's half by `colorScheme`, or `SoulPalette.workout(workoutLook)` on the workout ground.
- `PaintFlood` uses the incoming look's live, context, tess and now.
- `Glint` with no sheen reads `Theme.Colors.sheen` and `sheenBlend`. LiveSetStrokes still passes #FFE2A8 with plus-lighter, which is right for the workout.
- `pigmentGlow` gives a full glow on dark looks and on the workout ground, and 30% with a 3 pt blur on light looks. ProcessSeam uses it.

## Lows
- **W8:** pages pushed inside the workout draw the night look, because they are forced dark. But tokens that read `ThemeStore.current` still give the day look on a Light phone: `halo`, `soulBlend`, `actionBloom`, `sheen`, and `pigmentGlow`'s halo branch. So on an exercise page opened mid-workout, a multiply blend or a light-look glow sits on black and mostly disappears. This is cosmetic and rare.
  - Fix: base those tokens on a page look taken from the environment's `colorScheme` (`pair.night` when dark), rather than on `current`.
- **W9:** `LookTable` copies the workout hexes from Looks.swift, because the extension can't import DesignSystem. Add a test asserting `RestPalette.named(look.name)` equals each `Look`'s workout set and context, so the two can't drift.

The #211 merge kept `BackupLogicalDayTests.swift`, as you said.
