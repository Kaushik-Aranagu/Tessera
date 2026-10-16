# Theme checks: proportions, contrast, Tess and UNDO, system surfaces (board item 57)

Source: `docs/design/themes.md` on `origin/claude/project-thread-b3tu3f` (incl. the addendum, 86b2d01), and `themes-token-audit.md`. Every number below comes from a Python script (WCAG 2.x relative luminance; APCA-W3 0.0.98G for Lc). Ink tiers are composited as solid colours over each surface (`ink` at 60%, 38%, 14%) before measuring. Hex values are exactly those in themes.md "The five themes" and "Addendum: Workout tokens, completed".

Pass rules used: 16pt, Label 16/700 caps and Body 21 need 4.5:1 (in WCAG terms none of them counts as large text; bold large starts near 18.7pt). Title 34-44/500, Hero 56 and Numeral 80 Light need 3:1. APCA guide (rough): Lc 90 for 16pt regular, 75 for Body 21, 60 for Label 16/700, 45 for 34pt+ (Numeral 80 Light: 45 is fine at that size).

## 1. Proportion guide (themes.md "How much of each", "The field")

| Theme | Ground | Raised | Ink, all tiers | Accent | Where accent may appear |
|---|---|---|---|---|---|
| Porcelain | 86% | 3% | 8% | 3% | One stroke under the action of the moment plus its 360x120 bloom; Tess cobalt words; class dabs. Nothing else. A screen with nothing running is white and ink only. |
| Obsidian | 88% | 2% | 8% | 2% | Same places, but pigment is light: count the halo (radius 6) as accent area. Keep the lit area small; the glow doubles its visual weight. |
| Plein | 80% | 2% | 10% | 8% | The three washes take about 5% (diffuse, low chroma); real pigment strokes stay near 3%. |
| Lacquer | 84% | 4% | 9% | 3% | As Obsidian, glow bloom at 14%. The specular band is not accent: it is ground. |
| Celadon | 82% | 6% | 9% | 3% | As Porcelain. Raised is white slip, so 6% raised reads as a second ground, not as colour. |

Ink split inside the ink share (all themes): `ink` about 5% (names, numbers, the stroke word), `inkSecondary` about 2.5%, `inkTertiary` under 0.5% (large type or marks only, see section 2), `hairline` the rest.

Accent rules that keep proportion honest:
- One leading accent per screen (the action stroke). Tess cobalt is the only other text pigment; class dabs are marks, not text.
- `now`, `health`, `training`, `neutral`, `sky` are never text on light grounds (they are 1.7 to 3.9:1 there; see table).
- Live/vermilion appears only for a running thing, UNDO and Finish. If two things run, they share it; nothing else borrows it.
- Workout (dark in every theme): `signal` and `rest` are the only big pigment areas; rest sky (`Workout.tess` 35%) may fill the top band of the Live Activity only.

## 2. Contrast checks, main surfaces (WCAG ratio / APCA Lc)

Text-capable tokens first; pigments after the bar. "S" = fine for 16-21pt, "L" = only 34pt+, "X" = fails even 34pt+.

