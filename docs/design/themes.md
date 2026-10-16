# Themes (build sheet)

Kaushik asked for a few rich, sophisticated themes (Oct 15, 6:40 PM PT), including one on pure white with rich colour pops (likely his default) and one on pure black. He wants no cheap gradients or boring textures. This sheet gives the five themes as tokens, the rule for switching, and how DesignSystem should hold them so a switch is cheap.

Preview (Home, Now, a workout and Review in each theme, with swatches and proportions): https://claude.ai/artifact/BLpU1bW4Zx9E3mVtBHdfDz. Its source is `studies/themes.html`.

## What a theme changes, and what it never changes
- **A theme changes only three things:** the ground (with its field), the ink, and the pigments.
- **Everything else stays the same in every theme:**
  - Inter Tight and the type tiers.
  - The ink actions, with no button shapes.
  - Stroke words, dabs, the soul, motion and layout.
- Every existing screen works in every theme, because screens already read `Theme.Colors.*` and never hard-code a hex.

## How much of each
A theme is mostly ground. Colour arrives only where something matters: the action of the moment, Tess, a running thing, a class dab.

| Theme | Ground | Raised | Ink (all tiers) | Accent |
|---|---|---|---|---|
| Porcelain | 86% | 3% | 8% | 3% |
| Obsidian | 88% | 2% | 8% | 2% |
| Plein | 80% | 2% | 10% | 8% (the washes count) |
| Lacquer | 84% | 4% | 9% | 3% |
| Celadon | 82% | 6% | 9% | 3% |

- **One accent leads per screen:** the stroke under the action of the moment. Class dabs and Tess's cobalt are the only other colour.
- **No two strokes on one screen share a pigment,** except where the meaning is shared, such as two running things.

