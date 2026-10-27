# The looks beyond Obsidian, recut (Design item 43)

**Kaushik's principle, in one line:** pure black is right, and the other looks should be as sure of themselves as the black is: each one a real material with its own pigments, not a tint of the same palette.

Kaushik's first review of the build (16 Oct, 11:58 PM PT): "pure black is good, the other colours could be better." Obsidian stays exactly as built. This sheet recuts Porcelain, Plein, Celadon and Lacquer. It changes only what `themes.md` lets a look change: the ground with its field, the ink and the pigments. Type, ink actions, the soul's shape, motion and layout are untouched, and every rule in `themes.md` and its addenda stands unless a line below says otherwise.
- Board: `mockups/looks-recut.png` (source `studies/looks-recut.html`). Five columns on the Home frame from `home-first-review.md`: each look at rest (only the context line in colour), each in a moment (a task struck in `context`, the fleck's bloom on the day name, Tess's line in cobalt with UNDO), and under each the new tokens with the old value beneath ("was").
- Recording: `recordings/looks-flood.mp4` (14s). The looks flood in from the soul one after another (PaintFlood, 700ms, house curve): Porcelain, Plein, Celadon, Obsidian, Lacquer and back.

## What was wrong
- The four looks shared one palette, shifted a little. Plein's and Celadon's pigments were Porcelain's with the saturation turned down, so they read as faded, not as different materials.
- Plein's washes and grain were the one texture in the app, and the one thing on screen that looked like an effect.
- Lacquer's plum was close to Obsidian's `context` violet, so the whole look read as "black, but violet".
- The context colour on light looks (`#6A4C9C`, `#7A5C8E`, `#456680`) was muddy: a violet with grey in it, on every hero.
- The light inks had a violet cast (`#17141F`, `#2B2440`) that greyed the type against a coloured ground.

## The idea per look
| Look | The idea | What you'd notice |
|---|---|---|
| **Porcelain** (default by day) | White, with the soul's own pigments as the pops | Denser ink, a clearer violet on the context line. Her colours (cobalt, vermilion, cadmium) are the moment colours, as he just chose for the soul |
| **Plein** | Warm paper and earth: indigo, rust, ochre | Flat paper, no washes, no grain. A warm black ink. Every pigment is an earth or a mineral |
| **Celadon** | Jade glaze and slate: a cool ground, warm moments | A touch greener, with a slate-blue context line; coral and gold arrive in moments |
| **Obsidian** (default by night) | Stays as is | Nothing |
| **Lacquer** | Urushi: black-red, ivory ink, gold and vermilion | The ground is lacquer's own black-red instead of plum; the sheen band stays; rose instead of lavender on the context line |

## Tokens
Values that change are in bold; "was" is master's `Looks.swift`.

| Token | Porcelain | Plein | Celadon | Obsidian | Lacquer |
|---|---|---|---|---|---|
| `ground` | #FFFFFF | **#F3EDE2** (was #F2ECE3) | **#E0EAE2** (was #E7EEE9) | #000000 | **#130A0D** (was #140F1B) |
| `raised` | **#F6F5F9** (was #F5F4F8) | **#FBF7F0** (was #FAF6EF) | #FFFFFF | #0F0E12 | **#221317** (was #221A2D) |
| `ink` | **#121016** (was #17141F) | **#26201E** (was #2B2440) | **#0C1E19** (was #0F231D) | #F5F2EC | **#F3E8D6** (was #F1E7D6) |
| `context` | **#5A3DAF** (was #6A4C9C) | **#7D4E6E** (was #7A5C8E) | **#3A6584** (was #456680) | #B7A6E0 | **#D9A6B8** (was #C3A6DE) |
| `muted` | #B9B3C3 | **#BDB2A4** (was #A39AAE) | #97ABA2 | #5C5765 | **#6E5C62** (was #6C6078) |
| `tess` | #2450D8 | **#2A4FA8** (was #2A64A0) | #2C59BE | #86B4FF | **#8FB5FF** (was #8DB2FF) |
| `live` | #E2432A | **#B9452B** (was #C8452F) | **#D94B2E** (was #D8462C) | #FF5B3A | **#F0583A** (was #F06A4C) |
| `liveInk` | #C23A22 | **#A33A22** (was #B83C28) | **#B23A1F** (was #B8361E) | #FF7A5C | **#FF7C5E** (was #FF8466) |
| `now` | #F0A500 | **#C98E1B** (was #E0B341) | **#CF9418** (was #D99A1C) | #FFC23D | **#E9B64A** (was #E8B54A) |
| `health` | #12936A | **#5E8F5A** (was #6E9E6A) | **#1F8B6A** (was #23866A) | #3FD49A | **#86C9A0** (was #8FCB9E) |
| `training` | #CC3F68 | **#B04A5E** (was #6E9E6A) | **#BF4664** (was #C24766) | #FF6B92 | **#F48BA6** (was #F07FA0) |
| `neutral` | #9C95A8 | **#A89C90** (was #A39AAE) | #7E918A | #8E879A | **#9E8F93** (was #9A8FA6) |
| `sky` | #7FB6E0 | **#8DB4C8** (was #9EC3D6) | **#86B8D4** (was #8DBBD6) | #7CC4F0 | **#A6BCD6** (was #9DBCD6) |
| `sheen` | #F0A500, on letters | **#E0B341** (was #F7E6B8), plus-lighter | #D99A1C, on letters | #FFE2A8 | #FFE2A8 |
| `field` | pigmentBloom | **flat** (was plein) | glaze | emissive | lacquer, `fieldShade` **#050203**, `fieldSpecular` **#FFF1E0** |

