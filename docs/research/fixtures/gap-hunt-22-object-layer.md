# Gap hunt 22: the object layer (object pages, plate, handles, links, class page, Spotlight, deep links) under privacy, Low Power and VoiceOver (static read, origin/master 9eb2713f, Sun Oct 18 PT)

For: Builder B (Features/Objects, Notes link line), Builder A (motion policy, haptics, Home keys), Core (ObjectPrivacy, PrivateWords, ObjectStore, the index, intents), Design (plate, sides, new strings), QA. Docs only. Nothing was built or run: there is no Swift toolchain here, so "traced" means I read the line and saw what the row says, "inferred" means the row follows from code I did not read in full, and a Spotlight or deep-link row marked (not built) is a spec to test when the feature lands. Method and row format follow `gap-hunt-21-plan-daylog-speak.md`. Every file:line below was read in a worktree of origin/master 9eb2713f. HS ids are rows in `gap-hunt-home-settings.md`, PT ids are rows in `private-title-masks.md`, P ids are rows in `spotlight-widgets-privacy.md`; they are referenced, not repeated, unless master changed under them (noted per row).

**Gap ids.** `git grep -ho "G[0-9]\{3,4\}" origin/master -- docs | sort -u`, with the G4001 to G4015 series ignored (it is the kitchen lists series), ends at **G636** (gap hunt 21). New gaps here are **G637 to G646**, the ten ranked rows. I did not read the project mirror, so another open research PR may hold G637 or above; renumber at merge (question 8 in section 5). Row ids use the prefix **OL**, unique only inside this file (OL appears nowhere else I know of, but rows from other files are always written with their file name).

Status words: **traced** means the code does what the Expected column says (a pass, or a fact to pin); **inferred** means the row follows from a ruling or code I did not read in full; **gap** means master has nothing for it or contradicts a ruling. **(not built)** marks a screen or surface that does not exist: a spec to test when it lands. **(latent)** marks a gap with no caller yet. **(unruled)** marks an Expected that rests on my default, not a Product ruling; each is also in PRODUCT CALLS. Owners as above.

Rulings used (`docs/product/decisions.md` in the repo at 9eb2713f, line numbers of that file). Every stamp is read as PT as written.
- Line 61 (3:17 AM Oct 17): on-screen counts keep private items and hide only names.
- Line 171 (2:45 PM Oct 16, amended 2:55): any object flagged private shows its class's private label with its fields hidden on the generic page, PropertyList and the class page's newest row.
- Lines 185 and 197 (2:41 PM, 2:24 PM Oct 16): every screen declares its own side swipe; a side never shows a private fact the front hides; a screen with no side fails review from the SideHost PR on, only for screens that PR or a later one adds or changes. Line 165 (2:59 PM): the right edge goes in, the left edge goes out, a swipe right goes one step back.
- Line 243 (1:35 PM Oct 16): one UNDO slot, 4 s for a new thing, 10 s for a change, 10 s for everything under VoiceOver, thing first.
- Line 283: private notes are never indexed. Lines 496 to 501 (12:26 PM Oct 16): titles that trip the secret-word or money/body checks are hidden from Spotlight, Siri replies and the Live Activity; every free-text field on a future widget gets `.privacySensitive`.
- Lines 907, 909, 931 (Oct 17): a private routine or workout reads "Private workout" wherever it shows, no screen is exempt for being his own, the op log keeps the raw title, and the extra sites named for the object page are the hero (`ObjectPage.swift:260`, "ObjectPrivacy.label needs a workout branch") and the routine search in `Entities.swift:91`.
- Lines 11, 975, 995 (Oct 17): an ingredient used only by private recipes reads "Private item"; once a private recipe is cooked that ingredient stays "Private item" (G139 sticky); a private recipe's own page shows each ingredient as "Private item", VoiceOver included.
- Line 991 (7:39 PM Oct 17, D5) and line 1003 (8:20 PM): Low Power = Reduce Motion everywhere, sides and page turns included (150 ms crossfade, no drag spring); the soul keeps her own Low Power form.
- Lines 993 and 1029 (7:39 PM, 9:33 PM Oct 17): every private row draws at 100% ink, no dimming, no tell; a private row keeps its neighbours' height; opening a private note in its editor is not a reveal.
- Line 1011 (9:18 PM Oct 17): named-action-only is for hold keys; tap keys keep VoiceOver double tap.
- Line 1051 (10:47 PM Oct 17, Kitchen gap hunt 21 calls): the app hands every extension and index only masked words through the one private-text function; a private object is not indexed in Spotlight at all and leaves the index the moment it turns private; `.privacySensitive` stays as a second layer.

Cross-references that are not repeated: HS01 to HS05 (raw Home titles, Low Power as Reduce Motion, haptic gate), HS07 (raw animations); PT24 to PT26 (object page hero, Used in row and grouping), PT8 to PT12 (RoutineEntity and the Siri dialogs), PT32 to PT35 (RoutineEditor), PT52 and PT55 (Home Start key, op summaries) and the "AppModel.title(of:)" item in its section 4; P1 to P22 of `spotlight-widgets-privacy.md`; `undo-slot-voiceover.md` rules 1 to 4.

## 1. State of master for these areas

