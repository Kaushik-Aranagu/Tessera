# Build A1 brief: schema changes in the op log, with undo

For: Core engine
Date: 2026-10-15. Checked against origin/master `0950ba7` (ship list A1 was checked against `5956550`).
Inputs: `../product/ship-list-build.md` (A1), `app-from-a-sentence.md` section 5, `add-a-field.md` pitfalls 1 and 3.
All paths below are under `TesseraCore/Sources/TesseraCore/`.

## What master gives us, and what is missing

- **Values are keyed by field id, not name.** Good news. `FieldValues.storage: [UUID: FieldValue]` (Model/FieldValue.swift:81-100), "Values are stored by `id`, never by name" (Model/Models.swift:151). Rename and soft remove never need to touch `valuesData`.
- **`key` is what formulas and actions use.** Formulas look fields up by `key` (Engine/ObjectStore.swift:195-197); actions write by key (Actions/Transaction.swift:40-48). So rename changes `name` only and the `key` never changes.
- **Undo is a guarded replay of inverse ops** (Actions/ActionEngine.swift:136-150, 202-244). Undo sets the record `undone`, redo sets it `committed`; the rows stay.
- **Objects already soft-delete** with cascade to children and a matching restore (Engine/ObjectStore.swift:52-72). Links are not deleted with the object, so restore brings them back working.
- **Upgrades re-add missing shipped fields by stable id** and refresh name, unit, options and default unless `isUserModified` (Catalog/SystemCatalog.swift:319-382).

### Blockers on master (fix in A1)

1. **`Op` has no schema cases** and `objectID` assumes an object (Actions/Op.swift:22-53).
2. **`ActionEngine.apply` starts with `guard let object = store.object(id:)`** (Actions/ActionEngine.swift:212), so any non-object op would come back "skipped" as a conflict.
3. **Replay is partial, never all-or-nothing** (Actions/ActionEngine.swift:202-208). "Undo with a foreign object changes nothing" needs a check pass before any op is applied.
4. **No soft delete for schema.** No `retiredAt` on ClassDef, FieldDef or ViewDef, and the GRDB tables have no such column (Model/TesseraDatabaseSchema.swift:14-22, 36-38). The only delete is a hard one that drops fields, views and incoming links and detaches objects (Model/TesseraContext.swift:98-106).
5. **Nothing filters retired schema.** `effectiveFields` (Engine/ClassResolver.swift:64-104), `descendants` (:44-55), `allClasses` (Engine/ObjectStore+Lifecycle.swift:30-32), and the UI reads `subclasses` and `allClasses()` directly (Features/Objects/ObjectPage.swift:67, Features/Command/BottomChrome.swift:641, TesseraTess/TessTools.swift:239).
6. **Key lookup is first-wins.** `byKey` uses `uniquingKeysWith: { first, _ in first }` (Engine/ObjectStore+Caches.swift:43). A retired "rating" and a new "rating" would silently collide unless retired fields leave the resolver.
7. **Schema writes bypass the op log.** `createClass` writes straight to the context (Engine/ObjectStore+Lifecycle.swift:41-50); there is no add-field or rename API at all; `markUserModified` exists (Catalog/CatalogPackage.swift:14-26) but has no callers.
8. **`isUserModified` is one Bool per row** (Model/Models.swift:104, 210) with no memory of which edit set it, so undo cannot simply clear it.
9. **Caches.** `classInfo` is cached per class id (Engine/ObjectStore+Caches.swift:36-46); every schema op must call `invalidateCaches()` (Engine/ObjectStore.swift:30) and `noteChange()`.
10. **FieldDef has no package marker.** A shipped field is only recognisable as `owner.systemKey != nil` plus `id == stableID("<systemKey>.<key>")` (Catalog/SystemCatalog.swift:326).
11. Minor: `OpRecord.ops` decodes with `try?` (Model/Models.swift:576-578), so one unknown case drops a whole record's ops. Fine on one device; matters for backups read by an older build.

## 1. The smallest op shapes

Nine new `Op` cases. Each carries enough to reverse itself, like the object ops. The snapshot cases exist so the log can rebuild schema later (export, sync); undo itself only flips `retiredAt`.

```swift
public struct ClassSnapshot: Codable, Hashable, Sendable {
    var id: UUID; var name: String; var parentID: UUID?; var symbolName: String
    var colorRole: String; var traits: [String]; var packageID: String?   // "me" for user classes
}
public struct FieldSnapshot: Codable, Hashable, Sendable {
    var id: UUID; var ownerID: UUID; var name: String; var key: String; var kind: String
    var sortIndex: Int; var unit: String?; var options: [String]; var targetClassID: UUID?; var isRequired: Bool
}
case createClass(ClassSnapshot)                        // inverse: retireClass(id)
case retireClass(class: UUID)                          // inverse: reviveClass
case reviveClass(class: UUID)                          // inverse: retireClass
case addField(FieldSnapshot)                           // inverse: retireField(id)
case retireField(field: UUID)                          // inverse: reviveField
case reviveField(field: UUID)                          // inverse: retireField
case renameClass(class: UUID, old: String, new: String)
case renameField(field: UUID, old: String, new: String) // name only; key never changes
case setModified(schema: UUID, old: Bool, new: Bool)   // emitted only when the flag flips
```

