# Reading layouts inventory (for Design's reading-layouts sheet)

Static read of master f5fd3a86, no app run. Rule being checked (Kaushik, project chat, Oct 18): reading layouts differ per content kind (notes, lists, paragraphs, exercise details, recipe steps, receipts), no new fonts, at most about 3 type sizes per screen. Facts only; proposals are limited to the last section.

Method notes. Every `file:line` was taken from a numbered read of that line on master. Sizes are the Plein concept's (the active look; `ThemeConcept.all = [.plein, .workshop, .machined]`, Theme.swift:244; the other two were not read for sizes). "Sizes" counts distinct point sizes among the text on the screen in its main state (empty and error states noted). Characters per line are estimates (Inter Tight averages roughly 0.48 em per character), not measurements: 56 pt about 13, 44 pt about 16, 21 pt about 34, 18 pt about 39, 16 pt about 44 characters in the 358 pt column (402 pt iPhone 17 screen minus two 22 pt gutters). Row text is the visible text only; fixed-width or `lineLimit(1)` rows are noted.

## 1. Type tokens (all of them)

| Token | Definition | Size / weight / line height | Dyn Type | File:line |
|---|---|---|---|---|
| `scale.hero` (`.textRole(.hero)`) | display family, Inter Tight in Plein | 56 / medium / 1.0, tracking -4% | scales from `.largeTitle`; capped at xxxLarge | Theme.swift:226, Editorial.swift:40 |
| `scale.title` (`.title`, `.titleNumber` mono) | display | 44 / medium / 1.05 | from `.title`; to accessibility5 | Theme.swift:228, Editorial.swift:24-40 |
| `scale.body` (`.body`, `.bodyStrong` = medium) | ui | 21 / medium (Plein) / 1.3 | from `.body`; to accessibility5 | Theme.swift:230, Editorial.swift:29 |
| `scale.label` (`.label`, `.labelStrong` = bold, `.data` = case kept) | ui | 16 / bold / 1.25, UPPERCASE, +8% | from `.callout`; to accessibility5 | Theme.swift:231, Editorial.swift:30 |
| `scale.field` (`.textRole(.field)`) | ui | 18 / regular / 1.33 | from `.callout`; to accessibility5 | Theme.swift:75 |
| `Theme.voice` / `Theme.voice(size:)` | `concept.fonts.voice`, Inter Tight | 21 regular default; any size passed | scales from `.body`; no cap | Machined.swift:225-231 |
| `Theme.numeral(_:weight:)` | display face, monospacedDigit | any size, default light | from `.largeTitle` if over 40 else `.title`; no cap | Machined.swift:218-222 |
| `PageType.small` | ui | 18 / medium | from `.subheadline` | ExercisePaint.swift:10-13 |
| `PageType.caption` | ui | 16 / medium, case kept | from `.callout` | ExercisePaint.swift:16-19 |
| `PageType.voice` | = `Theme.voice(size: 21)` | 21 / regular | as voice | ExercisePaint.swift:22-24 |
| `InkWordType.font` | display | 34 / medium (literal 34) | from `.title` | Paint.swift:479-483 |
| `WorkoutParts.title34` | title spec with size set to 34 | 34 / medium (literal) | from `.title` | WorkoutParts.swift:99-102 |
| `Theme.Typography.font(spec, weight:)` | used directly with `scale.body` / `scale.label` | 21 / 16 | from the spec's style | Theme.swift:513-522 |
| Color tokens read | `Theme.Colors.ink`, `.inkSecondary`, `.inkTertiary`, `.context` (context lines), `.tess` (Tess voice), `.muted`, `.live`, `.health`, `.now`; workout ground uses `Paint.cream`, `.secondary`, `.tess` | | | Theme.swift:299-424 |

Two things the table hides. (1) The scale is described as four sizes (hero 56, title 44, body 21, label 16) but the app also reads from 18 (field, `PageType.small`, `voice(size: 18)`), 34 (`voice(size: 34)`, `InkWordType`, `title34`) and a spread of literal numeral sizes (21, 24, 26, 28, 34, 44, 56, 72, 80). (2) `voice` and `numeral` have no Dynamic Type cap and `voice(size:)` takes any number, so the token does not guard the size. Line height is only applied by `textRole` (Editorial.swift:38); `Theme.voice`, `numeral`, `PageType` and `InkWordType` get the system default. `lineSpacing` appears once in Features (SwapPanel.swift:141, value 4).

Layout facts that apply to every row unless a row says otherwise: horizontal inset is `Theme.Spacing.gutter` = 22 (Theme.swift:553); no `readableContentGuide`, no reading max-width modifier exists in Features (a grep for readable/readingWidth finds only `readableContentTypes`, BackupView.swift:354). Text fills the full gutter-to-gutter column. Fixed max widths in use: 270 (Tess lines), 220 (hold keys), 250 (SwapPanel check).

## 2. Surface rows

Columns: Kind. Fonts (token names). Wt / lines. Measure. Dyn Type. Sizes (distinct on the screen). Colour. Cite. Status.
Status key: OK = within the 3-size cap; OVER = over the cap; LIT = literal font/size found; UNK = unknown.

