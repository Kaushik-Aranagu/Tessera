# Op log health check (before Build A1)

Board item 29. Traced by hand on `origin/master` at `8f8c2f2` (Merge #160). No build was run. Line numbers are
master's. Paths that start with `Core/` are under `TesseraCore/Sources/TesseraCore/`.

For: Core, Builder A, Builder B. Read with `build-a1-brief.md` (cited as "brief") and `undo-lines.md` (cited as
"UL row N" or "UL Bn"). Rows already in those files are cited, not repeated; only what is new is written out.

## How a write reaches the log today

- The only logged path is `ActionEngine.perform` (Core/Actions/ActionEngine.swift:41-68). It hands the action a
  `Transaction` (Core/Actions/Transaction.swift:6-96), which calls the store and appends an `Op` for each change.
- Everything under the transaction is public and unlogged on its own: `ObjectStore.create`, `softDelete`,
  `restore`, `set`, `setLinks`, `setClassLink`, `ensureClassObject` (Core/Engine/ObjectStore.swift:39-72, 115,
  169, 216, 238), `createClass` and `resetUserData` (Core/Engine/ObjectStore+Lifecycle.swift:41-69), and
  `TesseraContext.insert`, `delete`, `deleteAll`, `save` (Core/Model/TesseraContext.swift:55, 95, 145, 233).
  Any caller outside a `Transaction` skips the log.
- Searched for: `write(`, `dbQueue`, `dbPool`, `DatabaseQueue`, `insert(`, `save(`, `update(`, `delete(`,
  `deleteAll`, `execute(sql`, `OpRecord`, `ActionEngine`, `ObjectStore`, `valuesData`, every `store.create/set/...`
  call, and every direct property write on a model (`.title =`, `.values =`, `.sortIndex =`, `.id =`, `.name =`,
  `.parent =`, `.createdAt =`, `.isClassObject =`, `.state =` and so on), plus `UserDefaults` and `@AppStorage`.

The app target writes outside the engine in only three places: `ObjectPage.swift:136`, `WorkoutSession+Rest.swift:40`
and `DemoData.swift`. The rest of the bypasses are in Core: seeding, the installers, import, restore and the engine
itself.

## 1. Writes that skip the log or can't be undone

Each item: where, what it writes, the risk (undo, A1, later sync), the smallest fix, the owner.

### Schema

**S1. New subclass.** `Features/Objects/ObjectPage.swift:136-139` calling `Core/Engine/ObjectStore+Lifecycle.swift:41-50`.
Already UL row 41, UL B9 and brief blocker 7.
- New here: the class gets the placeholder name "New Bench Press", and master has no rename and no delete for
  classes. So a mis-tap leaves a permanent junk class in `allClasses()`, the Objects list and Tess's class list
  (`TesseraTess/TessTools.swift:239`), and nothing can remove it.
- Sync: the class row never reaches another device, but later ops that create objects of it carry its `classID`,
  so on replay they point at a class that isn't there.
- Fix: A1's `Transaction.createClass` plus a user-only `AddClass` action. Make `ObjectStore.createClass` a wrapper
  over it (brief slice item 4). Then this call site becomes `engine.perform(AddClass(...), by: .user)`.
- Owner: Core (API), Builder B (call site).

**S2. Add field and rename (class or field).** There is no code path on master. The only renames are the seed's
(S3 and S4), and `markUserModified` (`Core/Catalog/CatalogPackage.swift:16-25`) has no callers (brief blocker 7).
- Risk: none today. The danger is that the first add-field or rename UI lands as a direct write like S1.
- Fix: no UI for these until A1's `AddField`, `RenameClass` and `RenameField` exist.
- Owner: Core, with Builder B for any UI.

**S3. Seed renames Routine on every launch.** `Core/Catalog/SystemCatalog.swift:303-305`.
- What it writes: if the routine class is named "Plan", the seed renames it to "Routine". This check runs on every
  launch, outside the `packageVersion < package.version` gate (:319) and ignoring `isUserModified`.
- Undo and A1 risk: if he ever renames Routine to "Plan" (a natural name), the next launch silently renames it back.
  The A1 rename op's guard ("current name equals old") then fails, so undo returns a conflict and the history shows
  a rename that didn't stick.
- Fix: one line. Guard it with `classDef.packageVersion < 3 && !classDef.isUserModified`.
- Owner: Core.

**S4. Package refresh of system classes and fields.** `Core/Catalog/SystemCatalog.swift:296-392` (insert at :316 and
:354, refresh at :362-382, formula upgrade at :385-392, save at :357).
- Verdict: fine to keep out of the log. Ids are stable (`stableID`), so the result is the same on every device, and
  a package version is a deterministic function of the build.
- Conditions: refresh must honour `isUserModified` and A1's `setModified` op (brief section 3, blockers 7 and 8),
  and the seed must never clear `retiredAt` (brief section 3).
- Owner: Core.

**S5. Exercise library install.** `Core/Catalog/ExerciseLibraryInstaller.swift:42-129` and
`Core/Catalog/MuscleLibrary.swift:7-23`. It runs once per library version (:30-39) and again on every
`resetUserData` (ObjectStore+Lifecycle.swift:65, DemoData.swift:26).

What it writes, all without ops:
- library classes (:64, :126, stable ids);
- the parent of every library class, on every run (:66);
- traits, on every run (:67-73);
- class objects through the store's `ensureClassObject` (:77, :97, :109), with random v7 ids;
- every profile value: `repMin`, `repMax`, `restSeconds`, `pattern`, `family`, `mechanic`, `logType` and
  `aliases` (:78-86), plus the muscle and equipment links (:90-92);
- Equipment objects (:144) and Muscle objects (MuscleLibrary.swift:15), with random ids. Muscles are matched by title.

Risks:
- **Undo.** The next library bump overwrites any edit to these values or links, including edits made through the
  log (for example `RenameObject` on a muscle, which is in `ActionRegistry`). Undoing that edit afterwards
  conflicts, because the guard sees the installer's value.
- **Duplicates.** A muscle or equipment object deleted with `DeleteObject` is invisible to `store.objects(of:)`, so
  the installer makes a new one. Undoing the delete then leaves two "Chest" muscles. A renamed muscle is not matched
  by title, so it gets a duplicate too.
- **A1.** The installer ignores `isUserModified` for parent and traits. Parent change is outside A1, but it means a
  later "move class" is silently reverted.
- **Sync.** Random ids for class objects, muscles and equipment mean each device seeds different objects for the same
  thing. Logged `setLinks` ops then point at muscle ids the other device doesn't have, and `fetchClassObject`
  (ObjectStore.swift:109-111) picks whichever is oldest.

Smallest fix:
- Stable ids: `stableID("library.<key>.classObject")`, `stableID("muscle.<seed>")` and `stableID("equipment.<kind>")`.
- Match deleted rows too, so a delete is never reseeded.
- Write a profile value only when it is nil or still equals the previous package's value, the same overlay rule
  `refresh` uses.
- Owner: Core.

**S6. Notes create class objects inside an action.** `Core/Notes/Notes.swift:176-183`. This is logged (`create`), but
`object.isClassObject = true` (:181) is not in the op. See E1.

### Seeding and starter data

**D1. Starter plan and gym kit.** `Core/Catalog/StarterContent.swift:69-114`.

What it writes, all without ops:
- 6 routines (:76, rekeyed to stable ids at :77);
- their slots (:81, random ids, `sortIndex` written directly at :82) and slot values (:83-86);
- the plan (:90-92, stable id);
- `configureEquipment` (:97-114), which overwrites `barWeight`, `plates` and `loads`.

Risks:
- Undo: none needed for a first-launch seed. But `configureEquipment` also runs from `resetUserData` and overwrites
  gym-kit edits without a trace.
- Sync: slot ids are random, so a second device seeds different slots under the same routine id. That gives doubled
  routines, and `EditSlot` and `MoveSlot` ops from device 1 hit slot ids device 2 lacks.

Fix:
- Stable slot ids: `stableID("starter.routine.<key>.slot.<i>")`.
- `configureEquipment` fills only nil values.
- Owner: Core.

**D2. Groceries list.** `Core/Kitchen/Groceries.swift:24-28`. Creates one list with a stable id, rekeyed after insert.
Fine to keep out: it is deterministic and the same on every device.

**D3. Demo seeding.** `Features/Demo/DemoData.swift`.
- What it writes: `resetUserData` (:23), a library reinstall (:26), and history and today written straight to the
  store (:141-155, :181-184, :187-207), including `createdAt` (:142) and `sortIndex` (:203). The plan goes through
  actions (:49).
- Verdict: fine to keep out. It runs only under `-demo` or `-resetDemo`.
- Two caveats:
  - The code has no `#if DEBUG` guard; only the launch argument keeps it off the phone.
  - Demo history has no op records, so Review, the object history and any "undo" demo show nothing for past workouts.
- Fix: wrap `DemoData.prepare` and `resetUserData` in `#if DEBUG`. If recordings need history, seed the past
  workouts through `LogSet` with a system actor.
- Owner: not named in the owner list (`Features/Demo`). See open questions.

**D4. Reset user data.** `Core/Engine/ObjectStore+Lifecycle.swift:53-69`.
- What it writes: hard deletes of every link, object and op record and every user class, then a reseed.
- Verdict: fine as a developer tool, and it is the one place A1 keeps hard delete (brief section 1).
- Fix: `#if DEBUG`, as in D3.
- Owner: Core.

### Engine-level gaps

**E1. The create op is lossy.** `Core/Actions/Op.swift:23`, `Core/Actions/Transaction.swift:34-38`,
`Core/Engine/ObjectStore.swift:40-47`.
- What the op leaves out: `.create` records the object, class, parent and title only. It does not record:
  - `sortIndex`, which `store.create` computes from the current sibling count (:40, :44);
  - `createdAt`, which `CreateNote` overrides directly for dated notes (`Core/Notes/Notes.swift:107`);
  - `isClassObject` (`Notes.swift:181`).
- Undo and redo are fine on one device, because undo soft-deletes and redo restores the same row.
- Sync: replaying the log on a fresh device can't rebuild these rows. Class objects come back as ordinary objects, a
  note "for Friday" lands on the replay day, and sibling order depends on arrival order.
- Fix: add optional `sortIndex`, `createdAt` and `isClassObject` to `.create`. Old records still decode because the
  fields are optional. Ship it in the same `Op` change as A1's nine cases, so the op format changes once.
- Owner: Core.

**E2. Undo, redo, commit and discard rewrite the record.** `Core/Actions/ActionEngine.swift:103, 117, 140, 148`, with the
setter at `Core/Model/Models.swift:568-573`.
- What it writes: `state` and `updatedAt` on the original row. No new entry is appended.
- Undo risk: `undo` marks the record `.undone` even when ops were skipped (UL B12).
- Sync: an undo is a mutation of an old row, not an event, so two devices that undo and redo the same record resolve
  by whichever row wins. There is also no trail of who undid what, or when.
- Fix: not needed for A1. Before sync, either append an `undo` or `redo` `OpRecord` that names the original, or add
  an append-only state-change list.
- Owner: Core.

**E3. Rolled-back actions leave orphans.** `Core/Actions/ActionEngine.swift:47-50`.
- What it writes: a throwing action is reverted with an unguarded replay. Objects it created stay as soft-deleted rows
  with no `OpRecord`, and link rows are deleted and recreated.
- Verdict: fine to keep out of the log. They are invisible, but they pile up.
- Fix: hard-delete rows created inside the failed transaction.
- Owner: Core. Low priority.

**E4. The write API is public.** These are all callable from the app with no op:
- `Core/Engine/ObjectStore.swift:39-72, 115-123, 169, 216, 238`;
- `Core/Engine/ObjectStore+Lifecycle.swift:42, 53`;
- `Core/Model/TesseraContext.swift:55, 95, 145`.

S1, B1 and D3 exist because of this.
- Fix: mark them `package`, so only TesseraCore and TesseraLegacyStore can call them. Expose an `@_spi(Seeding)`
  door for DemoData, or move the demo to actions.
- Owner: Core.

### Import, restore, settings

**I1. Legacy SwiftData import.** `TesseraLegacyStore/LegacySchema.swift:33-47` calling
`Core/Export/TesseraExport.swift:164-254`, from `App/TesseraApp.swift:24`.
- What it writes: classes, fields, objects, links and the old op records (:243-252), inserted straight into the
  context with their ids kept. When merging, it skips the children and links of objects already there (:205-210,
  :231-233).
- Undo: old records stay undoable. But a record whose objects were skipped by the merge undoes partly
  (`apply` returns false for a missing object, ActionEngine.swift:212). The old op data also decodes with `try?`
  (brief blocker 11).
- A1: the export has no `retiredAt`. Restore must carry it, or retired schema comes back live after a round trip
  (brief slice item 2).
- Sync: a bulk insert outside the log. Other devices never learn it happened.
- Fix: keep it out of the log. Write one system `OpRecord` ("importSnapshot", no ops) as a baseline marker, so sync
  knows the log starts after it. Add `retiredAt` to `ClassEntry` and `Field` in A1.
- Owner: Core.

**I2. Backup restore.** `Core/Export/TesseraBackup.swift:183-236`, staged from `Features/Backup/BackupView.swift:219`.
Already UL rows 35-36 and W12.
- New here: the restore swaps the whole file, op log included. On this device that is consistent, and the undo is
  the "Before-restore" copy. A backup taken before A1's `v3` migration still migrates on open.
- Sync risk: a restore rewinds the log. Ops made on other devices after the backup point are gone locally, and the
  device's log forks.
- Fix: keep it out of the log. Before sync exists, give each store a replica or epoch id and issue a new one on
  restore, so sync treats the restored store as a new replica.
- Owner: Core.

**I3. Settings.** No persisted app settings on master. The unit is `Format.unit`, a static set in code
(`App/AppClock.swift:36`). The theme and demo clock are launch arguments. The only `UserDefaults` writes are the
backup folder bookmark (`Features/Backup/BackupKeeper.swift:38-63`) and the launch note
(`Core/Model/TesseraSchema.swift:103-113`).
- Verdict: fine to keep out. These are device-local UI state.
- Note: when a unit or plate setting arrives, it is data about him, not the device. It should be a value on an
  object, through an action.

### Workout, App Intents, Live Activity, system writes

**B1. Rest saved over a logged field.** `Features/Workout/WorkoutSession+Rest.swift:26-41` (write at :40). It is
called after every log, undo, rest change and swap (WorkoutSession.swift:163, 364, 389, 421, 436, 445, 523;
+Edit.swift:68). UL row 7 lists it as "by design".

New here: it is not a separate field. It overwrites `resumePoint` on the process, a field that `LogSet`,
`LogNextSet` and `LogExercise` already wrote through the log (TrainingActions.swift:74 calling
`Core/Training/WorkoutProgress.swift:61-68` calling `Core/Processes/ProcessActions.swift:224-233`). So:
- **Every set undo is partial.** The `resumePoint` inverse op is skipped, because the current value is the rest
  version, not the one the action wrote. `nextStep` and `lastTouchedAt` do revert, so the process is left
  inconsistent.
- **The live screen repairs it** with its own `persistRest` right after (WorkoutSession.swift:421).
- **Siri and Lock Screen "Undo Last Set" don't** (Intents.swift:66). The process keeps a resume point and a rest end
  for the removed set. After a relaunch, `savedRest` (WorkoutSession+Rest.swift:13-22) picks up a countdown for a set
  that's gone. This adds to UL B1.
- **Sync:** two writers on one field, and only one of them is logged.

Fix:
- Give rest its own process field (`rest`, text) in `SystemCatalog`, written only by `persistRest`.
- `resumePoint` then belongs to actions alone.
- Owner: Builder A (call site), Core (field).

**B2. In-memory workout state.** Skip set, bests and the rest timer: UL rows 7-8, B4, B10. Nothing new.

**B3. App Intents.** `TesseraIntents/Intents.swift:28-143`. Every intent goes through the engine with
`.intent`: UL rows 43-49 and B1.
- New here: no intent saves. Persistence waits for autosave's next main-actor turn
  (Core/Model/TesseraContext.swift:218-228). An intent run in the background can return before that turn, so a
  logged set could be lost if the process is suspended straight away. The app's `revision` isn't bumped either.
- Fix: `try runtime.store.context.save()` before each `.result`.
- Owner: Core.

**B4. Live Activity buttons.** `Shared/RestIntents.swift:28-71` calling `Features/Workout/LiveActivity/LiveWorkout.swift:12-33`.
Done goes through `session.logSet`, so it is logged; +15, Skip rest and Skip set are session state. UL rows 2, 7, 8.
Nothing new beyond B1.

**B5. System housekeeping.** `Core/Processes/ProcessTable.swift:90` (suspend), :104 (put away), :124-125 (6 h wrap-up as
two records), and `App/AppModel.swift:247` (resume by system). All are logged with `.system`: UL rows 37-39, B11.
- New here: system records share the log with his. `undoLatest(by: nil)` (ActionEngine.swift:155-163) can pick a
  system record. Also, a system record that rewrites a field he also set (the wrap-up's `endedAt`, `lastTouchedAt` on
  every process op) makes his earlier record's undo partial.
- Fix: make `undoLatest` skip `.system` unless asked, and make the wrap-up one record (UL B11).
- Owner: Core.

**B6. RollForward.** `Core/Tasks/RollForward.swift:40-68`, with the runner at :86-94. Logged as one system record,
which is good. But:
- Nothing calls `rollForward` on master; only `ReviewView.swift:68` filters for it. Tasks never roll.
- `RollForwardTasks` is in `ActionRegistry.descriptors` (ActionRegistry.swift:23), so the on-device model route can
  call it.
- Once it is wired, it rewrites `startsAt` on tasks he may just have moved, so undoing that `MoveTask` after a roll
  conflicts. That is expected, but nothing tells him (UL B12).
- Fix: call `TaskList.rollForward(engine:now: AppClock.now)` from `AppModel.tidyProcesses` (Builder B), and drop it
  from `descriptors`, like A1's schema actions (Core).
- Owner: Core and Builder B.

**B7. Apple Health.** A side effect, not a store write: UL row 42, B7.

## 2. Fine to keep out of the log

| Write | Where | Why it's fine |
|---|---|---|
| Saving and autosave | Core/Model/TesseraContext.swift:218-249, App/AppModel.swift:345-348, Core/Training/TrainingIndexBuilder.swift:15-16, ObjectStore+Lifecycle.swift:25-27 | Persists changes the log already holds |
| Caches, revision, derived index | Core/Engine/ObjectStore+Caches.swift:14-21, 36-46, ObjectStore.swift:30-34 | In memory, rebuilt from data |
| Link rows replaced on every `setLinks` and every replay | Core/Engine/ObjectStore.swift:357-372 | The op holds the targets. Link ids and `createdAt` change on each replay, so sync must treat links as derived from ops, never sync them as rows |
| `updatedAt = .now` on rename or replay | Transaction.swift:79, ActionEngine.swift:230 | Metadata |
| Op record route and model | ActionEngine.swift:59-62 | Set before the record is first saved |
| System package seed (S4), Groceries list (D2) | above | Stable ids; the same result on every device |
| Daily backup files, bookmark, launch note | TesseraBackup.swift:33-109, BackupKeeper.swift:38-79, TesseraSchema.swift:103-113 | Files and device UI state |
| Backup restore (I2), legacy import (I1) | above | Whole-store events; they need a baseline marker, not ops |
| Demo seed, reset (D3, D4) | above | Developer only, once guarded by `#if DEBUG` |
| Rest timer, skip, bests (B2) | WorkoutSession | Session state, once B1 moves rest to its own field |
| Rollback orphans (E3) | ActionEngine.swift:47-50 | Invisible; a cleanup item only |

## 3. What this means for A1

- **Blocks A1 or must ship with it:**
  - S1: route `createClass` through the transaction (already brief slice item 4).
  - S3: the seed's Routine rename breaks the rename guard.
  - I1: `retiredAt` in export and restore.
  - E1: change the `Op` format once, together with the nine schema cases.
- **Should land before any add-field or rename UI:** E4. Making the write API `package` stops a second S1 from
  appearing in the app.
- **Doesn't block A1, but A1's fixtures will hit it:** B1. Any test that undoes a logged set and asserts
  `.applied` sees `.partial`.

## Summary by owner

| Owner | Items | Count |
|---|---|---|
| Core | S1 (API), S3, S4 (conditions), S5, D1, D4, E1, E2, E3, E4, I1, I2, B1 (field), B3, B5, B6 (registry) | 16 |
| Builder A | B1 (call site and rest field use) | 1 |
| Builder B | S1 (call site), S2 (no UI before A1), B6 (wire rollForward) | 3 |
| Not named | D3 (`Features/Demo`) | 1 |

Fine to keep out: 11 kinds of write (section 2). No action needed: S6, D2, I3, B2, B4 and B7 (cited or covered
elsewhere).

**Worst gap: B1.** It is quiet and it is on the main path. Every logged set undo returns `.partial`, and the Siri and
Lock Screen undo leaves a live rest for a deleted set on the process, which comes back after a relaunch.

**Worst sync gap: S5 and D1.** Random ids in the seed (class objects, muscles, equipment, starter slots) mean a second
device can never replay the first device's log cleanly.

## Open questions

1. Who owns `Features/Demo/DemoData.swift`? Should demo history go through actions, so Review and undo can be
   recorded in demos?
2. B1: a new `rest` field on Process (Core), or keep rest in `resumePoint` and have `touchWorkoutProcess` carry the
   extras forward? The second option keeps the schema but leaves two writers on one field.
3. S5: when the library version bumps, should his edits to exercise profiles win, as they do for class names? If so,
   the installer needs a per-value "edited" marker or the previous package value to compare against.
4. E2: for sync, should undo be a new `OpRecord` (an append-only log), or should the record's state carry a
   last-writer-wins clock? A1 doesn't need the answer, but the `Op` format change in E1 is the cheap moment to decide.
5. Should the starter plan (D1) be one system action ("Installed Push Pull Legs"), so he can remove it with one undo
   and history shows where it came from?
