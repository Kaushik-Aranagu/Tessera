# A time zone on each logged item: what it takes and when (board item 80)

For: Core's Later list. Date: 2026-10-16. Traced by hand on origin/master e75f40f (15 Oct 19:47 PT). No Swift toolchain,
nothing run. Builds on `day-log-late-night.md` (case 7), `fixtures/dst-travel.md` (rule 7, open question 1, D07) and
`backup-logical-day.md` (T8). There is no `research/dst-travel.md`; the fixture is the one meant.

## Where master is
- No zone is stored anywhere. The only zone in Core is a cache key: `workoutDaysZone` (`Engine/ObjectStore+Caches.swift:93-94`),
  checked in `finishedWorkouts(onDay:)` (`Training/WorkoutSummary.swift:86-104`). Tess formats with the calendar's zone
  (`TesseraTess/TessCaptureEngine.swift:228`, `TessModelCapture.swift:58`). Everything else reads `Calendar.current`.
- `OpRecord` (`Model/Models.swift:496-579`): action, actor, state, summary, `createdAt` (`.now`, `:521`), `opsData`,
  `objectIDs`, and the newest additions `routeRaw` and `model` (`:539-547`). The record is made in
  `ActionEngine.perform` (`Actions/ActionEngine.swift:52-63`), the one door every write goes through (app, Tess, intents).
- The `op` table: migration "v1" (`Model/TesseraDatabaseSchema.swift:39-42`), then "v2" adds `route` and `model` with two
  `ALTER TABLE op ADD COLUMN` (`:46-50`). Insert at `:106-114`, load at `:236-247`. Note the units: the `createdAt`
  column is seconds since 1970 (`:113`); dates inside the `ops` blob (`FieldValue.date`) are default `JSONEncoder`
  seconds since 2001. A zone is neither, so this does not matter for the change, but tests should not mix them up.
- `.tessera` backup (`Export/TesseraBackup.swift`): a plain SQLite copy plus `backupInfo` (`:42-49`). Version checks go by
  migration names: `inspect` refuses a file with a migration this build does not know (`:131-133`, `newerSchema`).
  Restoring opens the file as the store, and `TesseraContext.init` runs the migrator (`Model/TesseraContext.swift:48`).
- JSON export: `OpEntry` (`Export/TesseraExport.swift:65-77`) already has optional `route` and `model` that "older exports
  leave out"; write at `:135-138`, restore at `:243-251`. `currentVersion = 1` (`:7`).
- How logged items get their day: workouts by `TesseraDay.day(of: startedAt)` (`WorkoutSummary.swift:101`); done tasks by
  the 04:00 interval on `doneAt` (`Tasks/Tasks.swift:39-45`); a past-dated note moves its object's `createdAt` to `on`
  (`Notes/Notes.swift:106-108`). `TesseraDay.day(of:)` reads the hour in `calendar` (`Engine/TesseraDay.swift:22-26`).

## Which records need a zone
A zone only matters for things whose **day** is fixed when they happen and read later, maybe somewhere else:
workouts (start), done tasks (`doneAt`), notes and captures (`createdAt` or `on`), sets, cooks, shops, every Day log line.
It does not matter for: class and field definitions, links, views, timed tasks and reminders (fixed instants, dst-travel
rule 6), durations (absolute, rule 3), or the backup's own name (zone in force at the write, backup-logical-day T8).

**Default: one zone per op record, not a field per class.** Every logged item is born in an op, and every op is made in
one place (`ActionEngine.swift:52`). So one column covers every class, today's and the ones packs add later, with no
`FieldDef`, no catalog change and no per-class rules. dst-travel Q1 proposed a `zone` field on workouts, done tasks and
notes; that needs three catalog fields, a write in three actions, and misses captures, cooks and shops. The op answers it.
- The zone of an op is `TimeZone.current.identifier` at perform ("America/Los_Angeles"), not an offset or abbreviation:
  the identifier plus the instant gives the offset, DST included. In flight the phone keeps the departure zone, which
  is what case 7 wants.
