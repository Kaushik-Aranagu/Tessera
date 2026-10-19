# HealthKit reads: one small layer for W1 and W3

For: Core engine · Date: 2026-10-15 · Research lab
Reads with: `apple-watch.md` (W1, W3), `recovery-line.md` (W3 rule), `calendar-health-fixtures.md` (H01 to H17), `free-signing-survival.md`. Code: origin/master `e55d6d4`. Core owns `App/Health/`.

**Bottom line.** Add one protocol, `HealthReading`, in Core with plain value types and no HealthKit import. The app side, `App/Health/HealthKitReader.swift`, fills it with `HKSampleQueryDescriptor` reads over short date windows. Core turns samples into the few numbers W1 and W3 need (last night, resting HR, overnight HRV, workout HR). Ask for read access in context, never at launch. Treat "denied", "no Watch" and "no data" as the same quiet absence. Nothing read from Health is stored, logged or packed.

## 1. What master has today

- `App/Health/HealthExporter.swift` only writes: `requestAuthorization(toShare: [workoutType()], read: [])`, asked lazily on the first save. It caches `authorized` from `authorizationStatus(for: .workoutType())`, which only describes sharing. The read layer must not reuse that flag.
- `App/Tessera.entitlements`: `com.apple.developer.healthkit` = true, `healthkit.access` = empty array. Reads need nothing more (the access array is for clinical records only).
- `project.yml` already has both keys, and both say "Tessera saves your finished workouts to Apple Health." The share (read) string is wrong today and must change in this slice.

## 2. Read types

| Type | Kind, unit | Window | Used by | Core reads it as |
|---|---|---|---|---|
| `HKCategoryType(.sleepAnalysis)` | category: `asleepCore`, `asleepDeep`, `asleepREM`, `asleepUnspecified` (= `allAsleepValues`), `awake`, `inBed` | sample end in 18:00 yesterday to 14:00 today; 29 days for the baseline | W3 | `night(for: day)`: asleep minutes, stages, source |
| `HKQuantityType(.restingHeartRate)` | discrete, count/min | last 36 h; 29 days for the baseline | W3 | `restingHR(at: now)`: latest, nil if older than 36 h |
| `HKQuantityType(.heartRateVariabilitySDNN)` | discrete, ms | the night's asleep span | W3 | `overnightHRV(night)`: mean of samples starting inside the span |
| `HKQuantityType(.heartRate)` | discrete, count/min | workout start to end | W1 | `workoutHR(start:end:)`: avg and max, nil under 3 samples |
| `HKObjectType.workoutType()` (read) | `HKWorkout` | the workout's day | W4 later | Overlapping Apple Watch workout (source `productType` starts with "Watch") |

Ask for the first four now. Add the workout read with W4: a new type shows the sheet again for that type only, so nothing is lost by waiting.

