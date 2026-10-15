# Object model and data architecture: ideas scouted

For: Core engine (TesseraCore)
Date: 2026-10-15

Ranked by long-term leverage x v1 risk reduction / effort. **LOCK-IN** marks a choice that is cheap now and expensive to change once real data exists.

1. **Store objects generically in SQLite, not one @Model per class.** User classes (M3) and Tess-built apps (M4) are created at runtime, and SwiftData wants classes at compile time; with CloudKit it also bans unique constraints and any non-lightweight migration. Why: one store design that survives M3/M4. How: GRDB (or Point-Free's SQLiteData, GRDB plus CloudKit sync) with tables `object(id, classId, parentId, createdAt, deletedAt)`, `value(objectId, fieldId, json)` or a JSON props column, and generated/expression indexes for hot fields (exercise, date, weight). Swift structs for built-in classes are typed views over it. Effort M. **LOCK-IN.** Sources: https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/ , https://github.com/pointfreeco/sqlite-data , https://antonz.org/sqlite-generated-columns/

2. **Schema is data: classes, fields and traits are objects.** Anytype and Mentat both store the schema in the same store as the data, so renaming a field or adding a class is an ordinary write that undoes and syncs like any other. Built-in classes ship as a versioned package; user edits are an overlay (the roadmap's package manager idea). How: `Class` and `Field` are classes in the registry, keyed by stable IDs, with a schema version per package. Effort S-M. **LOCK-IN.** Sources: https://doc.anytype.io/anytype-docs/basics/glossary , https://mozilla.github.io/mentat/about/

3. **An operation log as the one write path.** Every typed action commits a transaction of ops (set field, link, create, delete) with actor (user, Tess, Intent), timestamp and inverse. Why: undo for Tess for free, a "what Tess did" receipt, time travel, an audit for export, and the unit sync will ship later. How: an append-only `op` table written in the same SQLite transaction as the state tables; state is the fast cache. Effort M. **LOCK-IN** on op format. Source: Mentat's transaction log idea above.

4. **IDs: UUIDv7 everywhere, assigned on device.** Time-sortable, merge-safe for CloudKit and future multi-device. Objects, classes, fields, ops and links all get one. Effort S. **LOCK-IN.**

5. **Links as a first-class table.** `link(from, fieldId, to, ord, owns)` indexed both ways makes backlinks ("Linked from 14") an index lookup, and `owns` gives cascade delete for Workout > Entry > Set. Effort S.

6. **Quantities stored canonical, shown in user units.** Mass in kg, Duration in seconds, with the entered unit kept as metadata. Wrong early, every PR and e1RM history needs a migration. Effort S. **LOCK-IN.**

7. **Derived data as rebuildable projections.** PRs, weekly sets per muscle and e1RM trends are indexes recomputed from sets on change, never hand-edited truth. Editing a 3-week-old set then fixes PRs everywhere. Subscribers on the event bus keep them current. Effort M.

8. **One small, pure expression and query language.** Computed fields, filters, view conditions and Tess queries share one serializable AST (Datalog-flavoured: "sets where exercise is-a BarbellLift"). Querying a parent class returns subclasses, as Tana's extended supertags do. Tess (M4) emits AST JSON, not Swift. Effort M. Source: https://outliner.tana.inc/learn/guides/when-to-use-extend-in-supertags

9. **Capability manifests per app and for Tess.** Each app package declares the classes it reads and writes and the actions it may call; Tess runs under a scoped capability, and destructive actions need confirm. v1: write the manifest, check it in the action dispatcher. M3/M4: user-built apps cannot touch what they did not declare. Effort S now, L later.

10. **Auto-generated schema and action catalog for Tess.** The registry emits a compact text catalog (classes, fields, actions with typed args) used as Foundation Models tool definitions and in Claude prompts. Quick Capture then cannot invent fields. Effort S.

11. **Defer CRDTs; plan field-level last-writer-wins sync.** CloudKit via CKSyncEngine (SQLiteData) fits a single-user app. Keep Automerge or Loro for rich-text notes in M2 only. Effort M, later. Sources: https://automerge.org/blog/automerge-2/ , https://loro.dev/about

## Cross-functional unlocks

- Design: a history scrubber on any object page, driven by the op log.
- Tess: "Undo what Tess did" and one-line receipts read from her ops.
- Workouts: edit any old set and PRs, volume and the progression rule recompute.
- Trust: JSON export is the schema plus the op log, replayable.

## Top 3 to act on now

1. Choose GRDB/SQLiteData with a generic object/value/link schema before M0 code lands (ideas 1, 5).
2. Make classes and fields objects with stable UUIDv7 IDs and canonical units (ideas 2, 4, 6).
3. Route every write through actions that append to an op log with inverses (idea 3).
