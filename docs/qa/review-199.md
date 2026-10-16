# Review #199 (merged 0532d73) — Themes follow-up: PASS

Static review only.

## T3 (review-193): closed
- `Theme.Colors.tier` picks each half's alpha from its own look (`pair.day.isDark`, `pair.night.isDark`), and
  retired concepts keep the old split. A pinned look has both halves equal, so the alpha is right whatever the
  trait says. "Porcelain always" on a dark phone gets 66% and 51%, and "Obsidian always" on a light phone gets 72%
  and 38%.
- The root sets `.preferredColorScheme(pinned.isDark ? .dark : .light)` when pinned, and nil (follow the system)
  otherwise, so the status bar matches. The workout's own `.dark` still nests inside it.

## T5: closed
LookTableTests pins every hex of all five looks (13 tokens plus 7 workout tokens) against the sheet, the light/dark
split, and Plein's light half against the pre-looks `ThemeConcept.plein`. That matches my diff script.

## T2: closed
Plein `training` is back to #6E9E6A (sage), and the test pins it.

## T1: closed (Design confirmed #86B4FF; themes.md fixed in 1ccbef7)
Obsidian `Workout.tess` is #86B4FF. The test now pins #86B4FF, but the addendum-1 workout table still says
#6FA4FF. Whichever Design picks, the sheet and the test should agree.

## The -theme question: in memory, with one leak
`Theme.configure` (TesseraApp.swift:18, every launch, not DEBUG-gated) → `ThemeStore.pin(look)`, which only sets
`pinned` and calls `rebuild()`, never `save()`. So `-theme` alone writes nothing to UserDefaults, and Builder A's
claim holds as written.
- **L1 (low):** any later `save()` in that run (tapping a name in the Look sentence, holding to pin or unpin)
  writes the whole state, including the `-theme` pin, to UserDefaults. A demo run with `-theme obsidian` where
  someone taps the sentence leaves "Obsidian always" saved for the next normal launch. This only matters on the
  simulator and for recordings, because the phone never gets `-theme`.
  Fix: keep the `-theme` pin in a separate `demoPin` that `save()` ignores, or skip saving when the pin came from
  `-theme`.

## LookSentence
- Uses the theme-names copy: the LOOK label, "by day, … by night." and the hold hints. The names stay value words
  (`.valueWash`), so no button shapes.
- VoiceOver: slot labels ("Day look" / "Night look"), the look name as the value with "plɛn" phonetics for Plein,
  the look's one-line description as the hint, an adjustable action and a named pin action.
- L2 (low): the adjustable action ignores direction, so swiping down also moves to the next look. With 2 or 3 looks
  per slot that's fine.
