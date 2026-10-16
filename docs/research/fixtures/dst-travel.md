# DST and travel fixtures for `TesseraDay` (board item 38)

Twenty moments for the `TesseraDay` helper proposed in `research/day-boundary.md` (section 1). They extend X1-X12
there and do not repeat them: X9-X12 cover the two 01:30s, 03:30 PST and 04:00 PST on 1 Nov as bare keys; these rows
add what gets **stored** and what **Now** shows, plus a trip to New York. Traced by hand on `origin/master` 582700b
(15 Oct 17:57 PT); no Swift toolchain, so nothing here was run.

## Rules assumed

1. **Stored instants are absolute.** Every `FieldValue.date` is a plain `Date` (`FieldValue.swift:36`), encoded by a
   default `JSONEncoder` as seconds since 2001 UTC. No zone is stored anywhere. Rest ends ride as
   `timeIntervalSinceReferenceDate` strings (`WorkoutSession+Rest.swift:30`). Master never names a zone: every date read
   uses `Calendar.current`, which is the phone's zone at the moment of the call.
2. **The logical day is read off the wall clock**, not absolute seconds: take the local date and hour in the zone in
   force; hour < 4 means the day before. So 01:30 counts as the evening before whether it is PDT or PST, and the day
   that ends at 04:00 on 1 Nov is 25 hours long (Sat 31 Oct 04:00 PDT to Sun 1 Nov 04:00 PST).
3. **Durations are absolute.** Rest timers, the 6 hour auto-finish (`ProcessTable.swift:14`), elapsed workout time and
   "within 15 minutes" on Now count real seconds, never wall clock.
4. **Adding days keeps wall time** (`Calendar.date(byAdding: .day)`), so "same time tomorrow" across 1 Nov is 25 h.
5. **A repeated hour resolves to the first one.** "1:30am" on 1 Nov means 01:30 PDT (08:30Z), Foundation's default
   `repeatedTimePolicy: .first` for `date(bySettingHour:)` (worth one check on device).
6. **A timed task is a fixed instant** (like a calendar event): "call mum tue 9am" made in LA rings at 12:00 in New
   York. A due date without a time should be a local date (y-m-d), but master has none: Tess writes 09:00 that day.
7. **Which zone decides on a trip (proposed default):** display and "today" use the phone's current zone at the
   moment of display. A logged item (a workout, a done task, a note) keeps the logical day it had in the zone where it
   was logged. That needs the zone stored with it (open question 1); until then, the fallback is the current zone.
8. **A workout belongs to the logical day it started** (open question 2), in the zone it started in.

Trip used: LA to New York on the red-eye, Mon 26 Oct 22:30 PDT to Tue 27 Oct 06:45 EDT, home Wed 28 Oct (JFK 18:00
EDT, LAX 21:20 PDT). Offsets: PDT is UTC-7 until 1 Nov 09:00Z, then PST UTC-8; EDT is UTC-4 for the whole trip.
Tasks: "Pay rent" Sat 31 Oct 21:00; "bins" made Sat 23:00 for 01:30 Sunday; "send invoice tue 10pm" made in LA.

## The 20 moments

"Day" is the logical day. P = master already gives the expected value; F = it does not.

