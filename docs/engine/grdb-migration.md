# Moving the engine's storage to GRDB

*Core engine, 2026-10-15. Kaushik chose GRDB after `docs/research/storage-spike.md`.*

## Goal

Same engine API, same object model, much faster storage: GRDB (SQLite) instead of SwiftData, then iCloud sync
built on the op log so edits to different fields on two devices both survive.

## What stays the same

- The object model: classes, fields, objects, links, class objects, the op log, typed actions, undo, pending
  previews, the training index, Tess and App Intents.
- Type names the app uses: `ObjectRecord`, `ClassDef`, `FieldDef`, `ObjectLink`, `OpRecord`, `ObjectStore`,
  `ActionEngine`, `TrainingLedger`. Their properties keep their names (`object.title`, `object.children`,
  `classDef.parent`, `classDef.objects`…).
- Ids, field ids and stored values: the export format moves data across losslessly.

## What changes for the app

The app stops touching SwiftData directly. Everything goes through `ObjectStore` (stage 0, available now):

| Today (SwiftData) | Use instead |
|---|---|
| `TesseraSchema.makeContainer()` + `container.mainContext` | `ObjectStore.open()` (`inMemory: true` in tests) |
| `SystemCatalog.seed(in: context)` (+ library install) | `store.prepareCatalog()` |
| `context.save()` | `store.save()` |
| `context.fetch(FetchDescriptor<ClassDef>())` | `store.allClasses()` / `store.classDef(named:)` |
| `context.fetch(… ObjectRecord … id …)` | `store.object(id:)` / `store.classDef(id:)` |
| `context.fetch(… classDef?.id == … )` | `store.objects(of: classDef)` |
| `context.insert(ClassDef(…))` | `store.createClass(name:parent:…)` |
| `context.delete(model: …)` (demo reset) | `store.resetUserData()` |
| `AppModel(context:)` | `AppModel(store:)` |

`import SwiftData` should then disappear from App/, Features/ and TesseraTests/.

## Stages

0. **App off SwiftData APIs** (this PR adds the engine side; iOS build switches its ~15 call sites).
1. **GRDB store behind the same API.** Models become plain `@Observable` final classes held in an in-memory
   identity map (the whole graph: about 46k objects at five years, tens of MB), loaded at launch with one
   query per table and written through to SQLite in transactions. Relationships (`parent`/`children`, links,
   backlinks, `classDef.objects`) are maintained in memory, so reads cost no queries. Aggregates for widgets and
   intents can run as SQL (`json_extract`) on a read-only pool in the app group. `DatabaseMigrator` replaces
   `VersionedSchema`. The engine test suite (88 tests) must pass unchanged.
2. **Data moves across.** On first launch of the GRDB build: open the old SwiftData store, `TesseraExport` it,
   restore into GRDB, keep the old store in `Backups/` untouched. Already tested: export → restore keeps ids,
   history, records, inheritance and undo.
3. **Sync** (needs the paid developer account for iCloud): CKSyncEngine over the op log, per-field
   last-writer-wins with hybrid logical clocks, links merged as sets, system classes merged by `systemKey`,
   plus a two-device offline test harness.

## Risks

- Stage 1 is the large one: every engine file that relies on SwiftData relationship maintenance moves to the
  identity map. The test suite and the 5-year scale test are the safety net.
- Observation: SwiftUI views currently re-render via `AppModel.revision`; the identity map keeps that working,
  and models become `@Observable` for finer updates later.
- One maintainer behind GRDB (Gwendal Roué); MIT-licensed, ten years old, no transitive dependencies.
