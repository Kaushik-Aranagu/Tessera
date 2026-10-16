# QA review: PR #367, Design 43 looks recut (Builder A)

Head `25b087d258710dd87fb2ead52a2ad4a7f8ecf5c0` (ios/looks-recut, rebased past #359). Static review: data safety and
tests; Design reviews the colours against its sheet. Trial merge onto master: clean. 7 files, +58/-49: Looks.swift,
Theme.swift, ThemeLayers.swift, Shared/LookTable.swift, LookTableTests, LookTableDriftTests, a still
(docs/recordings/43-looks-recut.png, 1400×608).

## Verdict: PASS

## Data safety
- **`-theme plein-washes` rides LaunchFlags.** It is a new value of the existing `-theme` flag, read through
  `LaunchFlags.value(after: "-theme", in:)` (Theme.swift:284), which returns nil unless
  `targetEnvironment(simulator)`. The `ProcessInfo.processInfo.arguments` default parameter on `configure` is the
  existing line, not new, and only feeds LaunchFlags. No raw ProcessInfo read came with it.
- **The pin is in memory only.** `ThemeStore.pin` sets `demoPin` and rebuilds; nothing is written to settings, so
  a pinned washes Plein can never stick on a phone.
- No engine, catalog, migration, project.yml or entitlement change. Look names are unchanged, so his saved look
  still resolves.

## Tests
- `everyLookMatchesTheSheet` is re-pinned to looks-recut.md for all thirteen roles of Porcelain, Plein, Lacquer and
  Celadon; Obsidian's row is unchanged, as the sheet says.
- `pleinKeepsTodaysLightHalf` is replaced by `pleinIsFlatWithEarthPigments` (field `.pigmentBloom`, training apart
  from health, sheen off the letters). That retires the old "Plein is the look he had" guard on purpose.
- New `theRecutLooksHoldDesignsValues` checks ground, ink, context and Lacquer's fieldShade/specular against the
  same numbers; `Shared/LookTable.swift` (widgets, Live Activity) carries the same grounds/inks/contexts, so the
  drift test keeps the two in step.

## What he'll notice (for the relay)
On his phone this changes every look but Obsidian, and Plein loses its washes and grain (the flat Plein). The pool
behind an action row goes from a 5-10% bloom with a dried ring to 12% falling to nothing, blurred 6 pt.
If Plein is his look, that's a visible change he didn't pick on the phone; `-theme plein-washes` keeps the old one
for side-by-side on the simulator only.

## Lows
- The record is a still (a 1400×608 sheet). Fine for colour, but the pool's blur and fade only show in motion;
  Design's call whether a short clip is needed.
- `pleinIsFlatWithEarthPigments` pins `sheen == 0xE0B341`, the old Plein rest colour, while the new Plein rest is
  `0xC98E1B`. If Design meant the sheen to follow, the test pins the wrong value; if not, a comment would say why.
