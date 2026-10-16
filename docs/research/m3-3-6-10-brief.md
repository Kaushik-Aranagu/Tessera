# M3 slices 3, 6 and 10: add a field, class inspector, starting shapes, engine brief

For: Core engine. Date: 2026-10-15. Research lab.
Inputs: `../product/ship-list-m3.md` (slices 3, 6, 10), `../product/ship-list-build.md` (A1), `build-a1-brief.md` (blocker numbers below are its numbers), `add-a-field.md`, `lists-daily.md`, `lists-templates.md`, `../product/decisions.md`. Repo `origin/master` at `e55d6d4`. Paths are under `TesseraCore/Sources/TesseraCore/` unless they start with `Features/` or `TesseraTess/`.

## What master has today (checked)

- **`Op` has 7 object cases only** (Actions/Op.swift:22-30) and `objectID` assumes an object (:46-53). `ActionEngine.apply` opens with `guard let object = store.object(id:)` (Actions/ActionEngine.swift:212); replay collects skips into `.partial` (:202-208).
- **Schema writes skip the log twice.** `ObjectStore.createClass` inserts straight into the context (Engine/ObjectStore+Lifecycle.swift:41-50). Worse, the class page's "New subclass" builds a `ClassDef` and calls `model.context.insert` itself, with no `invalidateCaches()` (Features/Objects/ObjectPage.swift:129-140). There is no add-field, rename or hide API anywhere.
- **No `retiredAt`.** GRDB tables `classDef`, `fieldDef`, `viewDef` (Model/TesseraDatabaseSchema.swift:14-22, 36-38); last migration is `v2` (:46-50).
- **Resolver.** `effectiveFields` reads every own field (Engine/ClassResolver.swift:64-104); `byKey` keeps the first of a key (Engine/ObjectStore+Caches.swift:43). Overrides (`overridesFieldID`) already exist (ClassResolver.swift:69-85), so "overlay" has a home.
- **Shipped fields are written by key from code.** `LogSet` writes `rpe` on every set, even when nil (Actions/TrainingActions.swift:66), and `Transaction.set` throws `unknownField` before it compares values (Actions/Transaction.swift:40-43). So a hidden shipped field must stay resolvable by key, or every logged set fails.
- **The class page exists**: lineage header, properties with inherited fields marked "↑" (Features/Objects/ObjectPage.swift:360-366), subclasses read straight from `classDef.subclasses` (:67). No instance count, no traits line. `objects(of:includingSubclasses:)` gives the count (Engine/ObjectStore.swift:77).
- **Views and queries.** `ViewDef` has `layout` and `filterData` only (Model/Models.swift:443-489); nothing on master ever creates one (the only `ViewDef(` call is the DB loader, Model/TesseraDatabaseSchema.swift:228). There is no query AST: `answerQuery` counts one class by `createdAt` and says the AST is M3 slice 4 (TesseraTess/TessTools.swift:230-255).
- **Lists.** `CreateList` makes a `List` object (Lists/Lists.swift:73-95); grammar already reads "list: packing" and "new list films" (TesseraTess/TessGrammar+Kitchen.swift:23-27). No reusable flag yet (Lists slice 4).
- **Paths.** `ClassResolver.path` uses the lineage only (Engine/ClassResolver.swift:112-116); no `/me/` prefix exists yet, though the M3 defaults say user classes live there.
- **Count note.** The A1 brief lists 11 numbered blockers (10 plus one minor); `decisions.md` says "six". This brief uses the 11.

**Product's A1 calls (decisions.md, 4:13 PM PT):** a shipped field can be hidden, never deleted, and hiding is undoable. A new field never reuses a retired field's key. Hard delete stays only in `resetUserData` (Engine/ObjectStore+Lifecycle.swift:53-69).

## Slice 3: Add a field to any class

> "One 'add…' row: type 'rating: 4' or 'due friday' and the type is inferred ... added as an overlay with undo."