### Notes

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL01 | Notes list, title | page title | `.hero` | medium, 1.0 | gutter 22 (NotesView:108), full width | hero capped xxxLarge | 4 on screen: 56, 21, 18, 16 (+44 empty) | `ink` | NotesView.swift:72 | OVER |
| RL02 | Notes list, context line | Tess/context line | `Theme.voice` | regular, default | full column, no limit | uncapped | (screen) | `context`, `tess` when key refused | NotesView.swift:67 | OVER (screen) |
| RL03 | Notes list, capture field | note input | `.field` | regular, 1...4 lines | full column | to AX5 | (screen) | `ink`, prompt `inkSecondary` | NotesView.swift:145, :157 | OVER (screen) |
| RL04 | Notes list row, title | note title | `.bodyStrong` | medium, `lineLimit(1)` | full column, one line | to AX5 | (screen) | `ink` | NotesView.swift:191, :193 | OVER (screen) |
| RL05 | Notes list row, remainder | note excerpt | `Theme.voice(size: 18)` literal | regular, `lineLimit(1)` | one line, about 39 chars | uncapped | (screen) | `inkSecondary` | NotesView.swift:197, :199 | LIT |
| RL06 | Notes list row, time | metadata | `.data` | bold 16, case kept | right of row | to AX5 | (screen) | `tess` if new else `inkSecondary` | NotesView.swift:205 | OVER (screen) |
| RL07 | Notes list, empty | empty state | `.title`, `Theme.voice` | medium 44 + regular 21 | full column | mixed | adds 44 | `ink`, `inkSecondary` | NotesView.swift:237, :240 | OVER |
| RL08 | Note editor, first line | paragraph heading (typed) | `.field` | regular, vertical axis, unbounded | gutter 22 (NoteEditor:110), about 39 chars | to AX5 | 3: 21, 18, 16 | `ink` | NoteEditor.swift:48 | OK |
| RL09 | Note editor, body | paragraphs (typed) | `.field` in `TextEditor`, minHeight 180 | regular 18, 1.33 | same column, -5 inset to align (NoteEditor:71) | to AX5 | (same) | `ink` | NoteEditor.swift:63 | OK |
| RL10 | Note editor, context line | context | `Theme.voice` | regular 21 | full column | uncapped | (same) | `context`, `tess` | NoteEditor.swift:42 | OK |
| RL11 | Note editor, linked-object line | link row | `.bodyStrong` | medium 21 | full column | to AX5 | (same) | `ink` | NoteEditor.swift:83 | OK |
| RL12 | Note editor, delete / gone | action, error | `.label`; `Theme.voice` | 16; 21 | full column | | (same) | `inkSecondary` | NoteEditor.swift:97, :106 | OK |

### Lists and Groceries

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL13 | Lists shelf, header | page title | `.title` | medium 44 | gutter 22 (ListsView:73) | to AX5 | 4: 56, 44, 21, 16 | `ink` | ListsView.swift:36 | OVER |
| RL14 | Lists shelf, context | context | `Theme.voice(size: 21)` | regular | full column | uncapped | | `context` | ListsView.swift:41 | LIT (21 hard-coded) |
| RL15 | Lists shelf, list names | list items by tier | `.hero` / `.title` / `.body` chosen per row tier | 56 / 44 / 21 on one screen | full width, `maxWidth: .infinity` (ListsView:108) | hero capped, others AX5 | 3 tiers in one list | `ink` at 1 / 1 / 0.75 opacity | ListsView.swift:99 | OVER (three sizes as a ranking in one column) |
| RL16 | Lists shelf, row state | metadata | `.label` | bold 16 | beside name | AX5 | | `live` / `inkSecondary` | ListsView.swift:104 | OK |
| RL17 | Lists shelf, "Put away" | section head | `Theme.voice(size: 21)` | regular, `ink` at 0.45 | | uncapped | | `ink.opacity(0.45)` literal opacity | ListsView.swift:63 | LIT |
| RL18 | Lists page, name | page title | `.hero` | 56 | single line not enforced | hero capped | 4: 56, 44, 21, 16 | `ink` | ListsView.swift:197 | OVER |
| RL19 | Lists page, section heading | section label | `.title` | 44, `ink` at 0.85 | | AX5 | | `ink.opacity(0.85)` | ListsView.swift:247 | OVER |
| RL20 | Lists page, item | list item | `.body` | 21, `lineLimit(2)`, min row 48 or 64 | about 34 chars, two lines then truncates | AX5 | | `ink` | ListsView.swift:349, :351, :353 | OK (row) |
| RL21 | Lists page, add field | typed item | `.body` TextField | 21 | full column | AX5 | | `ink` | ListsView.swift:401 | OK |
| RL22 | Lists page, key words (Run it, Put away, reusable, pick one) | action labels | `.labelStrong` | bold 16 | | AX5 | | `ink`/`live`/`inkSecondary` | ListsView.swift:463, :474, :487, :501 | OK |
| RL23 | Lists page, done summary | line | `.body` | 21 | | AX5 | | `ink`, `inkSecondary` | ListsView.swift:711, :723 | OK |
| RL24 | Lists put-away page | archive list | `.title` head; `.body` rows | 44 / 21 | gutter (ListsView:804) | AX5 | 2 | `ink`, `ink.opacity(0.75)` | ListsView.swift:787, :794 | OK |
| RL25 | Lists, reset ask | Tess line | `Theme.voice` | 21, key `maxWidth: 220` | 220 key | uncapped | | `tess` | ListsView.swift:619, :628 | OK |
| RL26 | Pick-one list | single big word | `.hero`, centred | 56 | gutter (ListsPick:100) | hero capped | 2 | `ink` | ListsPick.swift:76, :78 | OK |
| RL27 | Pick-one list, result line | Tess line | `Theme.voice` | 21 | | uncapped | | `tess` | ListsPick.swift:95 | OK |
| RL28 | Groceries, page header | page title | `.hero`, two copies (ink, live) | 56 | gutter (GroceriesView:110) | hero capped | 5: 56, 44, 21, 18, 16 | `ink`, `live` | GroceriesView.swift:350, :354 | OVER |
| RL29 | Groceries, context | context | `Theme.voice` | 21 | | uncapped | | `context` | GroceriesView.swift:66 | OVER (screen) |
| RL30 | Groceries, aisle name | section head | `.title`; `.hero` for the shop-mode current aisle | 44; 56 | | AX5; capped | | `ink.opacity(0.85)`; `ink` | GroceriesView.swift:435, :528 | OVER |
| RL31 | Groceries, item | list item | `.body` with semibold quantity | 21 | `maxWidth: .infinity` min 44 (:633) | AX5 | | `ink`, in-basket `inkSecondary` | GroceriesView.swift:471, :629, :645 | OK |
| RL32 | Groceries, "for tacos" provenance | annotation | `Theme.voice(size: 18)` | regular 18 | | uncapped | adds 18 | `health` | GroceriesView.swift:484 | LIT |
| RL33 | Groceries, shop-mode "then <aisle>" | preview | `.body` | 21 at 0.35 ink | | AX5 | | `ink.opacity(0.35)` | GroceriesView.swift:547 | OK |
| RL34 | Groceries, Tess note | Tess line | `.body`, `maxWidth: 270`, trailing, `lineLimit(2)` | 21 | 270 pt, about 26 chars per line, two lines | AX5 | | `tess` | GroceriesView.swift:685-689 | OK |
| RL35 | Groceries, empty | empty state | `.title`, `Theme.voice` | 44 + 21 | | | | `ink`, `tess` | GroceriesView.swift:715, :718 | OVER |