| # | Local time, zone (UTC) | Action | Expected stored (instant; day) | Now shows | Master today (traced) | P/F |
|---|---|---|---|---|---|---|
| D01 | Mon 26 Oct 18:00 PDT (01:00Z Tue) | Types "call mum tue 9am" | `startsAt` 2026-10-27T16:00Z (Tue 09:00 PDT); day Tue 27 | Unchanged (task is tomorrow); on Tue in NY it reads 12:00 and takes Now from 11:45 EDT | `TessGrammar.swift:513, 559`: weekday then `bySettingHour(9)` in PDT, same instant | P |
| D02 | Mon 26 Oct 21:40 PDT (04:40Z Tue) | Starts Mobility at the gate; last set 22:15 PDT (05:15Z), boards | `startedAt` 04:40Z; day Mon 26 (LA) | "Running since 21:40" | `NowRanker.swift:113, 333-335`: clock in `Calendar.current` (PDT) | P |
| D03 | Tue 27 Oct 06:55 EDT (10:55Z), phone now in EDT | Opens the app after landing | Process suspended at 05:15Z, not wrapped (5 h 40 real idle, under 6 h); roll-forward runs (day Tue 27 in EDT) | No running item; Mobility on the ledger row with Resume; Mon's undone tasks carried | `AppModel.swift:250` then `ProcessTable.swift:88-90, 100-101`: idle is absolute | P |
| D04 | Tue 27 Oct 07:10 EDT (11:10Z) | Resumes at 07:00, logs the last set, finishes | `endedAt` 11:10Z; workout day **Mon 26** (start day, LA) | Done line for Mobility; Tue's routine still offered (Mon's session does not fill Tue) | `WorkoutSummary.swift:92` buckets `startOfDay(endedAt)` in EDT: **Tue**; `AppModel.swift:508` then hides Tue's routine | F |
| D05 | Tue 27 Oct 22:00 EDT (02:00Z Wed) | Opens Home; "send invoice tue 10pm" (made in LA) is at 05:00Z Wed = Wed 01:00 EDT | Unchanged `startsAt` 05:00Z; day Tue 27 in both zones (01:00 EDT is before 04:00) | Invoice in today's list; it takes Now at 00:45 EDT | `Tasks.swift:38-47`: end is Wed 00:00 EDT, so it is missing from today and sits in `upcoming` (`Tasks.swift:64`) | F |
| D06 | Wed 28 Oct 04:00 EDT (08:00Z) | Roll-forward on foreground | Invoice `startsAt` 2026-10-29T05:00Z (Thu 01:00 EDT, Wed 22:00 PDT), `rolls` 1, `rolledFrom` 05:00Z; day Wed 28 | Invoice carried, flexible (5:41 PM PT rule) | `RollForward.swift:43, 49, 61-62` in EDT: offsets equal all night, so the same value at 04:00 EDT | P |
| D07 | Wed 28 Oct 06:30 EDT (10:30Z) | Hotel gym, Pull A 05:40 to 06:30 EDT; viewed again Thu 29 08:00 PDT at home | `startedAt` 09:40Z, `endedAt` 10:30Z; day **Wed 28** (logged in EDT). In LA that end is Wed 03:30 PDT | Thu at home: week strip has Wed filled | `WorkoutSummary.swift:92` in PDT: midnight cut gives Wed, right by accident. A naive `TesseraDay` in the current zone gives **Tue**: why the zone must be stored | P |
| D08 | Wed 28 Oct 21:30 PDT (04:30Z Thu), app kept in memory | Opens Home after landing; nothing to tidy or roll, so no write | Nothing written | Week strip shows Mon (D04), Wed (D07) filled; today's done line has Pull A | `WorkoutSummary.swift:85-97`: `workoutDays` was keyed by EDT midnights and only rebuilds on a new `revision`; the PDT key misses, so **every day reads empty** until the next write | F |
| D09 | Sat 31 Oct 03:59:59 PDT (10:59:59Z) | Opens the app | Nothing; day Fri 30 | Fri's Now; roll-forward does nothing | `RollForward.swift:71-73`: minus 4 h is Fri 23:59:59, Fri (no DST yet) | P |
| D10 | Sat 31 Oct 21:05 PDT (04:05Z Sun) | "Not now" on Pay rent (21:00) | `startsAt` 2026-11-02T05:00Z (Sun 21:00 PST, 25 h later); day Sun 1 Nov | Pay rent leaves Now | `Tasks.swift:117-119`: `byAdding: .day` keeps 21:00 | P |
| D11 | Sat 31 Oct 23:00 PDT (06:00Z Sun) | Types "bins sun 1:30am" | `startsAt` 2026-11-01T08:30Z (first 01:30, PDT); day **Sat 31** | Bins in tonight's list; takes Now at 01:15 PDT unless a workout runs | Instant right (`TessGrammar.swift:513, 559`); `Tasks.swift:38-47` leaves it out of today (after Sun 00:00 PDT), so it shows as tomorrow | F |
| D12 | Sun 1 Nov 01:58:30 PDT (08:58:30Z) | Push B (started 00:50 PDT, 07:50Z) logs a set; rest 3:00 | `restEndsAt` 09:01:30Z, saved as "815216490.0"; Live Activity end and `staleDate` 09:01:30Z; workout day Sat 31 | "Running since 00:50", rest ring counts 180 real seconds to 01:01:30 PST | `WorkoutSession.swift:363`, `+Rest.swift:30`, `RestActivityController.swift:107, 117`: all absolute | P |
| D13 | Sun 1 Nov 01:00:00 PST (09:00Z) | App relaunched mid-rest (wall clock now reads earlier than the set) | Nothing new; rest restored with 1:30 left | Rest ring at 1:30, then "ready" at 01:01:30 PST | `+Rest.swift:13-17`: `endsAt > now` on absolute dates | P |
| D14 | Sun 1 Nov 01:20 PST (09:20Z) | Finishes Push B | `endedAt` 09:20Z; elapsed 1:30:00 (not 0:30); day **Sat 31** | Done line; at Sun 10:00 Home still offers Sun's routine | Elapsed right (`WorkoutModeView.swift:324`); `WorkoutSummary.swift:92` puts it on **Sun**, so `AppModel.swift:508` offers no routine on Sunday | F |
| D15 | Sun 1 Nov 01:25 PST (09:25Z) | Bins (08:30Z) still not done | Nothing; bins stays on Sat 31 | Bins is **not** "in 5 min": it was 55 real minutes ago | `NowRanker.swift:218-219` and `118-121` compare absolute instants | P |
| D16 | Separate night: Pull A set aside Sat 31 Oct 22:00 PDT (05:00Z); opens Sun 03:15 PST (11:15Z) | Foreground tidy | Wrapped up: `endedAt` 05:00Z (last touch); day Sat 31. Wall clock says 5 h 15, real idle is 6 h 15 | Tess: "Saved Pull A, 3 of 5 exercises" | `ProcessTable.swift:100-101, 123-125`: absolute idle, end at last touch | P |
| D17 | Sun 1 Nov 03:59:59 PST (11:59:59Z) | Opens the app | Nothing yet; day Sat 31; bins not carried | Sat's Now; bins in tonight's list | `RollForward.swift:72-73`: minus 4 h is Sun 00:59:59 PDT, so it is already **Sun** and bins rolled at 03:00 PST (extends X11) | F |
| D18 | Sun 1 Nov 04:00 PST (12:00Z) | Roll-forward | Bins `startsAt` 2026-11-02T09:30Z (Mon 01:30 PST), `rolls` 1, `rolledFrom` 08:30Z; day Sun 1 Nov. Sat 31's interval was 11:00Z to 12:00Z next day, 25 h | Bins carried, flexible, no time shown | `RollForward.swift:61-62` gives the same value (but ran an hour early, D17) | P |
| D19 | Sun 1 Nov 23:30 PST (07:30Z Mon) | Opens Bench history; a set from Sat 31 Oct 18:00 PDT (01:00Z) | Nothing | Row reads "Yesterday" | `ExerciseDigest.swift:195`: `now - 86400` is Sun 00:30 PDT, still Sunday, so the row reads "Sat 31" (23:00-23:59 PST only) | F |
| D20 | Mon 2 Nov 04:00 PST (12:00Z); twin 03:59:59 (11:59:59Z) | Opens the app | Day Mon 2; the twin is Sun 1. Sun 1's interval is 12:00Z to 12:00Z, 24 h | New day's Now; roll-forward runs at 04:00 | `RollForward.swift:72-73`: offsets equal again, both right | P |

