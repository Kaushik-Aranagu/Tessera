# Themes: token leftovers on master (board item 76)

Rerun of `themes-token-audit.md` (102 hits at 589f243). First pass: `origin/master` at **dc0968f**. Second pass (this version): checked #215 "Themes 2b" at its head `ios/themes-soul` **838fee2** while it was still open; it then merged as **862ed68**, and `origin/master` at **1c6193a** (#217) has the same theme files as 838fee2 (only Backup differs, no colour), so everything below holds on master. That branch changes only theme files (Machined, ThemeLayers, PaintFlood, TessMotifs, TessSoul, WorkoutModeView, RestActivityController, RestActivityAttributes, RestLiveActivity, new `Shared/LookTable.swift`); nothing else in scope changed on master since dc0968f (Backup files only, no colour). Line numbers below are as on 838fee2.

Scope as before (`App/`, `DesignSystem/`, `Features/`, `Widgets/`, `Shared/`, `TesseraCore/Sources`), same searches: `Color(hex:)` and raw hex, `.white`/`.black`, system colours, opacity on fixed colours, hard-coded materials, `UIColor`, blend modes, shadows, colour picked by `colorScheme` instead of the look. Masks are left out. Contrast numbers come from `theme-checks.md` or the same WCAG formula.

Note on #195: on master, #195 is "ios/start-guard", not the Themes PR. It made **Porcelain by day, Obsidian by night the default for everyone**, so every leftover below shows on those two looks by default.

## Totals

