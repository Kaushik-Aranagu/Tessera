# Review #203: Themes part 2a, the workout follows the look (68cee3a)

Builder A. 17 files, +360/-77. Static review, since there's no Swift toolchain here. I checked it against research/theme-schedule.md (fixtures 1-25, C1-C9) and themes.md at 73a0395, on branch b3tu3f.

**Verdict:** PASS with one should-fix (W1) and one low-to-should (W2). L1 is closed.

## Should-fix

**W1: the ink keys are invisible in the workout when a light look is pinned.**
- Where: DesignSystem/Paint.swift:256. #203 replaced `dark ? Color(hex: 0xF3ECE0) : Theme.Colors.ink` with `Theme.Colors.ink`.
- Why it breaks: `Theme.Colors.ink` is `Color(light: day.ink, dark: night.ink)`. The workout cover forces `.dark`, so it resolves to the night half. When a look is pinned, `pair` is (pin, pin). With Porcelain pinned, the key labels draw in #17141F on Porcelain's workout ground #14111A, so they can't be seen. Plein pinned (#2B2440) and Celadon pinned (#0F231D) fail the same way.
- What's affected: every PaintKey in the workout. That's the set row key (WorkoutParts.swift:283), Finish (ExerciseStrip.swift:110), Done (WorkoutFinishView.swift:78), and the four keys in WorkoutModeView.swift:566-604. Their meta text (ink at 60%) goes the same way.
- Unpinned is fine, because the night slot always holds a dark look.
- **Fix:** inside the workout, PaintKey should take `Theme.Colors.Workout.ink`. Either:
  - an environment flag (`\.onWorkoutGround`) set once on WorkoutContent, read in PaintKey; or
  - `colorScheme == .dark && !ThemeStore.shared.current.isDark ? Theme.Colors.Workout.ink : Theme.Colors.ink`.
  - The flag is cleaner, because it also covers a dark pinned look whose page ink and workout ink differ.
- Test: pin Porcelain, start a workout, log a set, and check the keys read.

## Low to should

**W2: the workout's hold doesn't cover the field, the shadows or the glass edge (fixture 13 is only partly met).**
- What's held: `holdWorkoutLook()` holds `concept.workout`, which covers the colours.
- What isn't: `WorkoutField` (ThemeLayers.swift:74), `WorkoutPaint.dropsShadows` (WorkoutPaint.swift:55) and `Workout.glassEdge` (Theme.swift:463) still read `ThemeStore.shared.current`.
- Example: with Plein by day and Lacquer by night, the workout opens on PleinGround. If the phone flips Dark mid-set:
  - the ground becomes a flat Plein workout ground with Lacquer's band;
  - drop shadows switch off;
  - the glass edge changes.
- That's the switch during set entry the schedule rules out.
- **Fix:** add `var workoutLook: Look { workoutHeld ?? current }` to ThemeStore and use it in those three places.
- Test: extend `theWorkoutKeepsItsLookUntilItCloses` to assert `workoutLook.field`.

## Lows
- **W3:** the sheen is only half wired.
  - GlintOnce takes `Theme.Colors.sheen` but still hardcodes `.blendMode(.plusLighter)` (ExercisePaint.swift:186). `sheenBlend` (Theme.swift:380) is defined but never used, and themes.md asks for `.normal` on Porcelain and Celadon.
  - The sheen also gets 0.95 opacity on top of its built-in 0.6.
  - `Glint` (TessMotifs.swift:7, fixed #F7E6B8) and the ProcessSeam glint (Paint.swift:73) don't read the token yet.
  - On Porcelain, a plus-lighter #F7E6B8 over white shows nothing. Fine to fold into 2b.
- **W4:** the demo pin and the sentence disagree.
  - With `-theme obsidian`, the Look sentence still shows "Porcelain by day, Obsidian by night", because LookSentence reads `store.pinned`, not `store.pin`.
  - A tap then changes a saved slot but nothing on screen. The test `theDemoPinIsNeverSaved` asserts that `look.day` is saved.
  - theme-schedule.md (the `-theme` edge and fixture 22) says taps during a demo run also stay in memory.
  - DEBUG only, but it will show in any recording of the sentence. Fix: when `demoPin` is set, have the sentence show the pinned form and have `save()` return early.
- **W5:** `systemIsDark` is seeded from `UITraitCollection.current` when `ThemeStore.shared` first loads. Outside a trait context that is the screen's trait on current iOS, which should be right, but I can't verify it here. Check fixture 2 once with a Dark-mode simulator launch, looking at the halo and blend on the first frame. Research suggested the window scene's trait.

## Checked, fine
- **Fixture 12:** unpinning puts the look back in its own slot by `isDark`, and the other slot is kept. Tested.
- **Fixture 22 / L1:** the demo pin is never written, and the root `preferredColorScheme` follows the demo pin. L1 is closed (W4 is the leftover).
- **Fixture 14 / C3:** the workout ground is `Workout.ground`, PleinGround only on Plein, and Lacquer's band is at 3%. The ask sheet's background is themed.
- **Fixture 11:** `cyclePinned` walks all five looks both ways. VoiceOver decrement steps back on all three names. The action wording now matches theme-names.md, which closes C8.
- Plates:
  - The change plates (2.5 and 1.25) moved to `Theme.Colors.plate`, so they stay fixed in every look, per the addendum.
  - The plate shade uses the workout ground.
- WorkoutPaint names map to tokens.
- The set cycle is signal, tess, rest, health. That's the same order as before (live, cobalt, now, health), with tess in for cobalt per the addendum.
- Shadows are off on #000 looks.
- The Veil hairline is a token now.
- MonthPage's numeral uses `paper`.
- `.onAppear` and `.onDisappear` sit on the cover's content (RootView.swift:58 fullScreenCover). The hold is taken when the cover opens and released when it closes.
- I found no clash with #201: the files don't overlap.

## Still open from the schedule (2b or later)
- Flood on a sentence tap (5, C9).
- Live Activity look (16-19, C7).
- Backup keys (24).
- App Group (25, C6).