### Pantry and Kitchen

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL36 | Pantry, title | page title | `.title` | 44 | gutter (PantryView:79) | AX5 | 4: 56, 44, 21, 16 | `ink` | PantryView.swift:37 | OVER |
| RL37 | Pantry, hero front | front line | `.hero` | 56 | | capped | | `ink` | PantryView.swift:49 | OVER |
| RL38 | Pantry, context and empty body | context | `Theme.voice(size: 21)`, `Theme.voice` | 21 | | uncapped | | `context`, `inkSecondary` | PantryView.swift:43, :56 | LIT (21 hard-coded) |
| RL39 | Pantry, ledger row | list item + state word | `.body` name; `.body` state word with fontWeight semibold/bold | 21; name `fixedSize` vertical | HStack at normal, VStack at AX (PantryView:182) | explicit AX layout switch | | `ink` (state differs by weight only) | PantryView.swift:187, :194 | OK |
| RL40 | Pantry, section state head | label | `.labelStrong` | 16 | | AX5 | | `inkSecondary` | PantryView.swift:66 | OK |
| RL41 | Cook mode (steps) | recipe steps | no view on master: `RecipePage.cookModeReady = false` (RecipePage.swift:13); words only in `CookModeCopy` | | | | | | CookModeCopy.swift:1-20 | UNK |

### Recipes

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL42 | Recipe page, name | page title | `.hero`; `lineLimit(nil)` at AX else 3, `minimumScaleFactor` 0.6 normal / 1 at AX | 56 | gutter (RecipePage:187) | hero capped; explicit AX branch | 4: 56, 44, 21, 16 | `ink` | RecipePage.swift:228, :232, :233 | OVER |
| RL43 | Recipe page, second title | title | `.title` (private-masked title) | 44 | | AX5 | adds 44 | `ink` | RecipePage.swift:495 | OVER |
| RL44 | Recipe page, context | context | `Theme.voice` | 21 | | uncapped | | `context` | RecipePage.swift:88 | OK (21 shared) |
| RL45 | Recipe page, ingredients | ingredient list: amount column + name | `.body` both, amount in 600, names 400, staples dimmer | 21; amount column fixed width unless AX | `IngredientColumnLayout.stacks(typeSize)` (RecipePage:366, :393, :405) | explicit AX branch | | `ink` | RecipePage.swift:352, :398, :418 | OK |
| RL46 | Recipe page, step count | metadata | `.label` (steps present) else `.body` | 16 / 21 | | AX5 | | `inkSecondary` | RecipePage.swift:161 | OK |
| RL47 | Recipe page, cook line, source, "Not yet" | provenance | `.body`, `Theme.voice` | 21 | | | | `ink`, `inkSecondary` | RecipePage.swift:507, :501, :520 | OK |
| RL48 | Recipe page, "Tacos, 7 added." | receipt line | `.body` + Undo | 21 | HStack with Spacer | AX branch (RecipePage:104) | | `ink` | RecipePage.swift:352 (SentLine struct, :344-355) | OK |
| RL49 | Recipes shelf | shelf list | `.title` head, `.body` rows, `.label` section, voice 21 | 44 / 21 / 16 | gutter (RecipesShelfView:115) | AX5 | 3: 44, 21, 16 | `ink`, `inkSecondary` | RecipesShelfView.swift:60, :65, :86, :94, :134, :141 | OK |
| RL50 | Paste recipe, input | paragraphs (typed) | `.field` in `TextEditor`; placeholder `.body` | 18 / 21 | gutter (PasteRecipe:121) | AX5 | 5 on the sheet: 44, 21, 18, 16 | `ink` | PasteRecipe.swift:99, :111 | OVER |
| RL51 | Paste recipe, painted read-back lines | recipe steps and ingredients | title `.title` (455), heading `.label` (460), meta `Theme.voice` (464), step `.body` (470), ignored `.body` (475), ingredient `.body` (494, 510) | 44 / 16 / 21 / 21 | `maxWidth: .infinity` after a 22 pt margin column (PasteRecipe:426) | AX5 | | `ink`, `context`, `inkTertiary` | PasteRecipe.swift:455-510 | OVER (4 sizes incl. 18) |
| RL52 | Paste recipe, step numerals | step margin number | `Theme.voice(size: 18)` | 18, in a 22 pt column | 22 | uncapped | | `inkSecondary` | PasteRecipe.swift:421, :426 | LIT |
| RL53 | Paste recipe, saved and Tess lines | Tess lines | `Theme.voice` | 21 | | uncapped | | `tess` | PasteRecipe.swift:50, :376 | OK |
| RL54 | Paste recipe, durations in step text | inline emphasis | `Theme.Typography.font(scale.body, weight: .semibold)` on an AttributedString range | 21 semibold | | from `.body` | | `now` | PasteRecipe.swift:727 | OK (no new size) |
| RL55 | Portion drum | numbers | `.titleNumber` current, `.body` others; "serves" `Theme.voice(size: 18)` | 44 / 21 / 18 | | AX5 / uncapped | 3 | `ink`, `inkTertiary` | PortionDrum.swift:36, :41, :76 | LIT (18 hard-coded) |

