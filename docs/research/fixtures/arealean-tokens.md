# areaLean token sweep (all five looks)

For: Builder A and B (the area-colour pass), Core (the resolver and contrast helper), Design (flags), QA. Docs only; nothing was built or run (no Swift toolchain; the arithmetic is a short Python script whose formula and worked examples are in section 6). Extends #905 (Obsidian and Porcelain) to Plein, Lacquer and Celadon. Written Sun Oct 18 from `design/gaps-92.md` (section "Area lean per look (Oct 17, 5:05 PM PT; supersedes the table in section 2)", the lean table, plus Design's answers (a) and (b)), `docs/research/theme-checks.md` and master at `6899613b` (worktree on origin/master). Commit `74314410` is not in this clone or on any branch I could list, so the lean table was read from the sheet file under `design/gaps-92.md` in the project files; every one of its 15 mixed hexes and 15 ratios was reproduced exactly by the script (section 6). Every `file:line` below was opened and read.

Status words: **traced** means I read the master line and it does what the row says; **inferred** means the row follows from a sheet or from code I did not read in full; **gap** means master has nothing for it (not built) or contradicts it.

## 0. Rulings this sweep rests on

- Design (a): the hexes in the area table are the **pigments**; what is drawn is `areaLean(area)`, the 72% mix with ink. No pigment is drawn straight.
- Design (b): **master is truth.** Obsidian ground is `#000000`; the board hexes `#121014`, `#FF7D62`, `#52D3A3`, `#B8A3FF` are void.
- Lean sheet (Oct 17, 5:05 PM PT) **supersedes #905 on one point**: Training's pigment is `training`, never `liveInk` (reserved for a running thing). #905 used `liveInk` for T01 and T02; this file corrects that (flag 1).
- Product: the mix is 72% pigment + 28% the look's `ink` token, **per sRGB byte, rounded** (not Oklab, so `Color.mix(with:by:)`, which defaults to a perceptual space, must not be used).
- Product: **4.5:1 applies to text only**: the caps label, the title key word and the lead numeral. The section hairline at 34% is decoration (sheet: "needs no 3:1 contrast because nothing is carried by the hairline alone"); it has no bar and no row here. The hairline rows and the 3:1 tier of #905 are removed.

## 1. Tokens: pigment and mix (T01 to T15)

Master pigment is read from `DesignSystem/Looks.swift`. "Sheet" is the ratio printed on the lean table; every mixed hex below equals the sheet's, and every ratio equals it to two decimals. Today has no area colour (cobalt is Tess's voice) and falls back to `ink`, so there is no Today row.

| Id | Area | Look | Master token and file:line | Pigment | Mix, sRGB bytes (drawn) | Sheet ratio | Hex vs sheet | Status |
|---|---|---|---|---|---|---|---|---|
| T01 | Training | Porcelain | `training`, `Looks.swift:54-55` | `#CC3F68` | `#983251` | 7.22 | match | traced (token); gap (no `areaLean`) |
| T02 | Kitchen | Porcelain | `health`, `Looks.swift:54-55` | `#12936A` | `#126E52` | 6.22 | match | traced (token); gap (no `areaLean`) |
| T03 | Review | Porcelain | `context`, `Looks.swift:54-55` | `#5A3DAF` | `#463084` | 10.41 | match | traced (token); gap (no `areaLean`) |
| T04 | Training | Obsidian | `training`, `Looks.swift:62-63` | `#FF6B92` | `#FC91AB` | 9.78 | match | traced (token); gap (no `areaLean`) |
| T05 | Kitchen | Obsidian | `health`, `Looks.swift:62-63` | `#3FD49A` | `#72DCB1` | 12.59 | match | traced (token); gap (no `areaLean`) |
| T06 | Review | Obsidian | `context`, `Looks.swift:62-63` | `#B7A6E0` | `#C8BBE3` | 11.67 | match | traced (token); gap (no `areaLean`) |
| T07 | Training | Plein | `training`, `Looks.swift:69-70` | `#B04A5E` | `#893E4C` | 6.31 | match | traced (token); gap (no `areaLean`) |
| T08 | Kitchen | Plein | `health`, `Looks.swift:69-70` | `#5E8F5A` | `#4E7049` | 4.82 | match | traced (token); gap (no `areaLean`) |
| T09 | Review | Plein | `context`, `Looks.swift:69-70` | `#7D4E6E` | `#654158` | 7.36 | match | traced (token); gap (no `areaLean`) |
| T10 | Training | Lacquer | `training`, `Looks.swift:77-78` | `#F48BA6` | `#F4A5B3` | 10.10 | match | traced (token); gap (no `areaLean`) |
| T11 | Kitchen | Lacquer | `health`, `Looks.swift:77-78` | `#86C9A0` | `#A5D2AF` | 11.55 | match | traced (token); gap (no `areaLean`) |
| T12 | Review | Lacquer | `context`, `Looks.swift:77-78` | `#D9A6B8` | `#E0B8C0` | 10.94 | match | traced (token); gap (no `areaLean`) |
| T13 | Training | Celadon | `training`, `Looks.swift:85-86` | `#BF4664` | `#8D3B4F` | 5.93 | match | traced (token); gap (no `areaLean`) |
| T14 | Kitchen | Celadon | `health`, `Looks.swift:85-86` | `#1F8B6A` | `#1A6C53` | 5.14 | match | traced (token); gap (no `areaLean`) |
| T15 | Review | Celadon | `context`, `Looks.swift:85-86` | `#3A6584` | `#2D5166` | 6.87 | match | traced (token); gap (no `areaLean`) |