| Token | Porcelain gnd / raised | Obsidian | Plein | Lacquer | Celadon |
|---|---|---|---|---|---|
| ink | 18.2 / 16.6 S | 18.8 / 17.2 S | 12.5 / 13.6 S | 15.4 / 13.7 S | 13.9 / 16.4 S |
| inkSecondary 60% | 4.75 / 4.59 S (Lc 73/69) | 6.68 / 6.61 S (Lc 43/46) | **3.84 / 3.96 L** | 6.08 / 5.72 S (Lc 43/44) | **4.16 / 4.40 L** |
| inkTertiary 38% | **2.42 / 2.39 X** | 3.14 / 3.31 L | **2.18 / 2.22 X** | 3.12 / 3.11 L | **2.27 / 2.34 X** |
| hairline 14% | 1.34 / 1.33 | 1.32 / 1.43 | 1.30 / 1.30 | 1.41 / 1.47 | 1.31 / 1.33 |
| context | 6.72 / 6.13 S | 9.54 / 8.74 S | 4.77 / 5.20 S | 8.82 / 7.84 S | 4.75 / 5.60 S |
| tess | 6.53 / 5.97 S | 8.43 / 7.72 S | 4.66 / 5.08 S | 8.93 / 7.93 S | 5.43 / 6.40 S |
| liveInk (light) / live (dark) | 5.35 / 4.89 S | 6.81 / 6.24 S (Lc 45) | 4.81 / 5.25 S | 6.17 / 5.48 S (Lc 44) | 4.97 / 5.86 S |
| muted | **2.04 / 1.86 X** | 3.01 / **2.75 X** | **2.30 / 2.50 X** | 3.22 / **2.86 X** | **2.06 / 2.42 X** |
| live (as text, light) | **4.14 / 3.78 L** | | **4.11 / 4.48 L** | | **3.68 / 4.35 L** |
| now | 2.08 / 1.90 | 13.0 / 11.9 | 1.67 / 1.82 | 10.0 / 8.9 | 2.07 / 2.44 |
| health | 3.88 / 3.55 | 11.1 / 10.2 | 2.64 / 2.88 | 10.1 / 8.9 | 3.80 / 4.48 |
| training | 4.69 / 4.28 | 7.77 / 7.12 | 4.11 / 4.48 | 7.40 / 6.58 | 4.06 / 4.79 |
| neutral | 2.89 / 2.64 | 6.08 / 5.57 | 2.30 / 2.50 | 6.15 / 5.47 | 2.82 / 3.33 |

Findings:
- **inkSecondary fails small text on Plein and Celadon** (3.84 to 4.40). It passes on Porcelain only just (4.59 on raised). Alpha needed for 4.5:1 on both surfaces: Porcelain 60, Plein 66, Celadon 63, Obsidian 48, Lacquer 51.
- **inkTertiary is not a text tier under 34pt anywhere**, and on the three light themes it fails even 34pt+ (2.2 to 2.4). Alpha needed for 3:1: Porcelain 47, Plein 51, Celadon 49; dark themes already pass at 38. If it must carry small captions it needs the 4.5 alpha above, i.e. it becomes inkSecondary.
- **muted fails everywhere as text.** Fine as disabled ink or a mark only; say so in the token comment.
- **APCA flags dark themes** that WCAG passes: inkSecondary (Lc 43), live (Lc 45) and neutral (Lc 40) on black or plum are weak for 16-21pt regular. Saturated red-orange on black reads dimmer than its 6.8:1 suggests. inkSecondary at 72% gives Lc 58 on Obsidian, 57 on Lacquer.
- Plein `tess` (4.66) and Celadon `context` (4.75) pass by a hair; any wash under them (Plein's washes, Celadon's 6% glaze pool at the bottom) can push them below 4.5.
- `training` on Porcelain ground is 4.69, but the spec rightly keeps it off text.
- Hairline 14% (1.3:1) is decorative only. Where a hairline is the only edge of something tappable, WCAG 1.4.11 wants 3:1; the "no button shapes" design means the word itself must carry that, which ink does.

### Workout palette (dark in every theme)

| Token on Workout ground / raised | Porcelain | Obsidian | Plein | Lacquer | Celadon |
|---|---|---|---|---|---|
| ink | 16.7 / 14.7 | 18.8 / 16.7 | 14.8 / 10.5 | 16.2 / 14.6 | 15.6 / 12.5 |
| inkSecondary 60% | 6.52 / 6.12 | 6.68 / 6.50 | 6.03 / 4.88 | 6.14 / 5.94 | 6.30 / 5.50 |
| inkTertiary 38% | 3.31 / 3.28 L | 3.14 / 3.33 L | 3.23 / **2.88 X** | 3.07 / 3.12 L | 3.31 / 3.10 L |
| signal | 6.05 / 5.32 | 6.81 / 6.03 | **4.42 / 3.15 L** | 6.49 / 5.84 | 4.82 / **3.86 L** |
| rest | 8.97 / 7.88 | 13.0 / 11.6 | 9.76 / 6.95 | 10.5 / 9.46 | 8.33 / 6.67 |
| Workout.tess | 8.73 / 7.67 | 8.43 / 7.47 | 9.11 / 6.49 | 9.39 / 8.45 | 8.96 / 7.18 |
| Workout.health | 8.53 / 7.49 | 11.1 / 9.83 | 6.93 / 4.94 | 10.6 / 9.52 | 7.76 / 6.21 |

