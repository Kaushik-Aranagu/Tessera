# Recovery line (W3)

For: Core engine, Builder B · Date: 2026-10-15 · Research lab
Reads with: `apple-watch.md` (W3), `../product/ship-list-m4.md` (slice 2), `calendar-health-fixtures.md` (H01 to H12), `tess-voice.md`, `fixtures/ranker.md`, `context-packing.md`, `../product/tess-model-layer.md`. Code: origin/master `0950ba7`.

**Bottom line.** On training days only, Now gets one quiet line from last night's sleep, resting HR and overnight HRV (SDNN), each against Kaushik's own previous 28 days. Sleep is required; HR and HRV can only add weight. One odd marker alone says nothing. No baseline, no line. It never leaves the phone.

## 1. What master has today

`git grep` on `App/Health/` finds one file, `HealthExporter.swift`. It writes only: `requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])`. There are **no HealthKit reads**. Both `project.yml` usage strings say "Tessera saves your finished workouts to Apple Health." No `ContextPack` type exists yet (T4 is not on master). `RestDay` and `WeekDay.isRest` exist in `TesseraCore/Training/` and decide "training day".

## 2. The rule (all on the phone, pure function in Core)

Inputs for wake day D, read on foreground only (Health is locked with the phone):
- **S, asleep minutes:** the slice 2 night (H01 to H07): sum of `asleepCore + asleepDeep + asleepREM + asleepUnspecified`, Watch source wins, naps ignored. `inBed` and `awake` never count. An in-bed-only night is S = none.
- **R, resting HR:** latest `restingHeartRate` sample, none if older than 36 h (decisions.md).
- **H, overnight HRV:** mean of `heartRateVariabilitySDNN` samples that start inside the night's asleep span. Daytime samples are left out: SDNN depends on conditions and recording length, so only like-for-like readings compare.

Baseline, per signal: one value per day from D-28 to D-1 (today excluded). Valid only with **7 or more days**; fewer means that signal is unknown. Use the median, and a robust spread `sd = 1.4826 x MAD`. HRV works in log (`ln H`), since HRV is skewed. Only HRV samples with the same `HKMetadataKeyAlgorithmVersion` as today's count (UNVERIFIED that the Watch sets it; if absent, treat all as one version).

| Flag | Fires when | Why this cut |
|---|---|---|
| `short` | S ≤ median S minus 60 min | A full hour under his own usual is a real single-night deficit; strength sessions lose volume and quality after restricted sleep (Knowles 2018). No absolute "6 h", his median is the norm |
| `hrvLow` | ln H ≤ median ln H minus 1.0 x sd (sd floored at 0.10) | Kiviniemi 2007 cut at 1 SD under a personal baseline. The floor stops a very steady baseline from firing on tiny dips |
| `rhrUp` | R ≥ median R + max(3 bpm, 1.0 x sd) | Resting HR day-to-day noise is near 10% CV; a rise with lower HRV points at sympathetic load (Buchheit 2014). 3 bpm keeps it above watch noise |

Decision (first match wins): no line if not a training day, S is none, or the sleep baseline has under 7 nights. Then: `short` and (`hrvLow` or `rhrUp`) gives **L1**; `short` alone gives **L2**; `hrvLow` and `rhrUp` with sleep not short gives **L3**; otherwise **no line**. One marker alone is too noisy on one day (Buchheit: single days mislead; averages of 3 to 4 days track performance), so it stays silent. Unknown HR or HRV (missing, stale, under 7 days) never fires and never blocks.

## 3. Thresholds: what the literature says