**Master: 13 pass, 7 fail** (D04, D05, D08, D11, D14, D17, D19). Every stored instant on master is already right:
rest timers, the Live Activity, auto-finish, "not now" and roll-forward values all use absolute time or calendar
arithmetic. The failures are all about **which day** a moment or record belongs to.

| Fail | Owner | Fix |
|---|---|---|
| D04, D14 | Core (`WorkoutSummary.swift:92`; Home inherits via `AppModel.swift:508-515`) | Bucket by `TesseraDay.day(of: startedAt)` in the logged zone |
| D05, D11 | Core (`Tasks.swift:38-47`, `64`) | `TaskList.today` / `upcoming` from `TesseraDay.interval(of: now)` (already #165's item) |
| D08 | Core (`WorkoutSummary.swift:85-97`) | Key `workoutDays` / `daySummaries` by revision **and** zone identifier; Builder B refreshes Now on `NSSystemTimeZoneDidChange` |
| D17 | Core (`RollForward.swift:71-73`) | `TesseraDay.day(of:)` (C1 in `day-boundary.md`) |
| D19 | Builder A (`ExerciseDigest.swift:192-196`) | `day.isSameDay`, yesterday via `day.adding(days: -1, to: now)` (A4) |

Worst: **D14 (and D04)**. A session that runs past midnight on 1 Nov, or ends after a red-eye, is filed under the next
day, so Home tells him that day's training is done and never offers the routine. Core, `WorkoutSummary.finishedWorkouts`.
Close second: **D08**, the silent empty week after flying home, because nothing invalidates the cache on a zone change.

## Swift Testing sketch

`TesseraCore/Tests/TesseraCoreTests/TesseraDayTests.swift`, next to the X1-X12 table. Fixed zones, never `.current`.

```swift
import Foundation
import Testing
@testable import TesseraCore

private func day(_ zone: String) -> TesseraDay {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US") // weeks start Sunday
    calendar.timeZone = TimeZone(identifier: zone)!
    return TesseraDay(calendar: calendar)
}

private let la = day("America/Los_Angeles"), ny = day("America/New_York")
private func utc(_ text: String) -> Date { try! Date(text, strategy: .iso8601) }
private func ymd(_ helper: TesseraDay, _ date: Date) -> String {
    let parts = helper.calendar.dateComponents([.year, .month, .day], from: helper.day(of: date))
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
}

struct TesseraDayDSTTravelTests {
    @Test(arguments: [
        ("2026-10-31T10:59:59Z", "2026-10-30"), // D09
        ("2026-11-01T08:30:00Z", "2026-10-31"), // D11, first 01:30
        ("2026-11-01T09:25:00Z", "2026-10-31"), // D15, second 01:25
        ("2026-11-01T11:59:59Z", "2026-10-31"), // D17 (master says Nov 1)
        ("2026-11-01T12:00:00Z", "2026-11-01"), // D18
        ("2026-11-02T11:59:59Z", "2026-11-01"), // D20 twin
        ("2026-11-02T12:00:00Z", "2026-11-02"), // D20
    ])
    func losAngelesDay(instant: String, expected: String) {
        #expect(ymd(la, utc(instant)) == expected)
    }

    @Test func dayLengths() { // D18, D20
        #expect(la.interval(of: utc("2026-10-31T12:00:00Z")).duration == 25 * 3600)
        #expect(la.interval(of: utc("2026-11-01T12:00:00Z")).duration == 24 * 3600)
        #expect(la.week(containing: utc("2026-11-01T07:50:00Z")) // D12: Push B is in the week of 25-31 Oct
            == DateInterval(start: utc("2026-10-25T11:00:00Z"), end: utc("2026-11-01T12:00:00Z")))
    }

    @Test func addingDaysKeepsWallTime() { // D10, D18
        #expect(la.adding(days: 1, to: utc("2026-11-01T04:00:00Z")) == utc("2026-11-02T05:00:00Z"))
        #expect(la.adding(days: 1, to: utc("2026-11-01T08:30:00Z")) == utc("2026-11-02T09:30:00Z"))
    }

    @Test func repeatedHourIsTheFirst() { // D11
        let sunday = la.calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        #expect(la.calendar.date(bySettingHour: 1, minute: 30, second: 0, of: sunday) == utc("2026-11-01T08:30:00Z"))
    }

    @Test func sameDayAcrossFallBack() { // D12 start, D14 end, D17/D18 edge
        #expect(la.isSameDay(utc("2026-11-01T07:50:00Z"), utc("2026-11-01T09:20:00Z")))
        #expect(!la.isSameDay(utc("2026-11-01T11:59:59Z"), utc("2026-11-01T12:00:00Z")))
    }

    @Test func trip() {
        #expect(ymd(la, utc("2026-10-27T04:40:00Z")) == "2026-10-26") // D04: start day of Mobility
        #expect(ymd(ny, utc("2026-10-28T05:00:00Z")) == "2026-10-27") // D05: invoice is Tue in NY
        #expect(ymd(ny, utc("2026-10-28T08:00:00Z")) == "2026-10-28") // D06: roll at 04:00 EDT
        #expect(ymd(ny, utc("2026-10-28T10:30:00Z")) == "2026-10-28") // D07 in the zone it was logged
        #expect(ymd(la, utc("2026-10-28T10:30:00Z")) == "2026-10-27") // D07 trap: why the zone is stored
    }
}
```

Site tests (one per fail row) reuse these instants: `finishedWorkouts` for D04/D14, `TaskList.today` for D05/D11,
a zone swap without a write for D08, `RollForwardTasks(time:)` for D17/D18, `ExerciseDigest.historyDate` for D19.

## Open questions (recommended default first)

1. **Store the zone with logged items?** Yes: a `zone` text field (TimeZone identifier) on workouts, done tasks and
   notes, written at log time; the day of a logged item is `TesseraDay` in that zone, falling back to the current zone
   when it is missing (all history so far is LA, so no migration). Without it D07 flips to Tue once he is home. Core.
2. **Does a workout belong to its start or its end?** Start. D04 (red-eye) and D14 (past 01:00 on 1 Nov) both read
   right, and X2 in `day-boundary.md` does not change (Push A starts and ends on Fri's logical day).
3. **Timed tasks: fixed instant or floating wall time?** Fixed, as master does and as calendar events are. A due date
   with no time should become a stored local date ("2026-10-27") when date-only due dates arrive; until then 09:00.
4. **The repeated hour.** "1:30am" on 1 Nov is the first one (PDT), with no question asked. One device check that
   `date(bySettingHour:)` really picks `.first`.
5. **Zone change while the app is open.** Key the day caches by zone too (D08) and refresh Now on
   `NSSystemTimeZoneDidChange`. Core for the cache, Builder B for the Now refresh.
6. **Clock labels for something started in another zone.** Current zone ("Running since 00:40" in New York for a
   21:40 PDT start), no zone tag. Revisit only if it reads wrong in use.
7. **Roll-forward on landing east.** It runs as soon as the phone flips to EDT (D03: 03:55 PDT became 06:55 EDT).
   Accept it; nothing is lost and the carried line explains it.