Inks and grounds, all read from `Looks.swift`: Porcelain ink `#121016`, ground `#FFFFFF`, raised `#F6F5F9` (`:54`); Obsidian ink `#F5F2EC`, ground `#000000`, raised `#0F0E12` (`:62`); Plein ink `#26201E`, ground `#F3EDE2`, raised `#FBF7F0` (`:69`); Lacquer ink `#F3E8D6`, ground `#130A0D`, raised `#221317` (`:77`); Celadon ink `#0C1E19`, ground `#E0EAE2`, raised `#FFFFFF` (`:85`). `Looks.all` lists five looks (`:91`). **No look is missing lean values on master or on the sheet**: all fifteen pigment tokens exist on master and all fifteen cells are on the sheet, so there is no value gap, only the missing resolver. Master has no `areaLean` function: grep of `*.swift` finds `areaLean` only in a comment at `Features/Kitchen/PantryColour.swift:4`. Token pins today: `TesseraTests/LookTableTests.swift` (all looks) and `TesseraTests/LookTableDriftTests.swift:23-27` (Obsidian ground and context, Porcelain ink and context, Plein field and ink, Celadon ground and context).

## 2. Contrast of the drawn colour (C01 to C15)

Ratios use the formula in section 6. "Ground" is the look's ground (a page label sits on it); "raised" is the `raised` surface (margin check if a lean word ever sits on one); "tinted" is the ground with `groundTint(area)` (2.5% of the pigment on light looks, 3% on dark; `type-round-86.md:45`; not built, so **inferred**, and Lacquer is treated as dark). "Pigment straight" shows what the mix buys. Margin is the thinner of ground and raised minus 4.5.

| Id | Area, look | Mix on ground | Mix on raised | Mix on tinted ground | Pigment straight on ground | Margin | Status |
|---|---|---|---|---|---|---|---|
| C01 | Training, Porcelain | 7.22 | 6.65 | 6.97 | 4.69 | +2.15 | computed, inferred (tint) |
| C02 | Kitchen, Porcelain | 6.22 | 5.73 | 6.02 | 3.88 **fails 4.5** | +1.23 | computed, inferred (tint) |
| C03 | Review, Porcelain | 10.41 | 9.60 | 10.02 | 7.72 | +5.10 | computed, inferred (tint) |
| C04 | Training, Obsidian | 9.78 | 8.95 | 9.54 | 7.77 | +4.45 | computed, inferred (tint) |
| C05 | Kitchen, Obsidian | 12.59 | 11.53 | 12.21 | 11.10 | +7.03 | computed, inferred (tint) |
| C06 | Review, Obsidian | 11.67 | 10.69 | 11.32 | 9.54 | +6.19 | computed, inferred (tint) |
| C07 | Training, Plein | 6.31 | 6.88 | 6.11 | 4.52 | +1.81 | computed, inferred (tint) |
| C08 | Kitchen, Plein | 4.82 | 5.26 | 4.71 | 3.25 **fails 4.5** | +0.32 | computed, inferred (tint) |
| C09 | Review, Plein | 7.36 | 8.03 | 7.11 | 5.66 | +2.86 | computed, inferred (tint) |
| C10 | Training, Lacquer | 10.10 | 9.27 | 9.75 | 8.44 | +4.77 | computed, inferred (tint) |
| C11 | Kitchen, Lacquer | 11.55 | 10.60 | 11.14 | 10.10 | +6.10 | computed, inferred (tint) |
| C12 | Review, Lacquer | 10.94 | 10.04 | 10.54 | 9.38 | +5.54 | computed, inferred (tint) |
| C13 | Training, Celadon | 5.93 | 7.31 | 5.75 | 3.98 **fails 4.5** | +1.43 | computed, inferred (tint) |
| C14 | Kitchen, Celadon | 5.14 | 6.34 | 5.02 | 3.44 **fails 4.5** | +0.64 | computed, inferred (tint) |
| C15 | Review, Celadon | 6.87 | 8.47 | 6.67 | 5.05 | +2.37 | computed, inferred (tint) |

