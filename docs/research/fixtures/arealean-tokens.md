# areaLean token sweep (Obsidian and Porcelain)

For: Builder A and B (the area-colour pass), Core (the resolver and contrast helper), Design (flags), QA. Docs only; nothing was built or run (no Swift toolchain; the arithmetic is a short Python script whose formula and two worked examples are in section 6). Written Sun Oct 18 from `design/gaps-92.md` (section 2 and "Answers to Research #897", Design's answers (a) and (b)), `design/type-round-86.md`, `docs/research/theme-checks.md`, `research/fixtures/gaps-92-swipe-lean.md` (section 4, the earlier sweep this one corrects) and master at `8e70743b` (worktree on origin/master). Every `file:line` below was opened and read.

Status words: **traced** means I read the master line and it does what the row says; **inferred** means the row follows from a sheet or from code I did not read in full; **gap** means master has nothing for it (not built) or contradicts it.

## 0. Rulings this sweep rests on

- Design (a), `gaps-92.md:40`: the hexes in the sheet 86/92 area table are the **pigments**. What is drawn is `areaLean(area)`, the 72% mix with ink. "Builders use the mixed value; no pigment is drawn straight." Design's own check: Kitchen on Porcelain draws `#126E52`, 6.22:1.
- Design (b), `gaps-92.md:41`: **master is truth for Obsidian.** Ground is `#000000`; the partners are master's `liveInk` (Training), `health` (Kitchen), `context` (Review). The `#121014` ground and the `#FF7D62`, `#52D3A3`, `#B8A3FF` hexes on the boards "were board approximations, now void".
- Mix: 72% pigment + 28% the look's `ink` token, per sRGB byte, rounded. SwiftUI's `Color.mix(with:by:)` defaults to a perceptual (Oklab) space (the Pantry state word uses it, `Features/Kitchen/PantryColour.swift:16-18`), so section 1 gives both results; they differ by up to 17 per channel.

### The bars (which bar, and where it is named)

| Use | Bar | Named by |
|---|---|---|
| Caps label (small text, 16 to 21 pt) | 4.5:1 | Design (a), `gaps-92.md:40` ("clears 4.5:1 for small caps labels"); `theme-checks.md:27` ("S" = fine for 16 to 21 pt) |
| Title key word, lead numeral | 3:1 | `theme-checks.md:27` ("L" = only 34 pt and up, the 3:1 tier) and `theme-checks.md:33` (alpha "for 3:1"); applied to large text by the earlier sweep (AL12) |
| Section hairline at 34% | **none named** | `docs/DESIGN_MOTION.md` names no contrast number anywhere (grep for "contrast": zero hits). `theme-checks.md:46` calls the 14% hairline "decorative only". I report the ratio against 3:1 (WCAG 1.4.11, non-text) for information and mark the verdict "no bar" (Q1) |

## 1. Tokens: pigment, sheet hex, mix (T01 to T08)

Master pigment is the token Design named, read from `DesignSystem/Looks.swift`. "Sheet" is the hex on the Design sheet 86/92 table; where it differs it is a board approximation and is void (Design (b)). Differences are flags, neither value is final until the resolver is built.

| Id | Area | Look | Master token and file:line | Master pigment | Sheet hex | Sheet vs master | Mix, sRGB bytes (drawn) | Mix, Oklab (what `Color.mix` gives) | Status |
|---|---|---|---|---|---|---|---|---|---|
| T01 | Training | Porcelain | `liveInk`, `Looks.swift:55` | `#C23A22` | `#C23A22` | same | `#912E1F` | `#8C3124` | traced (token); gap (no `areaLean`) |
| T02 | Training | Obsidian | `liveInk`, `Looks.swift:63` | `#FF7A5C` | `#FF7D62` | differs (+3, +3, +6) | `#FC9C84` | `#FF9E86` | traced (token); gap |
| T03 | Kitchen | Porcelain | `health`, `Looks.swift:55` | `#12936A` | `#12936A` | same | `#126E52` | `#206B51` | traced (token); gap |
| T04 | Kitchen | Obsidian | `health`, `Looks.swift:63` | `#3FD49A` | `#52D3A3` | differs (+19, -1, +9) | `#72DCB1` | `#83DDB1` | traced (token); gap |
| T05 | Review | Porcelain | `context`, `Looks.swift:54` | `#5A3DAF` | `#5A3DAF` | same | `#463084` | `#443180` | traced (token); gap |
| T06 | Review | Obsidian | `context`, `Looks.swift:62` | `#B7A6E0` | `#B8A3FF` | differs (+1, -3, +31) | `#C8BBE3` | `#C8BBE4` | traced (token); gap |
| T07 | Today | Porcelain | none ("cobalt is Tess's voice", `gaps-92.md:23`); falls back to `ink` `#121016`, `Looks.swift:54` | none | none | n/a | none | none | gap (no resolver) |
| T08 | Today | Obsidian | none; falls back to `ink` `#F5F2EC`, `Looks.swift:62` | none | none | n/a | none | none | gap |

Mix inputs: ink `#121016` (Porcelain) and `#F5F2EC` (Obsidian). Grounds: Porcelain `#FFFFFF` and raised `#F6F5F9` (`Looks.swift:54`), Obsidian `#000000` and raised `#0F0E12` (`Looks.swift:62`). Master has no `areaLean` function, no area type carrying a colour and no Theme token for any of this: grep of `*.swift` finds `areaLean` only in a comment at `Features/Kitchen/PantryColour.swift:4`. The tokens themselves are pinned: every look's hexes in `TesseraTests/LookTableTests.swift:6-` and Obsidian ground and context, Porcelain ink and context in `TesseraTests/LookTableDriftTests.swift:23-25`.

## 2. Contrast of the drawn colour on its real backgrounds (C01 to C06)

Ratios use the formula in section 6. "Real background" is the look's ground (a page label sits on it), the `raised` surface (worst case if a lean word ever sits on one; the sheet says rows stay ink, so this is a margin check), and the ground with `groundTint(area)` (2.5% of the area pigment into the ground on Porcelain, 3% on Obsidian; `type-round-86.md:45`; not built, so **inferred**). "Pigment straight" is the ratio if the pigment were drawn as is, which Design (a) rules out; it shows how much work the mix does.

| Id | Area, look | Mix on ground | Mix on raised | Mix on tinted ground | Mix (Oklab) on ground | Pigment straight on ground | Pigment straight on raised | Status |
|---|---|---|---|---|---|---|---|---|
| C01 | Training, Porcelain | 8.03 | 7.40 | 7.73 | 8.14 | 5.35 | 4.93 | computed, inferred (tint) |
| C02 | Training, Obsidian | 10.23 | 9.37 | 9.94 | 10.49 | 8.19 | 7.50 | computed, inferred (tint) |
| C03 | Kitchen, Porcelain | 6.22 | 5.73 | 6.02 | 6.40 | **3.88** | **3.58** | computed, inferred (tint) |
| C04 | Kitchen, Obsidian | 12.59 | 11.53 | 12.21 | 12.94 | 11.10 | 10.16 | computed, inferred (tint) |
| C05 | Review, Porcelain | 10.41 | 9.60 | 10.02 | 10.52 | 7.72 | 7.11 | computed, inferred (tint) |
| C06 | Review, Obsidian | 11.67 | 10.69 | 11.32 | 11.68 | 9.54 | 8.74 | computed, inferred (tint) |

Reference: ink alone is 18.89 on Porcelain ground and 18.79 on Obsidian ground. The void board hexes on master's black ground would have been 8.36, 11.21 and 9.72 (Training, Kitchen, Review); the earlier sweep's `#121014` figures are void with them.

## 3. Pass or fail per use (U01 to U24)

Each row judges the drawn (mixed, sRGB bytes) colour on the look's ground. Margin = ratio minus bar. A row passes on the Oklab mix and on the raised surface wherever the ratio column shows it (section 2); the thinnest margin in the table is Kitchen Porcelain on raised, 5.73 against 4.5.

| Id | Area, look | Use | Bar | Ratio | Verdict |
|---|---|---|---|---|---|
| U01 | Training, Porcelain | Caps label | 4.5 | 8.03 | pass |
| U02 | Training, Obsidian | Caps label | 4.5 | 10.23 | pass |
| U03 | Kitchen, Porcelain | Caps label | 4.5 | 6.22 | pass (fails at 3.88 if the pigment were drawn straight) |
| U04 | Kitchen, Obsidian | Caps label | 4.5 | 12.59 | pass |
| U05 | Review, Porcelain | Caps label | 4.5 | 10.41 | pass |
| U06 | Review, Obsidian | Caps label | 4.5 | 11.67 | pass |
| U07 | Training, Porcelain | Title key word (resting stop) | 3 | 8.03 | pass |
| U08 | Training, Obsidian | Title key word | 3 | 10.23 | pass |
| U09 | Kitchen, Porcelain | Title key word | 3 | 6.22 | pass (3.88 straight also passes 3) |
| U10 | Kitchen, Obsidian | Title key word | 3 | 12.59 | pass |
| U11 | Review, Porcelain | Title key word | 3 | 10.41 | pass |
| U12 | Review, Obsidian | Title key word | 3 | 11.67 | pass |
| U13 | Training, Porcelain | Lead numeral | 3 | 8.03 | pass |
| U14 | Training, Obsidian | Lead numeral | 3 | 10.23 | pass |
| U15 | Kitchen, Porcelain | Lead numeral | 3 | 6.22 | pass |
| U16 | Kitchen, Obsidian | Lead numeral | 3 | 12.59 | pass |
| U17 | Review, Porcelain | Lead numeral | 3 | 10.41 | pass |
| U18 | Review, Obsidian | Lead numeral | 3 | 11.67 | pass |
| U19 | Training, Porcelain | Hairline at 34% (composite `#DAB8B3`) | none named | 1.83 | no bar (below 3 if 3 applied) |
| U20 | Training, Obsidian | Hairline at 34% (`#56352D`) | none named | 1.94 | no bar (below 3) |
| U21 | Kitchen, Porcelain | Hairline at 34% (`#AECEC4`) | none named | 1.69 | no bar (below 3) |
| U22 | Kitchen, Obsidian | Hairline at 34% (`#274B3C`) | none named | 2.16 | no bar (below 3) |
| U23 | Review, Porcelain | Hairline at 34% (`#C0B9D5`) | none named | 1.88 | no bar (below 3) |
| U24 | Review, Obsidian | Hairline at 34% (`#44404D`) | none named | 2.09 | no bar (below 3) |

Arrival frames (labels mixing ink to lean over 320 ms, sheet 97) pass through lower ratios by design; every row here is the resting state. Status for all 24: computed from the design values; **gap** in master because no `areaLean` exists to draw them.

## 4. Flags: where the sheet, master and the earlier sweep disagree

1. **Obsidian hexes on the Design sheet are void** (Design (b)). Sheet vs master: Training `#FF7D62` vs `#FF7A5C`, Kitchen `#52D3A3` vs `#3FD49A` (largest gap, 19 in red), Review `#B8A3FF` vs `#B7A6E0` (31 in blue). Builders must take the master tokens; the sheet table should be redrawn or footnoted so nobody reads it as final. Owner: Design.
2. **Kitchen Porcelain `#12936A` is 3.88:1 on white and 3.58:1 on `raised` if it were the final colour.** It fails the 4.5 label bar either way. It only passes because Design draws the 72% mix `#126E52` (6.22). A resolver that returns the pigment (the "Reading A" the earlier sweep allowed) must fail test `areaLeanLabelContrast`. Owner: Core, Builder A.
3. **The earlier sweep said the 34% hairline "passes at 3:1".** That judged the full lean colour. The hairline is that colour at 34% over the ground, and it composites to 1.69 to 2.16:1 in all six cells. Either the hairline has no contrast bar (it is decorative, like the 14% hairline at 1.3:1, `theme-checks.md:46`) or it fails 3:1 everywhere. Needs a ruling (Q1). Owner: Design.
4. **Training reuses `liveInk`, the "running thing" colour.** `theme-checks.md:21` reserves live/vermilion for a running thing, UNDO and Finish. The mix (`#912E1F`, `#FC9C84`) is darker or paler than `liveInk`, but it is the same hue family on every Training page. Master's own `training` token (`#CC3F68` Porcelain, `#FF6B92` Obsidian, `Looks.swift:55`, `:63`) is a pink, not the one Design named. Confirm that `liveInk` is intended (Q2). Owner: Design.
5. **Oklab versus sRGB mix.** Same recipe, two results up to 17 per channel (Kitchen Obsidian `#72DCB1` vs `#83DDB1`). All pass either way, but a test that pins a hex must pick one. Recommended: Core does the mix in sRGB bytes on purpose and the test compares within 3 per channel of that, not of `Color.mix`. Owner: Core.
6. **Pantry ochre still ships.** `PantryColour.swift:7-8` holds `0xA4601A` and `0xE3A857`; the state word is used at `PantryView.swift:196`. It is replaced by Kitchen's drawn lean at the pass. Owner: Builder B.
7. **Other looks have no value** (Plein, Lacquer, Celadon; `Looks.all` has five, `Looks.swift:91`). Out of this sweep; the resolver must be total anyway (AL09 in the earlier sweep).

## 5. Swift Testing names (pure logic; Core lifts them)

All are gap rows until `areaLean(area, look)` and the contrast helper exist. Contrast tests take ratios from the formula in section 6, tolerance 0.01.

| Id | Test name | Expected | Status | Owner |
|---|---|---|---|---|
| S01 | `areaLeanPorcelainUsesMasterPigments` | Training `liveInk` `#C23A22`, Kitchen `health` `#12936A`, Review `context` `#5A3DAF` feed the mix (T01, T03, T05) | gap (tokens traced) | Core |
| S02 | `areaLeanObsidianUsesMasterNotBoardHexes` | pigments are `#FF7A5C`, `#3FD49A`, `#B7A6E0`; none of `#FF7D62`, `#52D3A3`, `#B8A3FF` appears in app code | gap | Core, Builder A |
| S03 | `areaLeanIsSeventyTwoPercentPigmentOverLookInk` | Porcelain Training `#912E1F`, Kitchen `#126E52`, Review `#463084`; Obsidian Training `#FC9C84`, Kitchen `#72DCB1`, Review `#C8BBE3`, each within 3 per channel | gap | Core |
| S04 | `areaLeanNeverReturnsTheRawPigment` | for all six cells, result differs from the pigment | gap | Core |
| S05 | `areaLeanTodayIsNone` | Today returns nil in both looks; caller uses `ink` | gap | Core |
| S06 | `areaLeanTodayNeverReturnsTess` | no area equals `tess` (`#2450D8`, `#86B4FF`) | gap | Core |
| S07 | `areaLeanLabelContrastAtLeastFourPointFive` | all six cells at least 4.5 on the look's ground and on `raised` (C01 to C06) | gap | Core |
| S08 | `areaLeanKitchenPorcelainRawPigmentFailsLabelBar` | `#12936A` on `#FFFFFF` is 3.88 (below 4.5), `#126E52` is 6.22; pins why the mix is required | gap | Core |
| S09 | `areaLeanLargeTextContrastAtLeastThree` | key word and numeral at least 3 in all six cells | gap | Core |
| S10 | `areaLeanContrastHoldsOnTintedGround` | still at least 4.5 on the 2.5% / 3% area-tinted ground (C01 to C06 tinted column) | gap | Core |
| S11 | `areaLeanHairlineCompositeIsRecorded` | the 34% hairline composites to the U19 to U24 values; asserts only that it is the lean colour at 0.34, not a bar (until Q1) | gap | Builder A |
| S12 | `areaLeanFollowsLookDarkness` | `Look.isDark` picks the Obsidian column; Porcelain otherwise | gap (flag traced, `Looks.swift:53`, `:61`) | Core |
| S13 | `areaLeanMixIsDoneInSRGBBytes` | the resolver does not use `Color.mix` (Oklab); equals S03 | gap | Core |
| S14 | `lookTableStillPinsLeanPigments` | `liveInk`, `health` of both looks stay equal to S01/S02 values (today only ground, context and ink are pinned, `LookTableDriftTests.swift:24-25`; all tokens in `LookTableTests.swift:6-`) | inferred (covered by `everyLookMatchesTheSheet`) | Builder A |
| S15 | `pantryStateWordIsKitchenLean` | `PantryColour` ochre gone; state word equals `areaLean(.kitchen)` | gap (`PantryColour.swift:7-8` still defines both) | Builder B |

## 6. The math (reproducible)

Formula (WCAG 2.x): linearize each sRGB channel `c/255` with `c <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4`; `L = 0.2126 R + 0.7152 G + 0.0722 B`; ratio = `(L_light + 0.05) / (L_dark + 0.05)`. Mix: `round(0.72 x pigment + 0.28 x ink)` per channel. Hairline composite: `round(0.34 x lean + 0.66 x ground)`. Tinted ground: `round(t x pigment + (1 - t) x ground)` with `t` 0.025 (Porcelain) and 0.03 (Obsidian).

Worked example, Kitchen Porcelain mix `#126E52` on `#FFFFFF`: pigment `#12936A` gives R 18, G round(0.72 x 147 + 0.28 x 16) = 110, B round(0.72 x 106 + 0.28 x 22) = 82. Linear channels 0.0060, 0.1559, 0.0844; L = 0.2126 x 0.0060 + 0.7152 x 0.1559 + 0.0722 x 0.0844 = 0.0013 + 0.1115 + 0.0061 = 0.1189. Ratio = 1.05 / 0.1689 = **6.22**. The straight pigment: L = 0.2204, ratio = 1.05 / 0.2704 = **3.88**.

Worked example, Training Obsidian mix `#FC9C84` on `#000000`: R round(0.72 x 255 + 0.28 x 245) = 252, G round(0.72 x 122 + 0.28 x 242) = 156, B round(0.72 x 92 + 0.28 x 236) = 132. L = 0.2126 x 0.9734 + 0.7152 x 0.3325 + 0.0722 x 0.2307 = 0.2069 + 0.2378 + 0.0167 = 0.4614; ratio = (0.4614 + 0.05) / 0.05 = **10.23**.

The script that produced every number (about 60 lines of Python, standard library only; it also carries the Oklab mix) is the author's scratch file and is not committed, to keep this change to one document; the two examples above are enough to recompute any row by hand.

## 7. Open questions

1. **Hairline bar (Design).** Does the 34% lean hairline have a contrast bar? As drawn it is 1.69 to 2.16:1. If 3:1 applies the opacity must rise; if it is decorative like the 14% hairline, say so and the rows stay "no bar".
2. **Training colour (Design).** Is `liveInk` the right pigment for Training given the live/vermilion reservation, or should Training lean on `training` (pink)? The sheet names the Porcelain hex that equals `liveInk`.
3. **Sheet redraw (Design).** Footnote or redraw the Obsidian column of the sheet 86/92 table with the master pigments so the board stops carrying void hexes.
4. **Mix space (Core and Design).** sRGB bytes (this fixture) or Oklab (`Color.mix`, as Pantry does today)? The values differ by up to 17 per channel; every contrast result passes either way.
5. **Plein, Lacquer, Celadon (Design).** No lean values; out of scope here, needed before the resolver ships.