## The five themes
| Token | Porcelain (light, **default by day**) | Obsidian (dark, **default by night**) | Plein (light, today's look) | Lacquer (dark) | Celadon (light) |
|---|---|---|---|---|---|
| `ground` | #FFFFFF | #000000 | #F2ECE3 | #140F1B | #E7EEE9 |
| `raised` (veils, held rows, Write layer) | #F5F4F8 | #0F0E12 | #FAF6EF | #221A2D | #FFFFFF |
| `ink` | #17141F | #F5F2EC | #2B2440 | #F1E7D6 | #0F231D |
| `context` | #6A4C9C | #B7A6E0 | #7A5C8E | #C3A6DE | #4C6B85 |
| `muted` | #B9B3C3 | #5C5765 | #A39AAE | #6C6078 | #97ABA2 |
| `tess` (cobalt, Tess only) | #2450D8 | #6FA4FF | #2E6DA4 | #8DB2FF | #2C59BE |
| `live` (running, UNDO, Finish) | #E2432A | #FF5B3A | #C8452F | #F06A4C | #D8462C |
| `liveInk` (live as text, light themes) | #C23A22 | = live | #B83C28 | = live | #B8361E |
| `now` (cadmium: the moment, rest, planning) | #F0A500 | #FFC23D | #E0B341 | #E8B54A | #D99A1C |
| `health` (sage: health, kitchen) | #12936A | #3FD49A | #6E9E6A | #8FCB9E | #23866A |
| `training` | #CC3F68 | #FF6B92 | #C8452F | #F07FA0 | #C24766 |
| `neutral` (class colour) | #9C95A8 | #8E879A | #A39AAE | #9A8FA6 | #7E918A |
| Workout `ground` | #14111A | #000000 | #1C1828 | #0C0812 | #0E1C17 |
| Workout `raised` | #221D2C | #141217 | #3B2D57 | #1C1426 | #18302A |
| Workout `ink` | #F5F2EC | #F5F2EC | #F3ECE0 | #F1E7D6 | #EEF3EF |
| Workout `signal` | #FF5B3A | #FF5B3A | #D9563F | #F06A4C | #E25A3E |
| Workout `rest` | #F0A500 | #FFC23D | #E8BD4C | #E8B54A | #E2A93A |

- **Ink tiers** are the same in every theme: `ink` 100%, `inkSecondary` 60%, `inkTertiary` 38%, `hairline` 14%.
- **Class colours** map as today:
  - training uses `training`.
  - planning uses `now`.
  - health and kitchen use `health`.
  - neutral uses `neutral`.
- **Text in a pigment:**
  - Only `tess`, `context` and `liveInk` (or `live` on dark themes) are ever text.
  - `now`, `health` and `training` are pigments for dabs and strokes, never body text on a light ground. On a light ground they fall under 4.5:1.
  - Ink on a stroke word stays `ink`.
- **The workout** always uses the workout tokens. It's dark in every theme, as today: "Same again" on the dark ground holds whatever he picks.

## The field (the background, per theme)
These are not gradients or textures pasted on. Each field is how the material would really behave.

- **Porcelain: `pigmentBloom`.**
  - The ground is flat white, with no grain and no wash.
  - Behind the action of the moment only, the pigment pools as a watercolour bloom: 5% in the middle with a 10% dried edge. It's irregular, sits about 360×120 behind the stroke word, and never moves.
  - With nothing running, the page is just white.
- **Obsidian: `emissive`.**
  - The ground is #000000, so the pixels are off.
  - Pigment becomes light: stroke words, dabs and the soul carry a halo (`shadow(color: pigment.opacity(0.55), radius: 6)`).
  - The bloom behind the action is an emitted glow: screen blend, 16% at the centre, blur 18.
  - There is nothing else on the ground.
- **Plein: `plein`.** Today's `PleinGround` is unchanged: three soft washes and a grain at 30% multiply.
- **Lacquer: `lacquer`.**
  - Plum-black deepens toward the bottom: the last 45% darkens to 75% of #06030A.
  - One wide specular band lies across the ground at −24°, 150pt tall, peaking at 5% warm white, blur 14.
  - The band can follow device tilt by up to 4° and 20pt (Core Motion at 15 Hz). It's still under Reduce Motion and in Low Power Mode.
  - The bloom is a glow, as in Obsidian, at 14%.
- **Celadon: `glaze`.**
  - A flat glaze. The bottom 260pt pools 6% ink-darker, the way glaze collects at the foot of a pot.
  - Anything lifted (a veil, a held row, the Write layer) is `raised` pure white slip.
  - The bloom is a pigment bloom, as in Porcelain.

**The soul** is three dabs in `live`, `tess` and `now`. They use a multiply blend on light themes and screen on dark ones, and the halo on Obsidian and Lacquer. Its states (bloom, pulse, calm) are unchanged.

**Live Activities and widgets:**
- The Live Activity background is the workout `ground`, with workout `ink` text and the horizon timer in workout `rest`.
- The rest sky is `tess` at 35% over the ground. Finish and UNDO use workout `signal`.
- Widgets use the theme's `ground`, `ink` and pigments, with no field. The bloom and band are too subtle at widget size and cost a render.

## Switching
- **Settings, Look, holds one sentence:** "**Porcelain** by day, **Obsidian** by night".
  - Each name is a value word. A tap cycles it through the light themes (Porcelain, Plein, Celadon) or the dark themes (Obsidian, Lacquer).
  - The app follows the system's appearance between the two.
  - Holding a name pins it: the sentence becomes "**Obsidian** always". Holding again unpins it.
  - This is the Settings page's existing value-word pattern, so there are no new controls.
- **The default** is Porcelain by day and Obsidian by night. Anyone already on Plein keeps "**Plein** by day" until they change it.
- **The change:** the new ground floods in from Tess's soul (`PaintFlood`, 700ms, house curve), with the ink crossfading inside it. Reduce Motion makes it a 250ms crossfade.
- Changing the system appearance swaps the same way.
- A running Live Activity follows on its next update. Widgets follow on their next timeline.
- **Never** switch mid-gesture, and never during a running workout's set entry: a swap that lands then waits for the page to settle.
- `-theme <name>` (DEBUG) still pins one, for the demo and recordings.

## For Builder A: holding themes as tokens
Keep every call site as it is: `Theme.Colors.ink`, `.paper`, `.tess` and the rest. Only DesignSystem changes.

1. **A `Look` per theme:**
   - Fields: name, mode (light or dark), the colour tokens in the table above, `field` (`pigmentBloom`, `emissive`, `plein`, `lacquer` or `glaze`) and the workout palette.
   - Single values, not pairs. Five static looks.
2. **The palette is composed from two looks.**
   - `ThemeConcept.palette` pairs are built as `(day.x, night.x)`. `Color(light:dark:)` then picks between day and night with the system appearance, with no new machinery.
   - Pinned is simply `(look.x, look.x)`.
   - The workout's `.preferredColorScheme(.dark)` keeps working because it reads the workout tokens.
3. **An `@Observable` `ThemeStore`:**
   - It holds the choice: day look, night look and pinned.
   - `Theme.concept` becomes a computed read of it. Observation tracks that read inside `body`, so every view redraws on a switch.
   - Views that copy a colour into a stored `let` won't update; grep for those.
   - Persist the choice in `UserDefaults`.
4. **`ThemedBackground` switches on `field`** in place of `BackgroundStyle`. Porcelain and Celadon reuse one `PigmentBloom`, Obsidian and Lacquer one `EmissiveGlow`, and Plein keeps `PleinGround`.
   - The bloom sits behind the action of the moment, as a modifier on the stroke word's row (`.actionBloom(Theme.Colors.live)`), so each field renders it its own way.
5. **New tokens:**
   - `raised`, `liveInk`, `neutral`, and the class colour map (`classColor(_ role:)`).
   - `soulBlend` (`.multiply` or `.screen`) and `halo` (on for dark looks).
6. **Live Activity:** pass the look's name in the activity's content state, so the extension draws the right workout palette without an App Group.
7. **Retire** `workshop` and `machined` from `ThemeConcept.all`. They stay in code for `-theme` until Kaushik has lived with the new five.