Reference: the thinnest cell on ground is Plein Kitchen (4.82, margin 0.32); on the tinted ground it is Plein Kitchen again at 4.71 (margin 0.21); Celadon Kitchen tinted is 5.02. No cell fails.

## 3. Pass or fail per use (U01 to U45)

Every use is text, so one bar: 4.5:1, judged on the drawn (mixed) colour over the look's ground. Arrival frames (labels mixing ink to lean over 320 ms, sheet 97) pass through lower ratios by design; every row is the resting state. Status for all 45: computed from the design values; **gap** in master because no `areaLean` exists to draw them.

| Id | Area, look | Use | Bar | Ratio | Verdict |
|---|---|---|---|---|---|
| U01 | Training, Porcelain | Caps label | 4.5 | 7.22 | pass |
| U02 | Training, Porcelain | Title key word | 4.5 | 7.22 | pass |
| U03 | Training, Porcelain | Lead numeral | 4.5 | 7.22 | pass |
| U04 | Kitchen, Porcelain | Caps label | 4.5 | 6.22 | pass |
| U05 | Kitchen, Porcelain | Title key word | 4.5 | 6.22 | pass |
| U06 | Kitchen, Porcelain | Lead numeral | 4.5 | 6.22 | pass |
| U07 | Review, Porcelain | Caps label | 4.5 | 10.41 | pass |
| U08 | Review, Porcelain | Title key word | 4.5 | 10.41 | pass |
| U09 | Review, Porcelain | Lead numeral | 4.5 | 10.41 | pass |
| U10 | Training, Obsidian | Caps label | 4.5 | 9.78 | pass |
| U11 | Training, Obsidian | Title key word | 4.5 | 9.78 | pass |
| U12 | Training, Obsidian | Lead numeral | 4.5 | 9.78 | pass |
| U13 | Kitchen, Obsidian | Caps label | 4.5 | 12.59 | pass |
| U14 | Kitchen, Obsidian | Title key word | 4.5 | 12.59 | pass |
| U15 | Kitchen, Obsidian | Lead numeral | 4.5 | 12.59 | pass |
| U16 | Review, Obsidian | Caps label | 4.5 | 11.67 | pass |
| U17 | Review, Obsidian | Title key word | 4.5 | 11.67 | pass |
| U18 | Review, Obsidian | Lead numeral | 4.5 | 11.67 | pass |
| U19 | Training, Plein | Caps label | 4.5 | 6.31 | pass |
| U20 | Training, Plein | Title key word | 4.5 | 6.31 | pass |
| U21 | Training, Plein | Lead numeral | 4.5 | 6.31 | pass |
| U22 | Kitchen, Plein | Caps label | 4.5 | 4.82 | pass |
| U23 | Kitchen, Plein | Title key word | 4.5 | 4.82 | pass |
| U24 | Kitchen, Plein | Lead numeral | 4.5 | 4.82 | pass |
| U25 | Review, Plein | Caps label | 4.5 | 7.36 | pass |
| U26 | Review, Plein | Title key word | 4.5 | 7.36 | pass |
| U27 | Review, Plein | Lead numeral | 4.5 | 7.36 | pass |
| U28 | Training, Lacquer | Caps label | 4.5 | 10.10 | pass |
| U29 | Training, Lacquer | Title key word | 4.5 | 10.10 | pass |
| U30 | Training, Lacquer | Lead numeral | 4.5 | 10.10 | pass |
| U31 | Kitchen, Lacquer | Caps label | 4.5 | 11.55 | pass |
| U32 | Kitchen, Lacquer | Title key word | 4.5 | 11.55 | pass |
| U33 | Kitchen, Lacquer | Lead numeral | 4.5 | 11.55 | pass |
| U34 | Review, Lacquer | Caps label | 4.5 | 10.94 | pass |
| U35 | Review, Lacquer | Title key word | 4.5 | 10.94 | pass |
| U36 | Review, Lacquer | Lead numeral | 4.5 | 10.94 | pass |
| U37 | Training, Celadon | Caps label | 4.5 | 5.93 | pass |
| U38 | Training, Celadon | Title key word | 4.5 | 5.93 | pass |
| U39 | Training, Celadon | Lead numeral | 4.5 | 5.93 | pass |
| U40 | Kitchen, Celadon | Caps label | 4.5 | 5.14 | pass |
| U41 | Kitchen, Celadon | Title key word | 4.5 | 5.14 | pass |
| U42 | Kitchen, Celadon | Lead numeral | 4.5 | 5.14 | pass |
| U43 | Review, Celadon | Caps label | 4.5 | 6.87 | pass |
| U44 | Review, Celadon | Title key word | 4.5 | 6.87 | pass |
| U45 | Review, Celadon | Lead numeral | 4.5 | 6.87 | pass |