| | First pass (dc0968f) | With #215 (838fee2) |
|---|---|---|
| Original hits | 102 | 102 |
| Fixed | 54 | 71 (17 more by #215) |
| Still there | 48 | 31 |
| New since the audit | 4 | 4 |
| Leftovers to fix now | 52 | 35 |

| Owner | First pass | With #215 |
|---|---|---|
| Builder A (Themes, set logger, workout, Live Activity, widgets) | 35 | 18 (14 + 4 new) |
| Builder B (Review, Home queue, capture, Day log, Lists) | 17 | 17 |
| Core (engine, no UI) | 0 | 0 |

Fixed by #215: the whole Live Activity (A9-A19: `RestPalette` per look from `lookDay`/`lookNight` in `ContentState`, Island on the Obsidian set), the soul palette by look (A24-A26), the flood from the incoming look (A27), the Glint default on `sheen`/`sheenBlend` (A28), and the seam glow through the new `pigmentGlow` (A22). #215 also stops pushed workout pages from flipping the app to night (`tracksAppearance`); that was not a token row. I could not match "W6/W7" to any row here.

Dead code #215 left behind (paints nothing, delete when touching the file): `TessSoul.swift:116-131` (old `light`/`dark` palettes and `forScheme`), `RestLiveActivity.swift:437` (old `Color(hex:)`). `Shared/LookTable.swift:14-23` copies the workout hex from `Looks.swift` for the extension; fine, but the two must change together.

Tokens nobody calls yet: `daySpectrum`, `sky`, `routines`, `classColor`, `soulBlend`. Most of Builder B's rows are one-line swaps onto these.

## Leftovers: Builder A (18 open, 17 fixed by #215)

| # | File:line | Snippet | Should use | Porcelain (white) | Obsidian (black) |
|---|---|---|---|---|---|
| A1 | Features/Workout/WorkoutPaint.swift:40 | `static let sheen = Color(hex: 0xFFE2A8)` | `Theme.Colors.sheen` read with the workout look (or new `Workout.sheen`) | fine (workout is dark) | fine |
| A2 | WorkoutPaint.swift:83, 87 | `.ultraThinMaterial`; `.white.opacity(0.14)` top edge | `Workout.raised` / `Workout.hairline` | fine | fine, edge a bit bright |
| A3 | Features/Workout/WorkoutModeView.swift:288 | `Color.black.opacity(0.35)` running-order scrim | `Workout.ground.opacity(0.6)` (see `theme-contrast-fixes.md`) | slight dim, fine | dims content behind only to 7.8:1, so it still competes with the panel; it can't darken the #000 ground |
| A4 | WorkoutModeView.swift:449 | `GlintIf` (PR glint, hex sheen) | sheen token | fine | fine |
| A5 | Features/Workout/LiveSetStrokes.swift:11 | `Glint(period: 3, sheen: Color(hex: 0xFFE2A8))` | drop the argument; Glint now reads the look | fine | fine |
| A6 | Features/Workout/WorkoutFinishView.swift:136-138 | `.white.opacity(0.22)` + `.blendMode(.screen)` | `Workout.ink.opacity(0.22)` | fine | fine |
| A7 | Features/Workout/ExerciseStrip.swift:48 | `Paint.sheen` in the sweep | sheen token (via A1) | fine | fine |
| A8 | Features/Plans/PlansView.swift:103 | `case .cobalt: Theme.Colors.tess` | `Theme.Colors.routines[3]` (context) | Pull reads as Tess's blue | same |
| A9-A19 | Widgets/RestLiveActivity.swift, Shared/RestActivityAttributes.swift | Plein palette, no look in state | **fixed by #215** | | |
| A20 | DesignSystem/Theme.swift:256, 404 | `progress` token (= `now`) | remove; use `ink` with a `now` dab | see A31 | see A31 |
| A21 | DesignSystem/Paint.swift:29 | `Color(hex: dark ? 0x1C1828 : 0xF2ECE3)` | `Look.plein.ground` / workout ground | not shown | not shown |
| A22 | DesignSystem/Machined.swift:208 | seam shadow | **fixed by #215** (`pigmentGlow`) | | |
| A23 | DesignSystem/InkActions.swift:127 | Veil `.fill(.ultraThinMaterial)` | `raised` | grey blur, close to raised | grey haze, lighter than #0F0E12 |
| A24-A26 | Features/Tess/TessSoul.swift | soul palette by `colorScheme`, Plein hex | **fixed by #215** (`SoulPalette.look`, `.workout`) | | |
| A27 | Features/Tess/PaintFlood.swift:15-18 | Plein flood hex | **fixed by #215** | | |
| A28 | Features/Tess/TessMotifs.swift:7, 32 | Glint default sheen, plus-lighter | **fixed by #215** | | |
| A29 | TessMotifs.swift:49 | `RoundRobin.tint = .init(hex: 0xC8452F)` | `Theme.Colors.live` | Plein red | dim red |
| A30 | Features/Tess/SoulGallery.swift:18 | `Color(hex: 0x1C1826)` | `Workout.ground` (DEBUG only) | n/a | n/a |
| A31 | Features/Objects/ObjectPage.swift:169 | `Stat(..., tint: Theme.Colors.progress)` | `Theme.Colors.ink` | **#F0A500 text, 2.1:1, fails** | 13:1, fine |
| A32 | DesignSystem/ThemeLayers.swift:56 (new) | `Color(hex: 0x06030A).opacity(0.75)` | Lacquer field value in `Look` | n/a | n/a |
| A33 | ThemeLayers.swift:61 (new) | `Color(hex: 0xFFF4E6).opacity(0.05)` | Lacquer field value in `Look` | n/a | n/a |
| A34 | ThemeLayers.swift:85 (new) | `Color(hex: 0xFFF4E6).opacity(0.03)` | same, workout band | n/a | n/a |
| A35 | DesignSystem/Theme.swift:375-376 (new) | `sheen` returns `Color(hex: 0xF7E6B8)` / `0xFFE2A8` | a `sheen` field on `Look` | n/a (Porcelain uses `now`) | fine |

## Leftovers: Builder B (17, none touched by #215)

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
| B16 | BottomChrome.swift:53, 535 | `CaptureWash(dark: colorScheme == .dark)` | `Theme.Colors.halo` or the look | fine | fine (pin sets scheme) |
| B17 | Features/Recipes/PasteRecipe.swift:56 | `.blendMode(.multiply)` on the `now` band | `Theme.Colors.soulBlend` | fine | **band invisible** (multiply on black) |

`NowPage.swift:538` and `DayStrip.swift:165` still use a raw `live` shadow; not counted (token colour), but `pigmentGlow` from #215 is now the one-line fix.

## Core (0)

TesseraCore has no colour code. The old Core row (PasteRecipe) is a capture screen, so it is B17.

## Looks wrong on Obsidian (black)

1. **B11 NowPage:542** white 80% chamfer: a bright white hairline under the process seam.
2. **B10 NowPage:519** #6E6480 step text: 3.8:1 on black, under 4.5 for 18 pt text.
3. **B14 HomeQueue:232** ink shadow: ink is near white, so a held row glows instead of lifting.
4. **B17 PasteRecipe:56** multiply band: multiply on black gives black, so the reading cue is gone.
5. **A3 WorkoutModeView:288** black scrim: Obsidian's workout ground is #000, so the running order gets no dimmed backdrop.
6. **B3 / B7 day stroke**: violet #7A5C8E is 3.75:1 on black, and the stroke never uses Obsidian's brighter spectrum.

Off the list since the first pass, fixed by #215: the Lock Screen Live Activity (now black with Obsidian ink and signal) and the Tess flood (now Obsidian's own pigments).

Porcelain-only: **A31** Best e1RM in #F0A500 text (2.1:1, fails). The seam glow (A22) and the Glint (A28) are fixed by #215.

## Fix order

1. B10, B11, B14, B17 (Builder B): four one-line fixes that look broken on the default night look.
2. A31 then A20 (Builder A): Best e1RM to `ink`, then remove `progress`.
3. A3 (Builder A): workout scrim that does nothing on Obsidian.
4. B1-B9, B12-B13 (Builder B): delete `HomePaint`, use `daySpectrum`, `now`, `classColor`.
5. A1, A4, A5, A7 (Builder A): one workout sheen token, drop the hex argument to `Glint`.
6. A2, A6, A8, A23, A29, A30, B15, B16 (both): token swaps with no visible bug today.
7. A21, A32-A35 (Builder A): move field and sheen hex into the `Look` table; delete the #215 dead code.
