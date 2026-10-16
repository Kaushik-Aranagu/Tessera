# QA review 266: one base for the workout (#266)

Merge e79dda2, head 92e1f4b, 19 files (+64/-108, plus docs/recordings/27-workout-one-base.mp4). Static review; no toolchain here.

**Verdict: PASS.** No reverts against the first parent. No blockers. Matches Kaushik's rule: the workout stands on Home's base in the active look; only the layers change.

## The three points the coordinator asked about
1. **Workout tokens are the look's own.** `Look.Workout` and the five per-look workout columns are gone (Looks.swift). `ThemeConcept.dressed` builds `WorkoutPalette` from `current` (Theme.swift:258-262): ground/raised/ink, signal = live, rest = now, tess, health. A new test pins it for every look (LookTableDriftTests `theWorkoutStandsOnTheLooksOwnBase`), and `RestPalette` is now checked against the base tokens. The held-look test still holds: while a workout is held, its ground stays Porcelain after the system turns dark (ThemeStoreTests:64-69).
2. **`-theme` behind `DemoData.isAllowed`** (Theme.swift:280). This is correct and closes part of review-244 G1: `-theme` no longer pins a look on his phone. `isAllowed` went `nonisolated` so the static `configure` can read it; it only reads a compile-time constant, so that's safe. `-queueScript`, `-tessScript` and `-demoTime` are still open under G1 and stay with Builder A's launch-flags PR.
3. **PleinGround hardcodes 0x1C1828** (Paint.swift:29). Behaviour is unchanged: it is the old `Look.plein.workout.ground` value. Since Plein is a light look and the workout now follows the look's scheme, this branch is reached only when Plein sits under a dark system scheme. **Low, B1:** give it a name (for example `Look.pleinDusk`) so it isn't a stray literal against the "tokens, not literals" rule. Paint.swift:11-12 also still says "the workout's `.preferredColorScheme(.dark)` gets the dark ground", which is no longer true; update the comment.

## Other checks
- **Colour scheme:** `WorkoutContent` and `LiveAskField` now set the scheme from `workoutLook.isDark` (WorkoutModeView.swift:140, WorkoutParts.swift:347). No other forced `.dark` is left in Features/Workout; SoulGallery's is a gallery, so it's fine.
- **Field:** `WorkoutField` is now `LookField(look: workoutLook)`, the same field as Home. Lacquer's 3% specular band now comes from LookField.
- **Readability on white:** the rest timer, "Go" and "Set N of M" changed from `Paint.now` (amber) to `Paint.cream`, which is now `Workout.ink`, so it stays dark on Porcelain and Celadon. The Undo and Remove words use `liveInk`, the readable red on light grounds. This fits the no-dots rule that colour comes through moments.
- **Shadows:** `dropsShadows` is now `!isDark` (WorkoutPaint.swift:57), so black shadows show only on light grounds. The `.black` stops left in WeightDial and RepsDrum are masks, not paint.
- **Glass:** WorkoutPaint.glass and Veil both use ground at 92% over the material, matching the themes.md fourth addendum. Veil changes Home's top and bottom too (`raised` 82% to `paper` 92%), on purpose under one base. `glassEdge` is ink 12% everywhere. **Low, B2:** the doc comment at WorkoutPaint.swift:44 still says "82%".
- **Sheen and soul:** the glint uses the look's own sheen (gold through letters on white). `SoulPalette.workout` is removed and the workout soul uses `SoulPalette.look(workoutLook)`. The soul itself is unchanged.
- **`paintLook`** is now `workoutHeld ?? current`; the test was updated.
- **Live Activity:** the Lock Screen follows the day or night look, so it is now light on Porcelain, Plein and Celadon (RestLiveActivity.swift:107). The Dynamic Island stays Obsidian (RestLiveActivity.swift:52). **Low, B3:** this is worth one look on the Simulator's Lock Screen in Porcelain, since this widget never drew on white before.

## Lows
- **B1:** name the 0x1C1828 Plein-dark ground and fix the Paint.swift:11-12 comment.
- **B2:** fix the stale "82%" comment at WorkoutPaint.swift:44.
- **B3:** check the light rest Live Activity on the Simulator's Lock Screen in Porcelain.