### Exercise details and Objects

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL56 | Exercise page, Tess line | Tess line | `PageType.voice` | 21 | gutter (ExercisePage:63) | uncapped | 5 on the page: 44, 24, 21, 18, 16 | `tess` | ExercisePage.swift:54 | OVER |
| RL57 | Exercise page, breadcrumb | path | `.label`, `lineLimit(1)` | 16 | one line | AX5 | | `inkSecondary`, `muted` | ExercisePage.swift:83, :88, :90 | OK |
| RL58 | Exercise page, context | context | `PageType.voice` | 21 | | uncapped | | `context` | ExercisePage.swift:110 | OK |
| RL59 | Exercise page, best-lift numbers | exercise stat | `Theme.numeral(44)` literal, `lineLimit(1)`, `minimumScaleFactor(0.7)` (:158); label `.label` | light 44 + 16 | grid; two columns at AX (ExercisePage:140) | numeral uncapped | | `ink`, `inkSecondary` | ExercisePage.swift:154, :156, :158 | LIT |
| RL60 | Exercise page, no-best line | empty | `Theme.voice(size: 21)` | 21 | | | | `inkSecondary` | ExercisePage.swift:130 | LIT |
| RL61 | Exercise page, trend caption | metadata | `.label` | 16 | | AX5 | | `tess` if rise else `inkSecondary` | ExercisePage.swift:177, :180 | OK |
| RL62 | Exercise page, "Add to routine" | action | `.bodyStrong` | 21 | | AX5 | | `ink` | ExercisePage.swift:231 | OK |
| RL63 | Exercise history list | history rows | date `PageType.small` in a fixed 92 pt column (:134); top set `Theme.numeral(21, weight: .regular)` | 18 + 21 | 92 pt date column then top set | explicit AX5 grid switch (ExerciseViews:182) | adds 18, 21 | `inkSecondary`, `ink` | ExerciseViews.swift:132, :134, :138 | LIT |
| RL64 | Exercise page, rep-max grid | stat grid | `.label` "5RM" + `Theme.numeral(24, weight: .regular)`, `lineLimit(1)` | 16 + 24 | 5 columns, 2 at AX (ExerciseViews:182) | numeral uncapped | | `ink` / `inkTertiary` | ExerciseViews.swift:187, :189, :191 | LIT |
| RL65 | Exercise page, notes/help lines | explanatory text | `PageType.small` | medium 18 | full column | from `.subheadline` | | `inkSecondary` | ExerciseViews.swift:107, :203, :221 | OK (18 is off the four-size scale) |
| RL66 | Exercise page, muscles | list | name `.bodyStrong`; role `PageType.small` | 21 / 18 | | AX5 / subheadline | | `ink`, `inkSecondary` | ExerciseViews.swift:251, :255 | OK |
| RL67 | Object page, notes | paragraph | `.body` | 21 | gutter 22 leading -6 (ObjectPage:78-79) | AX5 | 4: 44, 21, 17, 16 | `inkSecondary` | ObjectPage.swift:114, :280 | OVER |
| RL68 | Object page, field rows | key/value | name `.body`; value `.data`/`.titleNumber`; inherited arrow `.label` | 21 / 16 / 44 | HStack, baseline aligned | AX5 | | `inkSecondary`, `ink`, `inkTertiary` | ObjectPage.swift:223, :225, :416, :452, :455 | OVER |
| RL69 | Object page, session lines | history | date `.labelStrong`; sets `.data` | 16 | | AX5 | | `ink`/`inkSecondary` | ObjectPage.swift:237, :240 | OK |
| RL70 | Object page, class line | path | `.data` | 16 | | AX5 | | `inkSecondary` | ObjectPage.swift:383 | OK |
| RL71 | Object page, arrow glyph | icon in text | `.font(.system(size: 17, weight: .semibold))` | 17 semibold, SF | | fixed | adds 17 | `ink` | ObjectPage.swift:488 | LIT (system font, size 17) |
| RL72 | Object handle | linked-object word | `.textRole(role)` passed in | role dependent | inline | AX5 | | passed `color` | ObjectHandle.swift:25, :59 | UNK (role set by caller) |

