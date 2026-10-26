# Tess's soul: closer, and other colours (Design item 40)

Kaushik (11:41 PM PT): the soul's dabs sit too far apart, on the icon and in the app, and he wants to see colours beyond the first ones. This round changes only two things, **how close the dabs sit** and **which pigments they use**. Each dab keeps its paint (a radial from the pigment to 20% at the edge), its shape and its 1.2pt blur. Nothing changes in the app until he picks.
- Board: `mockups/soul-explore.png` (source `studies/soul-explore.html`). It has two parts:
  - Four spreads in today's colours, each on the icon by day and by night, and at Home size (true size, beside Tess's line).
  - Six palettes at the recommended spread, each with what it does to Tess's voice colour.
- Recording: `recordings/soul-palettes.mp4` (12s). The six palettes breathe as built (3.2s), with a slow drift so the mixing shows, then each one speaks in turn: her glow rises and she swells to 1.1.

## Spread
| Spread | What it does |
|---|---|
| 100% (today) | Three separate dots with white between them. This is what he called too far apart |
| 80% | The dabs just touch |
| **65% (recommended)** | The dabs overlap and mix at their edges, so she reads as one soul with three colours in her, and still shows all three at 29px |
| 50% | The middle starts to muddy into brown, and at small sizes she reads as one blot |

- Each dab's centre moves toward the centroid of the three: `centre' = centroid + f × (centre − centroid)`. The centroid is (21.3, 17.2) in her 46 × 40 box.
- **In the app**, the soul keeps its place (centred on 346, 779) and its 44pt touch target. Her drawn footprint shrinks from 46 × 40 to about 39 × 34 at 65%.
- **On the icon**, she grows as she tightens so she fills the same space: 14× at 100%, 16.3× at 65% (`14 / (0.55 + 0.45f)`).

## Palettes (each at 65%)
| Palette | Porcelain | Obsidian | Tess's voice colour |
|---|---|---|---|
| **Today** (cobalt, vermilion, cadmium) | `#2450D8` `#E2432A` `#F0A500` | `#86B4FF` `#FF5B3A` `#FFC23D` | Cobalt, as now |
| **Kiln** (indigo, terracotta, ochre) | `#2F3C9E` `#C4553B` `#D79A2B` | `#8E9BFF` `#F08A6E` `#F2C062` | Indigo, a shade deeper |
| **Lagoon** (teal, coral, butter) | `#0E8C86` `#F0624D` `#EDB730` | `#4FD8CF` `#FF8A75` `#FFD563` | No blue in her, so the voice stays cobalt (beside her, not in her) |
| **Orchard** (plum, rose, peach) | `#6E3A8E` `#E2557A` `#F29A5B` | `#C39BFF` `#FF86A6` `#FFBC86` | Plum is too close to `context` violet, so the voice stays cobalt |
| **Aurora** (sky, jade, violet) | `#2F6FE0` `#14A37F` `#8C5BD6` | `#7FB0FF` `#4FE0B5` `#BC97FF` | Sky, a shade lighter. All cool, with no warm pigment |
| **Ember** (ultramarine, magenta, gold) | `#3433D6` `#D6266E` `#F2B21B` | `#9A98FF` `#FF5C9A` `#FFD24A` | Ultramarine |

- **Tess's voice colour** covers her line, the ghosts and wet ink. Today it's her cool pigment, cobalt. A palette with a blue moves the voice to that blue; one without keeps cobalt.
- **How the app paints her today:** `TessSoul` takes her three washes from the look's own `live`, `tess` and `now` tokens (`TessSoul.swift:125`). So she already shifts a little per look, and today's colours are simply the look's moment colours.
- **A new palette goes in as soul-only pigments:** three new fields per look, used only by `SoulPalette`. Then `live`, `now`, `context`, the Live Activity's Cobalt sky and every other moment colour stay as they are. The only thing that may follow her is the voice colour, as in the table. If he'd rather the whole app's moment colours follow her, that's a bigger change, and it's his call.

## Recommendation
**Today's colours at 65%.** The closer spread fixes what he saw: she becomes one soul instead of three dots, on the icon and beside her line. Her colours are already the app's own: cobalt is her voice, vermilion is `live`, and cadmium is the beat stroke. The soul is where those colours come from, which no other palette keeps.

If he wants a new colour, **Lagoon** is the strongest change. It's fresh and warm-cool, it reads well on black, and it keeps cobalt for the voice.

## After he picks
- **The icon:** Design re-renders the `docs/design/icon/` masters (Any, Dark, Tinted, the clear variants and the layers) at his spread and palette, and Builder A wires them as in `app-icon.md`.
- **In the app (Builder A, who owns the looks):**
  - The spread: the main and satellite dabs' home offsets in `SoulParameters.swift`, scaled by f toward the soul's centre. Each mode's motion (bloom, carry, drip) keeps its own paths around the new homes.
  - The palette, if it changes: soul-only pigments per look, read by `SoulPalette.look`.
  - The `tess` voice token, only if the palette moves it.
- Every study that draws the soul follows on the next sheet that touches it. Old boards aren't re-rendered.
