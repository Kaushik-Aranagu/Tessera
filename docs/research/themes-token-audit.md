# Themes PR: token audit (checklist for Builder A)

Audited `origin/master` at **589f243** (Merge PR #182). Spec: `docs/design/themes.md` on `origin/claude/project-thread-b3tu3f` (that branch adds only `docs/design/**`: specs, mockups, studies and recordings, no Swift). Swift scanned: `App/`, `DesignSystem/`, `Features/`, `Widgets/`, `Shared/`, `TesseraCore/Sources` (TesseraCore has no colour code at all).

Each row below is a hard-coded colour or visual literal that will NOT follow a theme switch until it is moved onto a token. "Look" means the per-theme `Look` from themes.md section "For Builder A". Masks (`.black`/`.clear` stops inside `.mask { }` or `fadesAtBottom`) only shape alpha and are left out on purpose.

## Totals

| Team | Hit rows | Files with hits |
|---|---|---|
| Core (TesseraCore, Notes, Review, Groceries, Recipes, Backup) | 1 | 1 |
| Builder A (Workout, Exercise, Plans, Routine, Widgets, Live Activity) | 52 | 17 |
| Builder B (Home, Command, RootView, BottomChrome) | 17 | 5 |
| Design system itself | 24 | 5 |
| Unowned (Tess soul and motifs, Objects) | 8 | 5 |
| **Total** | **102** | **33** |

Headline: the light Home side is mostly clean already (Core is almost entirely on tokens). The workout is not: no production workout view reads `Theme.Colors.Workout`. Every workout colour comes from `WorkoutPaint` or four private `Paint` enums of Plein hex values, and the workout background is `PleinGround()` itself. `Theme.Colors.Workout.*` is used only in `#Preview` backgrounds (WeightDial:410-422, RPEStops:152, RepsDrum:142-148, PlateStack:148).

No hits for: `UIColor` outside Theme.swift, `.primary`/`.secondary` foreground styles, `.accentColor`, `symbolRenderingMode`/SF Symbol palette colours, `Color(.sRGB...)`, `Color(red:)` outside the two hex helpers. No stored `let x = Theme.Colors.*` copies were found (the static lets that will go stale are the literal palettes listed below).

## The 5 riskiest spots

1. **The workout ignores the workout tokens.** `Features/Workout/WorkoutModeView.swift:129` `.background { PleinGround() }`, `:127` `.presentationBackground(Color(hex: 0x1C1828))`, plus `WorkoutPaint.swift:6-16` and the private `Paint` enums in `Instruments/WeightDial.swift:5-11`, `RPEStops.swift:5-9`, `RepsDrum.swift:5-7`, `PlateStack.swift:6-12`. Every theme would get Plein's purple workout. Obsidian's spec'd workout ground is #000000 and Lacquer's #0C0812, so the glass in `WorkoutPaint.swift:56-57` (black outline .6, black shadow .45) also disappears on pure black: panels lose their edge.
2. **Light chamfer on Now's process seam.** `Features/Home/NowPage.swift:537` `Color.white.opacity(0.8)` draws a bright white 1px line on Obsidian/Lacquer, and nothing at all on Porcelain's #FFFFFF. Next to it, `:514` `Color(hex: 0x6E6480)` step text is about 3.7:1 on pure black (under 4.5:1) and does not follow ink.
3. **Glints vanish on pure white.** `Features/Tess/TessMotifs.swift:7/31` (`Glint`, sheen #F7E6B8, `.plusLighter`), `Features/Exercise/ExercisePaint.swift:180/187` (`GlintOnce` on the Exercise page record row, same sheen, `.plusLighter`) and `LiveSetStrokes.swift:11` (#FFE2A8 sheen). Plus-lighter over #FFFFFF adds nothing, so the PR glint is invisible on Porcelain and Celadon's white slip. Needs a sheen token with a per-mode blend.
4. **Tess's soul and the theme-switch flood are Plein-only.** `Features/Tess/TessSoul.swift:111-122` (SoulPalette light/dark hex) and `Features/Tess/PaintFlood.swift:14-17`. themes.md makes `PaintFlood` the switch animation itself and says the soul is `live`, `tess`, `now` with `soulBlend` and `halo` per look; today the soul picks its palette from `colorScheme` (so Lacquer and Obsidian get the same dab colours and no halo) and the flood always paints Plein vermilion/violet/cobalt.
5. **Live Activity is pinned to Plein.** `Widgets/RestLiveActivity.swift:10-32` (`Palette` and `RestMood` hex values, its own private `Color(hex:)` at :417). The extension cannot see Theme, so nothing changes until the look's name rides in `RestActivityAttributes.ContentState` (`Shared/RestActivityAttributes.swift:10`), as themes.md step 6 says. Also `PasteRecipe.swift:56` (`.blendMode(.multiply)` cadmium band) multiplies to nothing on Obsidian's black, so the "brush passing" reading cue disappears on dark looks.

Honourable mention: `DesignSystem/Machined.swift:185` `ProcessSeam`'s default colour is `MachinedMaterial.aluminium.liveColor` (fixed #C8452F). `BottomChrome.swift:598` `RunningSeam` uses that default, so the running-workout seam on every page ignores `live`.

## themes.md token gaps

These literals have no home in the spec's token table:

- **`progress`** (Theme.swift:29, used as a text tint at `Features/Objects/ObjectPage.swift:169`). Not in themes.md. Suggest folding into `now` (cadmium already means "a possible PR"), but `now` is never text on light grounds, so the Stat value needs `ink` with a `now` dab, or keep `progress` as a new text-safe token.
- **`sheen`** (glint highlight, #F7E6B8 and #FFE2A8 in five places) plus a blend per mode. NEW TOKEN needed: `sheen` and `sheenBlend` (`.plusLighter` dark, `.multiply` or skip on light).
- **Workout pigments beyond five.** The workout palette in themes.md has ground, raised, ink, signal, rest. The live workout also paints with tess (#9DBFE6), cobalt (#3F7FC0), tess bar (#C9D9EE), health (#7FB07A) and a secondary text colour (#A79FB5), and cycles four pigments for logged-set strokes (`WorkoutPaint.set`). NEW TOKENS needed: `Workout.tess`, `Workout.health`, and a `Workout.setCycle` (or say "use the night look's `tess`/`health`").
- **`Workout.glass`** (#1C1828 at .82 over a material). Could be derived as `Workout.ground.opacity(0.82)`; name it so Obsidian can choose its own edge.
- **Day spectrum.** Home's day stroke is a five-stop gradient (`HomePaint.dayGradient`: sky #9EC3D6, sage, violet, amber, vermilion). No sky-blue exists in the spec. NEW TOKEN needed: `daySpectrum`, or rule that it is `[tess, health, context, now, live]`.
- **Routine colours.** `RoutinePaint` (PlansView.swift:100-106) needs four distinct pigments; it uses `tess` for Pull, which breaks the "tess is Tess only" rule. The remaining spec pigments are `live`, `now`, `health`, `training`, but in Plein `training` equals `live` (#C8452F) and in Porcelain they are both reds. NEW TOKEN or spec decision needed: a fourth routine pigment.
- **Text on a strong pigment.** `MonthPage.swift:144` #FFF8EE numerals on heavy dabs. Map to `paper` (white on Porcelain, black on Obsidian's brighter dabs); no new token needed, but the spec should say so.
- **Lift/shadow.** `HomeQueue.swift:230` lifts a held row with an ink-coloured shadow, which turns into a pale glow on dark looks. themes.md says held rows are `raised`; use that, and note it in the spec.
- **Chamfer light** (NowPage:537). Spec has no "lit edge" token. Either drop it on dark looks or NEW TOKEN `edgeLight` (light looks only).
- **Plein's dark washes in the workout.** `Paint.swift:53-65` and the drift at :112 only make sense as Plein's workout field. themes.md says nothing about a workout field. Decide: flat `Workout.ground` for the other four looks, or a NEW `Workout.field`.
- **Plate colours** (`Theme.Colors.plate`, Theme.swift:351-359; PlateStack change plates #55534F, #A8A49C) are meaningful and stay fixed in every theme. Spec should say so; move the two change-plate hexes into `plate(_:)`.
- **Hairline in the workout** is 12% (Theme.swift:337-339) while themes.md says all tiers are 14%. Pick one.
- New tokens the spec already names but master lacks: `raised`, `liveInk`, `neutral`, `classColor(_:)`, `soulBlend`, `halo`, plus `field` replacing `BackgroundStyle`.

## Full tables

### Core (1)

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Recipes/PasteRecipe.swift:51-57 | `Theme.Colors.now` band with `.blendMode(.multiply)`, opacity .25 | the brush passing over pasted text | `now`, but blend must follow `soulBlend`-style mode (multiply on light, screen on dark) |

Not hits: GroceriesView:184 passes `Theme.Colors.live` to ProcessSeam (correct); GroceriesView:158 and PortionDrum:79-81 are masks.

### Builder A (52)

**Workout palette definitions (move into the Look's workout palette)**

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Workout/WorkoutPaint.swift:6 | `live` #D9563F | vermilion strokes, Finish, sweep | `Workout.signal` |
| WorkoutPaint.swift:7 | `tess` #9DBFE6 | Tess's words in the workout | NEW TOKEN needed: `Workout.tess` |
| WorkoutPaint.swift:8 | `tessBar` #C9D9EE | Tess bar text | NEW TOKEN needed: `Workout.tess` (lighter tier) |
| WorkoutPaint.swift:9 | `now` #E8BD4C | rest, "now", cadmium dabs | `Workout.rest` |
| WorkoutPaint.swift:10 | `health` #7FB07A | sage set stroke | NEW TOKEN needed: `Workout.health` |
| WorkoutPaint.swift:11 | `cobalt` #3F7FC0 | picked swap wash, set stroke, finish | NEW TOKEN needed: `Workout.tess` (merge with :7) |
| WorkoutPaint.swift:12 | `secondary` #A79FB5 | secondary words, label buttons | `Workout.inkSecondary` |
| WorkoutPaint.swift:13 | `cream` #F3ECE0 | workout ink | `Workout.ink` |
| WorkoutPaint.swift:14 | `sheen` #FFE2A8 | glint on the current exercise | NEW TOKEN needed: `sheen` |
| WorkoutPaint.swift:16 | `glass` #1C1828 at .82 | sheet and panel glass | NEW TOKEN needed: `Workout.glass` (or `Workout.ground` .82) |
| WorkoutPaint.swift:19-21 | `set()` cycles live, cobalt, now, health | logged-set stroke colours | NEW TOKEN needed: `Workout.setCycle` |
| WorkoutPaint.swift:48-57 | `.ultraThinMaterial`, `.white` .14 top edge, `.black` .6 outline, `.black` .45 shadow | workout glass edges | `Workout.raised` edge; black outline/shadow invisible on Obsidian #000 |
| Features/Workout/Instruments/WeightDial.swift:5-11 | private Paint: cream #F3ECE0, vermilion #D9563F, cadmium #E8BD4C, ticks/label/washTip as opacities | dial ticks, needle, rest wash | `Workout.ink` (+ tiers), `Workout.signal`, `Workout.rest` |
| Instruments/RPEStops.swift:5-9 | cream #F3ECE0, cadmium #E8BD4C, rail/dab/whole opacities | RPE rail and chosen stop | `Workout.ink` tiers, `Workout.rest` |
| Instruments/RepsDrum.swift:5-7 | cream #F3ECE0, neighbour .35, ghost .55 | reps drum numerals | `Workout.ink` tiers |
| Instruments/PlateStack.swift:6-10 | cream, label #A79FB5, sleeve/plateLight opacities, plateShade #1C1828 .45 | sleeve, plate light and shade, labels | `Workout.ink` tiers, `Workout.inkSecondary`, `Workout.ground` .45 |
| Instruments/PlateStack.swift:11-12 | changeLarge #55534F, changeSmall #A8A49C | change plates | keep fixed; move into `Theme.Colors.plate(_:)` |

**Workout call sites (switch from `Paint.*` once the palette above is tokens; listed so nothing is missed)**

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Workout/WorkoutModeView.swift:127 | `Color(hex: 0x1C1828)` | ask-field sheet background | `Workout.ground` |
| WorkoutModeView.swift:129 | `PleinGround()` | the whole workout background | `Workout.ground` (+ workout field decision, see gaps) |
| WorkoutModeView.swift:282 | `Color.black.opacity(0.35)` | running-order scrim | keep, or `Workout.ground` .35 |
| WorkoutModeView.swift:326,341,411,445 / 347,439,589 / 407,432,576 / 421,477 / 563,601 / 592 / 619 | Paint.secondary / cream / now / tess / live / cobalt / set | labels, numbers, rest, Tess, Finish, set strokes | per the palette rows above |
| WorkoutModeView.swift:443 | `GlintIf` (sheen #FFE2A8) | possible-PR glint | `sheen` |
| Features/Workout/WorkoutParts.swift:37,208,259,323 / 106-135,211,303,330 / 116-129,211 / 108,132,334 / 283 / 298 | Paint.cream / secondary / now / tess / set / live | set rows, hints, ask line, writing line | per palette rows |
| Features/Workout/WorkoutFinishView.swift:37,72 / 40,69 / 78 / 185 | Paint.secondary / cream / cobalt / live | finish words and mark | per palette rows |
| WorkoutFinishView.swift:136-138 | `.white.opacity(0.22)`, `.blendMode(.screen)` | wet edge on the painted mark | `Workout.ink` .22 |
| Features/Workout/ExerciseStrip.swift:36,38,155,171 | Paint.cream (.82, .2, .5, .1) | strip words, lifted fill | `Workout.ink` tiers |
| ExerciseStrip.swift:47-48 | live + `Paint.sheen` gradient | sweep on current exercise | `Workout.signal`, `sheen` |
| ExerciseStrip.swift:57,149 | `.shadow(Paint.live .8, r5)` | current-exercise glow | `halo` (Workout.signal) |
| ExerciseStrip.swift:91,105,164 / 110,147 / 160 | Paint.secondary / live / now | labels, marker, rest dab | per palette rows |
| ExerciseStrip.swift:172 | `.shadow(.black .4, r14)` | lifted-row drop | `Workout.raised`; black shadow invisible on Obsidian |
| Features/Workout/SwapPanel.swift:23,32,43 / 80,84 / 90,143 / 136 | Paint.secondary / cream / cobalt / tess | swap list, picked wash | per palette rows |
| Features/Workout/LiveSetStrokes.swift:11 | `Color(hex: 0xFFE2A8)` | PR glint sheen | `sheen` |
| LiveSetStrokes.swift:79 / 105 | Paint.tess .55, Paint.set / Paint.cream | ghost and logged strokes, breath | `Workout.tess`, `Workout.setCycle`, `Workout.ink` |
| Features/Workout/LiveTessCorner.swift:30 / 41 | Paint.tess / Paint.live | Tess corner | `Workout.tess`, `Workout.signal` |
| Instruments/WeightDial.swift:197,212-221,234-236,298-299 | Paint.label, cadmium/washTip, vermilion + `.shadow` .7 | dial labels, rest wash, needle glow | `Workout.inkSecondary`, `Workout.rest`, `Workout.signal` + `halo` |
| Instruments/RPEStops.swift:36,91,93,103 | rail, dab, cadmium + `.shadow` .6 r8 | RPE rail and chosen glow | `Workout.ink` tiers, `Workout.rest` + `halo` |
| Instruments/RepsDrum.swift:40,102 | ghost, cream, neighbour | drum numerals | `Workout.ink` tiers |
| Instruments/PlateStack.swift:53,65,87-88,95-96 | label, sleeve, plateLight/Shade, change plates | bar diagram | as palette rows |

**Exercise, Plans**

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Exercise/ExercisePaint.swift:180,187 | `Color(hex: 0xF7E6B8)` .95 with `.plusLighter` | record-row glint on the Exercise page (light ground) | `sheen` + `sheenBlend`; invisible on Porcelain today |
| Features/Plans/PlansView.swift:100-106 | `RoutinePaint.cobalt` → `Theme.Colors.tess` | Pull routine dab | NEW TOKEN or spec decision: fourth routine pigment (tess is Tess only) |
| Features/Plans/MonthPage.swift:144 | `Color(hex: 0xFFF8EE)` | numerals on heavy month dabs | `paper` |

**Widgets and Live Activity**

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Widgets/RestLiveActivity.swift:10 | `cream` #F6EFE4 | all Lock Screen and island text, lines | `Workout.ink` |
| RestLiveActivity.swift:11 | `vermilion` #E2603F | tick, Go glow, keyline | `Workout.signal` |
| RestLiveActivity.swift:13 + :77 | `materialTint` #120E1A .46 → `activityBackgroundTint` | activity background | `Workout.ground` |
| RestLiveActivity.swift:15-16 | goWash1 #E8BD4C .75, goWash2 #E2603F .6 | Go sky washes | `Workout.rest`, `Workout.signal` |
| RestLiveActivity.swift:27 | `Color(hex: 0x3F7FC0)` .75 | rest sky, top-left wash | `tess` at 35% (spec) |
| RestLiveActivity.swift:32 | `Color(hex: 0x7A5CA0)` .45 | rest sky, top-right wash | not in spec (spec has one tess sky): drop, or `context` |
| RestLiveActivity.swift:78,111 + 138,158,226,239,258,263,304,316,349,351 | `Palette.cream` and opacities .14-.62 | action colour, timer, labels, guides | `Workout.ink` tiers; the timer (111, 239) → `Workout.rest` per spec |
| RestLiveActivity.swift:117 | `.keylineTint(vermilion / mood.wash1)` | Dynamic Island keyline | `Workout.signal` / `tess` |
| RestLiveActivity.swift:183,189,273 | RadialGradients of the washes above | rest and Go sky | as :15-32 |
| RestLiveActivity.swift:417-421 | private `Color(hex:)` | duplicate helper | share Theme's look table into the extension (add `Shared/` file) |
| Shared/RestActivityAttributes.swift:10 | ContentState has no look | which palette to draw | add `look` name (themes.md step 6) |

No Home Screen widgets exist yet (`TesseraWidgetsBundle` holds only `RestLiveActivity`).

Token use (count only, correct): RoutineEditor 17, WeekPage 11, ExerciseViews 11, ExercisePage 11, MonthPage 7, PlansView 6, ExercisePaint 5, WeightDial 3, PlateStack 3, RepsDrum 2, CarriageRail 2, RPEStops 1, WorkoutPaint 1.

### Builder B (17)

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Home/HomeSpatialView.swift:7 | `daySky` #9EC3D6 | morning end of the day stroke | NEW TOKEN needed: `daySpectrum` (or `tess`) |
| HomeSpatialView.swift:8 | `daySage` #8FB58A | day stroke, Groceries dab | `health` |
| HomeSpatialView.swift:9 | `dayViolet` #7A5C8E | day stroke | `context` |
| HomeSpatialView.swift:10 | `dayAmber` #E0A35C | day stroke, Recipes dab, Now timer | `now` |
| HomeSpatialView.swift:11 | `dayVermilion` #C8452F | evening end of the day stroke | `live` |
| HomeSpatialView.swift:13 | `wetTip` #E0A35C | wet tip at now | `now` |
| HomeSpatialView.swift:15-16 | `dayGradient` of the five above | the day stroke | NEW TOKEN needed: `daySpectrum` |
| HomeSpatialView.swift:221 | `HomePaint.daySage / dayAmber` | Groceries and Recipes dabs | `classColor(.kitchen)` = `health` |
| Features/Home/NowPage.swift:218 | `HomePaint.dayAmber` .85 | block timer stroke | `now` |
| NowPage.swift:514 | `Color(hex: 0x6E6480)` | suspended process step text | `inkSecondary` |
| NowPage.swift:537 | `Color.white.opacity(0.8)` | lit chamfer under the seam | NEW TOKEN `edgeLight` (light looks) or drop on dark |
| Features/Home/DayStrip.swift:185 | `HomePaint.dayGradient` | day stroke | `daySpectrum` |
| DayStrip.swift:220 | `HomePaint.wetTip` | wet tip | `now` |
| Features/Home/HomeQueue.swift:230 | `.shadow(Theme.Colors.ink .18, r6, y3)` | held-row lift | `raised` fill (shadow turns into a glow on dark) |
| Features/Command/BottomChrome.swift:42-43, 534-538 | `.ultraThinMaterial` + `paper` .7; CaptureWash `paper` .95, tess .12 bloom only `if !dark` | Tess veil and Write wash | `raised`; bloom via `field` (`pigmentBloom` / `emissive`) |
| BottomChrome.swift:598 | `ProcessSeam()` default colour (fixed #C8452F) | running-workout seam on every page | pass `live` |

Token glows to route through `halo` once it exists (not counted): NowPage:533, DayStrip:165 (`live` .45 shadows), BottomChrome:139 (`paper` .9 legibility shadow, fine as is).

Token use (count only): NowPage 29, BottomChrome 22, TrainingPage 18, HomeQueue 10, HomeSpatialView 6, ReviewPage 5, DayStrip 4, RootView 1. HomeQueue:138-139 is a mask.

### Design system (24)

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| DesignSystem/Theme.swift:20-41 | `Palette` as (light, dark) pairs; defaults for tess, context, now, health, muted | every token | per-look single values; compose pairs from day and night looks; drop defaults |
| Theme.swift:29, 125, 179, 210 | `progress` pairs | PR tint | not in spec (gap) |
| Theme.swift:31, 126-131, 180, 211, 305-313 | `sky` tints, `skyTints(hour:)` | Workshop's time-of-day mesh | retire with workshop |
| Theme.swift:118-168 | `workshop` concept literals | retired look | keep for `-theme`, drop from `all` |
| Theme.swift:172-199 | `machined` concept literals | retired look | keep for `-theme`, drop from `all` |
| Theme.swift:203-231 | `plein` concept literals | Plein | becomes the `plein` Look (values match themes.md) |
| Theme.swift:233 | `all = [.plein, .workshop, .machined]` | theme list | the five looks |
| Theme.swift:240 | `nonisolated(unsafe) static var concept` | active theme | computed read of `@Observable ThemeStore` |
| Theme.swift:316-347 | `Workout` reads `Color(hex:)` single values | workout tokens | per look; add tess/health/setCycle/glass (gaps) |
| Theme.swift:337-339 | Workout hairline .12 | workout rules | 14% per spec, or keep and note |
| Theme.swift:351-359 | plate hexes | plate colours | keep fixed (meaningful) |
| DesignSystem/ThemeLayers.swift:6-10 | switch on `BackgroundStyle` | page background | switch on `field` |
| ThemeLayers.swift:15-52 | `GroundWithSky` mesh, opacity by `colorScheme` | Workshop sky | retire |
| DesignSystem/Paint.swift:29 | `Color(hex: dark ? 0x1C1828 : 0xF2ECE3)` | Plein ground (and the workout's ground) | Plein `ground` / `Workout.ground` |
| Paint.swift:53-65 | dark washes #3B2D57, #1E3D4A, #45302A | Plein workout washes | Plein field only; NEW `Workout.field` decision |
| Paint.swift:73-91 | light washes #F7E6B8, #D8CBE6, #BFD8E2, #C9DDB8 | Plein Home washes | private to the `plein` field (fine) |
| Paint.swift:112 | drift #7A5C8E .35 / #E9B7A8 .5 | drifting wash | private to the `plein` field |
| Paint.swift:40-41 | grain blend softLight/multiply by `colorScheme` | paper grain | `plein` field only |
| Paint.swift:257 | `dark ? Color(hex: 0xF3ECE0) : Theme.Colors.ink` | stroke-word text | `ink` (night look resolves it) or `Workout.ink` |
| DesignSystem/Machined.swift:50-91 | aluminium and graphite material hexes | Machined surfaces (otherwise unused) | retire with machined |
| Machined.swift:185 | `ProcessSeam.color` default `aluminium.liveColor` | running seam | default to `Theme.Colors.live` |
| Machined.swift:198 | `Color(hex: 0xFFE2A8)` | seam glint | `sheen` |
| Machined.swift:208 | `.shadow(color .6, r7)` | seam glow | `halo` |
| DesignSystem/InkActions.swift:127, 141 | Veil `.ultraThinMaterial`; `colorScheme == .dark ? Color.white .12 : ink .14` | veils and their seam | `raised`; `hairline` (drop the branch) |

Token use (count only): ThemeLayers 8, Paint 4, Editorial 4, ThinkingIndicator 3, TextEffects 3, InkActions 3, Controls 2. FontRegistry, MotionPolicy: none needed.

### Unowned (8): Tess soul and motifs, Objects

Suggest Builder A takes these with DesignSystem, since the soul and flood are part of the switch.

| File:line | Literal | Paints | Maps to |
|---|---|---|---|
| Features/Tess/TessSoul.swift:111-116 | light SoulPalette: washes #C8452F, #2E6DA4, #E0B341; halo #D66046/#7A5C8E; ring #7A4A3A; `.multiply` | soul on light grounds | `live`, `tess`, `now`; `soulBlend` |
| TessSoul.swift:117-122 | dark SoulPalette: #D9563F, #3F7FC0, #E8BD4C; `.screen` | soul on dark grounds | same tokens + `halo` |
| TessSoul.swift:43, 124-126 | palette chosen by `colorScheme` | which soul | by Look (`soulBlend`, `halo`) |
| Features/Tess/PaintFlood.swift:14-17 | #C8452F, #7A5C8E, #2E6DA4, #E0B341 | Tess flood (the theme-switch animation) | `live`, `context`, `tess`, `now` (of the incoming look) |
| Features/Tess/TessMotifs.swift:7, 24, 31 | sheen #F7E6B8 .9 with `.plusLighter` | Glint motif | `sheen` + `sheenBlend` |
| TessMotifs.swift:48 | `RoundRobin.tint` #C8452F | background-work bar | `live` |
| Features/Tess/SoulGallery.swift:18-19 | `Color(hex: 0x1C1826)` + forced dark | DEBUG gallery dark panel | `Workout.ground` (low priority) |
| App/RootView.swift:41 | mounts `PaintFlood` | (see PaintFlood) | not counted, same fix |
| Features/Objects/ObjectPage.swift:169 | `Theme.Colors.progress` as text tint | Best e1RM value | gap: `progress` |

Token use (count only): ObjectPage 19, SoulGallery 10, ObjectHandle 6, TessMotifs 1. Core files, for reference: GroceriesView 25, PasteRecipe 22, RecipePage 18, NotesView 14, BackupView 12, ReviewView 10, NoteEditor 9, PortionDrum 3.

## Suggested order for the PR

1. DesignSystem: Look table, ThemeStore, `field`, new tokens (`raised`, `liveInk`, `neutral`, `classColor`, `soulBlend`, `halo`, `sheen`, the workout additions).
2. Workout: replace `WorkoutPaint` and the four private `Paint` enums with `Theme.Colors.Workout.*`, and swap `PleinGround()` out of WorkoutModeView:129. Biggest single change, all in Builder A's folders.
3. Soul, flood, glints (risk 3 and 4).
4. Home `HomePaint` and the NowPage chamfer (needs a Builder B review).
5. Live Activity: add `look` to ContentState and a shared look table for the extension.