**Data and ops.** One migration `v3`: `retiredAt REAL` on `classDef`, `fieldDef` and `viewDef` at once, so slices 6 and 10 need no second migration. Ops: `addField(FieldSnapshot)`, `retireField(field:)`, `reviveField(field:)`, plus one case the A1 nine lack: `setFieldOptions(field:old:new:)`, because a choice grows as he types new words. The value goes in the same record as today's `setValue`. Pure parser `FieldInference.guess(_ text:, on: ClassDef, store:) -> FieldGuess {name, key, kind, unit, value, reuse: UUID?, revive: UUID?, alternatives}`; the preview cycles `alternatives`. User-only action `AddField(object:, guess:)`, left out of `ActionRegistry.descriptors` (Actions/ActionRegistry.swift:6-25).
**Rules.** Key = camelCase of the name, unique against live and retired fields of the lineage and subclasses; a clash gets a suffix (`rating2`), never a reused key. A name that matches a live field reuses it (setValue only). A name that matches a retired field offers "Bring back Rating?" and revives it (same id, old values return). A retired user field leaves the resolver; a hidden shipped field stays in `byKey` and only leaves display. A user field on a shipped class is the overlay: its id is not a `stableID`, so seed never touches it (Catalog/SystemCatalog.swift:324-334).

Setup: user class Plant (fields Species, key `species`), objects o1 "Monstera", o2 "Pothos"; Pot class with object "Blue pot"; shipped Set. Now = Thu 15 Oct 2026 18:00 local.

| # | Typed on | Expected state |
|---|---|---|
| 1 | o1: `rating: 4` | New Rating, number, key `rating`; o1 = 4, o2 empty; one record [addField, setValue] |
| 2 | o1: `due friday` | Due, date, key `due`; o1 = Fri 16 Oct 2026 00:00 local |
| 3 | o1: `pot weight 2.5 kg` | Pot weight, mass, unit kg, stored 2.5 |
| 4 | o1: `soak 45 min` | Soak, duration, stored 2700 s |
| 5 | o1: `light: bright` | Light, choice, options [bright] |
| 6 | o2: `light: low` (after 5) | Reuses Light; one record [setFieldOptions [bright] to [bright, low], setValue] |
| 7 | o1: `pot @Blue pot` | Pot, ref, target Pot; setLinks o1 to Blue pot |
| 8 | o2: `species Calathea` | No new field; setValue on Species (reuse by name, case-insensitive) |
| 9 | set s1: `rpe 8` | Reuses shipped RPE; Set gets no new field; `isUserModified` unchanged |
| 10 | set s1: `mood good` | User field Mood on Set; seed at version + 1 leaves it, flag stays false |
| 11 | o1: `notes: water less in winter` | Reuses inherited Notes (Thing, richText); no new field |
| 12 | Fixture 1, then undo | Rating retired; `value("rating", o1)` nil; o1 data still holds 4 under its id |
| 13 | After 12, o2: `rating: 5` | Preview "Bring back Rating?"; accept: reviveField (same id), o1 shows 4, o2 = 5 |
| 14 | After 12, o2: `rating: 5`, choose "new" | New field, key `rating2`, never `rating`; reviving the old Rating later cannot clash |
| 15 | o1: `due soon` (Due is a date) | Preview "Due is a date"; no write |
| 16 | o1: `12` | Preview asks for a name; no write |