- The zone of a logged item is the zone of the op that set the date it is dated by: the workout's root op
  (`startWorkout`, the earliest record whose `objectIDs` holds it), the record that set `doneAt`, the note's `createNote`.
  Finding the first record that touched an object needs only `objectIDs` (a TEXT column read at load), no blob decode.

## Schema change and GRDB migration
```swift
migrator.registerMigration("v3") { db in try db.execute(sql: "ALTER TABLE op ADD COLUMN zone TEXT") }
```
- `OpRecord.zone: String?` with `didSet { didChange() }`, like `model`. Add `zone` to the insert (`:108-114`) and
  `record.zone = row["zone"]` to the load (`:245-246`).
- Old rows get NULL. NULL means "the device zone at read time", which is exactly what master does today, so nothing old
  changes meaning. No backfill: guessing LA for history is right for every op so far but wrong to write down as fact.
- Set it in `perform` next to the attribution (`ActionEngine.swift:59-62`): `record.zone = zone().identifier`, with
  `zone: () -> TimeZone = { .current }` on the engine so tests inject LA or New York. Undo and redo records get the
  zone of the moment they were made; a pending Tess record keeps the zone of the proposal.
- `TesseraLegacyStore` copies leave it NULL. Cost per row: about 20 bytes.

## Op log JSON and .tessera backup
- **`.tessera`**: no code change. The file is the store, so the column rides along. Old backup restored on a new build:
  the migrator runs "v3" on open and old rows read NULL. New backup on an old build: `inspect` already says
  `newerSchema` (`TesseraBackup.swift:133`). `backupInfo` and `TesseraBackup.version` stay as they are.
- **JSON export**: `OpEntry.zone: String?`, written at `:136-138`, restored at `:249-250`, the same pattern as
  `route`/`model`. `currentVersion` stays 1: the key is optional and additive, so old exports decode with nil. An older
  build reading a new export ignores the key (the zone is lost on that import, nothing else). Sorted keys keep it stable.
- An unknown identifier on read (a renamed tzdb name is mapped by Foundation; a garbage string is not) falls back to the
  current zone, never throws.

## TesseraDay and the Day log fold
- Add `TesseraDay.day(of date: Date, loggedIn zone: String?) -> Date`: run `day(of:)` with the calendar's zone swapped
  for `zone` (nil or unknown: unchanged), take year, month and day there, and return the midnight of that date **in
  the current calendar**. Keys stay current-zone midnights, so week strips, Review and `isSameDay` keep working.
- `finishedWorkouts(onDay:)` (`WorkoutSummary.swift:101`): `day(of: started, loggedIn: rootZone(workout))`. The zone
  cache key (`:92-96`) stays: the keys still move with the current zone.
- `Tasks.today` (`Tasks.swift:44-45`): a done task is today when `day(of: doneAt, loggedIn:)` equals `today(now)`, not the
  04:00 interval test, which is in the current zone only.
- `DayStory` (not on master): fold rule 1 becomes `day(of: root.createdAt, loggedIn: root.zone)`, the group takes its
  root's day and zone (late-night Day 4), a past-dated note uses its object's `createdAt` with its op's zone.
- Times inside a block still print in the current zone (dst-travel open Q6). With a zone stored, the Day 5 default
  ("10:30, 00:40, 04:30" read in New York) can switch to the logged zone's times; Product's call, not needed for days.
- A small cache, object id to root zone, built from `objectIDs` once per revision in `DerivedCache`
  (`ObjectStore+Caches.swift:87-99`), so Home does not scan the log per workout (`ActionEngine.swift:222` is linear).

