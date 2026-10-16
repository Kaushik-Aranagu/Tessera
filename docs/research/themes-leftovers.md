# Themes: token leftovers on master (board item 76)

Rerun of `themes-token-audit.md` (102 hits at 589f243) against `origin/master` at **dc0968f** (after #212). Same scope (`App/`, `DesignSystem/`, `Features/`, `Widgets/`, `Shared/`, `TesseraCore/Sources`) and the same searches: `Color(hex:)` and raw hex, `.white`/`.black`, system colours, opacity on fixed colours, hard-coded materials, `UIColor`, blend modes, shadows, and colour picked by `colorScheme` instead of the look. Masks (`.black`/`.clear` inside `.mask`, `DryBreakUp`) are left out, as before. Contrast numbers come from `theme-checks.md` or the same WCAG formula.

Note on #195: on master, #195 is "ios/start-guard" (empty routines, rest set id, look sentence on Review), not the Themes PR. It touched one theme file: `Looks.swift` now makes **Porcelain by day, Obsidian by night the default for everyone** (Plein is no longer kept for old users), and `ReviewView` shows the `LookSentence`. The theme work itself landed in #193, #199, #203 and #207. Because of #195, every leftover below now shows on Porcelain or Obsidian by default.

## Totals

| | Count |
|---|---|
| Original hits | 102 |
| Fixed | 54 |
| Still there | 48 |
| New since the audit | 4 |
| Leftovers to fix now | 52 |

| Owner | Leftovers (still + new) |
|---|---|
| Builder A (Themes, set logger, workout, Live Activity, widgets) | 35 (31 + 4 new) |
| Builder B (Review, Home queue, capture, Day log, Lists) | 17 |
| Core (engine, no UI) | 0 |

What got fixed: the whole workout palette (`WorkoutPaint`, the four private `Paint` enums, `WorkoutField`, sheet background, set cycle, glass, change plates, hairline 14%), the Look table and `ThemeStore`, `ProcessSeam` default and glint, the Exercise glint, the month numerals, the veil hairline branch, Plein's field washes kept private to Plein. TesseraCore still has no colour code, so Core owns nothing. Owners were moved to the new split: Tess, Objects and the design system go to Builder A (Themes); Home, Command and Recipes paste go to Builder B (Home queue, Day log, capture). Tess and Objects have no named owner, so that part is inferred.

Tokens that exist but nobody calls yet: `daySpectrum`, `sky`, `routines`, `classColor`, `soulBlend`, `halo`. Most of Builder B's rows are one-line swaps onto these.

## Leftovers: Builder A (35)

| # | File:line | Snippet | Should use | Porcelain (white) | Obsidian (black) |
|---|---|---|---|---|---|
| A1 | Features/Workout/WorkoutPaint.swift:40 | `static let sheen = Color(hex: 0xFFE2A8)` | `Theme.Colors.sheen` read with the workout look (or new `Workout.sheen`) | fine (workout is dark) | fine |
| A2 | WorkoutPaint.swift:83, 87 | `.ultraThinMaterial`; `.white.opacity(0.14)` top edge | `Workout.raised` / `Workout.hairline` | fine | fine, edge a bit bright |
| A3 | Features/Workout/WorkoutModeView.swift:286 | `Color.black.opacity(0.35)` running-order scrim | `Workout.ground.opacity(0.35)` or ink-darken | slight dim, fine | **no effect**: black on #000 |
| A4 | WorkoutModeView.swift:447 | `GlintIf` (PR glint, hex sheen) | sheen token | fine | fine |
| A5 | Features/Workout/LiveSetStrokes.swift:11 | `Glint(period: 3, sheen: Color(hex: 0xFFE2A8))` | sheen token | fine | fine |
| A6 | Features/Workout/WorkoutFinishView.swift:136-138 | `.white.opacity(0.22)` + `.blendMode(.screen)` | `Workout.ink.opacity(0.22)` | fine | fine |
| A7 | Features/Workout/ExerciseStrip.swift:48 | `Paint.sheen` in the sweep | sheen token | fine | fine |
| A8 | Features/Plans/PlansView.swift:103 | `case .cobalt: Theme.Colors.tess` | `Theme.Colors.routines[3]` (context) | Pull reads as Tess's blue | same |
| A9 | Widgets/RestLiveActivity.swift:10 | `cream = Color(hex: 0xF6EFE4)` | look `Workout.ink` | Plein cream, not Porcelain ink | same |
| A10 | RestLiveActivity.swift:11 | `vermilion = Color(hex: 0xE2603F)` | look `Workout.signal` | not the look's signal | dimmer than #FF5B3A |
| A11 | RestLiveActivity.swift:13, 83 | `materialTint` #120E1A .46 into `activityBackgroundTint` | look `Workout.ground` | plum, not #14111A | **plum, not black** |
| A12 | RestLiveActivity.swift:15-16 | go washes #E8BD4C .75, #E2603F .6 | `Workout.rest`, `Workout.signal` | Plein colours | Plein colours |
| A13 | RestLiveActivity.swift:27 | `Color(hex: 0x3F7FC0).opacity(0.75)` | `Workout.tess` at 35% | Plein cobalt | Plein cobalt |
| A14 | RestLiveActivity.swift:32 | `Color(hex: 0x7A5CA0).opacity(0.45)` | drop, or `context` | off-spec | off-spec |
| A15 | RestLiveActivity.swift:36, 84, 119, 146, 166, 231, 234, 258, 271, 290, 295, 336, 348, 381, 383 | `Palette.cream` and .14-.62 tiers | `Workout.ink` tiers; timer `Workout.rest` | as A9 | as A9 |
| A16 | RestLiveActivity.swift:125 | `.keylineTint(isGo ? Palette.vermilion : mood.wash1)` | `Workout.signal` / `Workout.tess` | Island is black anyway | fine |
| A17 | RestLiveActivity.swift:191, 197, 305 | RadialGradients of the washes | as A12-A14 | as above | as above |
| A18 | RestLiveActivity.swift:449 | private `Color(hex:)` | shared look table in `Shared/` | n/a | n/a |
| A19 | Shared/RestActivityAttributes.swift:10 | `ContentState` has no look | add `look` name | always Plein | always Plein |
| A20 | DesignSystem/Theme.swift:256, 404 | `progress` token (= `now`) | remove; use `ink` with a `now` dab | see A31 | see A31 |
| A21 | DesignSystem/Paint.swift:29 | `Color(hex: dark ? 0x1C1828 : 0xF2ECE3)` | `Look.plein.ground` / workout ground | not shown | not shown |
| A22 | DesignSystem/Machined.swift:208 | `.shadow(color: color.opacity(0.6), radius: 7)` | gate on `Theme.Colors.halo` | **red glow on white** (halo is dark-only) | fine |
| A23 | DesignSystem/InkActions.swift:127 | Veil `.fill(.ultraThinMaterial)` | `raised` | grey blur, close to raised | grey haze, lighter than #0F0E12 |
| A24 | Features/Tess/TessSoul.swift:111-116 | light SoulPalette hex (#C8452F, #2E6DA4, #E0B341, halo, ring) | `live`, `tess`, `now`, `soulBlend` | Plein dabs, not Porcelain | n/a |
| A25 | TessSoul.swift:117-122 | dark SoulPalette hex (#D9563F, #3F7FC0, #E8BD4C) | same tokens + `halo` | n/a | Plein dabs, dimmer than #FF5B3A / #86B4FF |
| A26 | TessSoul.swift:43, 124-126 | `SoulPalette.forScheme(colorScheme)` | read the look | works (pin sets scheme) | works |
| A27 | Features/Tess/PaintFlood.swift:14-17 | #C8452F, #7A5C8E, #2E6DA4, #E0B341 | incoming look's `live`, `context`, `tess`, `now` | Plein flood | **muddy, dark flood on black** |
| A28 | Features/Tess/TessMotifs.swift:7, 31 | `sheen = 0xF7E6B8`, `.blendMode(.plusLighter)` | `sheen`, `sheenBlend` | **invisible** (plus-lighter on white) | fine |
| A29 | TessMotifs.swift:48 | `RoundRobin.tint = 0xC8452F` | `live` | Plein red | dim red |
| A30 | Features/Tess/SoulGallery.swift:18 | `Color(hex: 0x1C1826)` | `Workout.ground` (DEBUG only) | n/a | n/a |
| A31 | Features/Objects/ObjectPage.swift:169 | `Stat(..., tint: Theme.Colors.progress)` | `ink` | **#F0A500 text, 2.1:1, fails** | 13:1, fine |
| A32 | DesignSystem/ThemeLayers.swift:54 (new) | `Color(hex: 0x06030A).opacity(0.75)` | Lacquer field value in `Look` | n/a | n/a |
| A33 | ThemeLayers.swift:59 (new) | `Color(hex: 0xFFF4E6).opacity(0.05)` | Lacquer field value in `Look` | n/a | n/a |
| A34 | ThemeLayers.swift:83 (new) | `Color(hex: 0xFFF4E6).opacity(0.03)` | same, workout band | n/a | n/a |
| A35 | DesignSystem/Theme.swift:375-376 (new) | `sheen` returns `Color(hex: 0xF7E6B8)` / `0xFFE2A8` | a `sheen` field on `Look` | n/a (Porcelain uses `now`) | fine |

A9-A19 are the Live Activity: nothing there changed since the audit. The Dynamic Island is always black, so only the Lock Screen face is off.

## Leftovers: Builder B (17)

| # | File:line | Snippet | Should use | Porcelain (white) | Obsidian (black) |
|---|---|---|---|---|---|
| B1 | Features/Home/HomeSpatialView.swift:7 | `daySky = Color(hex: 0x9EC3D6)` | `Theme.Colors.sky` | faint, about 1.8:1 on white | fine |
| B2 | HomeSpatialView.swift:8 | `daySage = 0x8FB58A` | `health` | Plein sage | dull |
| B3 | HomeSpatialView.swift:9 | `dayViolet = 0x7A5C8E` | `context` | fine | **3.75:1, sinks into black** |
| B4 | HomeSpatialView.swift:10 | `dayAmber = 0xE0A35C` | `now` | Plein amber | dull |
| B5 | HomeSpatialView.swift:11 | `dayVermilion = 0xC8452F` | `live` | Plein red | dim next to #FF5B3A |
| B6 | HomeSpatialView.swift:13 | `wetTip = 0xE0A35C` | `now` | as B4 | as B4 |
| B7 | HomeSpatialView.swift:15-16 | `dayGradient` of B1-B5 | `Theme.Colors.daySpectrum` | as above | as above |
| B8 | HomeSpatialView.swift:236 | `HomePaint.daySage / dayAmber` dabs | `classColor(.kitchen)` | Plein colours | Plein colours |
| B9 | Features/Home/NowPage.swift:218 | `HomePaint.dayAmber.opacity(0.85)` timer | `now` | Plein amber | dull |
| B10 | NowPage.swift:519 | `.foregroundStyle(Color(hex: 0x6E6480))` step text | `inkSecondary` | 5.5:1, fine | **3.8:1, fails 4.5** |
| B11 | NowPage.swift:542 | `Color.white.opacity(0.8)` chamfer | drop on dark, or new `edgeLight` | invisible on white | **bright white 1px line** |
| B12 | Features/Home/DayStrip.swift:185 | `HomePaint.dayGradient` | `daySpectrum` | as B7 | as B7 |
| B13 | DayStrip.swift:220 | `HomePaint.wetTip` | `now` | as B4 | as B4 |
| B14 | Features/Home/HomeQueue.swift:232 | `.shadow(color: Theme.Colors.ink.opacity(0.18), ...)` | `raised` fill | soft shadow, fine | **pale glow round held text** |
| B15 | Features/Command/BottomChrome.swift:42-43 | `.ultraThinMaterial` + `paper.opacity(0.7)` | `raised` | fine | fine |
| B16 | BottomChrome.swift:53, 535 | `CaptureWash(dark: colorScheme == .dark)`, bloom only if light | `!Theme.Colors.halo` or the look | fine | fine (pin sets scheme) |
| B17 | Features/Recipes/PasteRecipe.swift:56 | `.blendMode(.multiply)` on the `now` band | `Theme.Colors.soulBlend` | fine | **band invisible** (multiply on black) |

## Core (0)

TesseraCore has no colour code. The old Core row (PasteRecipe) is a capture screen, so it is B17 now.

## Looks wrong on Obsidian (black)

1. **B11 NowPage:542** white 80% chamfer: a bright white hairline under the process seam on pure black.
2. **B10 NowPage:519** #6E6480 step text: 3.8:1 on black, under 4.5 for 18 pt text, and it ignores ink.
3. **B14 HomeQueue:232** ink shadow: ink is near white on Obsidian, so a held row gets a pale glow, not a lift.
4. **B17 PasteRecipe:56** multiply band: multiply on black gives black, so the "brush passing" cue is gone.
5. **A3 WorkoutModeView:286** black scrim: Obsidian's workout ground is #000, so the running order gets no dimmed backdrop.
6. **A11 RestLiveActivity:13/83** (with A9-A19): the Lock Screen activity stays Plein plum #120E1A with Plein cream and vermilion, next to an all-black app.
7. **A27 PaintFlood:14-17**: Plein's dark red, violet and cobalt, blurred over black, read as a muddy dark smear when Tess floods to Home.
8. **B3 / B7 day stroke**: violet #7A5C8E is 3.75:1 on black and the stroke never uses Obsidian's brighter spectrum.

Porcelain-only problems worth the same attention: **A31** Best e1RM in #F0A500 text (2.1:1, fails), **A22** red seam glow on white, **A28** Glint invisible on white (only in the DEBUG gallery today).

## Fix order

1. B10, B11, B14, B17 (Builder B, four one-line fixes that look broken on the new default night look).
2. A31 and A20 (Builder A): Best e1RM to `ink`, then remove `progress`.
3. B1-B9, B12-B13 (Builder B): delete `HomePaint`, use `daySpectrum`, `now`, `classColor`.
4. A3, A22, A27, A28 (Builder A): scrim, gated seam glow, flood from the incoming look, Glint on `sheen`/`sheenBlend`.
5. A9-A19 (Builder A): `look` in `ContentState` and a shared look table for the Live Activity.
6. A1-A2, A4-A8, A23-A26, A29-A30, B15-B16 (both): token swaps with no visible bug today.
7. A32-A35 and A21 (Builder A): move field and sheen hex into the `Look` table so all colour lives in one place.
