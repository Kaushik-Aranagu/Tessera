# Materials: zero tolerance

Parts look milled from one block. Boundaries are a cut, a tonal step and a chamfer catching one light from above. There are no boxes, gaps or drop shadows.

## Light: Home, bead-blasted warm aluminium
- **Base** `#E7E3DC`. The brushed texture is optional: 1pt alternating rows, white 3.5% / black 1.8%.
- **Raised part:**
  - Fill `#ECE9E3`.
  - Inner top chamfer: a 1px line, white 95%.
  - Inner bottom shade: a 1px line, black 7%.
  - Outline: 0.5pt `rgba(40,36,30,.22)`.
- **Recess** (wells, channels, input slots):
  - Fill `#DCD8D0`.
  - Inner top: 1px black 10%.
  - Inner bottom lip: 1px white 85%.
  - Outline: 0.5pt `rgba(40,36,30,.16)`.
- **Seam between surfaces:** two lines, each `1 / displayScale` wide. Dark on top: `rgba(40,36,30,.16–.35)`. Light directly below: white 80%. It should read as a cut, not a border.
- **Text:** ink `#1C1B1A`, secondary `#6E6A63`, disabled `#9C978E`.

## Dark: Workout, anodised graphite
- **Base** `#1B1C1E`, with an optional vertical brushed texture.
- **Raised** `#25262A`: inner top 1px white 10%, inner bottom 1px black 55%, outline 0.5pt black 90%.
- **Recess** `#131416`: inner top shadow (y 1, blur 2, black 70%), inner bottom lip 1px white 7%.
- **Seam:** black 75% over white 7%.
- **Text:** `#ECE9E3`, secondary `#8B877F`, dim `#5F5C57`.

## Accents: the paint, used only for meaning
| Role | Light | Dark |
|---|---|---|
| Live, running, the log key, PR | vermilion `#C8452F` | `#D9563F` |
| Tess, and anything she changed | cobalt `#2E6DA4` | `#3F7FC0` |
| Now, rest | cadmium `#E0B341` (as text: `#8A6A1C`) | `#E8BD4C` |
| Health and recovery blocks | sage `#5E8C61` | same |

## Radii: continuous and concentric (inner = outer − inset)
- Big block 22pt.
- Key 16pt, with its channel at 8pt (inset 8).
- Wells 10pt.
- Small inlays 3–6pt.
- **Never use height/2.** No capsules anywhere, including glass: always pass `in: .rect(cornerRadius:)` or `ConcentricRectangle()`. Check that `.buttonStyle(.glass)` doesn't fall back to a capsule.

## Grouping
- No cards and no drop shadows.
- A group is one milled block cut into cells by seams.
- Separate groups with 12–20pt of space plus one tonal step (2–3% luminance).

## Glass: floating chrome only (the Ask Tess bar), shaped as a flush lens
- **Light:** radius 16, height 64.
  - Fill: a white gradient, 55% at the top to 25% at the bottom.
  - Blur 18, saturation 1.6.
  - Inner top 1px white 95%, inner bottom 1px black 6%.
  - Outline 0.5pt; soft ambient shadow at y 10, blur 30, 12%.
- **Dark:** radius 18, height 70.
  - Fill: white 10% to 3%.
  - Inner top white 18%, inner bottom black 50%.
- Never put glass on glass. Content is never glass.

## Position indicators (no dots, no capsules)
- **x (lanes and siblings):** a ruler of ticks, each 2pt wide and spaced 9pt.
  - Inactive: 6pt tall, ink at 30%.
  - Current: 12pt tall, full ink.
  - Height and colour animate over 220ms.
- **y (bounded vertical wells):** the same ruler turned sideways, inside the well's right edge. Inactive 6pt wide, current 12pt.
- **Home sibling rail:** the words REVIEW · NOW · TRAINING in the label style. The active word is ink, the others `#9C978E`.
  - Under them is a recessed 4pt track with a solid ink "carriage" one third wide.
  - The carriage follows the scroll offset continuously, not by page, like a part sliding in a track.
- **Running process:** a lit 3pt seam along the very top edge of the screen.
  - Vermilion, with a light glint (`#FFE2A8`) sweeping across about every 4.5s and a soft 12pt glow.
  - It replaces every status pill and rest pill.
