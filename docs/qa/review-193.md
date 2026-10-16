# Review #193 (merged 30aa845) — Themes part 1 (Builder A): PASS with should-fixes (not in tonight's install)

Static review against docs/design/themes.md with both addenda (8ac2e99 on claude/project-thread-b3tu3f) and
research/theme-checks.md. I diffed every hex in Looks.swift against the sheet's tables with a script.

## Hex values: 1 mismatch out of 92
Matching: every main-table row (ground, raised, ink, context, muted, tess, live, liveInk, now, health, training,
neutral, and the five Workout rows), the Workout `health` row and the `sky` row, for all five looks.
- **T1** Obsidian `Workout.tess`: the code has #86B4FF, but the addendum-1 workout table says #6FA4FF. Addendum 2 #5
  ("Obsidian `tess`: #86B4FF, for words and the soul alike") may mean the workout too, but it also says "the tables
  above already carry the new hex values", and that table still reads #6FA4FF. **Design to confirm.** Either the code
  changes, or the workout table does.

## Ink tiers: match addendum 2
- `inkSecondary` is 66% light / 72% dark, `inkTertiary` 51% light / 38% dark, `hairline` 14%.
- Workout: `inkSecondary` 72%, `hairline` 14% (the old 12% is gone).

## Plein: not byte-identical to today, but every difference comes from the sheet
Light half compared with today's `ThemeConcept.plein`: ground, ink, live, context, now, health, muted and the whole
workout palette (ground, raised, ink, signal, rest, tess #9DBFE6, health #7FB07A) are identical.
Differences:
- `tess` #2E6DA4 → #2A64A0 (addendum 2 #6, contrast, intended).
- `inkSecondary` 60% → 66% and `inkTertiary` 38% → 51% (addendum 2, intended).
- `progress` #E0A35C retires to `now` #E0B341 (addendum 1, intended).
- **T2 `training` #6E9E6A (sage) → #C8452F (vermilion).** The sheet's Plein column says #C8452F, but today's Plein
  draws training dabs in sage. On Plein, every training class dab and training-coloured mark turns vermilion,
  the same colour as `live`. That clashes with "one accent leads per screen" and with "no two strokes share a
  pigment". **Design to confirm.** The sheet may have copied `live` by mistake.
- Plein's own dark half (#1C1828 ground and so on) is gone. At night Plein users now get the night look
  (Obsidian). That's by design under day/night pairing, but it is a visible change for him tonight if his phone
  goes dark.

## Should-fix
- **T3 a pinned look against the system appearance gets the wrong tiers and status bar.**
  `Color(light:dark:lightAlpha:darkAlpha:)` picks the ink alpha by `userInterfaceStyle`. With "Obsidian always" on a
  light-mode phone, the pair is (Obsidian, Obsidian), but the tiers come out 66% and 51% (light values) on black.
  "Porcelain always" on a dark-mode phone gives 72% and **38% tertiary on white**, which fails contrast. Nothing
  sets `.preferredColorScheme`, so a pinned dark look on a light system also keeps a dark status bar on #000.
  Fix: take alphas from `pair.day.isDark` and `pair.night.isDark`, not the trait. When pinned, apply
  `.preferredColorScheme(pinned.isDark ? .dark : .light)` at the root.
- **T4 the default for existing users** (`hasLaunched || existing store → Plein by day`): you've asked Builder A to
  drop this. He wants Porcelain by day and Obsidian by night. Note that the phone already has a store, so without the
  drop he'd get Plein.
- **T5 a look-table test (cheap, worth asking for):** pin `Look.all` against the sheet (names, isDark, field and
  every hex), and pin `Look.plein`'s light values against today's Plein, except the five listed differences. My
  diff script would be the test's oracle: about 40 lines of Swift Testing.

## Lows
- T6: `cycle(pinned:)` calls togglePin twice, so it saves and rebuilds twice. Harmless.
- T7: the LookSentence names use `.valueWash`, the existing value-word pattern. Fine under the no-buttons rule,
  assuming that's the Settings value word.
- T8: the Lacquer band has no tilt yet (the sheet allows Core Motion at 15 Hz), so it's static. Fine for part 1.