- `objectID` stays non-optional and returns the class or field id, so `OpRecord.objectIDs` and `isPending(_:)` work for ghost classes with no new column. Ids are UUIDv7 and never clash.
- New column `retiredAt REAL` on `classDef` and `fieldDef` (migration `v3`, after `v2` at Model/TesseraDatabaseSchema.swift:46). Hard delete stays only in `resetUserData`.
- **Remove field** = one record `[retireField(f)]`. Values stay in every object's `valuesData`.
- **Remove class** = one record: `softDelete(o)` for every live object of the class (class object included), then `retireClass(c)`. Fields need no ops: a retired class hides its own fields. Refused with a live subclass ("Move or delete Fern first") or when shipped (`systemKey != nil`), since actions look system classes up by key (Actions/Transaction.swift:26-29).
- **Remove a shipped field** is refused in A1 (actions write keys such as `endedAt`, Actions/ActionEngine.swift:176). Hiding shipped fields is a later view setting.
- **Rename of shipped schema** appends `setModified(old: false, new: true)` after the rename, so the next package refresh keeps the new name.
- Views (`createView`, `retireView`, `reviveView`) copy the class pattern exactly; add them when A4 needs a starter view.

**Engine changes.** `apply` switches on the op first and looks up the right row per case. Records that hold any schema op get a check pass: every op is guarded first, and if any fails nothing is applied and the outcome is a new `.conflict(skipped: [Op])`. Object-only records keep today's partial replay.

**Guards (guarded replay).**
- `retireClass`: class live, no live subclass, no live object of it other than ones this record soft-deletes or creates.
- `reviveClass`: class retired and its parent live. `reviveField`: field retired, owner live, and no live field with the same `key` in the owner's lineage or its subclasses.
- `retireField`: field live. `renameX`: current name equals `old`.
- `setModified` on undo: only flips back if no other non-undone record has a `setModified` for the same id; otherwise it is skipped quietly (the flag is still needed), not a conflict.

## 2. What undo and redo do to rows already written

- **Remove field, then undo:** `reviveField` clears `retiredAt`; every value is still in `valuesData` under the field id, so all values come back. Redo hides them again, still stored.
- **Add field, write values, undo the add:** the field retires, `value(key)` returns nil and writes by key throw `unknownField`, but stored values stay. Redo revives the same id and the values show again. Undoing the later `setValue` records still works while retired, since they replay by field id (Engine/ObjectStore.swift:323-328).
- **Rename:** values, links (`ObjectLink.fieldID`, Model/Models.swift:377-380) and formulas never see the name, so nothing moves.
- **Remove class with objects:** objects soft-delete with their children at one instant; undo revives the class first (reverse order), then restores the objects, and `restore` brings back only children deleted at that same instant (Engine/ObjectStore.swift:64-72). Objects deleted earlier stay deleted.
- **Add class, then he adds objects, then undo the add:** conflict, nothing changes; the page offers "Remove Plant and its 4 plants?" as a separate, user-only remove.
- **Refs into a removed class:** another class's ref field keeps its links; the target shows as "(deleted)" until undo.

## 3. System package upgrades and isUserModified

- Seed decides "missing" from `ownFields` ids (Catalog/SystemCatalog.swift:324). Retired fields stay in `ownFields`, so soft retire is never resurrected. Seed must never clear `retiredAt`.
- `refresh` overwrites shipped names unless the flag is set (Catalog/SystemCatalog.swift:362-382). That is why every rename of shipped schema emits `setModified`.
- Undoing the only edit clears the flag, so later package renames apply again. Undoing one of two edits keeps it.
- User fields added to a shipped class are never touched by seed (it only checks stable ids). Risk: a later package field with the same `key` loses to first-wins `byKey`; the seed should log it and A2's validator should reserve shipped keys.

## 4. Twenty fixtures

Setup unless noted: user class Plant (P, packageID "me") with field species (S, key `species`); objects o1 (S = "Monstera"), o2 (S = "Pothos"). System class Set with shipped field rpe (name "RPE"). Rn is a record; "hidden" means retired with values kept.

