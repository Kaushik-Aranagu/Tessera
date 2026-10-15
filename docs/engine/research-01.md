# Engine research 01: sync, schema evolution, typed hot paths, performance, undo

Scope: `TesseraCore/Sources/TesseraCore` on branch `core/object-model` (ClassDef / FieldDef / ObjectRecord /
ObjectLink / ViewDef, ClassResolver, ObjectStore, Formula, SystemCatalog, TrainingLedger).
Sources checked with Apple docs (sosumi) are linked inline. Statements marked *(inferred)* are my reading of
behaviour that Apple does not document precisely.

## Top 5 changes to make next (ranked)

1. **Make `values` decode tolerant and never lose unknown entries.** Today one unknown `FieldValue` case
   (written by a newer app version on another device) makes `try? JSONDecoder().decode` return nil, `values`
   returns an empty `FieldValues`, and the next `set` re-encodes that empty dict, **wiping every value on the
   object, and then syncing the wipe**. Verified: decoding `[UUID: FieldValue]` with one unknown case yields nil.
   Fix: custom per-entry decode that keeps undecodable entries as raw JSON and writes them back untouched;
   add a `valuesFormat: Int = 1` attribute. Also note `[UUID: X]` encodes as a flat `[key, value, key, value]`
   array, not an object; switch storage to `[String: FieldValue]` (uuidString keys) now, while there is no
   production data.
2. **Fix the O(n) `classObject(of:)` lookup and add a resolved-schema cache.** `classObject(of:)` filters
   `classDef.objects` (every Set ever logged) and runs on *every* inherited/default value read, for every class
   in the lineage. With 40k sets, reading `rpe`/`isWarmup` across history is roughly 40k x 40k relationship
   walks. Give class objects a deterministic id (`stableID("classObject.\(classID)")`) or a dedicated
   `ClassDef.classObject` to-one relationship, and put lineage, fields-by-key, fields-by-id, parsed formulas
   and class-object ids in a per-container `SchemaCache` invalidated on any ClassDef/FieldDef change.
