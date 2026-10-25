# Item 116: the softer type pair (Figtree words, Outfit numbers)

Replaces the pair in item 115 (Cormorant Garamond and Urbanist). Kaushik picked number 2 of the softer boards on Oct 21
("a little too sharp ... more eased out and cooler, casual"). Board: mockups/fonts-softer-116.png. Everything in item 115
that is not about the faces stays: the unit wheel, the data and control planes, owners, the kicker row's content, the
Review switch.

## 1. Files and licence
- fonts/Figtree.ttf (variable, weight 300 to 900) and fonts/Outfit.ttf (variable, weight 100 to 900), both SIL OFL 1.1,
  both with the `frac` and `tnum` features. Bundle both in the app and the widget targets. Do not subset away `frac`.
- Credit on About, one line: "Figtree and Outfit, SIL Open Font License 1.1." (names and licence text go in the About
  licences list with the other credits).
- Review switch "Font" keeps its key. On = this pair. "As before" = the face the app drew before the font PR (Inter
  Tight look). Default On. Nothing else is stored.

## 2. Roles
| Role | Face and weight | Size | Notes |
|---|---|---|---|
| Page title | Figtree 500 | 72 if the name fits on one line in the gutter width, else 48 | tracking -0.03 em, stage colour, wraps to two lines, never "..." (measure with ViewThatFits, no 62 or other in-between size). Live set title 56 to use 48 |
| Body, row names, works line | Figtree 500 | 21 | works line in ink 60% |
| Key word (START, LOG, RESUME) | Figtree 600 | 32 | sentence case as today's label style draws it; the app's label style may keep capitals for keys |
| Kicker row | Figtree 500 | 14 | sentence case, tracking +0.02 em, ink 50% (no uppercase, no wide tracking) |
| Detail under a row (4 x 5-8) | Figtree 500 | 12 | sentence case, tracking +0.02 em, ink 50% |
| Numbers (rows, live) | Outfit 200 (ExtraLight) | 48 in rows, 108 live reps, 162 live weight | tracking -0.02 em, tabular (`tnum` on) |
| Unit beside a number | Figtree 600 | 11 | lowercase, tracking +0.04 em, ink 50%, 4 pt after the number, on its baseline |
| Small numbers inside words (Set 1, 82.5 kg x 8) | Outfit 300 | the size of the words around them | |

The 1.5x scale holds for the sizes above (14, 21, 32, 48, 72, 108, 162). The only new rule: the title picks 72 or 48,
never a size between.

## 3. Fractions (cook-style amounts)
Neither face has the characters for 1/3 and 2/3, and Outfit also lacks 1/8, 3/8, 5/8, 7/8. Both have the `frac`
feature, so draw EVERY fraction the same way, as digits with `frac` on, in the number face:
- Core's string (for example "1 1/2 cups", "1/3 cup", written in vulgar-fraction characters) is for VoiceOver and for text that never meets the font. The view
  draws the whole part, a thin space (U+2009), then the numerator, a slash and the denominator as digits, with the
  `frac` feature on (CoreText: kFractionsType with kDiagonalFractionsSelector, or UIFontDescriptor feature
  settings) in Outfit 200.
- Display only: nothing stored changes.

## 4. Where it applies
Every `Theme.Typography` role goes through one token, so the font PR swaps the token and nothing else. Today's lowercase
"kg" on the live set and the uppercase unit on Training rows both become the unit role above.

## Weight floor (Design, Oct 22, PR #1200)
Outfit numbers: 300 below 28 pt, 200 (ExtraLight) from 28 pt up. 200 under 28 pt is too
hairline to read. The 108 pt live-set numeral takes the whole row; "x 7" drops to its own
line under it (sheet to follow).