### Training, Plans and Workout

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL73 | Training page, Tess lines | Tess line | `Theme.voice(size: 21)` | 21 | | uncapped | 3: 44, 21, 16 (+ 16 system) | `context`, `tess` | TrainingPage.swift:89, :136 | LIT |
| RL74 | Training page, lane rows | training log rows | name `Theme.voice(size: 21).weight(.medium)`, `lineLimit(1)`; target `.system(size: 16, weight: .semibold)` | 21 medium; 16 semibold SF | one line | name uncapped; system font fixed relative | | `ink`, `inkSecondary` | TrainingPage.swift:601, :603, :606 | LIT (system font) |
| RL75 | Training page, plan line | metadata | `.label`, `lineLimit(1)` | 16 | one line | AX5 | | `inkSecondary` | TrainingPage.swift:213, :216 | OK |
| RL76 | Training page, rest day | empty | `.title`, `.bodyStrong` | 44 / 21 | | | | `ink` | TrainingPage.swift:690, :699 | OK |
| RL77 | Plans page, headline | headline | `.hero`, `lineLimit(2)`; context `PageType.voice` | 56 / 21 | gutter (PlansView:40) | hero capped; explicit AX branch (PlansView:85) | 2 | `ink`, `context` | PlansView.swift:120, :124, :126 | OK |
| RL78 | Week page | sets per muscle | title `.title` `lineLimit(1)`; names `.bodyStrong` `lineLimit(AX ? 2 : 1)`, name column 112 / 150 pt (WeekPage:199); counts `Theme.numeral(21, weight: .regular)`; captions `PageType.caption` | 44 / 21 / 16 | fixed 112 pt name column | explicit AX line limit | 3 | `ink`, `muted` | WeekPage.swift:24, :195, :197, :220, :99 | LIT (numeral 21) |
| RL79 | Month page | calendar numerals + notes | `PageType.voice`, `PageType.caption`, `PageType.small`, `.label` | 21 / 16 / 18 / 16 | 7-column grid | from callout/subheadline | 3: 21, 18, 16 | `tess`, `inkSecondary`, `numeral` | MonthPage.swift:35, :123, :168, :69 | OK |
| RL80 | Routines page | routine list | title `.title`; context voice 21; routine name `Theme.voice(size: 21).weight(.medium)`; detail `Theme.voice(size: 16)` | 44 / 21 / 16 | gutter (RoutinesPage:75) | | 3 | `ink`, `context`, `inkSecondary` | RoutinesPage.swift:42, :48, :288, :299 | LIT |
| RL81 | Routine editor, exercise rows | routine slots | name `.body` `lineLimit(2)`; scheme `.label` | 21 / 16 | gutter (RoutineEditor:78) | AX5 | 5 on the editor: 28, 21, 16 + semibold 21 | `ink`, `live` | RoutineEditor.swift:219, :221, :224 | LIT |
| RL82 | Routine editor, steppers and days | numerals / day chips | `Theme.numeral(28)` literal; days `Theme.voice(size: 21).weight(.semibold)` | 28 / 21 | | uncapped | | `ink` | RoutineEditor.swift:297, :323, :418, :432, :453 | LIT |
| RL83 | Live workout, rest and Go | timer numerals | `Theme.numeral(72)`; "rest" `Theme.voice` | 72 / 21 | centred | uncapped | 72, 21, 16 | `Paint.now`, `Paint.cream`, `Paint.secondary` | WorkoutModeView.swift:436, :441, :463 | LIT |
| RL84 | Live workout, Tess lines | Tess line | `Theme.voice`, `lineLimit(1)` | 21 | gutter (WorkoutModeView:217) | uncapped | | `context` | WorkoutModeView.swift:357, :407, :417 | OK |
| RL85 | Live workout, labels | metadata and keys | `.label`, `.labelStrong` | 16 | | AX5 | | `Paint.secondary`, `Paint.tess` | WorkoutModeView.swift:483, :534, :639-685 | OK |
| RL86 | Live workout, exercise title | name | `.title`, then `title34` literal step-down, `lineLimit(1)` / 2 via `ViewThatFits` | 44 -> 34 | gutter-to-gutter | from `.title` | adds 34 | `Paint.cream` | WorkoutParts.swift:36-38, :99-102 | LIT |
| RL87 | Live workout, exercise strip | running order | names `Theme.numeral(28, weight: .medium)` `lineLimit(1)`; set line `.label`; help `Theme.voice(size: 18)` | 28 / 16 / 18 | gutter (ExerciseStrip:122) | uncapped | 3 (28, 18, 16) | `Paint.cream`, `Paint.secondary` | ExerciseStrip.swift:155, :162, :166, :104 | LIT |
| RL88 | Swap panel | alternatives list | name `Theme.numeral(24, weight: .medium)` `lineLimit(1)`; load `Theme.numeral(21)`; voice 21 and 18; label 16; check `lineSpacing(4)`, `frame(width: 250)` | 24 / 21 / 18 / 16 | 250 pt check text | uncapped | 4 | `Paint.cream`, `Paint.tess` | SwapPanel.swift:77, :83, :22, :42, :31, :141, :154 | OVER |
| RL89 | Workout finish | summary | day line `Theme.voice`; hero `Theme.numeral(56, weight: .medium)` `lineLimit(2)`; counts `.label` | 56 / 21 / 16 | gutter (WorkoutFinishView:48) | uncapped | 3 | `Paint.cream`, `Paint.secondary` | WorkoutFinishView.swift:37, :40, :42, :69, :72 | LIT |
| RL90 | Workout weight / reps / RPE instruments | numerals | `Theme.numeral(80)`, `(34)`, `(56)`, `(26)`/`(21)`; RPE `dynamicTypeSize(...xxLarge)` | 80 / 56 / 34 / 26 / 21 | | RPE capped xxLarge; others uncapped | 5+ | | WeightField.swift:26; RepsRow.swift:41, :46; RPEStops.swift:115-116 | LIT |
| RL91 | Workout, Tess corner | Tess line | `Theme.voice` `lineLimit(2)`, `maxWidth: 270` | 21 | 270 pt, about 26 chars per line | uncapped | 1 | `Paint.tess` | LiveTessCorner.swift:58, :62 | OK |
| RL92 | Workout input field | typed command | `.field` | 18 | gutter (WorkoutParts:382) | AX5 | | `Paint.cream` | WorkoutParts.swift:362 | OK |