3. **Add a sync-time dedupe pass before turning CloudKit on.** Deterministic UUIDs do *not* merge records:
   Core Data names each CKRecord from its own identifier (`CD_<Entity>_<UUID>`), not from our `id` attribute
   ([Reading CloudKit Records for Core Data](https://developer.apple.com/documentation/coredata/reading-cloudkit-records-for-core-data)).
   Two devices that both seed will sync **two** "Bench Press" ClassDefs and two copies of every system
   FieldDef, with the same `id`. Dedupe ClassDef by `systemKey`, FieldDef by `id`, class objects by
   class, and re-point relationships to a deterministic winner.
4. **Add a local, derived `TrainingFact` projection (indexed) and route TrainingLedger through it.** One row
   per set: `setID, entryID, workoutID, exerciseClassID, date, weight, reps, rpe, e1rm, isWarmup`, with
   `#Index`. Rebuilt from writes and from remote-change history; stored in a **non-synced** configuration.
   This replaces the native-inheritance question (section 3) and fixes sessions/records/trends/weekly volume.
5. **Put every write behind a typed `EngineAction` executor with inverse actions** registered on an
   `UndoManager` (the app's, or `UndoableIntent.undoManager`), with ModelContext's automatic undo off. Tess,
   App Intents, and the UI all call the same executor (section 5). Do this before more UI writes `ObjectStore`
   directly, because retrofitting is the expensive part.

Close runners-up: soft delete for ClassDef/FieldDef; `VersionedSchema` V1 now; formulas stored by field id.

---

## 1. CloudKit sync risks

How SwiftData syncs: it uses `NSPersistentCloudKitContainer`; each model becomes a `CD_<Entity>` record,
to-one relationships become foreign-key fields, and many-to-many becomes CDMR join records
([Syncing model data across a person's devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)).
Relationships may arrive out of order and are not applied atomically, so all must be optional with inverses
([Creating a Core Data Model for CloudKit](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit)).
The current models satisfy the static rules: no `.unique`, all defaults/optionals, inverses everywhere.

**JSON blob `valuesData`.** Conflict resolution is at record-attribute granularity at best *(inferred: the
mirroring exporter sends changed keys; the same key from two devices resolves last-writer-wins)*. The whole
blob is one attribute, so concurrent edits to *different fields of the same object* lose one side.
- Where it actually bites for one person: watch + phone during a workout (watch sets `endedAt`, phone edits
  notes on the same Workout), and class objects (editing Bench Press cues on iPad while the phone writes
  muscles). Separate Set objects do not conflict, since each set is its own record.
- Recommendation: keep the blob (per-field rows would be ~160k ValueRow records for 40k sets, plus
  CloudKit chatter and rate limits, see TN3163's `ActivityRateLimitPolicy`), but (a) only write the blob when
  the value actually changed (the `values` setter currently bumps `updatedAt` and re-encodes on every set,
  even for no-op writes), (b) never write in response to a read (`ensureClassObject` currently mutates
  `isClassObject` on read paths), and (c) promote the few multi-device-hot fields of system classes into real
  columns later if conflicts show up in practice. Drop `.externalStorage`: blobs are a few hundred bytes, and
  CloudKit already moves oversized values to a `_ckAsset` field by itself.
- The tolerant decode in Top-5 #1 matters more for sync than for LWW: mixed app versions are guaranteed
  once two devices are involved.

**ObjectLink rows.** A good CloudKit shape (one-to-many foreign keys, no CDMR). Risks:
- `setLinks` deletes and re-inserts with fresh ids. Two devices editing the same refList offline produce the
  **union** of both new sets (each deletes only the links it knew about). `.ref` can end up with 2 links.
  Fix: diff instead of delete-all (keep rows whose target is unchanged, update `sortIndex`), and dedupe at
  read time by `(from, fieldID, target)`; for `.ref`, pick the newest `createdAt` deterministically.
- A link can arrive before its target, so `toObject` is nil for a while. Add scalar `toObjectID: UUID?` /
  `toClassID: UUID?` (and `fromID`) so a repair pass can relink, and readers can tell
  "pending" from "deleted".

**Deterministic UUIDs and duplicate system classes.** See Top-5 #3. `SystemCatalog.existing` already keeps the
oldest per key, but nothing merges, so objects and links stay split across two "Bench Press" classes and
backlinks and sessions miss half the history. Also note:
- `object(id:)` / `classDef(id:)` use `fetch(...).first`, which is ambiguous once ids are duplicated.
- `createdAt` is a per-device clock. Use a deterministic winner (for example, the lowest `persistentModelID`
  string, or `createdAt` with that string as the tie-breaker) so both devices pick the same winner and don't
  each delete the other's copy.
- The FieldDef id stability is still valuable: blobs keyed by field id stay valid after the dedupe.
- Run the dedupe from persistent history after each import (SwiftData `HistoryDescriptor`, iOS 18+; see
  [Fetching and filtering time-based model changes](https://developer.apple.com/documentation/swiftdata/fetching-and-filtering-time-based-model-changes)),
  on a background `ModelActor`, idempotently. Apple's Core Data + CloudKit samples use the same
  history-driven dedupe pattern for tags.
- Class objects: two devices calling `ensureClassObject` create two. Use a deterministic id and merge values
  (union of keys; for conflicts, prefer the newer `updatedAt`) during dedupe. Drop the legacy
  "top-level object titled like the class" fallback in `classObject(of:)` before sync. It can misidentify a
  user object as a class object.

**Soft delete.** Good choice for sync: a tombstone is a field update, and restore works. Gaps:
- `softDelete` cascades by stamping children. A set added on the watch to a workout deleted on the phone
  stays live under a dead parent. Readers should treat "any ancestor deleted" as deleted, or the dedupe and
  repair pass should re-stamp.
- `ClassDef` and `FieldDef` have no soft delete. `ClassDef.objects` is `.nullify`, so hard-deleting a class
  orphans objects with `classDef == nil` (invisible but synced forever). `FieldDef` deletion breaks undo and
  breaks older devices. Add `deletedAt` to both.
- A future hard purge (for example, after 30 days) must be a single, idempotent sweep, and should include an
  orphan sweeper for rows whose required parent never arrived.

**Before flipping `cloudKitDatabase` to `.private`:** the production CloudKit schema is additive-only. You
can't rename or delete record types or fields after promotion
([doc](https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit)).
So finalise entity and attribute names (`ObjectRecord.valuesData`, the `*Raw` columns), add the
`formatVersion` columns, the soft-delete columns, and the link id scalars first. Then run
`initializeCloudKitSchema` in DEBUG as that article shows.

## 2. Schema evolution

Two layers need different tools.

**Layer A: Swift model schema (5 @Model types).** Wrap the current models in `enum TesseraSchemaV1:
VersionedSchema` now, and pass a `SchemaMigrationPlan` (even with zero stages) to `ModelContainer`. Every
later model change becomes V2 with a `.lightweight` stage when additive (new optional or defaulted
attribute, new model, new index). Use `.custom` stages only for data rewrites, such as backfilling denormalised
columns. With CloudKit on: additive only, no renames (`@Attribute(originalName:)` is fine locally but CloudKit
keeps the old field), and no type changes. Keep model count small; the dynamic layer exists so that this layer
rarely changes. Ref: WWDC23 "Model your schema with SwiftData" (10195); WWDC25 "SwiftData: Dive into
inheritance and schema migration" (291).

**Layer B: user-level classes and fields (data, not schema).** No SwiftData migration is ever needed, but
some edits need *engine* migration logic, run as a typed action so it is undoable and syncs as ordinary
writes:

| User change | Needs logic? | What to do |
|---|---|---|
| Rename class or field display name | No | Ids are stable. |
| Add field, add class, add trait | No | Defaults apply on read. |
| Reorder fields, change unit display | No | `mass` is stored in kg. |
| Delete field | Minimal | Soft delete the FieldDef; leave values in blobs (undo; older devices). GC later. |
| Rename field **key** | Yes | Formulas reference keys. Better: store formulas compiled to field ids (`{f:UUID}`) and render keys for display. Then renaming needs no logic. |
| Change field kind (number to mass, text to choice, scalar to ref) | Yes | Convert values per object (or keep the old value and coerce on read). Block lossy conversions or confirm first. Scalar to link creates ObjectLinks. |
| Rename or remove a choice option | Yes | Values store option **strings**. Store option ids (`enumOptions` as `[{id,label}]`) so a rename is free. |
| Reparent a class (move in tree) | Yes (check) | Fields from the old lineage vanish from `effectiveFields`, but values stay in blobs. Show "hidden values". Overrides (`overridesFieldID`) pointing outside the new lineage become dead; flag them. Reject cycles at write time (the resolver only tolerates them). |
| Edit a formula | No data change | Invalidates `SchemaCache` and rebuilds `TrainingFact` (e1RM changes history). |
| Two devices add the same key to one class | Yes (sync) | Duplicate keys are possible; `field(key)` returns the first. Auto-suffix during dedupe. |
| System catalog version bump | Yes | Store `catalogVersion` in a synced settings record. Run ordered catalog migrations; follow Apple's "version attribute" pattern so older apps hide or read-only records with `formatVersion > supported`. |

## 3. Native SwiftData inheritance vs dynamic ClassDef

**Recommendation: do not add typed `@Model` subclasses for Set/Workout. Add a derived, local, typed projection
(`TrainingFact`, later others), indexed with `#Index`, and keep ObjectRecord the single source of truth.**

Reasons:
- Native inheritance gives compile-time types. User classes are runtime data, so only system classes could
  benefit. The engine would then have two value paths (column vs blob) for "weight", and the user-editable
  meaning of fields (formulas, overrides, class-object inheritance) would not apply to the column.
- Core Data stores an entity hierarchy in one table, and CloudKit stores the *root* entity as `recordType`
  with `CD_entityName` for the subclass
  ([doc](https://developer.apple.com/documentation/coredata/reading-cloudkit-records-for-core-data)). Every
  Set column would be added to every ObjectRecord row and record type, and it is permanent in production.
- Apple's guidance: inheritance fits genuine IS-A hierarchies queried both deep and shallow. Avoid it when the
  queries are effectively "fetch the base and filter"
  ([Adopting inheritance in SwiftData](https://developer.apple.com/documentation/swiftdata/adopting-inheritance-in-swiftdata)).
  Ours are shallow, hot, analytic queries over one class. That is what a projection table does best.
- `#Predicate` can't see inside `valuesData` (predicates on Codable or derived data crash at runtime; see the
  skill's predicates.md), so *some* typed columns are required. A projection gives `#Predicate { $0.exerciseClassID ==
  id && $0.weight >= 100 }` and sorted fetches with `fetchLimit`, without a CloudKit schema commitment.
- The projection is local-only (a second `ModelConfiguration` with `cloudKitDatabase: .none`, holding UUIDs and
  no relationships, because cross-configuration relationships aren't allowed), so it can change shape freely,
  and a rebuild is just a recompute.

Also add cheap denormalised, synced columns on ObjectRecord that every class benefits from: `classID: UUID?`,
`parentID: UUID?`, `occurredAt: Date?` (the engine fills it from the class's date trait: Workout
`endedAt ?? startedAt`, Task `due`). Index:
`#Index<ObjectRecord>([\.id], [\.classID, \.deletedAt], [\.occurredAt], [\.isClassObject])`,
`#Index<ObjectLink>([\.fieldID], [\.toClassID])`, `#Index<ClassDef>([\.id], [\.systemKey])`,
`#Index<FieldDef>([\.id])` (iOS 18+, local only and CloudKit-safe; see indexing.md).

## 4. Performance at 5 years (1,500 workouts, ~40k sets, ~6k entries)

Cost centres, worst first (static analysis):

1. **`classObject(of:)` scan**: O(objects of the class) per call. It is called by `inheritedClassObjects` for
   each lineage class on every non-own value read, by `objects(of:)` for every descendant, and by
   `ensureClassObject`. For Set (40k objects), each missing-value read (`rpe` nil, `isWarmup` default) faults
   and filters all 40k. `TrainingLedger.sessions(of: benchPress)` with about 2k bench sets would do on the
   order of 10^8 element visits. **Fix first** (Top-5 #2).
2. **`effectiveFields` per read**: `value(_:of:)` calls it twice (via `field(key)` then again). Each call
   walks the lineage, sorts `ownFields` (relationship faults), and JSON-decodes `defaultValueData` for every
   field (the `FieldDef.defaultValue` getter decodes). `workingSets` reads 5 keys per set, and `e1rm`
   recursively re-reads `weight` and `reps`, so about 9 resolutions per set, plus a `Formula.parse` per
   computed read. Fix: `SchemaCache` keyed by class id → `ResolvedClass { fieldsByKey, fieldsByID,
   parsedFormulas, lineageIDs, classObjectIDs, traits }`. Invalidate on local schema actions (a generation
   counter) and on any remote transaction touching ClassDef or FieldDef (history), and rebuild lazily. The
   schema is about 100 rows, so rebuild cost is negligible.
3. **JSON decode per value read**: `object.values` decodes the full blob on every access (5 to 9 times per
   set per pass, plus each class object). Fix: a `@Transient` memo on ObjectRecord holding `(Data,
   FieldValues)`; reuse it while `valuesData` is byte-equal. Also add a `values(of:)` that returns all
   resolved values for an object in one pass for list rows.
4. **`backlinks(to: class, includingSubclasses:)`**: loads every entry linking to the class tree, sorts in
   memory, then walks `ancestor()`, which calls `lineage` per hop. Acceptable once 1 to 3 are fixed, but
   `recordsBeaten` / `repsToBeatBestE1RM` recompute the full history on **every set log and keystroke**.
   Fix: serve records from `TrainingFact` (`max(e1rm)` via a sorted fetch with `fetchLimit = 1`, and
   rep-max by grouping) and cache a `PersonalRecords` per exercise invalidated by fact changes.
5. **`weeklySetsPerMuscle` and `objects(of:)`**: load all 1,500 workouts and filter dates in memory. Use
   `occurredAt` with a `#Predicate` range fetch, or the fact table.

Order to add: (1) class-object id or relationship, (2) SchemaCache, (3) values memo plus no-op write guard,
(4) ObjectRecord `classID` / `occurredAt` / `parentID` columns plus `#Index`, (5) `TrainingFact` projection.
Build a seeded perf fixture (1,500 workouts and 40k sets, in memory) with Swift Testing time budgets, so
regressions show up in CI.

## 5. Undo and typed actions (UI, Tess, App Intents on one path)

**Recommendation: build your own action layer. Use `UndoManager` as the undo *stack*, not ModelContext's
automatic undo, as the change *recorder*.**

Why not `isUndoEnabled` / `ModelContext.undoManager` alone: SwiftData registers changes saved to the
**main context only**
([Reverting data changes using the undo manager](https://developer.apple.com/documentation/swiftdata/reverting-data-changes-using-the-undo-manager)).
App Intents run off the main actor or in an extension, and Tess and dedupe work belong on a `ModelActor`.
The undo steps it creates are low level, such as "valuesData changed" or "ObjectLink deleted", which can't be
named ("Undo Log Set"), grouped (one Tess plan becomes one undo), or applied safely after a sync import has
changed the same rows. It also captures our own projection and cache writes.

Design:
- `enum EngineAction: Codable, Sendable` covers `createObject`, `setValue(objectID, fieldID, old, new)`,
  `setLinks(objectID, fieldID, old:[UUID], new:[UUID])`, `softDelete` / `restore`, `defineField`,
  `changeFieldKind(with conversion)`, `reparentClass`, and others. Each case is validated against the
  `SchemaCache`.
- `ActionExecutor` (`@MainActor` for UI, plus a `ModelActor` twin for background) does
  `apply(_ actions: [EngineAction], label:, author:)`: it validates, applies via ObjectStore internals, saves
  once, computes inverses, and registers one undo group with that label on the supplied `UndoManager`.
  Inverses are **compare-and-set**: revert only where the current value still equals what we wrote, so an
  undo doesn't clobber a newer synced change.
- Set `ModelContext.author` (`"ui"`, `"tess"`, `"intent"`, `"dedupe"`) so history transactions are
  attributable. The importer and projection rebuild can then skip their own writes, and Tess can show "Tess
  changed 3 things, Undo".
- App Intents: adopt `UndoableIntent` (iOS 26+) and pass its `undoManager` to the executor, so undo of a
  Shortcut or Siri action registers through the same path
  ([UndoableIntent](https://developer.apple.com/documentation/appintents/undoableintent)). Keep `perform()` on
  the executor; per App Intents rules it is retriable, so make actions idempotent (client-generated object
  ids).
- Optional: a short, **local, non-synced** action log (the same Codable actions) for "undo what Tess did
  yesterday" and debugging. Don't sync it, and don't use it as the replication mechanism; CloudKit already is.
- Make `ObjectStore`'s mutating methods `internal` to the executor module once the executor exists, so views
  and Tess can't bypass it.

## Code references

- Data-loss path: `Model/ObjectRecord.swift` `values` getter/setter (`try?` decode → empty → re-encode).
- O(n) class object: `Engine/ObjectStore.swift` `classObject(of:)`, `inheritedClassObjects(for:)`, `objects(of:)`.
- Per-read resolution: `ObjectStore.value(_:of:)` → `ClassResolver.field` + `effectiveFields`; `FieldDef.defaultValue` decode.
- Hot ledger paths: `Training/TrainingLedger.swift` `sessions(of:)`, `records(for:)`, `recordsBeaten`, `weeklySetsPerMuscle`.
- Seeding / dedupe assumption: `Catalog/SystemCatalog.swift` header comment ("CloudKit sync merges them") is incorrect.