- **Contrast** (text colours on their ground): ink 18.9 / 13.8 / 14.0 / 18.8 / 16.1; context 7.7 / 5.7 / 5.0 / 9.5 / 9.4; tess 6.5 / 6.5 / 5.2 / 10.0 / 9.5; liveInk 5.4 / 5.7 / 4.8 / 8.2 / 7.7. Every text colour clears 4.5:1, so the ink tiers in `themes.md` (66% / 72% secondary) stand.
- **Plein's training colour** was its sage, the same as `health`. It gets its own rose-rust so a training mark and a kitchen mark never share a pigment.
- **The Live Activity** follows: `LookTable` takes the new `ground`, `ink`, `signal` (= `live`), `rest` (= `now`), `tess` and `context` for Plein, Celadon and Lacquer. The Dynamic Island stays on the Obsidian set, and the rest sky stays Cobalt sky (`lockscreen.md`).

## Fields
- **Porcelain, Celadon:** unchanged. Flat ground; the pigment bloom behind the moment (now drawn as a soft pool, 12% at the centre falling to nothing, 6pt blur, no dried edge: the edge ring on the first sheet read as a shape). Celadon keeps its 6% pool over the bottom 260pt.
- **Plein: flat.** `PleinGround` (three washes, grain at 30% multiply) retires from the look. The ground is one colour. The bloom is the pigment pool, as on Porcelain. Plein's one-liner becomes "Warm paper, flat, with earth pigments."
- **Obsidian:** unchanged. Emissive glow behind the moment, halo on wet marks.
- **Lacquer:** the bottom 45% deepens to `#050203` at 75% and the specular band stays (−24°, 150pt, 5% warm white `#FFF1E0`, blur 14, tilt by up to 4° and 20pt). Its one-liner becomes "Black-red lacquer with one slow sheen that moves as you tilt."

## The soul in each look
She keeps drawing her three dabs from the look's `tess`, `live` and `now`, at the 65% spread (`soul-explore.md`), so she's cobalt, rust and ochre on Plein and cobalt, vermilion and gold on Lacquer. Item 48 (living colours) will give each look a bounded palette for her to move within; these tokens are the resting centre of that palette.

## Switching
Unchanged from `themes.md`: the Look sentence in Settings, tap to cycle, hold to pin, the flood from the soul on a tap (700ms; 250ms crossfade under Reduce Motion), an instant swap when the phone flips light and dark. The recording shows the flood.

## For Builder A
1. Replace the four looks' values in `DesignSystem/Looks.swift` with the table above; Obsidian's line doesn't change. Update the two one-liners in `Look.line`.
2. Plein's `field` becomes `.pigmentBloom`; `PleinGround` is no longer referenced by a look (keep it in code for `-theme plein-washes` until he's lived with the flat one, then delete).
3. `Shared/LookTable.swift`: the same values for Plein, Celadon and Lacquer; `cobaltSky` is untouched.
4. The bloom (`PigmentBloom`): a radial pool at 12% centre to 0, 6pt blur, no edge ring.
5. `LookTableDriftTests` carry the new values.

## Owners
- **Builder A:** the tokens, the fields, `LookTable`, the drift test.
- **Kaushik:** nothing to pick. If one of the four still reads wrong on his phone, say which, and that look gets a second cut.