## The 8 wrong-day cases (day-log-late-night.md)
| # | Item | Fixed by a stored zone? | What fixes it |
|---|---|---|---|
| 1 | Push Day B 23:20 to 00:52 | No | group by root, `TesseraDay` |
| 2 | Note 02:10 | No | `TesseraDay` instead of calendar day |
| 3 | Note "yesterday" at 02:12 | No | date by the object's `createdAt` (`on`) |
| 4 | Done 03:55 | No | `TesseraDay` |
| 5 | Pull Day A 03:50 to 04:30 | No | group by root |
| 6 | Mobility 21:40 PDT read in NY | Made safe | right fold already gives Mon (00:40 EDT < 04:00); a zone keeps it Mon for a later start, e.g. 01:30 PDT read as 04:30 EDT |
| 7 | In-flight note 01:30 PDT read in NY | **Yes** | only fix: 04:30 EDT is Tue; in its logged zone it is 01:30, Mon |
| 8 | Fall-back night after 00:00 | No | `TesseraDay` (wall-clock hour), minutes on `Date` |

So six of eight are fold bugs and need no zone. The zone fixes case 7 outright, hardens case 6, and also fixes
dst-travel D07 (a hotel-gym workout at 05:40 EDT viewed at home turns to Tue under `TesseraDay` in LA).
`inFlightNoteKeepsLoggedZoneDay` loses its `withKnownIssue`.

## Cost
Write side (the part that cannot wait): `Model/Models.swift`, `Model/TesseraDatabaseSchema.swift`,
`Actions/ActionEngine.swift`, `Export/TesseraExport.swift`. About 25 lines, no UI, no catalog change. Half a day with tests.
Read side (with `DayStory`): `Engine/TesseraDay.swift`, `Engine/ObjectStore+Caches.swift`, `Training/WorkoutSummary.swift`,
`Tasks/Tasks.swift`, the DayStory fold. About 80 lines plus tests.

Tests (Swift Testing, fixed zones, never `.current`):
- `SchemaSafetyTests`: `v3AddsNullableZoneAndOldRowsReadNil`, `zoneRoundTripsThroughSaveAndLoad`.
- `ActionEngineTests`: `performStampsInjectedZone`, `undoRecordTakesZoneOfItsOwnMoment`.
- `BackupTests`: `oldBackupWithoutZoneRestoresWithNilZone`, `backupWithV3IsNewerSchemaForV2Build` (fake migrator list).
- `ExportTests`: `exportWithoutZoneKeyDecodes`, `zoneSurvivesExportAndRestore`.
- `TesseraDayTests`: `dayOfLoggedInZoneMapsToCurrentMidnight` (D07: 10:30Z logged NY is Wed 28 in LA),
  `nilOrUnknownZoneFallsBackToCurrent`, `fallBackNightInLoggedZoneIsOneDay`.
- `DayStoryLateNightTests`: `inFlightNoteKeepsLoggedZoneDay`, `workoutDayComesFromRootOpZone`.

Risks:
- A clock or zone set by hand (Set Automatically off, as the QA steps do) stores that zone; that is the honest answer.
- Mixed zones: two items can share a day key but sit hours apart. Sort inside a day by instant, never by printed time.
- Key mapping: returning a logged-zone midnight instead of a current-zone midnight would silently miss every cache
  and grid. The `dayOfLoggedInZoneMapsToCurrentMidnight` test guards it.
- An export now shows where he was each day. It is his own file, but worth one line on the Backups page.
- Ops written through a path other than `perform` would miss the zone; today there is none (`git grep "OpRecord("`
  finds only `ActionEngine.swift:52`, the export restore `:244` and the store load `TesseraDatabaseSchema.swift:237`).

## Recommendation: write the column now, read it with DayStory
Do the write side now, as its own small PR, before the 26 Oct LA to New York trip in dst-travel (10 days away).
Reason: a zone not written at log time can never be recovered. Every op logged without one is permanently "device zone
at read time", which is wrong for exactly the records that matter (travel days). The op log is a few weeks old and all
LA, so NULL for the past costs nothing today; each week of waiting adds history that can never be fixed. The write side
is one nullable column, one optional JSON key and one line in `perform`, and it follows the v2 `route`/`model` pattern
step for step, so the risk is close to zero and no backup or export version changes.
Do the read side later, with `DayStory`: it only matters once a trip happens, and until then NULL and LA read the same.
Not recommended: a `zone` field per class (dst-travel Q1 as written). More catalog work, misses captures and cooks, and
it would need its own migration for every class a pack adds.