**Grammar or Tess rows.** None in TessGrammar for M3: the add row is its own parser on object and class pages. Rows for that parser are fixtures 1 to 16 plus `yes`/`no` as bool (FieldKind.bool exists; DEFAULT, the ship list's seven kinds omit it). There is no volume kind, so `500 ml` is a number with unit ml.
**Done when.** `AddFieldTests.swift`: the 16 rows as a parameterized table, each checked after undo and redo; no schema op writes `valuesData` (spy on `setRaw`); reopen GRDB after 12 and 13 and the state holds; `LogSet` still works with RPE hidden; `swift test` green.
**A1 blockers.** Clears 2 (per-case `apply`), 4 (`retiredAt` and `v3`), 6 (unique keys, retired user fields out of `byKey`), 9 (every schema op in `Transaction` calls `invalidateCaches()`). Partly 1 (field cases), 5 (resolver, not class lists), 7 (add-field API).

## Slice 6: Class inspector

> "Opens any class: fields (inherited marked), traits, subclasses, instance count; add a field (slice 3) from here."

**Data and ops.** Read model `ClassInspector.summary(of:) -> {fields: [ResolvedField + declaringClass + isShipped + isHidden], ownTraits, inheritedTraits, subclasses (live), count, ownCount, suggestions (max 3 from parent and siblings)}`; `includingRetired:` shows hidden rows faintly. Ops: `createClass(ClassSnapshot)`, `retireClass`, `reviveClass`, `renameClass`, `renameField` (name only, key never moves), `setModified(schema:old:new:)`. `FieldDef.isShipped` is derived: `owner.systemKey != nil && id == stableID("<systemKey>.<key>")` (Catalog/SystemCatalog.swift:326). "New subclass" (Features/Objects/ObjectPage.swift:134-139) and `ObjectStore.createClass` both go through `Transaction.createClass`. Hide = `retireField` (+ `setModified` when shipped). Class removal, kind change and reorder stay out (A5).

Setup: Thing, Plant (Species, Light), Fern under Plant (Frond length); o1, o2 Plant, f1 Fern; shipped Set.

| # | Action | Expected state |
|---|---|---|
| 1 | Inspect Plant | Notes (↑ Thing), Species, Light; traits none; subclasses [Fern]; count 3, own 2 |
| 2 | Inspect Fern | Notes ↑ Thing, Species ↑ Plant, Light ↑ Plant, Frond length; count 1 |
| 3 | New subclass "Cactus" of Plant | One record [createClass]; in Plant's subclasses and `allClasses`; caches rebuilt |
| 4 | Undo 3 | Cactus retired; gone from subclasses, `allClasses`, `descendants`, `answerQuery` lookup |
| 5 | Rename Plant to Houseplant | renameClass; ids, objects, paths by id unchanged; undo gives Plant |
| 6 | Hide Light (user field) | retireField; Fern stops showing Light; o1's value kept; undo shows it |
| 7 | Hide shipped Set.RPE | [retireField, setModified false to true]; hidden in inspector; `LogSet` still writes rpe; seed v+1 keeps it hidden |
| 8 | Undo 7 | RPE shows; flag false (only edit); seed then refreshes name again |
| 9 | Rename Set.RPE to Effort, then to Effort 1-10; undo the second | Effort, flag true (A1 rule: undoing one of two edits keeps it) |
| 10 | Undo rename 1 while rename 2 live | `.conflict`; nothing changes |
| 11 | Add `rest time` from the inspector (no value) | Slice 3 path, duration, no setValue in the record |
| 12 | Inspect List (shipped, no own fields) | Notes ↑ Thing only; count equals live lists (Groceries included, Kitchen/Groceries.swift:24-26) |

**Grammar or Tess rows.** None; Tess reads schema only through slice 7 and 8 later.
**Done when.** `ClassInspectorTests.swift` passes the 12 rows; ObjectPage no longer calls `context.insert` for classes (grep test or lint rule); every list of classes the UI and Tess read (ObjectPage.swift:67, Features/Command/BottomChrome.swift:641, TesseraTess/TessTools.swift:239) skips retired rows; seed v+1 after 7 to 10 keeps edits and never clears `retiredAt`.
**A1 blockers.** Clears 1 (class and field cases), 5 (`allClasses`, `descendants`, `subclasses` filtered), 7 (both class-create sites, rename, `markUserModified` replaced by `setModified`), 8 (`setModified` op and its undo rule). Partly 10 (derived `isShipped`; no stored marker).

## Slice 10: New app from a starting shape

> "Tracker (number over time) and Log (dated notes) create a user class with a default view; List creates a `List` object from the Lists app, not a new class."

**Data and ops.** Tracker = class (parent Thing, traits trackable and measurable, `packageID "me"`) with Amount (number, or the kind slice 3 infers from the first entry) and At (date), plus a list view sorted `-at`. Log = class under Note (inherits Body and About, Catalog/SystemCatalog.swift:203-206) with On (date), view sorted `-on`. List = `CreateList`, nothing else. New op `createView(ViewSnapshot {id, classID, name, layout, filterData})` with `retireView`/`reviveView`; sort lives in `filterData` JSON (DEFAULT from the build list). Everything, including the first entry if typed, is one record with an all-or-nothing check pass and a new `ReplayOutcome.conflict(skipped:)`. Path: classes with `packageID "me"` get `/me/` first.

| # | Shape and text | Expected state |
|---|---|---|
| 1 | Tracker `water` | Water (Thing, trackable, measurable, packageID me); Amount number, At date; view list `-at`; one record, 4 ops; no objects |
| 2 | Tracker `water 500 ml` | As 1, Amount unit ml; object w1 Amount 500, At now; one record, 7 ops |
| 3 | Tracker `sleep 7.5 h` | Amount is duration; first object 27000 s |
| 4 | Tracker `weight 78.4 kg` (no BodyWeight yet) | Weight with Amount mass, kg; after slice 1 lands, opens BodyWeight instead, no write |
| 5 | Log `dreams` | Dreams under Note; own field On date; view list `-on` |
| 6 | Log `gratitude: slept well` | Class plus first object, Body "slept well", On today |
| 7 | List `films` | `CreateList` Films; `allClasses` count and ViewDef count unchanged |
| 8 | List `groceries` (exists) | Opens the Groceries list; no record |
| 9 | Tracker `plant` (Plant exists) | Opens Plant; no record |
| 10 | Tracker `set` | Refused: "Set is built in"; no record |
| 11 | Undo 2 at once | Water, fields and view retired; w1 soft-deleted; redo brings back the same ids |
| 12 | 1, then he logs w1 (own record), then undo 1 | `.conflict`; Water and w1 unchanged; record 1 still committed |
| 13 | 1 as pending, discarded | Not in `allClasses`, resolver, inspector or `isPending` |
| 14 | `ClassResolver.path` of Water | `/me/water` |

**Grammar rows (TessGrammar, beside the list rule at TessGrammar+Kitchen.swift:24).**

| Phrase | Today on master | Resolution |
|---|---|---|
| `new tracker water 500 ml` | No shape rule; falls to later rules or the model | Tracker shape, ghost waits for a tap (schema never auto-commits) |
| `new log dreams` | No shape rule; later rules or the model | Log shape |
| `new list films` / `list: films` | `CreateList` (exists) | Unchanged |
| `log bench 80x5` | lift | Unchanged: "log" alone is never a shape; only `new log` |
| `track my plants` | No rule; later rules or the model | Not here: Build A3's route. Offline, it opens these shapes with "plants" filled in |

**Done when.** `StartingShapeTests.swift` passes the 14 rows and the grammar table; fixture 12 compares a full export before and after the undo; no List shape ever creates a class; `scripts/test.sh --package-only` ends "All green".
**A1 blockers.** Clears 3 (check pass and `.conflict`). Adds view ops early (A1 had left views to A4).

## Every A1 blocker against the slice that clears it

| # | Blocker (build-a1-brief.md) | Cleared by |
|---|---|---|
| 1 | `Op` has no schema cases | Partly 3 (fields), fully 6 (classes); views come with 10 |
| 2 | `apply` assumes an object | 3 |
| 3 | Replay is partial, not all-or-nothing | 10 (first multi-op schema record) |
| 4 | No `retiredAt`, only hard delete | 3 (migration `v3` on all three tables) |
| 5 | Nothing filters retired schema | Partly 3 (resolver), fully 6 (class lists, UI, Tess) |
| 6 | `byKey` first-wins | 3 (keys never reused, so the collision cannot happen) |
| 7 | Schema writes bypass the op log | Partly 3 (add field), fully 6 (both create sites, renames) |
| 8 | `isUserModified` is one Bool | 6 (`setModified` op) |
| 9 | Caches not rebuilt on schema ops | 3 (rule in `Transaction`); 6 fixes ObjectPage.swift:137 |
| 10 | FieldDef has no package marker | Partly 6 (derived `isShipped`); a stored marker is still open after 3/6/10 |
| 11 | `OpRecord.ops` decodes with `try?` | Still open after 3/6/10 (Model/Models.swift:576-578) |

**Build order: 3, then 6, then 10.** Slice 3 clears 4 blockers fully (2, 4, 6, 9) and starts 3 more, so it goes first. Slice 6 finishes 1, 5, 7 and 8. Slice 10 clears 3 and brings view ops. After all three, A1 is down to blocker 11 and the stored half of 10, plus the class remove action and fixture 14 of the A1 brief, which "never reuse a key" turns from a conflict into a plain revive.