### Home, Now, Review and Tess

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL93 | Home / Now, context line | Home line | `Theme.voice(size: 21)` | 21 | gutter | uncapped | 5 on Now: 56, 44, 21, 18, 16 | `context` | NowPage.swift:190 | OVER |
| RL94 | Home line hero | Home line, hero | `ViewThatFits`: `.hero` lineLimit(1) -> `.title` lineLimit(1) -> `.title` wrapped; also `@ScaledMetric` hero / title sizes | 56 -> 44 | one line then wrap | hero capped | 56 / 44 (a step-down) | `ink` | HomeLineHero.swift:83-87, :73-74 | OK |
| RL95 | Home line, voice line | Tess line | `Theme.voice(size: 21)`, `lineLimit(1)` + `fixedSize`, `ViewThatFits` with a short form | 21 | one line | uncapped | | `tess` when wet else `context` | HomeLineHero.swift:33-38 | OK |
| RL96 | Now page, plan rows | schedule lines | title `Theme.voice` `lineLimit(1)`; time `Typography.font(scale.label)` | 21 / 16 | one line + right time | from `.label` | | | NowPage.swift:523-527 | OK |
| RL97 | Now page, current task | task + next step | title `.bodyStrong`; next step `Theme.voice(size: 18)` `lineLimit(1)` | 21 / 18 | one line | | adds 18 | `ink`, `inkSecondary` | NowPage.swift:601, :604, :606 | LIT |
| RL98 | Now page, empty | empty | `.title`, `.bodyStrong` | 44 / 21 | | | | `ink` | NowPage.swift:352, :359 | OK |
| RL99 | Now page, keys | action words | `.labelStrong` (Resume, Start, Finish, Cook) | 16 | | AX5 | | `ink` | NowPage.swift:67, :83, :257, :310 | OK |
| RL100 | Home queue headings | section head | `Theme.voice(size: 34)` ("Later", heading) | 34 | | uncapped | 3: 34, 21, 16 | `ink` | HomeQueue.swift:134, :180 | LIT |
| RL101 | Home queue rows | queue lines | `Typography.font(scale.body, weight: isNext ? .medium : .regular)`; time `.data` | 21 / 16 | | | | `ink` opacity 0.45 when struck | HomeQueue.swift:361, :381 | LIT-adjacent (weight by state) |
| RL102 | Home plan block | plan lines | heading `Theme.voice(size: 34)`; privacy note `Theme.voice(size: 16)`; rows `Typography.font(scale.body ...)`, `lineLimit(2)`; time `scale.label` | 34 / 16 / 21 | rows two lines | | 3: 34, 21, 16 | `ink`, `inkSecondary` | HomePlan.swift:268, :294, :325, :329, :364 | LIT |
| RL103 | Home spatial, link names | object links | `.title` hero link; `.bodyStrong`; `.body` separator; `.label` | 44 / 21 / 16 | `ViewThatFits`; explicit AX branch (HomeSpatialView:215) | AX5 | 3 + voice 21 | `ink`, `muted` | HomeSpatialView.swift:381, :410, :535, :374 | OK |
| RL104 | Day strip | day phrase | `Theme.voice(size: 21)` | 21 | | uncapped | 1 | `ink` | DayStrip.swift:112 | LIT |
| RL105 | Review page (Home), word | review headline | `.hero` in `ViewThatFits` (one line, two lines); stroke words `InkWordType.font` (34) and `.title` | 56 / 44 / 34 | `lineLimit(1)` each | hero capped | 4: 56, 44, 34, 21 | `ink` | ReviewPage.swift:367, :534-548, :238 | LIT (34 literal) |
| RL106 | Review week | week reading | letters `.label`; figures `.labelStrong`; list text `Theme.voice(size: 16)` | 16 all | | AX5 / uncapped | 1 size, 3 tokens | `ink`, `inkSecondary` | ReviewWeek.swift:243, :278, :344-355 | LIT |
| RL107 | Review view | week counts and Tess line | `Theme.voice` context and Tess; `.body` counts; `.label` weekday; `.data` time | 21 / 16 | gutter (ReviewView:241) | | 2 | `context`, `tess`, `ink` | ReviewView.swift:159, :177, :212, :285, :316 | OK |
| RL108 | Look sentence | "look" picker sentence | `.body` hint; name `.fontWeight(.semibold)` | 21 | | AX5 | 1 | `inkSecondary` | LookSentence.swift:73-76, :88 | OK |
| RL109 | Command bar: Tess voice | Tess lines | `Theme.voice`, `lineLimit(1)` / `ViewThatFits` `lineLimit(3)`, `maxWidth: 270` | 21 | 270 pt | uncapped | | `tess` | BottomChrome.swift:157, :160, :187, :194, :197, :200, :316 | OK |
| RL110 | Command bar: typing | typed capture | `.field` | 18 | gutter (BottomChrome:420) | AX5 | 2 | `ink` | BottomChrome.swift:377 | OK |
| RL111 | Speak layer | heard words and refusals | `Theme.voice`, `lineLimit(2)` | 21 | gutter (SpeakLayer:63) | uncapped | 1 | `inkSecondary`, `tess` | SpeakLayer.swift:18-45 | OK |
| RL112 | Capture parts | typed-word reveal | `.bodyStrong`; key `.labelStrong` | 21 / 16 | | AX5 | | `ink`, `inkSecondary` | CaptureParts.swift:38, :132 | OK |
| RL113 | Tess gallery (debug) | design gallery | `.title`, `.label` | 44 / 16 | gutter | AX5 | 2 | | SoulGallery.swift:14-69 | OK |

