# Apple Health round trip (board item AY, for Builder A 0m)

For: Builder A (body weight page, Health read, 0m), Core (`HealthExporter`, engine observers, PrivateFacts), QA.
Owner: Research lab. Date: Oct 16, 2026 (Pacific). Every value below is made up.

Read against `origin/master` at c7346eb. Nothing here was built or run; status comes from reading the code.

## The rules this file checks

From `docs/product/decisions.md` on master:

- **1:23 pm PT Oct 16, body weight.** Apple Health is read only in v1. One entry a day. Tessera's entry wins, and
  Health fills the gaps. Siri says "Body weight logged." and never the number. A sick mark holds every habits ask that
  day. "sick", "unwell" and "feeling sick" join PrivateFacts on the next build.
- **12:45 pm PT Oct 16, undo windows.** Undoing a finish removes the Health workout. Plain hold-to-finish gets a 10 s
  UNDO. Undo windows pause in the background. Siri undo has no window. (1:35 pm refines this into one UNDO slot.)
- **5:14 pm PT Oct 15.** `App/Health/HealthExporter.swift` is Core's. Undoing a finish also deletes the Health
  workout we wrote.
- **5:56 pm PT Oct 15.** One ask a day, never from a background finish. Core replaces the Health read string with an
  honest one.
- **12:02 pm and 1:36 pm PT Oct 16.** Body and health facts stay on the phone with or without a number.

Other fixtures this file leans on instead of repeating:

- Weight phrases and the weigh-in week: [`habits-weight-week.md`](habits-weight-week.md) (HW1, HW12, HW37, HW38;
  gaps A1 to A3) and [`body-weight.md`](body-weight.md) (BP1 to BP6). Health dedupe: H16 in
  [`../calendar-health-fixtures.md`](../calendar-health-fixtures.md) and [`../healthkit-reads.md`](../healthkit-reads.md).
- Sick and rest marks: [`day-marks.md`](day-marks.md) (DM1 to DM13, D4, D5), and the word sweep in
  [`private-health-words.md`](private-health-words.md).
- The Oct 26 trip and zones: [`trip-week.md`](trip-week.md) (TW1 to TW21), [`trip-rehearsal.md`](trip-rehearsal.md).
- The Nov 1 fall-back night: [`dst-nov-1.md`](dst-nov-1.md) (DS1 to DS37), [`dst-travel.md`](dst-travel.md).
- Undo wording: [`undo-collision.md`](undo-collision.md).

## What master has

- One file talks to HealthKit: `App/Health/HealthExporter.swift`, created in `App/TesseraApp.swift:38`.
- It **writes** finished workouts only: `requestAuthorization(toShare: [workoutType], read: [])`
  (`HealthExporter.swift:42`). It **reads nothing**: no bodyMass, no sleep, no heart rate.
- It listens to `ActionEngine.observe` (`HealthExporter.swift:16-23`) and saves on `finishWorkout` or
  `finishWorkoutEarly` (`:27-29`). Each save is a traditional strength training workout with the workout id as
  `HKMetadataKeySyncIdentifier`, the end time in seconds as `HKMetadataKeySyncVersion`, and two metadata numbers:
  sets and volume in kg (`:59-66`). A workout with no sets, or no start and end, is skipped (`:51`).
- `ActionEngine.undo` and `redo` replay ops and set the state, but never call `notify` (`ActionEngine.swift:143-155`;
  `notify` is only called at `:71`, `:110`, `:124`). So no integration hears a take-back.
- There is no delete path to Health, no body weight class, no weight page, no sick mark, and no Health setting.
- Entitlements: `App/Tessera.entitlements:5-7` has the HealthKit keys. `project.yml:73` is the write string (honest).
  `project.yml:74` says Tessera "reads your workouts, heart rate and body weight", and nothing reads any of them.
- Tests: `TesseraTests/HealthExporterTests.swift:6-15` checks only which action names export.

## Simulator or device

HealthKit on the iOS 27 Simulator does: `isHealthDataAvailable()` is true, the permission sheet shows, workouts and
bodyMass samples save and read back, the Health app is there to add a weight by hand or delete a workout, and
Settings > Health > Data Access can turn read or write off. So most rows can be walked on the iPhone 17 simulator.

