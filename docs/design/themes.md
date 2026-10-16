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
A theme is mostly ground. Colour arrives only where something matters: the action of the moment, Tess, a running thing, a data mark at rest tint. **Colour arrives through motion and moments; resting colour stays low-contrast** (`no-dots.md`).

| Theme | Ground | Raised | Ink (all tiers) | Accent |
|---|---|---|---|---|
| Porcelain | 86% | 3% | 8% | 3% |
| Obsidian | 88% | 2% | 8% | 2% |
| Plein | 80% | 2% | 10% | 8% (the washes count) |
| Lacquer | 84% | 4% | 9% | 3% |
| Celadon | 82% | 6% | 9% | 3% |

- **One accent leads per screen:** the stroke under the action of the moment. Data marks at rest tint and Tess's cobalt are the only other colour. No coloured dot ever sits beside text.
- **No two strokes on one screen share a pigment,** except where the meaning is shared, such as two running things.

## The five themes
| Token | Porcelain (light, **default by day**) | Obsidian (dark, **default by night**) | Plein (light, today's look) | Lacquer (dark) | Celadon (light) |
|---|---|---|---|---|---|
| `ground` | #FFFFFF | #000000 | #F2ECE3 | #140F1B | #E7EEE9 |
| `raised` (veils, held rows, Write layer) | #F5F4F8 | #0F0E12 | #FAF6EF | #221A2D | #FFFFFF |
| `ink` | #17141F | #F5F2EC | #2B2440 | #F1E7D6 | #0F231D |
| `context` | #6A4C9C | #B7A6E0 | #7A5C8E | #C3A6DE | #456680 |
| `muted` | #B9B3C3 | #5C5765 | #A39AAE | #6C6078 | #97ABA2 |
| `tess` (cobalt, Tess only) | #2450D8 | #86B4FF | #2A64A0 | #8DB2FF | #2C59BE |
| `live` (running, UNDO, Finish) | #E2432A | #FF5B3A | #C8452F | #F06A4C | #D8462C |
| `liveInk` (live as text: UNDO, Finish words) | #C23A22 | #FF7A5C | #B83C28 | #FF8466 | #B8361E |
| `now` (cadmium: the moment, rest, planning) | #F0A500 | #FFC23D | #E0B341 | #E8B54A | #D99A1C |
| `health` (sage: health, kitchen) | #12936A | #3FD49A | #6E9E6A | #8FCB9E | #23866A |
| `training` | #CC3F68 | #FF6B92 | #6E9E6A (today's sage) | #F07FA0 | #C24766 |
| `neutral` (class colour) | #9C95A8 | #8E879A | #A39AAE | #9A8FA6 | #7E918A |
| Workout `ground` | #14111A | #000000 | #1C1828 | #0C0812 | #0E1C17 |
| Workout `raised` | #221D2C | #141217 | #3B2D57 | #1C1426 | #18302A |
| Workout `ink` | #F5F2EC | #F5F2EC | #F3ECE0 | #F1E7D6 | #EEF3EF |
| Workout `signal` | #FF5B3A | #FF5B3A | #D9563F | #F06A4C | #EE7056 |
| Workout `rest` | #F0A500 | #FFC23D | #E8BD4C | #E8B54A | #E2A93A |

- **Ink tiers** (revised by Research's contrast check, see the second addendum):
  - `ink` is 100% everywhere.
  - `inkSecondary` is 66% on light looks and 72% on dark looks and every workout.
  - `inkTertiary` is 51% on light looks and 38% on dark looks, for 34pt and up or marks only.
  - `hairline` is 14%.
- **Class colours** map as today:
  - training uses `training`.
  - planning uses `now`.
  - health and kitchen use `health`.
  - neutral uses `neutral`.
- **Text in a pigment:**
  - Only `tess`, `context` and `liveInk` (or `live` on dark themes) are ever text.
  - `now`, `health` and `training` are pigments for dabs and strokes, never body text on a light ground. On a light ground they fall under 4.5:1.
  - Ink on a stroke word stays `ink`.
- **The workout is pure black in every look** (fourth addendum). Every look uses Obsidian's workout column, and the workout rows in the table above are superseded.

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
- **When the phone flips Light/Dark, pages swap at once,** with no flood, because iOS swaps the system chrome instantly. Only a tap on the Look sentence floods. A running workout keeps its palette until it closes (Research `theme-schedule.md`, #200).
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

## Addendum: gaps from Research's token audit
This addendum answers `docs/research/themes-token-audit.md` (#185). Where it differs from the sections above, it wins.

### Workout tokens, completed
The workout follows the theme. Every workout view reads `Theme.Colors.Workout.*`: `WorkoutPaint`, the private `Paint` enums in WeightDial, RPEStops, RepsDrum and PlateStack, and the `0x1C1828` literals all go.

| Workout token | Porcelain | Obsidian | Plein | Lacquer | Celadon |
|---|---|---|---|---|---|
| `tess` (Tess's words, the swap wash, the cobalt set stroke; replaces `tess`, `tessBar` and `cobalt`) | #8FB0FF | #86B4FF | #9DBFE6 | #8DB2FF | #9DBBEA |
| `health` | #3FC58F | #3FD49A | #7FB07A | #8FCB9E | #5DBE98 |
| `inkSecondary` | `ink` at 60% (replaces #A79FB5) | same | same | same | same |
| `glass` | `ground` at 82% over the material | same | same | same | same |
| `glassEdge` (outline) | `ink` at 12% | `ink` at 12% | black at 60% (today's) | `ink` at 12% | `ink` at 12% |
| field | flat `ground` | flat `ground` | Plein's dark washes and drift (today's) | the lacquer band at 3% | flat `ground` |

- **`setCycle`:** `[signal, tess, rest, health]` of the workout palette, in that order, as today.
- **Black drop shadows in the workout** (ExerciseStrip:172, the glass's .45 shadow) stay only on Plein. Every other look lifts with a `raised` fill and draws no shadow, because a black shadow can't show on #000.
- **Workout hairline: 14%.** That's one rule for every tier, everywhere. The workout's 12% goes.
- **The workout's background:** `Workout.ground` plus the look's workout field. `PleinGround()` is only the Plein field.

### Sheen (glints)
| Look | `sheen` | `sheenBlend` |
|---|---|---|
| Porcelain | `now` (#F0A500) at 60%, masked to the glyphs | `.normal` |
| Celadon | `now` (#D99A1C) at 60%, masked to the glyphs | `.normal` |
| Plein, light pages | #F7E6B8 (today's) | `.plusLighter` |
| Obsidian, Lacquer, and every workout | #FFE2A8 | `.plusLighter` |

On white, the glint is a gold band passing through the letters; on dark looks it's light passing over them. This covers `Glint`, `GlintOnce`, `GlintIf`, the ExerciseStrip sweep and the ProcessSeam glint.

### Soul, flood and blends
- **TessSoul:** the washes are the look's `live`, `tess` and `now` (in the workout, `signal`, `Workout.tess` and `rest`).
  - Halo uses `live` and `context`. The ring uses `context` at 60%.
  - Blend is `soulBlend`: `.multiply` on light looks and `.screen` on dark looks (all workouts are dark).
  - The halo glow is on for Obsidian, Lacquer and every workout.
  - Pick the palette by the look, not by `colorScheme`.
- **PaintFlood** paints the incoming look's `live`, `context`, `tess` and `now`.
- **`pigmentBlend`** is the same rule as `soulBlend`, for any pigment overlay. That covers PasteRecipe's cadmium band (multiply on light, screen at 35% on dark) and the RoundRobin bar (`live`).
- **Glows** (`.shadow(pigment...)` on the needle, the RPE stop, the current exercise, the seam, NowPage:533 and DayStrip:165) all go through `halo`. They're full on dark looks; on light looks a glow becomes a 3pt blur of the pigment at 30%.

### Other tokens
- **Routine colours (four):** `[live, health, now, context]`, so Pull gets `context` (violet) instead of `tess`. Tess's cobalt stays hers alone.
- **`progress` retires.** The Best e1RM value on ObjectPage is `ink`, with a small `now` dab beside it. Cadmium already means "a possible record".
- **`sky`:** a new pigment, the morning end of the day stroke.

  | Porcelain | Obsidian | Plein | Lacquer | Celadon |
  |---|---|---|---|---|
  | #7FB6E0 | #7CC4F0 | #9EC3D6 | #9DBCD6 | #8DBBD6 |

  - **`daySpectrum`** is `[sky, health, context, now, live]`, morning to evening.
  - **On Porcelain and Celadon the day stroke has its own stops:** sky #509BD5 (3.00:1) and now #C58700 (3.07:1), so the stroke and its wet tip read on white. These two are for the stroke only and never text. Plein keeps today's stroke, and dark looks use the normal tokens (Research item 82).
  - `HomePaint.dayAmber` and `wetTip` use `now`, and `daySage` uses `health`.
- **`edgeLight`:** the lit chamfer under Now's seam (NowPage:537).
  - Plein: white at 80% (today's).
  - Celadon: white at 90%.
  - Porcelain, Obsidian and Lacquer: none. The edge isn't drawn.
  - NowPage:514's step text becomes `inkSecondary`.
- **Text on a heavy dab** (MonthPage:144): use `paper`.
- **A held row lifts** with a `raised` fill. The ink shadow (HomeQueue:230) stays only on light looks.
- **Veil seams** (InkActions:141): `hairline` in every look, with no `colorScheme` branch.
- **`ProcessSeam`'s default colour** is `Theme.Colors.live`, not Machined's fixed vermilion. That fixes `RunningSeam`.
- **Plates stay fixed in every theme.** They mean real plates. PlateStack's change plates (#55534F, #A8A49C) move into `Theme.Colors.plate(_:)`.

### Live Activity
- Add a `Shared/LookTable.swift` holding the five looks' workout palette, plus `tess` and `context`. Compile it into both the app and the widget extension.
- RestLiveActivity's private `Palette`, `RestMood` and `Color(hex:)` go.
- `RestActivityAttributes.ContentState` carries `look`.
- Rest sky: `Workout.tess` at 35% top-left, `context` at 45% top-right. Go washes: `rest` and `signal`. Keyline: `signal`.

## Second addendum: Research's contrast check (#189, `docs/research/theme-checks.md`)
This addendum wins over everything above. The tables above already carry the new hex values.

**Hex and tier fixes:**
1. `inkSecondary`: 66% on light looks (Plein and Celadon failed 4.5:1 at 60%), and 72% on dark looks and the workout (APCA Lc 58 instead of 43).
2. `inkTertiary`: 51% on light looks, 38% on dark looks. It's text only at 34pt and up; below that, it's for marks. Placeholders use `inkSecondary`.
3. `muted` is never text. It's for disabled marks only.
4. `liveInk` is its own value on dark looks too: Obsidian #FF7A5C and Lacquer #FF8466. **UNDO and every vermilion word always use `liveInk`.** Fills and strokes keep `live`.
5. Obsidian `tess` and Obsidian Workout `tess` are both #86B4FF, for words and the soul alike.
6. Plein `tess`: #2A64A0, and Celadon `context`: #456680. These are margin, so the washes and the glaze pool can't drop them under 4.5:1.
7. Celadon Workout `signal`: #EE7056. Plein keeps #D9563F, because it's the approved look; instead, no signal text ever sits on Plein's Workout `raised`.

**Rules:**
- **No halo on text under 34pt.** Halo is for strokes, dabs, the soul and numerals only.
- **On dark looks, a cobalt word never sits next to vermilion.** Keep at least 24pt of ground, or a line of ink, between Tess's words and UNDO.
- **Ink never sits on a signal fill.** A word on a filled signal patch is Workout `ground`.
- **The signal keyline stays off the rest-sky wash.**

**Live Activity and widgets:**
- **Lock Screen:**
  - `activityBackgroundTint` is Workout `ground`.
  - `activitySystemActionForegroundColor` is Workout `ink`.
  - Text is `ink` or `inkSecondary`, never `inkTertiary`, because Always-On dims it.
- **Dynamic Island:** always the Obsidian workout set, whatever the look (Plein's signal is 4.4:1 on black), with `keylineTint` = `signal`.
- **StandBy night mode:** signal, rest and Tess must differ by luminance or shape, not hue. The horizon is a line and the timer is a word.
- **Removable backgrounds** (StandBy, clear or tinted Home Screen): use the night look's ink and pigments.
- **Lock Screen accessory widgets:** opacity tiers only. Done reads as a filled dab and open as a ring, so meaning never rides on hue.
- **Accented mode:** exactly one `.widgetAccentable()` element, the action stroke or the running dab. The soul glyph uses `.accented`.
- **App icon:** three variants.
  - Light: Porcelain white with the three soul dabs.
  - Dark: #000 with the Obsidian dabs and no halo.
  - Tinted: the dabs at clearly different greys (live 30%, tess 55%, now 85% lightness).

## Third addendum: no dots (Kaushik, Oct 15, about 8:08 PM PT)
- **The rule:** colour arrives through motion and moments; resting colour stays low-contrast. The full list of places is in `no-dots.md`.
- **No coloured mark sits before or after a line of text,** in any look. The row dabs on Home, Now, Kitchen, Groceries, Notes, capture modes, muscles and the month key are removed.
- **Data marks rest at `restTint`:** the pigment at 45% on light looks and 55% on dark looks and in the workout. They land wet at 100%, then dry over `Theme.Motion.dry` (1.1s on the house curve, after 0.4s).
- **On dark looks a resting mark has no halo.** The halo belongs to the wet moment only and dries away with the colour.
- **The themes preview** (artifact v5) drops the Home row dabs.

## Fourth addendum: the workout is pure black (Kaushik, Oct 15, about 8:22 PM PT)
He likes the workout in pure black and doesn't like today's tinted workout grounds. He wants one consistent base: nothing much brighter or much darker than the rest.

**Tokens:** every look uses Obsidian's workout set. This replaces the per-look workout columns from #203.

| `Workout.*` | Value in every look |
|---|---|
| `ground` | #000000 |
| `raised` | #141217 |
| `ink` | #F5F2EC |
| `inkSecondary` | 72% |
| `inkTertiary` | 38% (34pt and up, or marks only) |
| `signal` | #FF5B3A |
| `rest` | #FFC23D |
| `tess` | #86B4FF |
| `health` | Obsidian `health`, #3FD49A |

**What follows from that:**
- **Sheen:** the workout's sheen is Obsidian's, light passing over the letters, never the gold band.
- **The pin and the day look don't reach the workout.** Pinning Porcelain doesn't make the workout white.
- **`LookTable` keeps one workout set,** and the drift test checks that all five looks resolve to it.

**Accents on black (consistency):**
- **Nothing glows at rest.** The halo appears only in a moment: a set landing, a new best, Go, Finish. It dries away with the colour (`no-dots.md`).
- **The ProcessSeam and the current-exercise segment** keep `signal` with no glow.
- **Set strokes** land in their cycle colour and rest at 55%.
- **The soul is unchanged:** screen blend, the workout palette as today, and her halo as today (Kaushik: the soul stays as he knows it).
- **Status words** rest in workout `ink` (no-dots B1 to B4). Colour arrives only when something changes.

**Entering and leaving the workout on a light look,** so the white-to-black switch isn't a jolt:
- **Entering.**
  1. The tapped Start word's stroke stays put.
  2. Black floods out from it with `PaintFlood` (#000, 620ms, house curve). The page under it fades to 0 over the first 240ms, so no white text is ever drawn on black mid-flood.
  3. The workout's content rises 12pt and fades in during the last 260ms.
  4. The status bar flips to light at the flood's halfway point.
- **Leaving** (Finish, or close after the finish sentence):
  1. The finish sentence and the gathered set strokes stay.
  2. Black draws back into the Home Now slot it came from: a reverse flood, 560ms, house curve.
  3. The light page fades in behind it, already at rest.
  4. The status bar flips back at the halfway point.
- **On dark looks** (Obsidian, Lacquer), the change is only the content crossfade (300ms), because the ground is already black or near-black.
- **Pages opened from inside a running workout** (the exercise page, swap, finish) are black. The same pages opened from Home or Plans follow the look.
- **Home's running-workout row** on a light look stays on the light page. Only its seam is `signal`.
- **Reduce Motion:** a 250ms crossfade both ways, with no flood.

**The rest Live Activity:**
- **The Lock Screen rest Live Activity always uses the black workout set,** like the Dynamic Island already does. It ignores the day and night looks, so it matches the workout it belongs to.
- The rest sky washes stay as approved: rest uses `Workout.tess` at 35% and `context` at 45%, and Go uses `rest` at 75% and `signal` at 60%.
- The tick rests in ink. Go glows only as it lands.

**Later (a direction, not a task):** each area becomes its own app inside the app, with its own UI and its own look on top of one shared base, like apps on a computer. The workout is the first one. A new look can be explored then. For now there's one consistent base, and customisation sits on top.
