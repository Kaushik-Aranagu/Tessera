# Review #207: Themes, fixes for W1-W5 (df856c6)

Builder A. 10 files, +55/-11. Static review: I read the code but couldn't build or run it, because there's no Swift toolchain here.

**Verdict:** GO for W1. The workout screen's keys now draw in `Workout.ink`, and Builder A confirmed cream on #14111A with Porcelain pinned.
- W2 and W4 are closed, and W3 is closed where it matters.
- W5 rests on Builder A's simulator check; I can't see it in the diff.
- Two new items came out of the fix and its surroundings:
  - W6, a low: the flag reaches too far.
  - W7, a should-fix: a pushed page inside the workout can flip the store to night. It predates #203.

## Closed
- **W1:** `onWorkoutGround` (Paint.swift:378) is set on the workout's NavigationStack (WorkoutModeView.swift:32). It reaches the set row key, Finish, Done, the four rest keys and the ask sheet.
- **W2:** `workoutLook = workoutHeld ?? current` now drives `WorkoutField`, `dropsShadows` and `glassEdge`. The test `theHeldLookIsTheWorkoutsLook` covers it.
- **W3:** GlintOnce takes `sheen` once, with `sheenBlend`. ProcessSeam uses `sheen` over `Theme.Colors.live`.
  - What's left: `Glint` (TessMotifs.swift:7) still uses fixed #F7E6B8 with plus-lighter. Its only page use is SoulGallery, a debug screen. The workout use (LiveSetStrokes) is #FFE2A8, which is correct. Not worth a change now.
- **W4:**
  - The sentence reads `store.pin`, and `save()` returns early while a demo pin is set.
  - Cycling and unpinning during a demo stay in memory, and there's a new test for it.
  - Unpinning the demo look leaves his saved slots exactly as they were. Taps after that point are saved, which is fine because the run is no longer a demo.

## W6 (low): the workout-ground flag also covers pages pushed inside the workout
- **Where:** WorkoutModeView.swift:32 sets `onWorkoutGround` on the whole NavigationStack, which includes the `ObjectPage` destinations.
- **What goes wrong:** ExercisePage draws `ThemedBackground` (ExercisePage.swift:26). With a light look pinned, that background is white. But its "Log a set" PaintKey (ExercisePage.swift:204) now draws cream `Workout.ink`, so it can't be seen.
  - Before #207 it drew in page ink.
  - Unpinned it's fine, because the pushed page draws the night look.
- **Fix:** move `.environment(\.onWorkoutGround, true)` onto `WorkoutContent` inside the stack. Sheets and WorkoutFinishView still inherit it, and pushed pages don't.

## W7 (should-fix, predates #203): a page pushed inside the workout switches the store to night
- **Where:** ThemedBackground.onChange(of: colorScheme, initial: true) sets `ThemeStore.shared.systemIsDark` (ThemeLayers.swift:17). Each pushed `ObjectPage` and `ExercisePage` draws its own `ThemedBackground`. Inside the workout cover the scheme is forced `.dark`, so opening an exercise page from the workout sets `systemIsDark = true`.
- **What goes wrong:** after the workout closes on a Light phone, nothing sets it back. The root background's scheme never changed, so its `onChange` never fires. Until the next appearance flip or relaunch:
  - `current` is the night look: Obsidian on his default setup.
  - Every reader of `current` is wrong on white pages: `halo` turns on, `soulBlend` uses screen, `actionBloom` shows the emitted glow, and `sheen` and `glassEdge` follow.
  - The next workout holds the night look's palette.
- **Fix:** only the root background should write `systemIsDark`. Either:
  - add `guard !onWorkoutGround` in that `onChange` (once W6 moves the flag, also skip when the scheme is forced), or
  - give `ThemedBackground` a `tracksAppearance` parameter that only RootView sets.
- **Verify in the simulator:** Light phone, unpinned. Start a workout, open an exercise page from it, close the workout. Home should show no halo or glow.
- **Caveat:** this assumes the cover's `.preferredColorScheme(.dark)` stays inside the cover (Research fixture 15, not verified on iOS 27). If it leaks to the root instead, the root flips back when the cover closes and W7 doesn't happen.

Neither item blocks the install. W1's common path, the workout screen itself, is fixed.