- **Own baseline, not norms.** HRV-guided training studies compare each day to a personal rolling baseline and normal range (Kiviniemi 2007: 10 days, 1 SD; Plews and Buchheit: 7-day mean against 1 to 2 months; HRV4Training: 2 months, 1.5 SD). 28 days follows a training block without chasing last week. 7 days is the shortest window these studies use.
- **SDNN is not RMSSD.** Apple's doc: "HealthKit uses SDNN heart rate variability, which uses the standard deviation of the inter-beat (RR) intervals." The studies above use RMSSD (vagal, beat to beat). SDNN mixes sympathetic and vagal input and grows with recording length; values from different epoch lengths do not compare (Shaffer and Ginsberg 2017). So: overnight samples only, log scale, no absolute cut, no "ms" shown.
- **iOS 27 adds `heartRateVariabilityRMSSD`.** Reported with Series 12 (Sept 2026); Apple has not confirmed the Watch writes it, nor how it maps to the Vitals "Recovery HRV". Not in this slice. Later: if RMSSD samples exist, keep a separate baseline and never mix the two.
- **Readiness** (Apple's 0 to 10 score, Series 12 and Ultra 4) is not exposed to apps; we do not copy or read it.

## 4. Copy (Tess voice: calm, no grading, no numbers but sleep hours, under 40 characters)

| Case | Line | Chars | Notes |
|---|---|---|---|
| L1 | Slept 5h 40m, take it lighter | 29 | `{h}h {m}m`, minutes rounded to 5; "6h" when m is 0 |
| L2 | Slept 5h 40m. Lighter is fine today | 35 | An option, not an instruction |
| L3 | Still recovering. Lighter is fine | 33 | No sleep figure: sleep was in range |
| None | (nothing) | 0 | Including "all good" days: silence is fine (voice rule 7) |

Never: red or amber, "low", "poor", "bad", "score", "%", "bpm", "ms", "HRV", "missed", "should". VoiceOver reads "Slept 5 hours 40 minutes, take it lighter". Long-press "Why is this here?" gives "Short night against your usual" (L1, L2) or "Heart signs off your usual" (L3), no numbers.

## 5. Where it shows

- **Now only, training days only:** `WeekDay` for today has `planned` and not `isRest`, or a workout is running. Rest days stay "Rest day" with nothing added.
- **One quiet line under the Now hero,** in secondary ink. When a workout is running it sits below the running process, never in place of it. It is not a ranker candidate: it does not score, never moves Now, is not `isAsk`, and does not use the day's one Tess suggestion.
- Computed once on the first foreground after the night closes, then frozen for the day (anti-flicker, context-packing §6). Gone once today's workout finishes.
- **Never** a notification, Live Activity, widget, Lock Screen, Day log entry, or Plan my day input.

## 6. Privacy: none of it goes to Claude or any pack

Rule: health samples, baselines, flags and the line are in-memory values (`RecoveryReading`), never `ObjectRecord`s and never in the op log. Any context pack, Claude or on-device Foundation Models, excludes them and the whole `/health` subtree. Conflict to flag: `tess-model-layer.md` lets Plan my day see "light day: yes or no"; that bit must come from energy and the slice 6 rule, never from this reading. Product to confirm.

Test `RecoveryNeverPacked`: load fixture F02 (L1 fires), build every pack the model layer offers (capture, plan, question, paste) through the real builder, serialise each to JSON, and assert none contains "Slept", "lighter", "recover", "/health", "sleep", "heart", 340, 36 or 58. Also assert `OpRecord`s written during the day contain none of those values. The test lands with T4; until then it runs against the one-line prompt builder for on-device Tess.

## 7. HealthKit reads and permission copy

| Type | Kind | Unit | Use |
|---|---|---|---|
| `HKCategoryType(.sleepAnalysis)` | category | stage values | S and the night span (slice 2) |
| `HKQuantityType(.restingHeartRate)` | quantity, discrete | count/min | R |
| `HKQuantityType(.heartRateVariabilitySDNN)` | quantity, discrete | ms (`.secondUnit(with: .milli)`) | H |

Add these to slice 2's single `requestAuthorization(toShare: [workoutType], read: [...])`, asked once in context. HealthKit never says whether a read was denied; a denial looks like no data, which is the no-line path, so nothing says "permission denied".
- `NSHealthShareUsageDescription` (reading): "Tessera reads your sleep, resting heart rate and heart rate variability to add a quiet note on training days. It stays on this iPhone."
- `NSHealthUpdateUsageDescription` (writing) keeps: "Tessera saves your finished workouts to Apple Health."

## 8. Fixtures: 20 days

Baseline B unless stated: 28 days; sleep median 7h20 (440, so short ≤ 380); HRV median 48 ms, sd 0.20 (low ≤ 39); RHR median 54, sd 2.5 (up ≥ 57). Training day, no workout running, unless stated.

| ID | S (asleep) | H (ms) | R (bpm) | Other | Expected |
|---|---|---|---|---|---|
| F01 | 7h25 | 50 | 53 | | none |
| F02 | 5h40 | 36 | 58 | | L1 "Slept 5h 40m, take it lighter" |
| F03 | 5h40 | 47 | 54 | | L2 "Slept 5h 40m. Lighter is fine today" |
| F04 | 6h20 (380) | 44 | 55 | Sleep exactly on the cut | L2 "Slept 6h 20m. Lighter is fine today" |
| F05 | 6h25 | 36 | 58 | Sleep not short, both markers | L3 "Still recovering. Lighter is fine" |
| F06 | 7h10 | 36 | 55 | HRV alone | none |
| F07 | 7h10 | 49 | 59 | RHR alone | none |
| F08 | 5h55 | none | 58 | No overnight SDNN samples | L1 "Slept 5h 55m, take it lighter" |
| F09 | 5h55 | none | none | | L2 "Slept 5h 55m. Lighter is fine today" |
| F10 | none | 35 | 60 | Watch charging overnight | none |
| F11 | in bed 7h45 only | none | 54 | iPhone only (H03) | none |
| F12 | 5h10 | 36 | 59 | Sleep baseline 6 nights | none |
| F13 | 5h10 | 35 | 55 | Sleep baseline 7 nights (median 440), HRV baseline 4 days | L2 "Slept 5h 10m. Lighter is fine today" |
| F14 | 5h00 | 33 | 60 | Rest day (`isRest`) | none |
| F15 | 5h40 | 37 | 54 | Push A running since 18:32 | L1, under the running process |
| F16 | 5h40 | 37 | 54 | Push A finished 19:40 | none (gone after finish) |
| F17 | 6h00 | 47 | 60, 40 h old | Stale RHR ignored | L2 "Slept 6h. Lighter is fine today" |
| F18 | 7h30 | 46, 50 overnight; 30 at 14:00 yesterday | 54 | Daytime sample excluded, H = 48 | none |
| F19 | 6h50 night + 40 min nap | 38 | 57 | Nap not added (H05) | L3 "Still recovering. Lighter is fine" |
| F20 | 7h00 | 33, algorithm v3; baseline all v2 | 58 | HRV baseline for v3 is 0 days | none (RHR alone) |

## 9. Smallest slice and done-when

Slice W3a, after slice 2 lands (owner Core, then Builder B for the line):
1. Core: `RecoveryRule.evaluate(night:restingHR:hrv:history:isTrainingDay:) -> RecoveryLine?`, pure, no HealthKit import; `HealthReader` in `App/Health/` maps samples into it.
2. Builder B: one secondary-ink line under the Now hero, frozen for the day.

Done when:
- `RecoveryRuleTests` pass all 20 fixtures above, with the pinned clock and calendar from `fixtures/ranker.md`.
- Every line in §4 is under 40 characters and passes the tess-voice banned-word and "!" checks (automated).
- `RecoveryNeverPacked` (§6) passes.
- With `-demoTime 07:40 -resetDemo` and demo Health fixtures F02 and F14, Now shows L1 on the Push day and nothing on the rest day; no notification is scheduled (`UNUserNotificationCenter` pending list unchanged).
- Denying Health access shows no line and no error text.

## Sources

- Apple, heartRateVariabilitySDNN: https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn
- Apple, Track your sleep on Apple Watch: https://support.apple.com/guide/watch/apd830528336 · Estimating Sleep Stages from Apple Watch (Oct 2025): https://www.apple.com/kr/health/pdf/Estimating_Sleep_Stages_from_Apple_Watch_Oct_2025.pdf
- iOS 27 RMSSD type and Series 12 Readiness: https://www.themomentum.ai/blog/apple-watch-series-12-ios-27-rmssd-healthkit · https://gadgetsandwearables.com/2026/09/11/apple-watch-recovery-hrv-overall-hrv-rmssd/
- Shaffer and Ginsberg 2017, An Overview of HRV Metrics and Norms: https://www.frontiersin.org/journals/public-health/articles/10.3389/fpubh.2017.00258
- Buchheit 2014, Monitoring training status with HR measures: https://pubmed.ncbi.nlm.nih.gov/24578692/
- HRV-guided training history (Kiviniemi 2007, Plews, Vesterinen, Javaloyes): https://marcoaltini.substack.com/p/a-brief-history-of-heart-rate-variability · HRV4Training normal range: https://www.hrv4training.com/blog2/redefining-hrv4trainings-daily-advice
- Knowles et al. 2018, Inadequate sleep and muscle strength: https://pubmed.ncbi.nlm.nih.gov/29422383/