| Area | What master has today | Evidence |
|---|---|---|
| Object page | One `ObjectPage` for every `Route` (`object`, `classDef`, `routines`): it hands exercises, plans, routines and plain notes to their own pages and draws everything else on a generic page (hero, class line, notes, properties, contents, "Linked from", Start workout). A private note stays on the generic page and reads its label with nothing under it. | `ObjectPage.swift:24-48, 247-319`; `RootView.swift:21-26` |
| Which objects mask | `ObjectMask.label` = Core's `ObjectPrivacy.label` (note, memory, task, recipe) plus "Private item" for an ingredient or list item and "Private list" for a list whose **title** is walled. Nothing for a workout, routine, cook or any other class. | `ObjectPage.swift:563-581`; `ObjectPrivacy.swift:28-57` (returns nil for workout and routine; "Private workout" comes only from `routineTitle` at :22-24, which no object-page line calls) |
| The export's mask | A second, wider function, `PrivateWords.labels`, masks any object with a flag, a walled title or a walled text value, everything inside a private object, anything carrying a private title, and an ingredient used only by private things. It is `internal` to TesseraCore, so the app cannot call it. | `PrivateWords.swift:15, 138-200, 203-206`; callers `TesseraExport.swift:147`, `TesseraBackup.swift:64, 95` only |
| Plate | `ObjectPlate` and `PlateWash` are built and unit-tested, but no screen draws a plate. | `ObjectPlate.swift:7-95`; `git grep "ObjectPlate("` finds only `PlateWashTests.swift:40` |
| Handles and links | `ObjectHandle` and `ObjectRow` take a raw `title: String` and a `Route`; they trust the caller to mask. Links are `ObjectLink` rows read through `linkedObjects`, `linkedClass`, `backlinks`. `ObjectPath` slugs come from raw titles and have no caller outside Core. | `ObjectHandle.swift:9-85`; `ObjectStore.swift:260-298`; `Models.swift:370`; `ObjectPath.swift:20-34, 47-76` |
| Class page / inspector | `ClassBody` is a partial inspector: lineage header, prototype notes and properties (inherited marked with an arrow), history and "Used in" for exercises, subclasses, "New subclass". No instance count, no traits, no add-a-field (ship-list slice 6 is not built). | `ObjectPage.swift:93-194`; `ship-list-m3.md:12` |
| Objects browser | **No screen.** Only a comment in `Groceries.swift:167` mentions it. | `git grep -i browser -- '*.swift'` |
| Spotlight | Nothing indexed: no `CSSearchableItem`, `IndexedEntity` or `NSUserActivity` in the repo. App Shortcuts list routine titles through `RoutineQuery`. | `git grep` for the three names; `Entities.swift:58-104` |
| Deep links | The `tessera` scheme is registered; `onOpenURL` acts only on host `workout`, and only with a live session. No object link and no `onContinueUserActivity`. | `Info.plist:32-41`; `TesseraApp.swift:107-111`; `RestLiveActivity.swift:33` |
| Intents on a locked phone | P16 of `spotlight-widgets-privacy.md` is **closed on master**: six intents set `requiresAuthentication`. | `Intents.swift:11, 91, 114, 135, 189` and the `TessTests.swift:257-259` list |
| Side swipe | `SideHost` does not exist (comments only); `SideFacts` (Core) builds default side fields and a class glance but nothing draws them. | `PantryView.swift:12`; `SideFacts.swift:5-117`; `git grep ClassGlance` finds only Core and its tests |
| Motion and Low Power | `MotionPolicy.resolve` takes Reduce Motion only. `isLowPowerModeEnabled` is read once, by the soul. | `MotionPolicy.swift:5-11`; `TessSoul.swift:108` |
| VoiceOver | No `AccessibilityNotification` or `UIAccessibility.post` in `Features/Objects`; two `accessibilityLabel` calls (the "inherited" arrow and the plate photo), two hints. | `git grep` over `Features/Objects` |
| Haptics | None played from the object layer. | `git grep tesseraFeedback -- Features/Objects` |

## 2. Top 10 gaps, ranked

Ranked by harm to him first (a private word printed or findable outside the app, then inside it), then by how many surfaces one fix touches.