| # | Ops | After undo | After redo |
|---|---|---|---|
| 1 | R1 createClass Fern (parent P) | Fern retired, not in allClasses or P's subclasses | Fern live, same id |
| 2 | R1 createClass Tree + addField height + addField girth | Tree retired; its fields hidden with it | All live, same 3 ids |
| 3 | R1 addField light to P; R2 set o1.light = "bright"; undo R1 | light hidden; value("light", o1) nil; o1 data still has light id = "bright" | light live; o1 shows "bright" |
| 4 | As 3, but undo R2 then R1; then redo R1 only | o1 has no light entry | light live, o1 empty for light |
| 5 | R1 retireField S | S live; o1 "Monstera", o2 "Pothos" | S hidden; both values still in data |
| 6 | R1 renameField S "species" to "Variety" | name species, key species, values same | name Variety, key species; a formula on `species` still evaluates |
| 7 | R1 rename S to Variety; R2 rename to Kind; undo R1 first | Conflict (name is Kind, not Variety); nothing changes | Undo R2 then R1: name species; redo both: Kind |
| 8 | R1 renameClass P to Houseplant | Name Plant; o1, o2 and ids unchanged | Name Houseplant |
| 9 | R1 remove P (o1, o2 live; o3 deleted last week) | P live; o1, o2 restored with values and links; o3 still deleted | P retired; o1, o2 soft-deleted again |
| 10 | o1 has child Note n1; R1 remove P | o1 and n1 restored together (same deletedAt) | o1 and n1 deleted again |
| 11 | Fern (child of P) live; remove P | Refused before any write; no record | n/a |
| 12 | R1 createClass Tree; R2 create t1 of Tree; undo R1 | Conflict: t1 is foreign; Tree and t1 unchanged, R1 still committed | Undo R2 then R1 succeeds; redo R1 then R2 brings both back |
| 13 | perform createClass Tree + 3 fields `pending: true`; discard | Not in allClasses, resolver, catalog pack or isPending; record undone | n/a |
| 14 | R1 retireField S; R2 addField S2 (key `species`); set o1.S2 = "Fern"; undo R1 | Conflict: key clash with live S2; nothing changes | n/a |
| 15 | R1 retireField S; undo R1; R2 set o1.species = "Fern"; redo R1 | (after the undo) S live, o1 "Monstera" | S hidden; o1 data holds "Fern"; undo R1 again shows "Fern" |
| 16 | R1 createClass Tree; R2 addField height to Tree; undo R1 (no objects) | Tree retired; height hidden with it; R2 still committed | Tree and height live |
| 17 | R1 renameField Set.rpe to "Effort" (+ setModified false to true) | Name RPE, flag false; seed with a package rename now applies it | Name Effort, flag true; seed keeps Effort |
| 18 | R1 rename rpe to Effort; R2 rename to "Effort 1-10"; undo R2, then undo R1 | After R2 undo: Effort, flag true. After R1 undo: RPE, flag false | Redo R1: Effort, flag true |
| 19 | R1 addField mood to Set (user field); seed with version + 1; undo R1; seed again | mood hidden; seed does not bring it back | mood live; seed leaves it alone |
| 20 | Pot class with ref field plant; pot1 links o1; R1 remove P | pot1's plant link works again; o1's backlinks list pot1 | pot1 keeps the link row; target shows "(deleted)" |

Also asserted in every fixture: `store.revision` moved and `classInfo` was rebuilt (no stale field lists).

## 5. The smallest Core slice and done-when tests

**Slice A1 (Engine only, no UI):**
1. The nine `Op` cases, snapshots, `objectID` for schema ops, and `.conflict` on `ReplayOutcome`.
2. `retiredAt` on ClassDef and FieldDef, migration `v3`, row mapping, export fields.
3. Resolver, `allClasses`, `descendants` and `byKey` skip retired rows; `includingRetired:` flag for the inspector and history.
4. `Transaction` gains `createClass`, `addField`, `renameClass`, `renameField`, `removeField`, `removeClass`, each emitting ops, invalidating caches and flagging shipped edits. `ObjectStore.createClass` becomes a wrapper over it.
5. User-only actions `AddClass`, `AddField`, `RenameClass`, `RenameField`, `RemoveField`, `RemoveClass`, left out of `ActionRegistry.descriptors` so no model route can call them (Actions/ActionRegistry.swift:6-25).
6. Engine: per-case `apply`, the check pass for schema records, and the `setModified` rule.

Out of A1: kind change with conversion, field reorder, parent change, traits and symbol edits, views (same pattern, add with A4), sync.

**Done when (Swift Testing, `TesseraCore/Tests/TesseraCoreTests/SchemaOpsTests.swift`, beside ActionEngineTests.swift):**
- All 20 fixtures pass as parameterized rows, each checking schema and object values after undo and after redo.
- A pending class with 3 fields, discarded, leaves nothing visible to any query (fixture 13).
- Commit, undo, redo keeps every class, field and object id (fixtures 1, 2, 9).
- Undo with a foreign object returns `.conflict` and changes no row: compare a full export before and after (fixture 12).
- No schema op ever writes `valuesData` (spy on `setRaw` across all 20 fixtures).
- Reopen the GRDB store after fixtures 5, 9 and 17: retired state and flags survive a reload.
- Seed at version + 1 after fixtures 17 to 19 keeps the person's edits and never revives a retired row.
- `scripts/test.sh --package-only` ends "All green".

## Open questions

- Should a removed shipped field be hideable in A1 (as a view setting), or stay refused until A5?
- Field `key` reuse: allow a new field to take a retired field's key (fixture 14 then blocks undo), or reserve retired keys for ever?
