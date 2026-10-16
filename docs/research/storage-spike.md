# Storage spike: SwiftData vs GRDB for Tessera's generic object store

*Core engine, 2026-10-15. Benchmark code and raw results: `tools/storage-spike/`. Decision owner: Kaushik.*

## The decision

Pick one:

- **GRDB + our own sync (recommended).** Move the store to GRDB behind the same `ObjectStore` API, then build
  CKSyncEngine sync from the op log, which is the only option that merges per field. Writes and queries become
  far faster on real data (below). We own sync correctness, with a two-device offline test harness.
- **Stay on SwiftData.** No dependency and Apple-managed sync, but saves get slower as history grows
  (130 ms per workout save at 5 years on a Mac; slower on a phone), and sync is whole-record last-writer-wins.
  First mitigation to try: drop the `ClassDef.objects` inverse (needs a V2 schema stage; not measured).
- **GRDB + SQLiteData sync.** Managed sync sooner, but only per-field once `values` is split into its own table,
  and it brings 14 packages including one still pre-1.0.

Nothing is blocked on this until iCloud sync is turned on, but every week of real data makes a move costlier.

**Recommendation.** Move the engine's storage to GRDB (plain SQLite we own), and plan sync as our own
CKSyncEngine layer fed by the op log. On the same generic schema, on disk, GRDB was 20x faster to insert the
5-year fixture in one transaction and 168x faster with per-workout transactions (how the app writes). It
cold-read every set into plain values 2.9x faster with the same JSONDecoder, or 19x faster with SQLite
`json_extract`. A records query was 86x faster, log-a-set plus re-query 73x faster, and file size was the
same. SwiftData's cost is mostly in writes and saves, and it grows with the store: 130 ms per workout save
at 5 years. For sync, no managed option gives Tessera per-field merge, because all field values sit in one JSON
column. SwiftData merges whole records with last-writer-wins. SQLiteData merges per column, which for us
still means the whole `values` blob. Only an op-log-driven CKSyncEngine merges at field level, and the op log
already exists. Fallback if managed sync is wanted sooner: GRDB with SQLiteData, but only after splitting `values`
into a per-field table.

## Results (1,500 workouts × 5 entries × 5 sets = 37,500 sets; 46,500 objects, 7,500 links)
macOS 27.0 (26A5388g), Swift 6.4, `-c release`, M-series Mac, on-disk WAL stores, each step in a fresh
process. Medians of 3 unless marked. GRDB 7.11.1; SwiftData is the system framework.

| Measurement | SwiftData | GRDB | Ratio |
|---|---:|---:|---:|
| Insert fixture, one transaction | 19,242 ms | 985 ms | 20x |
| Insert fixture, one save per workout (1,500 commits) | **196,025 ms (1 run only)** | 1,165 ms | 168x |
| Cold open (container/pool + catalog lookups) | 19.9 ms | 4.1 ms | |
| Read every set + entry + exercise link → plain values (JSONDecoder) | 1,739 ms | 600 ms | 2.9x |
| Same read, scalars via SQL `json_extract` | n/a | 90 ms | 19x |
| Cold open + full read (training-index build) | 1,759 ms | 604 ms | |
| Records for one exercise (best e1RM over 7,500 sets), fresh context | 843 ms | 9.8 ms SQL agg / 103 ms Swift decode | 86x |
| Log one set (+ op record), commit, re-query records | 989 ms | 13.6 ms | 73x |
| Store size, per-workout build | 19.2 MB | 20.3 MB | ~same |
| Store size, one-tx build | 20.0 MB | 20.3 MB | ~same |

How to read these numbers:
- The SwiftData per-workout insert ran once, because 3 runs would take more than 10 min. At 100 workouts it took 1.25 s, or 12 ms per
  save. At 1,500 workouts it took 130 ms per save. A fresh ModelContext per workout didn't help (1.44 s at 100). *Inferred:*
  each save maintains the to-many inverses `ClassDef.objects` and `children`, and `ClassDef.objects` holds every Set ever logged. The real
  models have the same inverses, so the live app pays this on every save. Dropping that inverse may be a
  SwiftData-only mitigation. **Not measured.**
- Of SwiftData's 989 ms for log + re-query, about 145 ms is the save and about 845 ms is the naive records walk. For GRDB the split is about 4 ms + 10 ms.
  The app normally answers records from the cached TrainingIndex (6–30 ms), so the gap users would see is the
  per-save cost and the launch-time index build.
- Of GRDB's 600 ms JSONDecoder read, about 500 ms is `FieldValues` decoding (compare 90 ms with `json_extract`). That is a
  format cost, and SwiftData pays it too.
- "Cold" means a new process. The OS page cache was warm (purging needs sudo). These are Mac numbers, not
  iPhone. Expect a device to be several times slower, with similar ratios (not measured).
- Both engines returned identical results: 7,500 entries, 37,500 sets, best e1RM 128.7, and 175.0 after logging 150×5.
- SQLiteData 1.12.1 resolved and built cleanly (`SQLiteDataProbe` target). It is not benchmarked separately: it runs
  on GRDB, so its SQL performance is GRDB's. Its CloudKit `SyncEngine` was not exercised, because there is no iCloud entitlement.