| Rank | Gap id (row) | Gap | file:line | Owner |
|---|---|---|---|---|
| 1 | G637 (OL37) | Live today: `RoutineEntity` and `RoutineQuery` hand every routine's raw title to Shortcuts, Siri's picker and the App Shortcut "Start (routine)" that Spotlight lists. A routine named "Knee rehab day" is findable by title and shown as typed. Ruled hidden (lines 496 to 501, 931). | `Entities.swift:65-66, 84, 91, 95-102` | Core |
| 2 | G638 (OL01) | The generic page for a workout or routine prints its raw title as the hero and in "object <title> : Workout"; no "Private workout" branch exists on the page or in `ObjectPrivacy.label`. Same hole in `SideFacts.defaultFields`, so the future side would print a private workout's fields. | `ObjectPage.swift:256-265`; `ObjectPrivacy.swift:28-57`; `SideFacts.swift:62-66` | Core + Builder B |
| 3 | G639 (OL05) | Two mask functions disagree. The page masks by the object's own title or flag; the export masks by `PrivateWords.labels` (children of a private object, carriers of a private title, an ingredient only private things use, any object with a walled text value). The wider one is `internal`, so the page cannot use it. | `ObjectPage.swift:563-581`; `PrivateWords.swift:15, 138-206` | Core + Builder B |
| 4 | G640 (OL04) | `PropertyList` prints every field value of any object whose label is nil, with no `isShowable` check: a plain-titled object with a secret word or an amount in a text field shows it on the page. `SideFacts` already has the check; the page does not call it. | `ObjectPage.swift:446-452, 461-469`; `SideFacts.swift:40-60` | Builder B + Core |
| 5 | G641 (OL03) | "Linked from", ref-field handles and "Used in" take `?? source.title` / `target.title`: a workout or routine on the other end prints raw, and an object with an empty title (a set, an entry) becomes a blank row with an empty spoken label and the hint "Opens ". | `ObjectPage.swift:155, 304-306, 434-435` | Builder B |
| 6 | G642 (OL40) | Spotlight is not built, and the contract that makes it safe is not written into code: one function for every indexed word (title, keywords, description, thumbnail, user info), private objects not indexed at all, the object leaving the index the moment it turns private, delete, rename to a walled title and restore all handled. | `git grep CSSearchableItem` (none); line 1051 | Core |
| 7 | G643 (OL47) | Deep links: `onOpenURL` knows only `workout`; there is no object link or Spotlight-tap handler. When one is added it must carry the id only (`ObjectPath` slugs embed titles) and cope with a private, missing or soft-deleted target: today `object(id:)` returns soft-deleted objects and a missing id draws an empty scroll view. | `TesseraApp.swift:107-111`; `ObjectStore.swift:93-95`; `ObjectPage.swift:67-73`; `ObjectPath.swift:20-34` | Builder B + Core |
| 8 | G644 (OL19) | VoiceOver reads a handle twice and reads decoration: label "Private note" plus hint "Opens Private note"; the row's arrow glyph is inside the combined element; the breadcrumb's "..." and "/" are spoken; the handle takes a raw string, so a caller that forgets the mask fails open. | `ObjectHandle.swift:24, 35, 67, 77`; `ObjectPage.swift:359-366` | Builder B |
| 9 | G645 (OL30) | Low Power is read by none of the object layer's motion: the zoom arrival, the glyph-by-glyph hero, the entrance stagger, the press fades and the plate dry-in follow Reduce Motion only (D5 rules Low Power = Reduce Motion); "Log a set" hard-codes `reduceMotion: false`. | `ObjectHandle.swift:132-148`; `Editorial.swift:62-83`; `TextEffects.swift:96-115`; `ObjectPage.swift:168` | Builder A (policy) + Builder B |
| 10 | G646 (OL58) | The object page, class page and the future Objects browser declare no side swipe. Ruled: every screen has one, and the default object side is LINKS plus the fields the front does not show, count only for a private object. | `ObjectPage.swift:62-89` (no side); `decisions.md:185, 197`; `SideFacts.swift:62-66` | Builder B + Core |

## 3. Full rows

Columns: id; what to check (with the gap id where the row is ranked); expected (with the Swift Testing name to write); status; file:line; the wall, Low Power or VoiceOver angle; owner.