- Plein's `Workout.raised` (#3B2D57) is light enough to sink signal (3.15) and inkTertiary (2.88).
- **Ink text on a signal fill fails in every look** (2.5 to 3.3). If Finish or UNDO ever sits on a filled signal patch, the word must be workout `ground` (4.4 to 6.8), not ink.
- Rest sky (Workout.tess 35% over ground, "Addendum: Live Activity"): ink on it 6.6 to 10.4, fine; `rest` on it 3.75 (Celadon) to 7.2, fine for the big timer only; **`signal` on it 2.0 to 3.75**: keep the UNDO/Finish keyline off the sky wash, or on the right-hand `context` side.

## 3. Tess cobalt and vermilion UNDO on pure white and pure black

| Case | Ratio | APCA Lc | Verdict |
|---|---|---|---|
| Cobalt #2450D8 on #FFFFFF | 6.53 | 82 | Good. Deep enough not to vibrate; reads as ink with a temperature. |
| Cobalt #2450D8 on raised #F5F4F8 | 5.97 | 75 | Good for Body 21; fine for 16pt. |
| UNDO in `live` #E2432A on white | **4.14** | 67 | Fails for Label 16/700. Spec already routes text to `liveInk`; enforce it for UNDO. |
| UNDO in `liveInk` #C23A22 on white / raised | 5.35 / 4.89 | 76 / 69 | Passes. Slightly brown on white; acceptable. |
| Cobalt #6FA4FF on #000000 | 8.43 | 53 | WCAG fine, APCA soft for 16pt. |
| UNDO #FF5B3A on #000000 | 6.81 | 45 | WCAG fine, APCA weak for a 16pt label. |

Halation and vibration on Obsidian:
- Pure black under saturated light text produces halation for many eyes (astigmatism): letter edges bloom, worse with the spec'd halo (`pigment.opacity(0.55)`, radius 6). On a 16pt label the halo fills the counters. **Do not halo text under 34pt**; halo strokes, dabs and the soul only, or drop text halo to 0.3 at radius 3.
- Vermilion #FF5B3A (L 0.29) and cobalt #6FA4FF (L 0.37) have nearly equal luminance and opposite hues: side by side on black they shimmer (chromostereopsis, red floats forward). Keep at least one line of ink or 24pt of ground between a Tess cobalt word and a vermilion UNDO; never stack them as adjacent strokes.
- On white the pair is safe: luminances differ and neither is light.

Suggested adjustments (hex):
- Obsidian `live` for text: **#FF7A5C** (8.19:1, Lc 52) or #FF8466 (8.74, Lc 55). Keep #FF5B3A for fills and strokes, i.e. give dark looks a real `liveInk` instead of "= live".
- Obsidian `tess` for text: **#86B4FF** (9.99:1, Lc 61). Lacquer's #8DB2FF is already there.
- Porcelain `liveInk` optional: **#BF3520** (5.61 / 5.12, Lc 77) if UNDO also appears on `raised` at 16pt; current #C23A22 passes, so this is margin, not a fix.

## 4. Live Activity and widget cases (themes.md "Live Activities and widgets", "Addendum: Live Activity")

Rendering behaviour below is from iOS 17 to 26 documentation; recheck on iOS 27 with the `widgets` skill or sosumi.

