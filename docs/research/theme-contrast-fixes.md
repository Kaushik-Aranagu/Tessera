# Theme contrast fixes for Design approval (board item 82)

Proposed values for the six Obsidian misses and the Porcelain Best e1RM miss in `themes-leftovers.md`. Checked on `origin/master` at **1c6193a** (includes #215). Ground values are read from master's `DesignSystem/Looks.swift` (the workout grounds match `Shared/LookTable.swift`): Porcelain ground #FFFFFF, raised #F5F4F8, ink #17141F, workout ground #14111A. Obsidian ground #000000, raised #0F0E12, ink #F5F2EC, workout ground #000000. Ratios use WCAG 2.x relative luminance. Alpha tiers are blended over the ground before measuring (inkSecondary is 66% on light looks and 72% on dark looks, inkTertiary is 51% and 38%, hairline is 14%). The script is in scratch and is not kept.

Targets: 4.5:1 for text under 18.7 pt bold or 24 pt regular. 3:1 for non-text marks that carry meaning (WCAG 1.4.11). Purely decorative marks have no target; each one is labelled.

## B10. Process step text (Builder B)

- File: `Features/Home/NowPage.swift:519`
- Current: `Color(hex: 0x6E6480)`. Porcelain 5.53 (on raised 5.05). **Obsidian 3.80** (on raised 3.48). Fails 4.5 on Obsidian.
- Proposed: **`Theme.Colors.inkSecondary`** (existing token).
- Result: Porcelain **5.84** (on raised 5.63), Obsidian **9.51** (on raised 9.12). Passes 4.5 on both.

## B11. Engraved seam under a waiting process (Builder B)

- File: `Features/Home/NowPage.swift:541-542` (a dark line at ink 12%, then `Color.white.opacity(0.8)`)
- Current light line: Porcelain 1.00 (white on white, invisible). **Obsidian 13.08** (a bright white line).
- Proposed: delete the white line and draw a single **`Theme.Colors.hairline`** line (existing token, ink at 14%).
- Result: Porcelain **1.34**, Obsidian **1.32**. The two looks now match.
- Intent: a quiet engraved rule that says "waiting". The suspended state is the 2 pt vermilion seam, and the row text names the next step. This line is decorative, so no 3:1 target.
- If Design wants the line itself to carry the state, use **`Theme.Colors.inkTertiary`** instead: Porcelain 3.55, Obsidian 3.14. Both meet the 3:1 target, but the line reads much heavier.

## B14. Held row in the Home queue (Builder B)

- File: `Features/Home/HomeQueue.swift:232`
- Current: `.shadow(color: Theme.Colors.ink.opacity(0.18), radius: 6, y: 3)`. The densest part of the shadow is Porcelain 1.47 (a soft dark lift) and Obsidian 1.50, but on Obsidian it is a **pale glow**, because ink is near white.
- Proposed: draw the shadow on light looks only: `Theme.Colors.ink.opacity(holding && !struck && !Theme.Colors.halo ? 0.18 : 0)` (existing tokens; `halo` is true on dark looks). The 1.03 scale and the haptic carry the lift on dark looks.
- Result: Porcelain stays 1.47 (unchanged). Obsidian has no glow. The row text stays ink: Porcelain 18.16, Obsidian 18.79.
- Intent: the row lifts toward your finger. The lift is shown by scale, motion and the haptic, so the shadow is decorative and has no 3:1 target.

## B17. Paste Recipe reading band (Builder B)

- File: `Features/Recipes/PasteRecipe.swift:56` (`.blendMode(.multiply)`, opacity .25 on line 57)
- Current: band against the ground: Porcelain 1.20. **Obsidian 1.00** (multiply on black gives black, so the band is invisible).
- Proposed: **`.blendMode(Theme.Colors.soulBlend)`** (existing token: multiply on light looks, screen on dark looks). Keep opacity .25.
- Result: band against the ground: Porcelain **1.20**, Obsidian **1.65**. Ink on the band: Porcelain 15.1, Obsidian 11.4, so the text stays readable.
- Intent: a soft brush passing down the text as it is read. It is a decorative motion cue, and the lines it passes are also painted in one by one, so no 3:1 target. Do not raise the opacity: at .5 Obsidian reaches 3.64, but the band would outshine the text.

## A3. Running-order scrim in the workout (Builder A)

- File: `Features/Workout/WorkoutModeView.swift:288` (`Color.black.opacity(0.35)`)
- Correction to `themes-leftovers.md`: the scrim does work on Obsidian. It cannot darken the #000 ground, but it does dim the workout content behind the panel. With no scrim, workout ink measures Porcelain 16.71 and Obsidian 18.79. Under the current scrim it drops to Porcelain 7.25 and Obsidian 7.79. The real gap is that at 7.8:1 the content behind still competes with the panel. The panel's own raised fill is only 1.14 (Porcelain) and 1.13 (Obsidian) against the ground.
- Proposed: **`Theme.Colors.Workout.ground.opacity(0.6)`** (existing token).
- Result: ink behind the scrim: Porcelain **3.55**, Obsidian **3.38**. It stays visible as context but clearly sits behind the panel text, which is ink at 16.7 to 18.8.
- Intent: push the workout back so the running order reads as the top layer. The target here is to keep the content behind at 3:1 or more so it stays legible, and below text level.

## B3 and B7. Home day stroke (Builder B)

- Files: `Features/Home/HomeSpatialView.swift:7-16` (`HomePaint`), used at `DayStrip.swift:185` and `:220`, `NowPage.swift:218`, `HomeSpatialView.swift:236`
- Current violet stop #7A5C8E: Porcelain 5.60, **Obsidian 3.75**. The current stops on Porcelain: sky 1.87, sage 2.30, amber 2.20, vermilion 4.83.
- Proposed: **`Gradient(colors: Theme.Colors.daySpectrum)`** (existing token: sky, health, context, now, live). Use `Theme.Colors.now` for the wet tip and the timer, and `Theme.Colors.classColor(.kitchen)` for the dabs. Then delete `HomePaint`.

| Stop | Porcelain hex | on #FFFFFF | Obsidian hex | on #000000 |
|---|---|---|---|---|
| sky | #7FB6E0 | **2.17** | #7CC4F0 | 11.01 |
| health | #12936A | 3.88 | #3FD49A | 11.10 |
| context | #6A4C9C | 6.72 | #B7A6E0 | 9.54 |
| now | #F0A500 | **2.08** | #FFC23D | 13.04 |
| live | #E2432A | 4.14 | #FF5B3A | 6.81 |

- Intent: the day as one stroke from morning to evening. Obsidian passes 3:1 at every stop. Porcelain misses 3:1 at the sky and now stops, as the current Plein colours already do.
- Design choice: (a) treat the stroke's colour as decorative, since the time is also in the text and in the wet tip's position, so no 3:1 target; or (b) give light looks a darker stroke-only sky **#509BD5** (3.00) and now **#C58700** (3.07). No token fits (b), so it needs two new values. Do not change `sky` or `now` themselves, because they are fills elsewhere.

## A31. Best e1RM value on the exercise object page (Builder A)

- File: `Features/Objects/ObjectPage.swift:169` (`tint: Theme.Colors.progress`, which resolves to `now`)
- Current: **Porcelain 2.08** (#F0A500 text on white, fails), Obsidian 13.04.
- Proposed: **`Theme.Colors.ink`** (existing token). Then remove the `progress` token (`Theme.swift:256, 404`).
- Result: Porcelain **18.16**, Obsidian **18.79**.
- Not proposed: `liveInk` (Porcelain 5.35, Obsidian 8.19) would pass, but vermilion means "running" in this app. If Design wants a PR cue, put a `now` dab beside the value, not on the text.

## Summary for Design

1. Five of the seven fixes are one swap to an existing token: inkSecondary, hairline, a shadow on light looks only, soulBlend, and ink. All pass on both Porcelain and Obsidian.
2. The workout scrim goes to Workout.ground at 60% (behind content 3.55 on Porcelain, 3.38 on Obsidian). The earlier "no effect on Obsidian" note was wrong: the scrim dims the content but cannot darken the black ground.
3. One decision is needed: the day stroke passes on Obsidian but misses 3:1 on Porcelain at sky (2.17) and now (2.08). Either call it decorative, or approve the stroke-only #509BD5 and #C58700.