### 3A. What the page prints for a private object

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL01 | G638. Open `Route.object` of a workout or routine whose title is walled ("Knee rehab day", a medicine, "Weigh in 82.4 kg"). | Hero "Private workout", class line "Workout", no properties, contents or "Linked from" (the label branch at :269-297 already hides them once the label is non-nil). The raw title is never in the hero, class line, VoiceOver header or the "Opens" hint. Test: `workoutObjectPageHeroReadsPrivateWorkout`. | gap | `ObjectPage.swift:256-265`; `ObjectPrivacy.swift:28-57`; PT24 | Wall: the page is reached from Used in, Linked from, Spotlight and a deep link, not only from the routine editor. VoiceOver: the header trait is on the hero (:375), so it reads the raw title as a heading. | Core (label branch) + Builder B |
| OL02 | "Used in" on an exercise class page: row title, hint and grouping. | The row reads "Private workout" and its hint "Opens Private workout"; grouping stays by the raw key so two different private workouts stay two rows (PT26). Test: `exerciseUsedInRowMasksPrivateWorkout`. | gap | `ObjectPage.swift:154-158, 186-193`; PT25, PT26 | Wall: line 909 says no screen is exempt. A merged count would also be a tell, so group by id, not by the masked word. | Builder B |
| OL03 | G641. "Linked from" rows, ref and ref-list handles, child rows: title source and fallbacks. | One function gives every row its shown title: label first, then the title, then (empty title) the class name and position as `displayTitle` does, never an empty string. A workout or routine on the other end reads "Private workout". Test: `linkRowsNeverShowRawWorkoutTitleOrBlank`. | gap | `ObjectPage.swift:304-306` (no empty fallback), `:434-435` (no empty fallback), `:331-335` (has one) | VoiceOver: an empty-title source gives a button with no label and the hint "Opens "; the ChildRow branch already falls back, the other two do not. Wall: the workout case is PT24's twin. | Builder B |
| OL04 | G640. Every field value on a plain-labelled object: text, rich text, choice, number, mass, date. | Each value passes the same showable check as a side (`SideFacts.isShowable(field, text, ...)`); a held-back value reads "Kept private" (my default, string for Design), counted the way `SideFacts.Lines.keptLine` counts. The load rule (a set's weight is the bar's) stays. Test: `propertyListHoldsBackWalledFieldValues`, `propertyListKeepsALoadWeight`. | gap | `ObjectPage.swift:446-452, 461-469`; `SideFacts.swift:40-60` | Wall: the export masks an object with a walled text value (PrivateWords.swift:176), the page does not. Unruled string. | Builder B + Core |
| OL05 | G639. Same object asked of `ObjectMask.label` and `PrivateWords.labels`. | One public Core function (the "one private-text function" of line 1051) answers for the page, the export and the index; `ObjectMask` shrinks to a call. A parity test seeds an object of each class and asserts the two agree. Test: `pageMaskAndExportMaskAgree`. | gap | `ObjectPage.swift:563-581`; `PrivateWords.swift:15, 138`; `PrivacyParityTests.swift` (covers titles, not objects) | Wall: today they diverge on OL06, OL07 and OL04. | Core |
| OL06 | A child of a private object (a recipe line or step of a private recipe, a cook of one), or an object that carries a private title, opened directly (a backlink, a deep link). | Reads the parent's label ("Private recipe"); the export already does this by walking `parent` and matching the title (`PrivateWords.swift:178-187`). Test: `childOfPrivateRecipeReadsPrivateRecipe`. | gap | `ObjectPage.swift:575-580` (title only); `PrivateWords.swift:178-187` | Wall: the parent's page hides its contents (:282), but the child's own route does not know it is inside. Inferred that a recipe line is reachable by `Route.object`; I did not trace a caller. | Core + Builder B |
| OL07 | An ingredient used only by private recipes or items, on its object page and as a handle. | "Private item" (lines 11 and 975; the export does it at `PrivateWords.swift:190-195`). Sticky once a private recipe is cooked. Test: `ingredientOnlyPrivateRecipesUseReadsPrivateItem`. | gap | `ObjectPage.swift:575-578` (title only); `PrivateWords.swift:190-195, 203-206` | Wall: Groceries and Pantry mask it, the object page is the third way to see the same word. | Core + Builder B |
| OL08 | Class page: prototype notes and prototype properties. | Notes go through `ObjectPrivacy.notesLine` (so a workout class prototype's notes read "Note kept private"), values through the OL04 check. Test: `classPageNotesUseTheNotesLine`. | gap | `ObjectPage.swift:112-118, 120` vs `:269-276`; `ObjectPrivacy.swift:94-103` | Wall: the instance page masks workout notes, the class page prints `ObjectNotes.shown(...)` of the prototype raw. Inferred that a prototype can hold notes in practice; the code path is open. | Builder B |
| OL09 | A private note opens on the generic page. | Hero "Private note", class line "Note", no notes, properties, contents or backlinks. | traced | `ObjectPage.swift:50-55, 256-298`; `ObjectMaskTests.swift`, `PrivateNoteObjectTests.swift` | Pins line 171. Opening it in the editor is not a reveal (line 1029). | Builder B |
| OL10 | Typing a walled word into a plain note does not swap the editor for the masked page. | `noteLatch` is set once per appearance and cleared on route change. | traced | `ObjectPage.swift:9-22, 40-42, 58-60` | Pins line 1029 (2). | Builder B |
| OL11 | Title fallbacks when the title is empty: hero, child row, link rows, handles. | One rule across the page: the class name and position (`displayTitle`), not "Untitled" in one place, "Item" in another and "" in a third. Test: `emptyTitleFallbackIsTheSameEverywhere`. | gap | `ObjectPage.swift:260` ("Untitled"), `:333` (class name or "Item"), `:305` and `:435` (blank) | VoiceOver: "Untitled" as a heading says nothing; the position suffix is what tells two empty objects apart. | Builder B |
| OL12 | A workout's notes on its generic page. | "Note kept private" (Product 5:20 PM), nothing else; only spaces is no notes. | traced | `ObjectPage.swift:269-276`; `ObjectPrivacy.swift:87-103` | Holds only when the page reaches this branch with a nil label; OL01 is the other half. | Builder B |

### 3B. The plate

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL13 | A private object's plate is plain ground; a plain one has the wash. | Unruled whether that difference is a tell. Line 993 says a private row has no tell and withdraws the dimmed row; a page header that loses its colour is the same kind of signal. See CALL 1. | gap (unruled) | `ObjectPlate.swift:195-213`; `decisions.md:993` | Wall: the wash is seeded from the id and coloured from the ingredient mix, which is why a private one draws none. | Design |
| OL14 | `photoLabel` for a private plate. | "Photo of Private recipe" is hard-coded for every private object, including a private item or note. Expected: the label of the object's own class ("Private item"), or no label at all for a private plate (it draws no photo). Test: `privatePlateLabelUsesTheObjectsOwnLabel`. | gap (latent) | `ObjectPlate.swift:181-186` | VoiceOver: a wrong noun is a tell the other way. Latent because nothing draws a plate (OL15). | Builder B |
| OL15 | Where the plate is drawn. | Recipe page and Ingredient page per sheet 88 (decisions 8:37 PM Oct 17). Today no screen calls `ObjectPlate(`. | gap (not built) | `PlateWashTests.swift:40` is the only caller | Each caller must pass `isPrivate` from the OL05 function; the init has no default so a forgotten argument does not compile (`ObjectPlate.swift:158-159`). | Builder B |
| OL16 | Plate motion: photo dry-in, Reduce Motion, Low Power. | 380 ms dry-in; Reduce Motion 150 ms crossfade with no blur or desaturation (traced); Low Power the same as Reduce Motion (D5). The animation goes through `withTesseraAnimation`, not a raw `withAnimation`. Test: `plateDriesInOneFadeInLowPower`. | gap | `ObjectPlate.swift:202-210, 188` | Low Power: `isLowPowerModeEnabled` is not read; the blur 5 to 0 and saturation 0.6 to 1 animate. | Builder A (policy) + Builder B |
| OL17 | Plate VoiceOver and Dynamic Type. | The wash is hidden from VoiceOver, the photo carries one label, no text sits on the plate, the height is a fixed 56 pt. | traced | `ObjectPlate.swift:204, 242, 191` | Nothing to scale; nothing to read twice. | Builder B |
| OL18 | The wash pigments are not evaluated for a private object. | `pigments` is an autoclosure, `[]` when private, so the ingredient colour table is never read. | traced | `ObjectPlate.swift:169-177` | Wall: the colour mix of a private recipe's ingredients would give the recipe away. | Builder B |

### 3C. Handles, rows, VoiceOver, Dynamic Type

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL19 | G644. A handle's label and hint. | The label is the shown title; the hint says what it does without repeating the title ("Opens the page"), or is dropped. Test: `handleHintDoesNotRepeatTheTitle`. | gap | `ObjectHandle.swift:24, 35, 58, 77` | VoiceOver: "Private note. Opens Private note." A raw caller makes the hint a second leak. | Builder B |
| OL20 | G644. Can a caller pass a raw private string. | `ObjectHandle` and `ObjectRow` take the object (or a `ShownTitle` value built by the OL05 function), not a `String`. Test: a compile-level check, plus `handleBuiltFromAPrivateObjectShowsItsLabel`. | gap | `ObjectHandle.swift:10, 42` | Wall: `ObjectPlate` made `isPrivate` required after QA on #754 for this reason; the handles never did. | Builder B |
| OL21 | The row's arrow. | Hidden from VoiceOver (the row is already a button with a hint). | gap | `ObjectHandle.swift:66-68, 76` | VoiceOver: the combined element includes `Text("→")`. Inferred that VoiceOver speaks it as an arrow. | Builder B |
| OL22 | Breadcrumb: the "..." handle and the "/" separators. | The "..." handle reads "Up to <class>" (the root it opens); separators are hidden from VoiceOver. | gap | `ObjectPage.swift:359-366` | VoiceOver: "dot dot dot, Opens dot dot dot" and "slash". Inferred. | Builder B |
| OL23 | Property rows: reading order and placeholder glyphs. | Each row is one element: "Weight, 82 kg" (name then value), the dash reads "none", the formula placeholder reads "calculated". The inherited arrow label "inherited" stays (traced). Test: `propertyRowReadsAsOneElement`. | gap | `ObjectPage.swift:408-422, 413-416, 450-452, 457-459` | VoiceOver: name and value are two stops; "em dash" and "f of" are read aloud. Inferred. | Builder B |
| OL24 | Dynamic Type at accessibility sizes: `ObjectRow`, property rows, `Stat`. | The row and property HStacks stack (title above data) like `MarginSection` does at accessibility sizes. Test: a snapshot at the largest size, or a `ViewThatFits` check. | gap | `ObjectHandle.swift:57-69`; `ObjectPage.swift:410-420, 218-222`; `Editorial.swift:100-106` (the model) | Inferred: a long title plus a "x4" and an arrow squeeze the title. | Builder B |
| OL25 | Actions row ("Log a set", "New subclass", "Start workout"). | Icon scales with Dynamic Type; the key is at least 44 pt (traced). | gap | `ObjectPage.swift:484` (fixed 17 pt), `:488` (minHeight 44) | Dynamic Type: the arrow is a fixed-size font next to scaling text. | Builder B |
| OL26 | The class line ("object push-day-a : Workout", "class Bench : Barbell"). | VoiceOver reads a spoken form ("Workout, a kind of activity"), the code-style text is the sighted form. Unruled. | gap (unruled) | `ObjectPage.swift:180-184, 261-264, 378-382` | VoiceOver: the identifier form is read letter by word. Inferred. | Design |
| OL27 | The hero is a header and respects Reduce Motion. | `.isHeader` on the hero (traced); glyph reveal and blur are skipped under Reduce Motion (traced at :110-114). Low Power is OL31. | traced | `ObjectPage.swift:374-376`; `TextEffects.swift:96-115` | Pins the half that works. | Builder B |
| OL28 | Route to an id that no longer exists. | A plain one-line page ("Not on this phone anymore.", my default) with focus on it, and a back word; not an empty scroll view. Test: `missingObjectRouteShowsAPlainLine`. | gap | `ObjectPage.swift:67-73` (`if let` with no `else`) | VoiceOver: an empty page is silent after the transition. | Builder B |
| OL29 | Route to a soft-deleted object. | Same as OL28; `object(id:)` returns it. Test: `softDeletedObjectRouteShowsGone`. | gap | `ObjectStore.swift:93-95`; `ObjectPage.swift:71` | Wall: a deleted private-flagged object still renders its label (fine), a deleted plain workout renders raw (OL01). | Core + Builder B |

### 3D. Motion, Low Power, haptics

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL30 | G645. Page arrival: zoom out of the row or cross-fade. | Reduce Motion or Low Power means the 150 ms crossfade (D5). Test: `arrivalIsCrossFadeInLowPower`. | gap | `ObjectHandle.swift:132-148` (reads `accessibilityReduceMotion` only) | Low Power: HS03. The policy needs one input, then every row here follows. | Builder A |
| OL31 | G645. First-visit entrance (six elements, 25 ms stagger, 14 pt rise) and the glyph reveal of the hero. | Low Power = Reduce Motion: opacity only, the glyph reveal and blur skipped. Test: `entranceIsOpacityOnlyInLowPower`. | gap | `Editorial.swift:62-83`; `TextEffects.swift:96-115` | Low Power. Traced for Reduce Motion, not read for Low Power. | Builder A |
| OL32 | G645. Press fades and scales on handles and keys. | Through `tesseraAnimation`, so Reduce Motion and Low Power resolve to the crossfade. | gap | `ObjectHandle.swift:101-115` (`Theme.Motion.snappy` raw); HS07 | `PressScaleStyle` scales to 0.97 whatever the setting. | Builder A |
| OL33 | G645. "Log a set" opens the command bar. | `reduceMotion` is the view's environment value, not a literal. Test: `logASetUsesTheEnvironmentReduceMotion`. | gap | `ObjectPage.swift:168` | Reduce Motion is ignored on this one call. | Builder B |
| OL34 | Haptics in the object layer. | His own touches keep theirs: a key press plays the shared selection, "New subclass" plays the landing tick once; nothing plays on a Tess-origin write. None is played today. | gap | `git grep tesseraFeedback -- Features/Objects` (none); `ObjectPage.swift:164-176, 316` | Low Power and quiet hours keep his touches (lines 1011, 1029 (7)). | Builder A |

### 3E. Actions, UNDO, announcements

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL35 | "New subclass" on a class page. | It creates a class on one tap and jumps into it. Expected: a thing-first receipt ("New Bench Press, made."), one UNDO for 10 s (a change, line 243) through the one slot, an announcement under VoiceOver. A second tap on the same class names it "New New Bench Press". Test: `newSubclassHasAnUndoAndAReceipt`. | gap | `ObjectPage.swift:164-176` | UNDO: 10 s sighted, 10 s VoiceOver, thing first. Owner open on whether it is a hold key: it creates, it does not replace data, so a tap (line 1011). See CALL 6. | Builder B |
| OL36 | Announcements from the object layer. | Arrival needs none (the system moves focus); the plate, the missing-object line (OL28) and the receipt (OL35) are announced once. Nothing is announced today. | gap | `git grep AccessibilityNotification -- Features/Objects` (none) | VoiceOver, `undo-slot-voiceover.md` rules 1 and 3. | Builder B |

### 3F. Spotlight, deep links, Siri entities, share

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL37 | G637. Routine titles in Shortcuts, Siri's picker and the App Shortcut that Spotlight lists. | A private routine reads "Private workout" (or is left out of the suggestions, see CALL 3). `RoutineEntity` is built through one masked constructor. Test: `routineEntityTitleIsMaskedForPrivateRoutine`, `suggestedRoutineEntitiesAreMasked`. | gap | `Entities.swift:65-66` (display), `:84` (by id), `:102` (all) | Wall: PT8, PT10, PT11 trace the same lines; this row is the Spotlight view and it is live today. VoiceOver: the picker reads the title aloud. | Core |
| OL38 | Matching a typed word against routines. | The filter runs over the shown (masked) titles, so typing the medicine word finds nothing and proves nothing (PT9). `entities(for:)` returns the masked entity. Test: `routineQueryDoesNotMatchPrivateRoutineByRawTitle`. | gap | `Entities.swift:80-93` | Wall: existence of a private routine must not be testable by title (decisions line 931). | Core |
| OL39 | Spotlight indexing exists at all. | (not built) P1 and P2 of `spotlight-widgets-privacy.md` still hold at 9eb2713f: no `CSSearchableItem`, `IndexedEntity` or `NSUserActivity`. | gap (not built) | `git grep` over the repo | Search is parked until Spotlight (decisions line 283). | Core |
| OL40 | G642. The indexer contract: what may be handed to the index. | Title, keywords, content description, thumbnail data and user info all come from the OL05 function. A private object (label non-nil) is not indexed at all, not indexed under its label. A plain object linked to a private one carries no private word. Test: `indexedItemForPrivateObjectDoesNotExist`, `indexedItemFieldsAreMasked`. | gap (not built) | line 1051; `PrivateWords.swift:138` | Wall: this is the headline rule. Low Power: see OL43. | Core |
| OL41 | G642. Leaving the index. | The item is removed in the same write that makes the object private: the flag set, a rename to a walled title, a text edit that adds a walled word (EditNote must run the same check as CreateNote, G607), a soft delete, and a restore from a backup that holds an older state. Test: `objectLeavesTheIndexWhenItTurnsPrivate`, `objectLeavesTheIndexOnDelete`. | gap (not built) | line 1051; `TesseraContext.swift:25` (the label cache is keyed by revision, so a changed revision is the trigger) | Wall: "the moment" means the removal does not wait for a batch. | Core |
| OL42 | Rebuild after a restore or import. | A full reconcile: delete every item, re-add only the non-private ones, off the first frame, under the budget `scripts/test.sh --scale` measures. | gap (not built) | `BackupView.swift:183-186` (restore entry) | Low Power: see OL43. Inferred: restore replaces the store wholesale. | Core |
| OL43 | Indexing under Low Power. | Adding and updating items waits for power OK; removing a private item never waits (privacy outranks power). Unruled; the nearest ruling is the automatic-job gate of 11:07 PM Oct 17. See CALL 5. | gap (unruled, not built) | none yet | Low Power. | Core |
| OL44 | Tapping a Spotlight result. | A continue-activity handler maps the item id to `Route.object(id)` with `.jump` (cross-fade) and runs the OL47 checks first. None exists. | gap (not built) | `TesseraApp.swift:107-111` (only `onOpenURL`); no `onContinueUserActivity` | Wall: the handler must re-ask the mask, since the item may be stale. | Builder B |
| OL45 | The URL scheme handler. | `tessera://workout` opens the live workout only with a session; any other URL is dropped without a screen or a sound. | traced | `TesseraApp.swift:107-111`; `Info.plist:32-41`; `BackupView.swift:101` (the Backups links are handled by a local `openURL` action, not by the app) | Pins that no object URL exists today, so none can leak. | Builder B |
| OL46 | G643. The shape of an object URL. | `tessera://object/<uuid>` only; never a title, never `ObjectPath.description` (its segments are slugs of raw titles). Test: `objectURLCarriesOnlyTheId`. | gap (latent) | `ObjectPath.swift:20-23, 32-34, 47-61`; `git grep "\.slug\|ObjectPath"` outside Core finds none | Wall: a private routine's slug would be a URL. Latent: no caller. | Core |
| OL47 | G643. What a link to a private, missing or soft-deleted target opens. | Private: the same label page as in the app (no tell). Missing or deleted: the OL28 line. See CALL 4. | gap (unruled, not built) | `ObjectPage.swift:67-73`; `ObjectStore.swift:93-95` | VoiceOver: the page announces its state. | Builder B |
| OL48 | Share sheet, drag, copy. | None exists for an object (no `ShareLink`, `Transferable`, `draggable`; the only exporter is the Backups copy). If one is added: a private object offers no share, or shares its label only (CALL 7). The Backups file name comes from the picked file's own name, never from a title. | traced | `BackupView.swift:187-193, 259`; `git grep ShareLink` (none) | Wall: a future share of "Knee rehab day" through a link title is the Spotlight leak again. Inferred that the picked file's name carries no title; I did not read how it is named. | Builder B |
| OL49 | Intents on a locked phone. | Six intents require authentication. P16 is closed. | traced | `Intents.swift:11, 91, 114, 135, 189`; `TessTests.swift:257-259` | Updates the Top gaps of `spotlight-widgets-privacy.md`: its first gap no longer holds. | Core |
| OL50 | Exercise entity names. | Class names such as "Bench Press"; a bare word never masks (line 1009). | traced | `Entities.swift:6-55` (P4) | Pins it. | Core |

### 3G. Links, paths, the class inspector, the Objects browser

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL51 | "Linked from" on a plain object lists a private source by its label. | Counts keep private things and hide names (line 61): the row reads "Private note" at the same height and weight. Dead and soft-deleted sources are dropped. | traced | `ObjectPage.swift:297-309`; `ObjectStore.swift:290-298` | Pins line 61 and line 993. The row for a workout source is OL03. | Builder B |
| OL52 | The Notes row's link line. | A note that links to a private task, list or workout shows the label, not `displayTitle`. Test: `noteLinkLineMasksPrivateTargets`. | gap | `NotesView.swift:301-304` | Wall: not in `private-title-masks.md`. A note row is a front screen. | Builder B |
| OL53 | `ObjectStore.displayTitle(of:)` is the shared raw source. | It returns `object.title` as stored and is called from about 25 sites (Home, Lists, Pantry, op summaries, DayStory). Expected: a sibling `shownTitle(of:)` in Core that applies OL05 and falls back like `displayTitle`; raw `displayTitle` becomes internal to Core. | gap | `ObjectPath.swift:64-76`; `NowPage.swift:88-90`; `NotesView.swift:302`; `TrainingActions.swift:227, 258, 295, 588` | Wall: "mask at the source" (decisions 3:35 PM Oct 17, line 921). One chokepoint ends the sweep series. | Core |
| OL54 | The class inspector (ship-list slice 6). | (not built) fields with inherited marked (traced), traits, subclasses, instance count, add a field. Counts keep private things; a class's newest row reads the label (`SideFacts.ClassGlance`). | gap (not built) | `ObjectPage.swift:93-194`; `SideFacts.swift:82-117`; `ship-list-m3.md:12` | Wall: instance count and "n private" are allowed; no title of a private instance. VoiceOver: the count row is one element. | Builder B |
| OL55 | The Objects browser. | (not built) rows from the OL05 function, private rows at 100% ink and the same height (lines 993, 1029), VoiceOver reads "Private note" and nothing else, no swipe-to-reveal. | gap (not built) | no file | Wall and VoiceOver. | Builder B |
| OL56 | Browser search by a typed word. | Matches the shown title only, so a private word matches nothing and proves nothing (the PT9 rule for objects). See CALL 2. | gap (unruled, not built) | no file | Wall. | Builder B + Core |
| OL57 | Browser performance on the full store. | The list is built from the in-memory graph and the OL05 cache (`context.revision`), not a scan per row; `scripts/test.sh --scale` has a row. | gap (not built) | `TesseraContext.swift:25`; `PrivateWords.swift:138-144` | Low Power: no per-frame work. | Core |

### 3H. The side swipe

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| OL58 | G646. Object page and class page declare a side. | Object: LINKS plus the fields the front does not show, via `SideFacts.defaultFields`; class: THE CLASS (count, private count, newest by label, most used) via `ClassGlance`. A private object's side shows its count only. Test: `objectPageDeclaresItsSide`. | gap (not built) | `ObjectPage.swift:62-89`; `SideFacts.swift:62-117` | Swipe-lean: a screen with no side fails review from the SideHost PR (line 185). Existing screens get theirs in the rollout order. | Builder B |
| OL59 | The default side's privacy check misses a workout. | `defaultFields` returns nil only when `ObjectPrivacy.label` is non-nil, which is never for a workout or routine, so a private workout's side would list its fields. Fix with OL01. Test: `defaultSideOfPrivateWorkoutIsCountOnly`. | gap (latent) | `SideFacts.swift:62-66`; `ObjectPrivacy.swift:28-57` | Wall: a side must not show a fact the front hides (line 185). | Core |
| OL60 | The Objects browser and the class inspector declare sides. | (not built) A side holds facts only, never controls, and nothing on it goes to Claude. | gap (not built) | none | Swipe-lean. | Builder B |

## 4. Counts

Rows: 60. By status: traced 11 (OL09, OL10, OL12, OL17, OL18, OL27, OL45, OL48, OL49, OL50, OL51), gap 49. No row has inferred as its first word; the inferred readings are marked inside rows OL06, OL08, OL21 to OL24, OL26, OL42 and OL48. Of the 49 gaps, 14 are (not built) screens or surfaces (OL15, OL39 to OL44, OL47, OL54 to OL58, OL60), 3 are (latent) (OL14, OL46, OL59), and 5 are (unruled) (OL13, OL26, OL43, OL47, OL56; OL04 and OL35 also rest on a proposed string). Gap ids G637 to G646 are the ten ranked rows (OL37, OL01, OL05, OL04, OL03, OL40, OL47, OL19, OL30, OL58).

Rows whose fix is one change: OL01, OL06, OL07, OL59 go with one Core change (a workout and routine branch in `ObjectPrivacy.label`, then the page calling the widened function, OL05). OL19 to OL23 go with one handle rewrite (OL20). OL30 to OL32 go with the one Low Power input in `MotionPolicy` (HS03).

## 5. Open questions (answered by the PRODUCT CALLS below, plus these)

8. Gap ids: I did not read the project mirror. If another open research PR has taken G637 or above, renumber at merge.
9. Order of work. Proposed: (1) OL37 and OL38 (live), (2) OL01 with OL05 (one Core change), (3) OL03 and OL04, (4) the index contract before any index code, (5) the Low Power input.

Things I could not read or did not trace: the project mirror at `/mnt/project-files/tessera` (not used); `RecipePage`, `NoteEditor`, `ExercisePage`, `ListPage` and `RoutineEditor` beyond line 102 (they are separate pages and out of scope); `AppModel.startWorkout`; how the Backups copy file is named; whether any caller can reach a recipe line or step by `Route.object` (OL06 is inferred). Nothing was built or run.

## PRODUCT CALLS

Format follows `docs/product/kitchen-open-calls-batches-oct18.md`: one question, options with one line each, a recommended option with a reason, then an owner. YES on the recommended option takes it as written; each call is reversible.

### CALL 1 (OL13): Does a private object's page lose its plate colour?

| Option | Consequence |
|---|---|
| A. Plain ground for a private page (master's code) | A private page reads as visibly flatter than its neighbours: a small tell, but no colour from a private ingredient mix. |
| B. A fixed neutral wash for every private page, seeded from the id | Private pages look like plain ones in weight; no ingredient colour is read, so nothing leaks. |
| C. The normal wash, but pigments taken from the class, not the contents | Identical look, but a private recipe's page would show the class colour, so some risk of a guess. |

Recommended: B. Reason: line 993 already says a private row has no tell; B keeps that for the header, and the wash never reads contents. Owner: Design, Builder B.

### CALL 2 (OL56): Does a typed word find private objects in the browser?

| Option | Consequence |
|---|---|
| A. Matches shown titles only | Typing a private word finds nothing; the private row is findable only by its label ("Private note"). |
| B. Matches raw titles, shows labels | Typing the word finds the row, which proves it exists and what it is about. |
| C. Private objects are left out of search | Search never lists them; a private note can be reached only by browsing. |

Recommended: A. Reason: it matches the PT9 rule for routines and the "no tell" rulings, and it keeps the private object reachable. Owner: Core, Builder B.

### CALL 3 (OL37, OL40): Which objects does Spotlight, Siri and the App Shortcut list?

| Option | Consequence |
|---|---|
| A. Notes, tasks, lists, recipes and exercises that are not private; routines listed by their masked title only when plain | Smallest useful surface; private ones are absent (not relabelled). |
| B. Every class with a title, private ones left out | Wider, includes workouts and routine titles, which are free text. |
| C. Off by default, a Settings switch per class | Safest, but search stays parked for him until he finds it. |

Recommended: A. Reason: line 1051 says a private object is not indexed at all, and workout titles are free text where a mistake is most likely; widen later. Owner: Core.

### CALL 4 (OL47): What does a link to a private, missing or deleted object open?

| Option | Consequence |
|---|---|
| A. Private: its label page. Missing or deleted: one plain line, "Not on this phone anymore." | Same behaviour as in the app; no tell either way. |
| B. Missing or deleted: go Home with no message | Quiet, but a stale Spotlight tap looks like a bug. |
| C. Private: ask to unlock first | An extra step for a screen that already shows only a label. |

Recommended: A. Reason: it is the in-app behaviour, and the line is announced once under VoiceOver. Owner: Builder B.

### CALL 5 (OL43): Does indexing wait for Low Power?

| Option | Consequence |
|---|---|
| A. Adding and updating wait for power OK; removing a private item never waits | Saves battery, privacy still wins. |
| B. Everything runs anyway | Simplest; index work is small, but it breaks the automatic-job gate. |
| C. Everything waits, including removal | A private item could stay in the index for hours on a low battery. |

Recommended: A. Reason: it follows the automatic-job gate (11:07 PM Oct 17) while keeping the line-1051 "the moment" rule. Owner: Core.

### CALL 6 (OL35): How does "New subclass" behave?

| Option | Consequence |
|---|---|
| A. Tap creates, thing-first receipt, 10 s UNDO, announced under VoiceOver | Matches one UNDO slot (line 243); a stray tap costs nothing. |
| B. A hold key with the named action "Create" | Safer against stray taps, but it creates and does not replace data (line 1011), so it is more friction than the rule asks. |
| C. Hide it on built-in classes | Fewer stray classes, but removes a path he may want. |

Recommended: A. Reason: it is a change that is undone, which is exactly what the slot is for. Owner: Builder B.

### CALL 7 (OL48): If an object can be shared, what leaves?

| Option | Consequence |
|---|---|
| A. A private object offers no share | Nothing to leak; a visible absence is a small tell. |
| B. A private object shares its label and a link, no words | Works everywhere, reads "Private note". |
| C. Ask first on a private object | A prompt that itself names the kind. |

Recommended: A. Reason: the export already leaves private things out (line 51), so sharing following the same rule needs no new copy. Owner: Builder B.