### Settings, Backup, receipts and logs

| ID | Surface | Kind | Fonts | Wt / lines | Measure | Dyn Type | Sizes | Colour | Cite | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| RL114 | Claude settings section | settings sentences | `.body` sentences; `.labelStrong` heads and separators; `.field` for the key | 21 / 16 / 18 | gutter (ClaudeSection:496) | AX5 | 3 | `ink`, `tess` for her lines, `inkSecondary` | ClaudeSection.swift:87-262 | OK |
| RL115 | Claude receipts page | receipts (money lines) | `.label` back; `.title` head; `.body` lines, min row 44 | 16 / 44 / 21 | gutter 22 (ClaudeSection:496) | AX5 | 3 | `ink`, `inkSecondary` | ClaudeSection.swift:468, :476, :481, :485, :490 | OK |
| RL116 | Receipt words (undo lines) | undo / receipt lines | `Receipt` enum is copy only; shown through `TessVoice` | n/a | Tess band | | | | Receipts.swift:5-52 | UNK (styling in TessVoice host) |
| RL117 | Rest-day receipt | undo line | copy via `TessVoice.shared.say` | n/a | Tess band | | | | RestReceipt.swift:19 | UNK |
| RL118 | "What was sent" log | sent payload list | no view on master; spec only, docs/ai/what-was-sent-log.md (list "in the house type", payload "in plain reading type") | | | | | | docs/ai/what-was-sent-log.md:39 | UNK |
| RL119 | Rest day sentence | settings sentence | `.body` | 21 | | AX5 | 1 | `ink` | RestDaySentence.swift:32 | OK |
| RL120 | Backup page | long explanatory text | `.hero` head, `Theme.voice` context and lines, `.body` blocks, `.label`, `.title` for "A restore is waiting" | 56 / 44 / 21 / 16 | gutter (BackupView:158) | hero capped | 4 | `ink`, `tess`, `inkSecondary` | BackupView.swift:50, :56, :64, :78, :88, :97, :125, :151, :204, :209, :227, :231 | OVER |
| RL121 | Backup export row | warning and line | `Theme.voice` | 21 | | uncapped | 1 | `ink`, `inkSecondary` | ExportRow.swift:48, :71 | OK |
| RL122 | Habits | habit list | no view on master; only `HabitsCopy.swift` strings (voice-over text) | | | | | | HabitsCopy.swift:72 | UNK |
| RL123 | Live Activity / widget | lock-screen rest text | `Typeface.font(17)`, `(24, .medium)`, `(18, .medium)`, `numerals(size)` literals | 17 / 18 / 24 | | widget-defined | 3+ | | Widgets/RestLiveActivity.swift:84, :147, :213, :216, :333 | LIT (outside Features, listed for completeness) |

## 3. Per-content-kind summary