## 4. Flags

1. **#905 used the wrong Training pigment.** It mixed `liveInk` (`#C23A22` / `#FF7A5C`); the lean sheet says `training` (`#CC3F68` / `#FF6B92`, `Looks.swift:55`, `:63`). Corrected here (T01, T04). Tests S01/S02 in #905 should be read as below. Owner: Core.
2. **Straight pigments that fail 4.5:1 on ground** (so the mix is mandatory): Porcelain Kitchen 3.88, Plein Kitchen 3.25, Celadon Training 3.98, Celadon Kitchen 3.44 (section 2, last column). Plein Training 4.52 passes only by 0.02. A resolver returning the pigment must fail `areaLeanLabelContrast`. Owner: Core, Builder A.
3. **Thinnest passing cells are the two light-look Kitchens**: Plein 4.82 (4.71 tinted) and Celadon 5.14 (5.02 tinted). Any change to Plein's `ink` `#26201E` or `health` `#5E8F5A`, or a stronger ground tint, can push Plein Kitchen under 4.5. Owner: Design.
4. **Lacquer Training `#F4A5B3` and Review `#E0B8C0` are both rose.** The sheet's own watch item; the word, not the hue, separates them. Not a contrast issue (10.10 and 10.94). Owner: Design (decide after a phone look).
5. **Mix space.** sRGB bytes by ruling. A test that pins a hex must not go through `Color.mix`. Owner: Core.
6. **Pantry ochre still ships.** `Features/Kitchen/PantryColour.swift:8-9` hold `0xA4601A` and `0xE3A857`. Ochre is removed: the state word becomes plain ink, and Kitchen's drawn lean goes only on the caps labels and the index line at the pass. Owner: Builder B.
7. **Lacquer groundTint percentage** (3% as a dark look) and **Plein** (2.5% as a light look) are assumed from `type-round-86.md:45`, which names Porcelain and Obsidian only. Owner: Design.
8. **Hairline** has no row and no test of contrast: decoration, by ruling.

## 5. Swift Testing names (pure logic; Core lifts them)

All are gap rows until `areaLean(area, look)` and the contrast helper exist. Tolerance 0.01 on ratios, 3 per channel on hexes.