## Sync
- **SwiftData + CloudKit (private DB):** this is NSPersistentCloudKitContainer underneath, and our models already meet its constraints
  (optional or defaulted properties, no `.unique`, optional relationships with inverses). Conflicts resolve as last-writer-wins
  and can't be customised. Point-Free describes the unit as the whole record. Apple doesn't document finer
  granularity, and research-01 says attribute-level at best. Either way `valuesData` is one attribute, so concurrent
  edits to different fields of one object lose one side. CKRecords are named from Core Data ids, not our `id`, so
  devices that both seed get duplicate system classes and need a dedupe pass (research-01 #3). The schema is
  additive-only after promotion. We write no sync code, but we also can't steer or debug it.
- **GRDB + SQLiteData `SyncEngine` (CKSyncEngine):** I verified this in its source and docs (`CloudKitSync.md`,
  `Internal/Metadatabase.swift`). The strategy is "field-wise last edit wins": a per-column `userModificationTime` is kept in a
  metadatabase, and merges go column by column. The strategy can't be customised. Its requirements fit our schema: globally unique,
  non-compound primary keys (UUID), no UNIQUE constraints, no RESTRICT/NO ACTION foreign keys, and new columns nullable or
  defaulted. It also supports sharing (root tables only) and assets. There are 2 catches for Tessera. First, `values` is one column, so
  we would get whole-blob last-writer-wins, the same as SwiftData, unless values move to a `fieldValue(objectId, fieldId, value)` table.
  That table would hold about 190k rows and CKRecords for 37.5k sets. Second, tables must be `@Table` structs registered with the engine.
  A community proposal (structuredpath/sqlite-data-conflict-resolution) argues the default drops valid concurrent
  edits and prototypes a 3-way merge in a fork. It is not upstream.
- **GRDB + our own CKSyncEngine from the op log:** this is the most work: zones, change tokens, record mapping, retries,
  account changes and initial upload. It is also the only option that matches the engine. Ops are already typed (set field, link
  add/remove, create, soft delete), so merges can be per field with a hybrid logical clock, links can be set-like,
  and system classes can merge by `systemKey`. CKSyncEngine (iOS 17+) handles scheduling, push and batching. A
  suggested shape: one CKRecord per object holding a fieldId → value map plus per-field clocks. My rough estimate is 1–2 weeks to a
  solid first version. **Not built or measured.**

## Migration
- SwiftData uses `VersionedSchema` + `SchemaMigrationPlan`. Lightweight stages are fine. Custom stages are clumsy, and a failed open
  falls into the move-store-aside path `TesseraSchema` already has. With CloudKit on, the schema becomes additive-only.
- GRDB uses `DatabaseMigrator`, which runs ordered, explicit SQL migrations. It is mature and testable. Because the engine is generic
  (classes and fields are rows), table migrations should be rare.
- Switching now is cheap, because there is no production data yet (research-01). Port `ObjectStore`, `ClassResolver` and
  `TrainingLedger` behind the same API. Most tests should carry over.

## SwiftUI observation, App Intents, widgets
- SwiftData offers `@Query` and observable `@Model` objects. The engine already routes reads through `ObjectStore` and a revision counter.
- GRDB offers `ValueObservation` (async sequence) and `DatabaseRegionObservation`. SQLiteData adds `@FetchAll`/`@FetchOne`/`@Fetch`,
  which work in views and `@Observable` models. Either can bump the engine's revision.
- App group: both work. SwiftData uses `ModelConfiguration(groupContainer:)` and picks up cross-process changes through persistent history.
  GRDB uses a `DatabasePool` in the group container with WAL. Follow GRDB's "Sharing a Database" guide (suspension handling to
  avoid `0xdead10cc`, cross-process change notification). Widgets and intents can open a read-only pool and run
  the 10 ms SQL aggregates without loading an object graph.

## Risk, maturity, licensing
- SwiftData is Apple's, so there is no dependency to manage. Its performance (measured above) and its sync are opaque, and fixes ship with OS releases.
- GRDB.swift is MIT-licensed, about 10 years old, very mature and widely used. It effectively has one maintainer (Gwendal Roué) and no transitive deps.
- SQLiteData is MIT-licensed, from Point-Free, at version 1.x. It pulls in 14 transitive packages, including swift-structured-queries **0.39
  (pre-1.0)**, swift-dependencies, swift-sharing and swift-syntax prebuilts. A cold build took about 3 min here. Its sync engine is young.
- Our own CKSyncEngine has no third-party risk, but we own correctness. It needs a two-device offline test harness.

## Reproduce
```bash
cd tools/storage-spike
swift build -c release --product Bench
.build/release/Bench suite 3 $PWD/work grdb            # GRDB, 3 runs, ~10 s
.build/release/Bench suite 1 $PWD/work sd              # SwiftData, 1 full run incl. per-workout build, ~4 min
cp -R work/sd-perWorkout work/sd-perWorkout-run1       # SwiftData runs 2-3: one-tx build + cold query, ~1 min
SPIKE_MODES_sd=oneTx SPIKE_QUERY_sd=sd-perWorkout-run1 .build/release/Bench suite 2 $PWD/work sd
# Single steps: Bench <sd|grdb> build <oneTx|perWorkout|perWorkoutFresh> <dir> ; Bench <sd|grdb> query <dir>
# Smaller fixture: prefix SPIKE_WORKOUTS=100
swift build -c release --product SQLiteDataProbe       # build check only
```
Raw output: `tools/storage-spike/results/`.