- **Lock Screen Live Activity.** Our background is honoured, so supply: `activityBackgroundTint` = Workout `ground` for the look, `activitySystemActionForegroundColor` = Workout ink (the system dismiss control), and keep text on ink and ink at 60%, not 38% (Always-On dims the whole activity; 3.1:1 tertiary will drop under 3).
- **Dynamic Island.** Always on black, whatever the look. Supply the Obsidian-like workout set: signal, rest, Workout.tess, and a `keylineTint` = `signal`. Plein's #D9563F on black is 4.4:1, so for Plein use the Obsidian signal in the Island.
- **StandBy night mode.** The system renders the activity and widgets red and monochrome; hue is gone, only luminance survives. Signal vs rest vs Tess must differ in luminance or shape (the horizon timer as a line vs a word), not hue alone. Rest #F0A500 and signal #FF5B3A differ in luminance by about 1.5x on black, which survives; Tess sky at 35% will read as near black.
- **Widgets with removable backgrounds (StandBy, iOS 26 clear/tinted Home Screen).** When `showsWidgetContainerBackground` is false, our ground is gone and content sits on black or system glass. Supply a "no ground" ink: the night look's ink and pigments, regardless of day look.
- **Lock Screen accessory widgets (vibrant).** Colour is discarded and content is drawn as luminance over the wallpaper. Supply opacity tiers only (ink, 60%, hairline); pigments must not be the sole carrier of meaning. Dabs become grey shapes, so give them a distinct form (filled vs ring).
- **Accented / tinted Home Screen mode.** Content splits into an accent group (`.widgetAccentable()`) and a default group, both recoloured by the user's tint. Mark exactly one thing accentable: the action stroke or the running dab, matching "one accent leads per screen". Images need `widgetAccentedRenderingMode` (`.desaturated` for photos, `.accented` for the soul glyph).
- **App icon: dark and tinted variants.** Supply three: light (Porcelain white field, the three soul dabs), dark (on #000, dabs at Obsidian values without halo), and tinted (a single greyscale layer; the three dabs need clearly different greys, e.g. live 30%, tess 55%, now 85% lightness, or they merge into one blob).
- **Per-look payload.** `ContentState.look` must carry the five looks' workout palette plus tess and context (the addendum's `Shared/LookTable.swift`); widgets also need `liveInk`, the class colours and the "no ground" ink above.

## 5. Proposed hex fixes for Design

1. Plein `inkSecondary`: 66% instead of 60% (passes 4.5 on ground and raised). Celadon `inkSecondary`: 63%. Or keep one rule and use 66% on every light look.
2. `inkTertiary` on light looks: 51% (3:1 floor), and document it as 34pt+ or marks only. Dark looks keep 38% under the same rule.
3. `muted`: mark as non-text (disabled, marks). If dark looks need muted text at 34pt+: Obsidian #716B7B, Lacquer #7A6E86 (3.5 to 3.75 on raised).
4. Dark `liveInk` becomes its own value: Obsidian **#FF7A5C**, Lacquer **#FF8466**. Fills stay #FF5B3A / #F06A4C.
5. Obsidian `tess` text: **#86B4FF** (or keep #6FA4FF for the soul dab and add the lighter one for words).
6. Dark looks `inkSecondary` at 72% if APCA matters to us (Lc 58 vs 43); WCAG already passes at 60%.
7. Plein Workout `signal`: **#F5826A** (4.88 on raised, 6.84 on ground), or never put signal text on Plein's raised. Celadon Workout `signal`: **#EE7056** (4.74 on raised).
8. Margin bumps: Plein `tess` #2A64A0 (5.22) and Celadon `context` #456680 (5.14), so washes and the glaze pool can't drop them under 4.5.
9. Halo: no halo on text under 34pt; cobalt and vermilion never adjacent on dark looks.
10. Ink never on a signal fill; use Workout `ground` there.

Script: `/tmp/claude-0/-home-claude/a21dc68c-0951-5bbf-9e1c-7675729e9a02/scratchpad/contrast.py` (scratch, not kept).