- Notes (RL01-RL12). List screen: hero + context + field + bodyStrong + voice 18 + data = 4 sizes (+44 empty). Editor: field 18 for all typed text, 3 sizes. Typed paragraphs use `.field` (18), read-back lines elsewhere use 21. No read-only note view exists: a note is read inside its editor at 18.
- Lists (RL13-RL27, RL35). Items are `.body` 21, `lineLimit(2)`. The shelf ranks names by `.hero`/`.title`/`.body` in one column, so one screen reaches 56, 44, 21. Headings use `.title`/`.hero`; Tess and context lines use `voice` 21. Quite consistent per token, but the shelf and page both run to 4 sizes.
- Groceries (RL28-RL35). Same list grammar as Lists, plus an 18 pt `voice` provenance line and hero aisle names in shop mode: 5 sizes.
- Pantry (RL36-RL40). Rows are `.body` with weight-only state; headings 44 plus a 56 front line: 4 sizes.
- Paragraphs (typed in RL08-RL09, RL50; Tess/context everywhere): typing is 18 (`field`), Tess/context is 21 (`voice`), settings and receipts sentences are 21 (`body`). Three different tokens for 18-21 pt running text; `voice` and `body` are the same size with different line-height handling (voice has none).
- Exercise details (RL56-RL66, RL63-RL64). Mixes `textRole`, `PageType.small` (18), `PageType.voice` (21) and literal `Theme.numeral` at 21, 24, 44. Five sizes. History date column is a fixed 92 pt.
- Recipe steps (RL41, RL45, RL51-RL52). Cook mode has no view on master (`cookModeReady = false`). Steps exist only in the paste read-back (`.body` 21 with an 18 pt numeral margin) and the ingredient column (`.body` 21, amount 600). Read-back mixes 44, 21, 18, 16.
- Receipts (RL115-RL118). Receipts page is the cleanest in the app: `.label`/`.title`/`.body`, 3 sizes. Undo receipts have no own layout (Tess band). The sent-log has no view yet.
- Tess and context lines (RL02, RL10, RL25, RL27, RL53, RL58, RL84, RL91, RL95, RL107, RL109, RL111). `Theme.voice` 21 regular in nearly every use; exceptions are `voice(size: 16/18/34)`.
- Training logs and Home lines (RL73-RL76, RL93-RL104). Mix `voice(size: 21)`, `voice(size: 34)`, `voice(size: 16)` and the SF system font at 16.
- Settings/Backup (RL114, RL119-RL121). Settings is within the cap; Backup is 4 sizes.

## 4. Top 10 inconsistencies

1. Groceries reaches 5 sizes (56, 44, 21, 18, 16) in one screen (RL28-RL35).
2. Now / Home reaches 5 sizes: hero, title, body, 18 (`voice(size: 18)`, NowPage.swift:604) and 16 (RL93-RL99).
3. Exercise page reaches 5 sizes with literal numerals (44 at ExercisePage.swift:154, 24 at ExerciseViews.swift:189, 21 at :138) plus `PageType.small` 18 (RL56-RL66).
4. SF system font used where the voice should be Inter Tight: TrainingPage.swift:606 (`.system(size: 16, weight: .semibold)`) and ObjectPage.swift:488 (`.system(size: 17)`); 17 is not on any scale.
5. Off-scale sizes 18 and 34 by literal: `voice(size: 18)` at NotesView.swift:197, GroceriesView.swift:484, PasteRecipe.swift:421, PortionDrum.swift:41, NowPage.swift:604, ExerciseStrip.swift:104, SwapPanel.swift:42; `voice(size: 34)` at HomeQueue.swift:134, :180, HomePlan.swift:268; 34 in `InkWordType` (Paint.swift:482) and `title34` (WorkoutParts.swift:99-102).
6. `voice(size: 21)` and `voice(size: 16)` hard-code a scale size instead of a role (ListsView.swift:41, :63, :178, :181; PantryView.swift:43; RecipesShelfView.swift:65; RoutinesPage.swift:48, :104, :288, :299; ReviewWeek.swift:344-355; HomePlan.swift:294).
7. Shelf-style lists put three sizes into one column: Lists rows pick `.hero` / `.title` / `.body` by tier (ListsView.swift:99).
8. Backup (RL120) and Pantry (RL36-RL40) carry 56 + 44 + 21 + 16 on a screen that is mostly sentences.
9. No reading width. All running text is gutter-to-gutter, about 34 characters at 21 pt, about 44 at 16 pt; only Tess lines are capped (270 pt) and no page has a max width. On any wider layout than a 402 pt iPhone the line is not bounded.
10. `voice`, `numeral`, `PageType` have no Dynamic Type cap, no line height and take a free size; `textRole` has a cap and line height. Same-size text (21 voice vs 21 body) therefore wraps and scales differently.

## 5. What Design's sheet needs to decide

- Whether 18 (field / `PageType.small` / `voice(size: 18)`) and 34 are sanctioned sizes or fold into 16 / 21 / 44.
- One token for running 18-21 pt text, replacing the `voice` / `body` / `field` split, with line height and a Dynamic Type cap defined for it.
- A reading width: whether a max line length (characters, or points) applies per content kind, and where Tess's 270 pt cap sits.
- Per kind: notes (typed 18 and read 21?), lists (single-size items vs the Lists tier ranking), paragraphs (settings, Backup), exercise details (numerals as `titleNumber` vs literal), recipe steps (cook mode does not exist yet), receipts (`.body` ledger as now, and the unbuilt sent-log).
- Whether numerals at 21, 24, 28, 34, 44, 56, 72, 80 map to the four roles or stay free for the workout ground.
- Whether the SF system font (TrainingPage:606, ObjectPage:488) is allowed.
- Line-spacing and line-limit rules: `lineLimit(1)` + `ViewThatFits` rows vs wrapping rows, and the AX switches that exist today (Pantry, Recipe, Plans, Week, Exercise).

## 6. Not verified

- Other looks (Workshop, Machined) sizes; only Plein scale values were read.
- Characters per line are estimates; no rendering was run.
- Cook mode, Habits UI and the sent-log views do not exist on master; their rows reflect that.
- Docs: docs/DESIGN_MOTION.md and `.claude/skills/tessera-design/SKILL.md` give the four-size rule (SKILL.md:20-29); docs/design has no "reading layouts" sheet (grep for "reading" found only motion notes and one copy line). docs/design/type-and-motion.md, cited in Theme.swift, is not in the tree.