| Id | Test name | Expected | Status | Owner |
|---|---|---|---|---|
| S01 | `areaLeanUsesTrainingHealthContextTokens` | Training = `training`, Kitchen = `health`, Review = `context`, in all five looks (T01 to T15); Training is never `liveInk` | gap (tokens traced) | Core |
| S02 | `areaLeanObsidianUsesMasterNotBoardHexes` | Obsidian pigments `#FF6B92`, `#3FD49A`, `#B7A6E0`; none of `#FF7D62`, `#52D3A3`, `#B8A3FF` in app code | gap | Core, Builder A |
| S03 | `areaLeanIsSeventyTwoPercentPigmentOverLookInk` | the 15 mixed hexes of section 1 | gap | Core |
| S04 | `areaLeanNeverReturnsTheRawPigment` | for all 15 cells the result differs from the pigment | gap | Core |
| S05 | `areaLeanTodayIsNone` | Today returns nil in all five looks; caller uses `ink` | gap | Core |
| S06 | `areaLeanTodayNeverReturnsTess` | no area equals `tess` in any look | gap | Core |
| S07 | `areaLeanLabelContrastAtLeastFourPointFiveOnGround` | all 15 cells at least 4.5 on the look's ground (C01 to C15) | gap | Core |
| S08 | `areaLeanLabelContrastAtLeastFourPointFiveOnRaised` | all 15 cells at least 4.5 on `raised` | gap | Core |
| S09 | `areaLeanContrastHoldsOnTintedGround` | all 15 cells at least 4.5 on the tinted ground (thinnest Plein Kitchen 4.71) | gap | Core |
| S10 | `areaLeanRawPigmentFailsLabelBarWhereExpected` | straight pigment is below 4.5 for Porcelain Kitchen, Plein Kitchen, Celadon Training, Celadon Kitchen; pins why the mix is required | gap | Core |
| S11 | `areaLeanMixIsDoneInSRGBBytes` | resolver does not use `Color.mix`; equals S03 | gap | Core |
| S12 | `areaLeanFollowsLookDarkness` | `Look.isDark` picks the dark tint (Obsidian, Lacquer) | gap (flag traced, `Looks.swift:24`) | Core |
| S13 | `areaLeanIsTotalOverLooksAll` | returns a value for every look in `Look.all` and every area except Today | gap | Core |
| S14 | `lookTableStillPinsLeanTokens` | `training`, `health`, `context`, `ink`, `ground`, `raised` of all five looks equal section 1 values (today only some are pinned, `LookTableDriftTests.swift:23-27`) | inferred (partly covered by `LookTableTests`) | Builder A |
| S15 | `pantryStateWordIsPlainInk` | `PantryColour` ochre gone; the state word is plain ink (not `areaLean`); `areaLean(.kitchen)` only on the Pantry caps labels and index line (index line ink until the area-colour pass, then Kitchen lean; Product 6:39 and 6:45 pm Oct 17) | gap (`PantryColour.swift:8-9`) | Builder B |

There is deliberately no hairline test.

## 6. The math (reproducible)

Formula (WCAG 2.x): linearize each sRGB channel `c/255` with `c <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4`; `L = 0.2126 R + 0.7152 G + 0.0722 B`; ratio = `(L_light + 0.05) / (L_dark + 0.05)`. Mix: `round(0.72 x pigment + 0.28 x ink)` per channel. Tinted ground: `round(t x pigment + (1 - t) x ground)` with `t` 0.025 (light) and 0.03 (dark).

Worked example, Celadon Kitchen `#1F8B6A` on ground `#E0EAE2`, ink `#0C1E19`: R round(0.72 x 31 + 0.28 x 12) = round(25.68) = 26 (`1A`), G round(0.72 x 139 + 0.28 x 30) = round(108.48) = 108 (`6C`), B round(0.72 x 106 + 0.28 x 25) = round(83.32) = 83 (`53`), so `#1A6C53`. Linear channels 0.0103, 0.1500, 0.0865; L = 0.2126 x 0.0103 + 0.7152 x 0.1500 + 0.0722 x 0.0865 = 0.0022 + 0.1073 + 0.0062 = 0.1157. The ground's linear channels are 0.7454, 0.8228, 0.7605, so L = 0.1584 + 0.5885 + 0.0549 = 0.8018. Ratio = (0.8018 + 0.05) / (0.1157 + 0.05) = 0.8518 / 0.1657 = **5.14**. The straight pigment `#1F8B6A` has L = 0.1980, ratio = 0.8518 / 0.2480 = **3.44**.

The Porcelain Kitchen and Obsidian Training examples worked in #905 section 6 still hold unchanged (`#126E52` 6.22 and, with the corrected pigment, Obsidian Training is `#FC91AB`, 9.78).

The script is the author's scratch file and is not committed, to keep this change to one document. Run on the 15 cells it reproduces all 15 sheet hexes and all 15 sheet ratios.

## 7. Open questions

1. **Plein and Lacquer ground tint (Design).** Confirm 2.5% and 3% for the two new looks (flag 7).
2. **Plein Kitchen margin (Design).** 0.32 on ground; keep, or nudge `health` or `ink` on Plein?
3. **Lacquer Training vs Review (Design).** The sheet's watch item stands; decide after a phone look.
4. **Sheet redraw (Design).** The superseded table in `gaps-92.md` section 2 still carries void Obsidian hexes and the `liveInk` Training pigment; footnote or delete it.