Apple facts that shape the rules: "Samples recorded by Apple Watch only include awake samples that occur between two sleep samples", and detailed samples "overlap the in-bed sample, but they don't overlap each other" ([HKCategoryValueSleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)). Apple DTS: "We stopped recording the inBed samples on watchOS 11 and iOS 18" ([forum 766977](https://developer.apple.com/forums/thread/766977)). So `inBed` now comes only from the iPhone sleep schedule or third-party apps, and nights must be found from asleep and awake samples, not from `inBed`.

## 3. Query APIs (iOS 27, Swift concurrency)

- **`HKSampleQueryDescriptor`** for every read in this slice: one-shot, `result(for: store)` returns typed samples ([Running queries with Swift concurrency](https://developer.apple.com/documentation/healthkit/running-queries-with-swift-concurrency)). Always a bounded date predicate, sorted by start date. Apple warns: "limit the number of results your queries may return... or specify a restricted date range". A 29-day sleep read is about 500 samples; workout HR with a Watch workout running is under 1,000. Fine.
- **`HKStatisticsQueryDescriptor`** (iOS 15.4+, `result(for:) -> HKStatistics?`, [docs](https://developer.apple.com/documentation/healthkit/hkstatisticsquerydescriptor)) with `[.discreteAverage, .discreteMax]` is the one-call way to get workout HR. Apple: "you can combine any number of discrete options" ([HKStatisticsOptions](https://developer.apple.com/documentation/healthkit/hkstatisticsoptions)). We still read raw samples and compute in Core, so the source rule is ours and testable with the fake. Use the statistics descriptor only as a DEBUG cross-check on device (avg within 1 bpm). Avoid `HKStatisticsCollectionQueryDescriptor` for now: an iOS 27 forum report says it "intermittently returns no data for certain date ranges" while sample and single statistics queries see the data ([forum 838450](https://developer.apple.com/forums/thread/838450), no Apple reply, unverified).
- **`HKAnchoredObjectQueryDescriptor`** (`init(predicates:anchor:limit:)`, one-shot or long-running `results(for:)`, anchors are `NSSecureCoding`) ([docs](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquerydescriptor)). Not in this slice. Saving an anchor only pays off if we keep a local copy of samples, and section 8 says we keep none. Re-reading 29 days on foreground is cheap. Revisit if a feature ever needs late-synced changes pushed while open (H10 is covered by re-reading on every foreground of the wake day).
- Read only in the foreground. A locked store throws (H17); that is an error, not "no data".

## 4. Asking for permission

- **Never at launch.** Ask the first time a feature needs it, in context:
  - W1: when the first workout finishes after W1 ships. Fold `heartRate` into the existing save prompt: `requestAuthorization(toShare: [workoutType()], read: [heartRate])`. One sheet, at the moment the summary wants the line.
  - W3: the first training-day morning after W3 ships, Now shows one tappable quiet line, "Add last night's sleep from Health?" Tapping asks for sleep, resting HR and HRV. Dismissed or answered, it never shows again. Product to confirm (the recovery line is otherwise silent).
- Before asking, call `statusForAuthorizationRequest(toShare:read:)`: `.unnecessary` means the sheet was already shown, so skip straight to reading.
- **Denial is hidden.** Apple: "HealthKit does not tell you when the user denies your app permission to query data. Instead, it simply appears as if HealthKit does not have any data matching your query" ([HKAuthorizationStatus](https://developer.apple.com/documentation/healthkit/hkauthorizationstatus)). So: denied, no Watch, Watch not worn and no data must give byte-identical results (the fixture D06 test runs twice). No screen ever says "denied" or "no data". The only hint lives in Settings: if 30 days return no sleep and no heart rate, Settings shows one quiet line, "Tessera sees no sleep or heart data. Health > Profile > Apps > Tessera to check." Never on Now, never a badge.
- **iOS 27 history choice (unverified).** A forum post says the iOS 27 read sheet asks "Past 30 Days and Future Data" or "All Recorded Data and Future Data", and that a 30-day grant looks the same as a new Watch owner ([forum 842499](https://developer.apple.com/forums/thread/842499), no Apple reply). Our 28-day baseline fits inside 30 days, so either answer works. `HKHealthStore.earliestAuthorizedSampleDate(for:)` exists in Apple's docs (search result); the page would not load, so its behaviour is unverified.

## 5. Info.plist (project.yml, `targets.Tessera.settings.base`)

```yaml
INFOPLIST_KEY_NSHealthUpdateUsageDescription: Tessera saves your finished workouts to Apple Health.
INFOPLIST_KEY_NSHealthShareUsageDescription: Tessera reads your sleep and heart rate to show workout heart rate and a quiet note on training days. It stays on this iPhone.
```

Plain, no "please", no promise of advice, says where the data stays (tess-voice principles 3, 4 and 6). The system shows it, so it names Tessera, not "I".

## 6. Free signing: entitlement status

**Not verified** as of 2026-10-15. Nobody has recorded a successful device install of the HealthKit entitlement on the Personal Team (`v1-gap-audit.md:47`, `free-signing-survival.md` checklist step 2). Evidence either way is indirect: an Apple DTS reply says personal teams register App IDs "including those with associated capabilities like App Groups and HealthKit" ([forum 834802](https://developer.apple.com/forums/thread/834802)); a 2022 thread asking the same question has no answer ([forum 722522](https://developer.apple.com/forums/thread/722522)). Reads add no new entitlement, so they carry exactly the write's risk. If Xcode refuses, `HealthKitReader` is never built and the app uses `NoHealth` (always empty), which section 4 already treats as normal.

## 7. The protocol and the fake (Core, no HealthKit)

```swift
// TesseraCore/Sources/TesseraCore/Health/HealthReading.swift
public struct HealthSource: Sendable, Hashable { public var bundle: String; public var productType: String?
    public var isWatch: Bool { productType?.hasPrefix("Watch") == true } }
public enum SleepStage: Sendable { case inBed, awake, core, deep, rem, unspecified }
public struct SleepSample: Sendable { public var stage: SleepStage; public var start, end: Date; public var source: HealthSource }
public enum HealthQuantity: Sendable { case heartRate, restingHeartRate, hrvSDNN }   // bpm, bpm, ms
public struct QuantitySample: Sendable { public var kind: HealthQuantity; public var value: Double; public var start, end: Date; public var source: HealthSource }
public enum HealthReadError: Error, Sendable { case unavailable, storeLocked }       // never "denied"

public protocol HealthReading: Sendable {
    func requestAccess(to kinds: Set<HealthQuantity>, sleep: Bool) async          // in context only
    func sleep(from: Date, to: Date) async throws -> [SleepSample]
    func quantities(_ kind: HealthQuantity, from: Date, to: Date) async throws -> [QuantitySample]
}
public struct FakeHealth: HealthReading { /* samples from a fixture, plus mode: .normal, .denied (returns []), .locked (throws) */ }
public struct NoHealth: HealthReading { /* always [] */ }
```

`HealthReads` (pure, in Core) holds the rules: window, clustering, source choice, staleness, minimum counts. `App/Health/HealthKitReader.swift` only maps `HKCategorySample`/`HKQuantitySample` into these structs (`sourceRevision.source.bundleIdentifier`, `sourceRevision.productType`). Engine tests use `FakeHealth` and never import HealthKit; `-resetDemo` can seed the same fixtures.

**Rules** (from H01 to H17, one refinement). Night: samples ending 18:00 yesterday to 14:00 today; pick the source (Watch, else most asleep minutes; never sum); cluster that source's asleep and **awake** samples with gaps under 90 min (awake joins a cluster, refining H05); the night is the cluster with most asleep minutes; others are naps. Asleep = core + deep + REM + unspecified. No asleep samples: asleep nil, `inBed` reported separately. Workout HR: samples inside start to end; Watch wins, else the source with most samples; under 3 samples gives nil; avg rounded to the nearest bpm. Resting HR: latest, Watch wins on the same day, nil if older than 36 h.

## 8. Fixtures: 15 days (America/Los_Angeles, wake day D, read at 07:30 unless noted)

Watch = `{bundle: com.apple.health.W1, productType: Watch7,1}`, iPhone = `{com.apple.health, iPhone18,1}`.

| Day | Health samples | Expected reads |
|---|---|---|
| D01 Oct 6 | Watch core/deep/REM 23:10 to 06:40, awake 03:00 to 03:15; iPhone inBed 22:50 to 06:55. RHR 54. HRV 46, 50 overnight. Push A 18:30 to 19:25, 15 Watch HR: 96 104 112 118 121 125 130 138 142 147 152 133 120 110 102 | night 435, Watch, inBed 485; RHR 54; HRV 48; workout avg 123, max 152 |
| D02 Oct 7 | Watch core 23:40 (Oct 6) to 07:05. RHR 55, HRV 44 | night 445 on Oct 7; nothing for Oct 6 |
| D03 Oct 8, read 16:00 | Watch night 23:30 to 06:30; nap 12:40 to 13:20; HRV 52 at 03:00, 30 at 13:00. RHR 53 | night 420 (nap ignored); HRV 52 (nap sample outside span) |
| D04 Oct 9 | Watch stages 412 min; AutoSleep (iPhone) asleepUnspecified 23:00 to 07:05 (485). RHR 54 at 06:40, HRV 47 | night 412, Watch (never 897) |
| D05 Oct 10 | Watch charging: iPhone inBed 23:05 to 06:50 only | asleep nil, inBed 465; RHR 54 (24 h 50 m old, kept); HRV nil |
| D06 Oct 11 | No samples at all. Run twice: `.normal` and `.denied` | night nil; RHR nil (48 h 50 m, stale); HRV nil; both runs byte-identical |
| D07 Oct 12 | Watch night 440. RHR 54, HRV 50. Pull A 18:00 to 19:00, Watch put on late: HR at 18:52, 18:57 | workout HR nil (2 samples), so no line |
| D08 Oct 13 | Watch night 455. RHR 55, HRV 45. Legs 18:30 to 19:30: 12 Watch HR 100 110 120 130 140 150 140 130 120 110 100 90; Polar strap app, 55 samples, max 171 | avg 120, max 150 (Watch wins, strap ignored) |
| D09 Oct 14 | Evening nap 18:30 to 19:10 (Oct 13, inside window); Watch 01:20 to 08:10. RHR 53, HRV 51 | night 410 (nap cluster ignored) |
| D10 Oct 15 | Watch core 23:00 to 02:00, awake 02:00 to 04:00, core 04:00 to 07:30. RHR 57, HRV 43 | night 390, awake 120, one cluster (not 210) |
| D11 Oct 16 | Watch night 23:20 to 06:30. HRV only at 15:00 Oct 15. RHR 56 | night 430; HRV nil |
| D12 Oct 17 | Watch 440 and Oura stages 450, overlapping; RHR Watch 55, Oura 51; HRV Watch 49, Oura 62 | night 440, Watch; RHR 55; HRV 49 |
| D13 Oct 18 | First foreground: `.locked`. Second: Watch 23:30 to 06:35, RHR 54, HRV 46 | first: `storeLocked`, W3 shows nothing, nothing cleared; second: night 425 |
| D14 Oct 19 | Watch night 450. RHR 55, HRV 48. Push B 18:30 to 19:25: D01's first 14 HR inside, plus 88 at 18:25 and 95 at 19:30 | avg 125, max 152 (edge samples excluded) |
| D15 Oct 20 | Watch 00:30 to 06:30. RHR 58, HRV 36. History read D-28 to D-1 | night 360; history 12 nights (D05, D06 none), median 432.5 |

## 9. Privacy

Health reads live only in memory as `HealthReads` values for the current screen and day. They are never in the op log, backups, exports, packs or logs, never in widgets, and never in any context pack (on-device Foundation Models or Claude). Ruled (Product, Oct 19, with Kaushik's approval in the Research thread): SleepNight, StepsDay and RestingHeartRate may exist as read-only mirror objects under `/health`, written store-only (no `OpRecord`); health values never leave the phone. W1's avg and max are re-read when a summary is shown, not saved on the Workout object, so they cannot reach history packs. Health stays the source of truth. This matches `recovery-line.md` section 6.

## 10. Smallest slice (H-reads) and done-when

Core, before W1 and W3: `HealthReading.swift`, `HealthReads.swift`, `FakeHealth`, `NoHealth` in `TesseraCore/Health/`; `App/Health/HealthKitReader.swift` with `HKSampleQueryDescriptor`; new share string. W1 then adds one summary line; W3 adds `RecoveryRule` on top.

Done when:
- `HealthReadsTests` pass all 15 days above in `swift test`, with the pinned clock and calendar from `fixtures/ranker.md`.
- `deniedEqualsEmpty`: D06 `.normal` and `.denied` encode to the same JSON.
- `lockedIsNotEmpty`: D13 first read throws `storeLocked` and earlier values stay.
- `workoutHRNeedsThree`: 0, 1 and 2 samples give nil; 3 give a value.
- `healthNeverPersisted`: after D01 with W1's summary shown, no `OpRecord`, backup copy, export or pack JSON contains 123, 152, 435 or "heart" (a store-only mirror object is allowed and is not checked).
- `scripts/test.sh` checks that no file under `TesseraCore/` imports HealthKit.
- On Kaushik's phone: no Health sheet at launch; the first finish shows one sheet with heart rate; a Watch-worn workout shows avg and max; Health > Tessera lists the read types. Photo in the PR.