It does not do, or does not do faithfully: data from an Apple Watch or a smart scale (no paired sources), protected
data while the phone is locked (Health's store is unreadable and unwritable while locked, which the simulator does
not enforce the same way), background delivery wake-ups, Health's iCloud sync between devices, and the real sign-in
state of his free developer account. Rows that depend on those say **Device** below. Every row can still get a unit
test with the fake store, so "Device" means "also walk it once on the phone", never "untested".

Launch flags work only on the simulator (`App/LaunchFlags.swift`), so device rows use real time, not `-demoTime`.

## The cases

Columns: **Health after** is what the Health app shows (Browse > Activity > Workouts, or Body Measurements > Weight).
**Tessera after** covers Home, the Day log, the weight page and Review. **Master** is pass, wrong or not built, with
file:line. **Where** is Sim or Device.

Fixed values: his weigh-ins are 82.4 kg (Tessera) and 82.6 kg (Health, from a scale). Push A runs 6:02 pm to 7:10 pm,
18 sets, 9,840 kg. Week of Mon Oct 19 unless named.

### Body weight (Health read, Tessera wins)

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR1 | Health read on. Scale writes 82.6 kg to Health at Tue Oct 20 6:40 am | He types `bw 82.4` at 7:05 am | 82.6 kg at 6:40 am, unchanged. Tessera writes no bodyMass (read only) | One entry for Tue: 82.4. Weight page: "82.4 this morning", one dot for Tue, no second dot. Home: the receipt "Body weight logged. 82.4 kg." (HW36). Day log: a private line, no number in any story. Review: no weight clause (HW30) | not built: no read (`HealthExporter.swift:42`, `read: []`), no BodyWeight class (A2 in habits-weight-week) | Sim |
| HR2 | As HR1, but the order flips: he types `bw 82.4` at 6:30 am, the scale writes 82.6 at 6:40 am | Opens the weight page at 7:00 am | 82.6 kg at 6:40 am | Still 82.4. Tessera's entry wins whatever came first; the later Health value never replaces it | not built (as HR1) | Sim |
| HR3 | No Tessera entry on Wed Oct 21. Health has 82.5 kg at 6:50 am | Opens the weight page | 82.5 kg | Wed fills from Health: 82.5, drawn as Health's dot (Design picks the mark; no "from Health" word needed in the line). Trend and weekly rate use it | not built | Sim |
| HR4 | Health has two weigh-ins on Thu Oct 22: 82.7 kg at 6:45 am and 83.1 kg at 9:30 pm | Opens the weight page Fri | Both samples | One entry for Thu. Which one is Q2 below; the pick is the first after 4 am, 82.7 | not built | Sim |
| HR5 | HR1 done (Tessera 82.4 on Tue) | He takes the entry back inside its 10 s UNDO: "Body weight, taken back." | 82.6 kg, unchanged | Tue falls back to Health's 82.6. The gap fills again, nothing is lost | not built | Sim |
| HR6 | HR3 done (Wed filled from Health) | He deletes the 82.5 kg sample in the Health app, then opens Tessera | No weight on Wed | Wed is empty on the weight page. Nothing of Health's value stays behind in Tessera's store (Q3) | not built | Sim |
| HR7 | His scale writes pounds: 181.7 lb on Sat Oct 24 7:00 am | Opens the weight page | 181.7 lb (Health shows his unit) | 82.4 kg (181.7 / 2.2046 = 82.42, shown to 0.1). Units follow the kg setting, never Health's | not built | Sim |
| HR8 | Health has 82.3 kg at Sun Oct 25 1:30 am (a late weigh-in) | Opens the weight page Sun noon | Under Sun Oct 25 (Health's days start at midnight) | Under **Sat Oct 24**, since his day runs 4 am to 4 am (`TesseraDay.swift:9-26`). If Sat has a Tessera entry, Tessera's wins and 82.3 is dropped | not built | Sim |
| HR9 | Siri, phone locked, scale has written 82.6 kg | "Hey Siri, log body weight 82.4 in Tessera" | 82.6 kg, unchanged | Siri says "Body weight logged." with no number. The entry is Tessera's and wins as HR1. Reading Health for the merge waits for the next unlock | not built | Device (locked store) |

### A finished workout

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR10 | Health write granted. Push A, 18 sets | Holds to finish at 7:10 pm | One Traditional Strength Training workout, 6:02 pm to 7:10 pm, 1 h 8 min, source Tessera, metadata 18 sets and 9,840 kg | Home: "Push A done". Day log: the session line under Tue. Review: Tue trained | pass (`HealthExporter.swift:50-68`) | Sim |
| HR11 | Push A with 4 of 6 exercises done | Finishes early from the running order | One workout, same shape, 12 sets | Two exercises marked skipped, one undo | pass (`HealthExporter.swift:27-29`; `HealthExporterTests.swift:6-10`) | Sim |
| HR12 | A workout opened, nothing logged | Finishes it | Nothing | "Push A, no sets, not saved." | pass (`HealthExporter.swift:51`, `sets > 0`) | Sim |
| HR13 | First finish ever, no Health answer yet | Finishes from live mode, in the app | Health's permission sheet shows once, after the finish, and only if no other ask came today | The finish lands first; the ask never blocks it | wrong: the ask fires on any first save with no one-ask-a-day check (`HealthExporter.swift:36-47`, called from `:21`). Owner Core | Sim |
| HR14 | First finish ever comes from the 6-hour wrap-up, Siri or the Lock Screen | Opens the app the next morning | No workout yet, and no sheet. The ask waits for an in-app finish (decisions 5:56 pm PT Oct 15) | "Push A saved. 6 of 6 exercises." (`ProcessTable.swift:144-151`) | wrong: the wrap-up's `FinishWorkout` by `.system` reaches the exporter, which asks at once (`ProcessTable.swift:144`, `HealthExporter.swift:17-21`, `:42`). Owner Core | Sim (Siri and Lock Screen: Device) |
| HR15 | Write granted. Phone locked | Finishes from the Lock Screen at 7:10 pm, unlocks at 7:30 pm | One workout, 6:02 pm to 7:10 pm, saved at the unlock | Same as HR10 | wrong: a locked-store save throws and is dropped with no retry (`HealthExporter.swift:69-71`). Owner Core | Device |

### Taken back and edited

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR16 | HR10 via LOG 80 × 8 AND FINISH | Taps UNDO within 10 s | The 6:02 pm workout is **gone** | Workout running again, the set's numbers back on the dial (`WorkoutSession.swift:437-445`). Home and Review: not trained yet. Line: "Push A, taken back." | wrong: `engine.undo` never notifies (`ActionEngine.swift:143-148`) and the exporter has no delete, so Health keeps the workout. Owners Core (notify on undo, exporter delete), Builder A (session) | Sim |
| HR17 | HR10 by a plain hold-to-finish | Taps the 10 s UNDO (decisions 12:45 pm) | The workout is gone | As HR16, no set taken back | not built: `canTakeBackFinish` is only set for LOG … AND FINISH (`WorkoutSession.swift:622-624`); no UNDO after a plain hold. Health delete as HR16 | Sim |
| HR18 | HR10 | "Hey Siri, undo in Tessera" (no window) | The workout is gone | As HR16 | not built: same missing delete as HR16 | Device (Siri) |
| HR19 | HR16 done | Logs one more set and finishes at 7:24 pm | One workout, 6:02 pm to 7:24 pm, 19 sets | Push A done, 19 sets | pass, by luck: same sync id, higher sync version (`HealthExporter.swift:61-62`) replaces the old one. Without HR16's fix, Health holds the stale 7:10 pm one in between, or forever if he never finishes again | Sim |
| HR20 | HR10 done | Edits set 3 of bench from 80 × 8 to 82.5 × 8 on the workout's page | Same workout, metadata volume 9,860 kg | Day log and Review use the edit | not built: no edit of a finished workout (`EditSet` only from the live session, `WorkoutSession+Edit.swift:39`), and no export on edit (`HealthExporter.swift:27-29`). Latent: the sync version is the end time (`:62`), so a re-save with the same end is not newer and Health keeps the old copy. Owner Core | Sim |
| HR21 | Wrap-up ended a forgotten workout at its last touch, 7:10 pm, but he left at 7:40 pm | Changes the end to 7:40 pm | One workout ending 7:40 pm | Duration 1 h 38 min | not built: no way to change the end on master. Health side as HR20 | Sim |

### A sick mark

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR22 | Thu Oct 22, Pull A due | Types `feeling sick, no gym` at 6:52 am | Nothing new. Tessera writes no symptom, no mindful minutes, nothing | Home: "Rest today. Pull A waits for tomorrow." (never the word "sick"). Day log: rest. Review: rest dab, not the miss ring. Habits ask held that day (1:23 pm). Never the model or Claude | wrong: "sick" is not in `symptoms` (`PrivateFacts.swift:55-58`), so it is not walled; no mark exists (`ReviewPage.swift:140`). Same as HW19 and D5. Owner Core 0ac | Sim |
| HR23 | HR22's mark | Feels better, trains Pull A at 6:00 pm, finishes | One workout as HR10 | The mark clears (DM4: trained today, so no mark); Review shows trained | not built (no marks); the Health part passes as HR10 | Sim |
| HR24 | Any finish on a sick day | Inspects the Health workout's details | Metadata: sync id, sync version, brand "Tessera", sets, volume. No title, no note, no mark | n/a | pass (`HealthExporter.swift:59-66`) | Sim |

### The Oct 26 trip

Zones and flights from [`trip-week.md`](trip-week.md): red-eye LAX Mon Oct 26 10:30 pm PDT, lands JFK Tue 6:45 am EDT,
home Wed Oct 28 9:20 pm PDT. A workout files under the day it started where he was (`WorkoutSummary.swift:97-104`).

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR25 | In New York | Hotel gym Tue Oct 27, 7:30 to 8:20 am EDT, finishes | One workout. In New York it reads 7:30 am Tue; back home it reads 4:30 am Tue (Health prints in the phone's zone) | Tue in both zones, printed in the phone's zone (TW10 rule) | pass (absolute dates, `HealthExporter.swift:58`, `:67`). No `HKMetadataKeyTimeZone` is set, which matches "times print in the phone's zone" | Sim |
| HR26 | In New York, the divergence window | Workout Tue 5:10 to 5:55 am EDT (2:10 am PDT) | Tue in Health in both zones (Health's day is midnight) | Tue (stored zone). At home Tessera still says Tue, though 2:10 am PDT alone would be Mon | pass for Health; Tessera side as TW rules | Sim |
| HR27 | In New York, Health read on | Hotel scale writes 82.9 kg Tue 6:50 am EDT; he opens the weight page at home Thu | 82.9 kg on Tue | 82.9 on **Tue**. Read naively in Pacific, 6:50 am EDT is 3:50 am PDT, before 4 am, so it would file under Mon (Q4) | not built | Device (scale in another zone) |

### The Nov 1 fall-back night

From [`dst-nov-1.md`](dst-nov-1.md): 1:00 to 1:59 am happens twice; first pass 8:00Z to 8:59Z, second 9:00Z to 9:59Z.

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR28 | Late session | Starts 12:50 am PDT (7:50Z), finishes 1:10 am PST (9:10Z) | One workout, 1 h 20 min (wall clock looks like 20 min) | Sat Oct 31 (before 4 am). Duration 1 h 20 min (DS rows) | pass (`end > start` on `Date`, `HealthExporter.swift:51`) | Sim |
| HR29 | Starts in the first 1:40 am, ends in the second 1:05 am | Finishes at 1:05 am PST (9:05Z) | One workout, 25 min, "1:40 to 1:05 am" | Sat Oct 31, 25 min | pass (`HealthExporter.swift:51`): the end is later in real time, so it saves | Sim |
| HR30 | Health read on | Scale writes 82.2 kg at the second 1:30 am (9:30Z) | Under Sun Nov 1 | Under Sat Oct 31 (Sat runs 25 h, to 4:00 am PST) | not built | Sim |

### Health read off or revoked

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR31 | Read never granted (he tapped Don't Allow) | Opens the weight page | Health has 82.6 kg | Only Tessera's entries. No error, no "no Health data" line, no second ask (W3 rule, 4:20 pm PT Oct 15). HealthKit never tells an app a read was denied, so this must look the same as "Health has nothing" | not built | Sim |
| HR32 | HR3 shown (Wed filled from Health) | Turns read off in Settings > Health > Data Access, reopens | Unchanged | Wed is empty again; Tessera's own entries stay | not built | Sim |
| HR33 | Write granted, then turned off mid-session | Finishes Push A | Nothing new | Workout safe. No error line (Health is a mirror) | pass in effect: the cached `authorized` stays true (`HealthExporter.swift:38-40`), the save throws and is dropped (`:69-71`). It works only because failure is silent | Sim |
| HR34 | Write off, then turned back on | Finishes Push B | Push B saves. Push A (from HR33) is missing for good | Push A and Push B both in Tessera | not built: no backfill of finishes that failed (Q6) | Sim |

### Privacy (body facts never go to Claude)

| id | Setup | Steps | Health after | Tessera after | Master | Where |
|---|---|---|---|---|---|---|
| HR35 | Any export | Reads what the export carries | Only start, end, activity type and the metadata in HR24 | Nothing leaves for Claude: the exporter has no Claude path, and Health's own iCloud sync is Apple's | pass (`HealthExporter.swift:50-68`) | Sim |
| HR36 | Health read on, weights filled from Health | Review's week story and Plan my day go to Claude | Unchanged | The pack has no weight, no mark kind, no Health value. A sick day goes as "rest day" at most. Memory turnover refuses weight and health words | not built for the read; today's guard holds (`WeekFacts.swift:3-5`, HW32; `TessMemory+Turnover.swift:104`, HW35). The read must keep it so | Sim |
| HR37 | First launch after the read ships | The Health sheet lists what Tessera reads | The sheet names body weight only | n/a | wrong: `project.yml:74` promises workouts, heart rate and body weight reads; v1 reads body weight only, and master reads nothing. Owner Core (decisions 5:56 pm PT Oct 15) | Sim |

## Counts

| Status | Count | Rows |
|---|---|---|
| pass | 10 | HR10, HR11, HR12, HR19, HR24, HR25, HR26, HR28, HR29, HR35 |
| pass in effect | 1 | HR33 |
| wrong | 7 | HR13, HR14, HR15, HR16, HR20 (latent sync version), HR22, HR37 |
| not built | 19 | HR1 to HR9, HR17, HR18, HR21, HR23, HR27, HR30, HR31, HR32, HR34, HR36 |

HR20 is counted under wrong for its latent sync-version bug; the edit itself is also not built. 37 cases in all.

Device rows: HR9, HR14 (Siri and Lock Screen legs), HR15, HR18, HR27.

## Gaps by owner

| id | Owner | Gap | Rows | Where |
|---|---|---|---|---|
| G1 | Core | Undo and redo never notify observers, so no integration sees a take-back | HR16, HR18 | `ActionEngine.swift:143-155` |
| G2 | Core | The exporter has no delete. On undo of `finishWorkout` or `finishWorkoutEarly`, delete the Health workout with that sync id | HR16 to HR18 | `HealthExporter.swift:16-23` |
| G3 | Core | The Health ask fires on any first save: no one-ask-a-day gate, and a background or wrap-up finish asks | HR13, HR14 | `HealthExporter.swift:36-47`; `ProcessTable.swift:144` |
| G4 | Core | A failed save is dropped with no retry (locked phone, write off) | HR15, HR34 | `HealthExporter.swift:69-71` |
| G5 | Core | The sync version is the end time, so an edit with the same end is not newer | HR20 | `HealthExporter.swift:62` |
| G6 | Core | The read string over-promises | HR37 | `project.yml:74` |
| G7 | Core 0ac | "sick" is not walled and there are no marks | HR22, HR23 | `PrivateFacts.swift:55-58`; `ReviewPage.swift:140` |
| G8 | Builder A | No bodyMass read, no BodyWeight class, no weight page, no merge | HR1 to HR9, HR27, HR30 to HR32 | none (A1 to A3 in habits-weight-week) |
| G9 | Builder A | No UNDO after a plain hold-to-finish; no edit of a finished workout | HR17, HR20, HR21 | `WorkoutSession.swift:431-445`, `:622-624` |

## Swift Testing cases

The tests run against two small protocols so no test touches HealthKit. `HKHealthStore` sits behind them in the app.

```swift
// App/Health/HealthStoring.swift (proposed)
protocol HealthWorkoutStoring: Sendable {
    func canAsk() -> Bool                          // one-ask-a-day gate, false from a background finish
    func requestWrite() async -> Bool
    func save(_ workout: HealthWorkoutDraft) async throws
    func deleteWorkout(syncID: UUID) async throws
}
protocol BodyMassReading: Sendable {
    func bodyMass(in interval: DateInterval) async throws -> [BodyMassSample] // empty when read is off
}
struct BodyMassSample: Equatable { let kilograms: Double; let at: Date; let zone: TimeZone? }

actor FakeHealthStore: HealthWorkoutStoring, BodyMassReading {
    var workouts: [UUID: HealthWorkoutDraft] = [:]  // keyed by sync id
    var samples: [BodyMassSample] = []
    var writeAllowed = true, readAllowed = true, locked = false, asks = 0
    func save(_ w: HealthWorkoutDraft) async throws {
        guard writeAllowed, !locked else { throw FakeError.denied }
        if let old = workouts[w.syncID], old.syncVersion >= w.syncVersion { return } // Health keeps the newer
        workouts[w.syncID] = w
    }
    func bodyMass(in i: DateInterval) async throws -> [BodyMassSample] {
        readAllowed ? samples.filter { i.contains($0.at) } : []   // denied looks like empty, as HealthKit does
    }
    // deleteWorkout, requestWrite (asks += 1), canAsk ...
}
```

The merge is a pure Core function, so most weight rows test in `swift test` with no app:
`BodyWeightDay.entries(tessera: [BodyWeight], health: [BodyMassSample], calendar: Calendar) -> [Date: Entry]`.
Calendars are built with a fixed zone, never `.current` (helper as in `dst-nov-1.md`).

| Test | Rows | Sketch |
|---|---|---|
| `tesseraEntryWinsOverHealthSameDay` | HR1 | Tessera 82.4 at 7:05 am, Health 82.6 at 6:40 am; `#expect(entries[tue]?.kilograms == 82.4)`, `#expect(entries.count == 1)` |
| `tesseraWinsWhateverCameFirst` | HR2 | Swap the times; still 82.4 |
| `healthFillsADayWithNoTesseraEntry` | HR3 | Health only on Wed; `#expect(entries[wed]?.source == .health)` |
| `twoHealthWeighInsKeepTheFirstAfter4am` | HR4 | 82.7 at 6:45 am and 83.1 at 9:30 pm; expect 82.7 |
| `takingBackTesseraEntryLetsHealthFillAgain` | HR5 | Undo the BodyWeight op; expect 82.6 from Health |
| `deletedHealthSampleLeavesNoTrace` | HR6 | Fake drops the sample; `#expect(store.objects(of: .bodyWeight).isEmpty)` and Wed empty |
| `poundsFromHealthShowInKilograms` | HR7 | 181.7 lb sample; `#expect(Format.kilograms(e.kilograms) == "82.4")` |
| `healthWeighInBefore4amFilesUnderTheDayBefore` | HR8 | Sun 1:30 am PDT; expect key Sat Oct 24 |
| `siriWeighInNeverSpeaksTheNumber` | HR9 | The intent's dialog equals "Body weight logged." and has no digit |
| `finishSavesOneStrengthWorkout` | HR10 | Perform `FinishWorkout`; fake has one draft, 6:02 pm to 7:10 pm, sets 18, volume 9,840 |
| `finishingEarlyReachesHealthLikeANormalFinish` | HR11 | Exists (`HealthExporterTests.swift:6`); add a fake-store save check |
| `emptyWorkoutNeverReachesHealth` | HR12 | Finish with no sets; `#expect(fake.workouts.isEmpty)` |
| `healthAskWaitsForOneAskADay` | HR13 | Another ask used today; finish; `#expect(fake.asks == 0)`, workout kept to save later |
| `backgroundFinishNeverAsks` | HR14 | Wrap-up via `ProcessTable.tidyNotes` with no prior answer; `#expect(fake.asks == 0)` |
| `failedSaveRetriesOnNextUnlock` | HR15, HR34 | `fake.locked = true`, finish, unlock, call the retry; expect one workout |
| `takingBackAFinishDeletesTheHealthWorkout` | HR16 | Finish, then `session.takeBackFinish()`; `#expect(fake.workouts[workoutID] == nil)` |
| `undoNotifiesObservers` (Core) | HR16, HR18 | Observe; `engine.undo(record)`; expect the observer saw the record with state `.undone` |
| `holdToFinishHasTenSecondUndo` | HR17 | Plain `finish()`; `#expect(session.canTakeBackFinish(at: t + 9))`, false at `t + 10` |
| `refinishReplacesNotDuplicates` | HR19 | Finish, take back, finish again; `#expect(fake.workouts.count == 1)` with the 7:24 pm end |
| `editAfterFinishResavesWithNewerVersion` | HR20 | Same end, new volume; expect the fake holds 9,860. Fails today: version is end seconds |
| `changingTheEndMovesTheHealthWorkout` | HR21 | End 7:10 pm to 7:40 pm; one workout ending 7:40 pm |
| `feelingSickIsWalledAndMarksRest` (Core) | HR22 | `#expect(PrivateFacts.isWalled("feeling sick, no gym"))`; the grammar returns a rest mark |
| `trainingClearsTheSickMark` | HR23 | Mark, then finish; expect no mark and one Health workout |
| `exportCarriesNoTitleNoteOrMark` | HR24, HR35 | Inspect the draft's metadata keys; expect exactly sync id, sync version, brand, sets, volume |
| `hotelWorkoutFilesUnderStartDay` | HR25, HR26 | NY start 5:10 am EDT, read in Pacific; expect Tue; Health draft dates are absolute |
| `healthWeighInFilesByZoneItWasTaken` | HR27 | Sample with zone New York at 6:50 am, calendar Pacific; expect Tue |
| `workoutAcrossFallBackKeepsRealDuration` | HR28, HR29 | 12:50 am PDT to 1:10 am PST; draft duration 4,800 s; 1:40 first to 1:05 second saves 1,500 s |
| `secondOneThirtyWeighInFilesUnderSaturday` | HR30 | 9:30Z Nov 1; expect Sat Oct 31 |
| `readOffLooksLikeNoHealthData` | HR31, HR32 | `fake.readAllowed = false`; entries are Tessera's only; no line text produced |
| `writeOffIsSilent` | HR33 | `fake.writeAllowed = false`; finish; no error line, workout in the store |
| `healthWeightNeverEntersClaudePacks` | HR36 | Health-filled week; `WeekFacts` and the plan pack JSON contain no weight digits and no "sick" |
| `readStringNamesOnlyBodyWeight` | HR37 | Read `NSHealthShareUsageDescription` from the bundle; expect it names body weight and not heart rate |

## Privacy check of the export path

- What goes out: the workout's start, end, activity type, and metadata of sets, volume in kg, brand "Tessera" and the
  sync id (`HealthExporter.swift:53-66`). No title, no note, no body weight, no mark. Health is on the phone; its
  iCloud sync is Apple's end-to-end encrypted Health data, not Claude.
- What never goes to Claude: nothing in the exporter calls the router or Claude. Body facts are walled by
  `PrivateFacts.isWalled` (`PrivateFacts.swift:7-11`) for every Claude caller. Sick and health words are walled from
  memory today (`TessMemory.swift:96-104`) but not from Claude ("sick" missing from `symptoms`, HR22).
- The risk arrives with the read. Health-filled weights must stay out of `WeekFacts`, the Plan my day pack and the
  memory turnover, the same as typed weights (HR36). A sick mark's kind must reach no pack; at most "rest day".

## Open questions for Product

1. **Q1. Does Tessera write bodyMass to Health?** Pick: no, read only in v1 as decided at 1:23 pm. Revisit only with a
   second device, so the two never echo.
2. **Q2. Two Health weigh-ins on one day with no Tessera entry: which one?** Pick: the first after 4 am, since a
   morning weigh-in is the comparable one. Later ones are ignored, not averaged.
3. **Q3. Are Health-filled weights copied into Tessera's store?** Pick: no. Read on open and keep an in-memory cache
   only, so a delete or a revoke in Health takes effect, and nothing body-shaped lands in the op log or a backup.
4. **Q4. Which zone files a Health weigh-in?** Pick: `HKMetadataKeyTimeZone` when the sample has it, else the zone
   of the nearest Tessera op in time (where he was), else the phone's zone. Matches the trip rule for workouts.
5. **Q5. Should the exporter set `HKMetadataKeyTimeZone` from the stored op zone?** Pick: yes, small and harmless;
   Health then shows a hotel workout at hotel time in its detail view. Not a blocker.
6. **Q6. Retry a finish that failed to reach Health?** Pick: yes, keep a small "owed to Health" list of workout ids,
   retried on the next unlock or foreground; drop an id once it is taken back. No backfill of anything older.
7. **Q7. Write turned off: say anything?** Pick: no line on Home; one plain line on the Health row in Settings
   ("Health saving is off.") with a link to Settings, like the calendar rule. Never an error.
8. **Q8. Sync version.** Pick: use a counter bumped on every change to the workout (finish, edit, end change), not
   the end time, so an edit always replaces.
9. **Q9. Free developer account and HealthKit on his phone.** CLAUDE.md says no paid account; master ships HealthKit
   entitlements. Pick: Builder A confirms once on the phone that a finish reaches Health before 0m builds the read on
   top. If it does not, HR10 and every write row become simulator-only until the account changes.
