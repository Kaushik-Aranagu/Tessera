# Calendar and Health fixtures (M4 slices 1 and 2)

For: Core engine (fixture tests), Product lead
Date: 2026-10-15
Inputs: `../product/ship-list-m4.md` (slices 1, 2), `m4-scouting.md`, `../product/ship-list-m3.md` (slice 1, `BodyWeight`), repo `origin/master`.

## What the repo has today

- `App/Health/HealthExporter.swift` is the only HealthKit code: it writes strength workouts (`toShare: [workoutType]`, `read: []`), asks lazily on the first save, and treats Health as a mirror. Nothing reads Health yet.
- `project.yml` already has `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` (both say "saves your finished workouts") and `CODE_SIGN_ENTITLEMENTS: App/Tessera.entitlements`. So HealthKit is not the first entitlement any more, contrary to the scouting note. The share string needs rewording once Tessera reads sleep and steps.
- No EventKit code and no calendar usage key. Slice 1 adds `NSCalendarsFullAccessUsageDescription`.

## Conventions used in the fixtures

- Fixture day: Tuesday 2026-10-20. Home time zone `America/Los_Angeles` (PDT, UTC-7). "Now" is 08:00 local unless a case says otherwise. Window for slice 1: 2026-10-19 00:00 to 2026-11-03 24:00 local.
- Input keys mirror the frameworks: EKEvent (`title`, `startDate`, `endDate`, `isAllDay`, `timeZone`, `occurrenceDate`, `isDetached`, `hasRecurrenceRules`, `status`, `availability`, `calendar {title, type, allowsContentModifications}`, `selfParticipantStatus` from the current user's `EKParticipant.participantStatus`, `externalId` = `calendarItemExternalIdentifier`). HealthKit (`type`, `value`, `start`, `end`, `source {bundle, productType}`, `quantity`).
- Expected objects use the `Event` fields from the scouting note (`title, start, end, allDay, calendarName, location, isRecurring`) plus fields marked (A), which are ASSUMED here and listed at the end. `busyMinutes` is what slice 3 day load reads, per local day.
- Health classes under `/health` are ASSUMED names: `SleepNight`, `StepsDay`, `RestingHeartRate`. Weight reuses `BodyWeight` from M3 slice 1.

## Calendar fixtures (slice 1): 19 cases

Event object key (A): `key = calendarItemExternalIdentifier + "@" + occurrenceDate(ISO, UTC)`. Apple: "Recurring event identifiers are the same for all occurrences. If you wish to differentiate between occurrences, you may want to use the start date." `occurrenceDate` is the original date and survives an edit of one occurrence, so it is the stable half of the key; `startDate` is not.

```yaml
- id: C01 recurring with an exception
  input:
    access: fullAccess
    events:   # what events(matching:) returns: one EKEvent per occurrence; Oct 27 deleted from the series (EXDATE)
      - {externalId: "standup-1", title: "Standup", startDate: "2026-10-20T09:30-07:00", endDate: "2026-10-20T09:45-07:00", occurrenceDate: "2026-10-20T09:30-07:00", hasRecurrenceRules: true, isDetached: false, calendar: {title: Work}, selfParticipantStatus: accepted}
      - {externalId: "standup-1", title: "Standup", startDate: "2026-10-21T09:30-07:00", endDate: "2026-10-21T09:45-07:00", occurrenceDate: "2026-10-21T09:30-07:00", hasRecurrenceRules: true}
      # ... weekdays through Nov 3, no row for Oct 27
  expected:
    - {path: "/calendar/standup-1@2026-10-20T16:30Z", class: Event, title: Standup, start: "2026-10-20T09:30-07:00", end: "2026-10-20T09:45-07:00", allDay: false, calendarName: Work, isRecurring: true, busy: true}
    # one Event per returned occurrence (10 in the window), none for Oct 27
  rule: Mirror occurrences exactly as EventKit expands them; never expand recurrence rules ourselves.

- id: C02 edited occurrence (detached)
  input:
    previous: C01
    events:
      - {externalId: "standup-1", title: "Standup (moved)", startDate: "2026-10-21T11:00-07:00", endDate: "2026-10-21T11:15-07:00", occurrenceDate: "2026-10-21T09:30-07:00", isDetached: true, hasRecurrenceRules: true}
  expected:
    - {path: "/calendar/standup-1@2026-10-21T16:30Z", op: update, title: "Standup (moved)", start: "2026-10-21T11:00-07:00", end: "2026-10-21T11:15-07:00", isRecurring: true, edited: true}
  rule: Same key because occurrenceDate is unchanged, so the diff is an update, not a delete plus insert (links and Day log mentions survive).

- id: C03 declined invite
  input:
    events:
      - {externalId: "qbr", title: "QBR", startDate: "2026-10-20T13:00-07:00", endDate: "2026-10-20T14:00-07:00", calendar: {title: Work}, selfParticipantStatus: declined, availability: busy}
  expected:
    - {class: Event, title: QBR, attendance: declined, busy: false, busyMinutes: 0}
  rule: Mirror it (so "you declined QBR" is linkable) but declined never counts as busy.

- id: C04 tentative
  input:
    events:
      - {externalId: "lunch-sam", title: "Lunch w/ Sam?", startDate: "2026-10-20T12:00-07:00", endDate: "2026-10-20T13:00-07:00", selfParticipantStatus: tentative, availability: tentative}
  expected:
    - {class: Event, attendance: tentative, busy: true, busyMinutes: 60}
  rule: Tentative and pending (no reply yet) count as busy; only declined and free do not.

- id: C05 all-day
  input:
    events:
      - {externalId: "offsite", title: "Team offsite", isAllDay: true, startDate: "2026-10-22T00:00-07:00", endDate: "2026-10-22T23:59:59-07:00", timeZone: null, availability: free}
  expected:
    - {class: Event, title: "Team offsite", allDay: true, date: "2026-10-22", busy: false, busyMinutes: 0}
  rule: All-day events are floating dates (no time zone), shown as a day label, never busy (ship list).

- id: C06 multi-day all-day
  input:
    events:
      - {externalId: "trip-nyc", title: "NYC trip", isAllDay: true, startDate: "2026-10-26T00:00-07:00", endDate: "2026-10-28T23:59:59-07:00", timeZone: null}
  expected:
    - {class: Event, title: "NYC trip", allDay: true, start: "2026-10-26", end: "2026-10-28", busy: false}
  rule: One Event object (EventKit returns one EKEvent spanning the days); each day's view queries by overlap, not by start date.

- id: C07 crossing midnight
  input:
    events:
      - {externalId: "redeye", title: "Flight SFO-JFK", startDate: "2026-10-25T22:30-07:00", endDate: "2026-10-26T06:45-04:00", timeZone: "America/Los_Angeles"}
  expected:
    - {class: Event, title: "Flight SFO-JFK", start: "2026-10-26T05:30Z", end: "2026-10-26T10:45Z", busyMinutes: {"2026-10-25": 90, "2026-10-26": 225}}
  rule: One object; day load splits busy minutes at local midnight of the device time zone.

- id: C08 time zone change while travelling
  input:
    deviceTimeZone: "America/New_York"   # Kaushik landed in NYC
    events:
      - {externalId: "meet-ny", title: "Client meeting", startDate: "2026-10-26T10:00-04:00", endDate: "2026-10-26T11:00-04:00", timeZone: "America/New_York"}
      - {externalId: "gym-float", title: "Gym", startDate: "2026-10-26T07:00-04:00", endDate: "2026-10-26T08:00-04:00", timeZone: null}   # floating
      - {externalId: "call-home", title: "Call with LA team", startDate: "2026-10-26T09:00-07:00", endDate: "2026-10-26T09:30-07:00", timeZone: "America/Los_Angeles"}
  expected:
    - {title: "Client meeting", start: "2026-10-26T14:00Z", eventTimeZone: "America/New_York", shownAs: "10:00"}
    - {title: Gym, start: "2026-10-26T11:00Z", eventTimeZone: null, shownAs: "07:00"}
    - {title: "Call with LA team", start: "2026-10-26T16:00Z", eventTimeZone: "America/Los_Angeles", shownAs: "12:00"}
  on_change: device zone change posts no EKEventStoreChanged; listen for NSSystemTimeZoneDidChange and refetch. Floating events move in absolute time, so their start changes (op: update).
  rule: Store absolute instants plus the event's time zone; render and split days in the device's current zone; refetch on zone change.

- id: C09 deleted event
  input:
    previous: [{externalId: "1on1", title: "1:1 Priya", startDate: "2026-10-21T15:00-07:00"}]
    events: []   # after EKEventStoreChanged, refetch no longer returns it
  expected:
    - {path: "/calendar/1on1@2026-10-21T22:00Z", op: delete}
  rule: In-window object missing from the refetch is deleted through ObjectStore (an op, so undo and Day log see it).

- id: C10 event with no title
  input:
    events:
      - {externalId: "notitle", title: "", startDate: "2026-10-20T16:00-07:00", endDate: "2026-10-20T16:30-07:00"}
  expected:
    - {class: Event, title: null, displayTitle: "Untitled event", busy: true, busyMinutes: 30}
  rule: Store null, never the placeholder; the placeholder is a view string. Still busy.

- id: C11 busy/free-only shared calendar
  input:
    events:   # a colleague's or delegated calendar exposing availability only (UNVERIFIED: title text varies by server)
      - {externalId: "fb-1", title: "Busy", startDate: "2026-10-20T10:00-07:00", endDate: "2026-10-20T11:00-07:00", availability: busy, calendar: {title: "Priya (shared)", allowsContentModifications: false}}
      - {externalId: "fb-2", title: "Free", startDate: "2026-10-20T15:00-07:00", endDate: "2026-10-20T16:00-07:00", availability: free, calendar: {title: "Priya (shared)"}}
  expected:
    - {title: "Busy", calendarName: "Priya (shared)", busy: false, countsForMe: false}
    - {title: "Free", calendarName: "Priya (shared)", busy: false, countsForMe: false}
  rule: Only calendars Kaushik owns or is invited on count as his busy time; other people's shared calendars are mirrored for reference only. availability == free is never busy on any calendar.

- id: C12 birthday calendar
  input:
    events:
      - {externalId: "bday-anya-2026", title: "Anya's Birthday", isAllDay: true, startDate: "2026-10-23T00:00-07:00", calendar: {title: Birthdays, type: birthday}, birthdayContactIdentifier: "ABC123:ABPerson"}
  expected:
    - {class: Event, title: "Anya's Birthday", allDay: true, kind: birthday, contactId: "ABC123:ABPerson", busy: false}
  rule: Mirror as an all-day Event with kind birthday (People area later links contactId); never busy, never in Plan my day.

- id: C13 zero-minute event
  input:
    events:
      - {externalId: "deadline", title: "Visa form due", startDate: "2026-10-20T17:00-07:00", endDate: "2026-10-20T17:00-07:00"}
  expected:
    - {class: Event, title: "Visa form due", start: "2026-10-20T17:00-07:00", end: "2026-10-20T17:00-07:00", busyMinutes: 0, marker: true}
  rule: Kept as a point-in-time marker; 0 busy minutes; can be "next event" for Start with.

- id: C14 overlapping events
  input:
    events:
      - {externalId: "a", title: "Design review", startDate: "2026-10-20T10:00-07:00", endDate: "2026-10-20T11:00-07:00"}
      - {externalId: "b", title: "Vendor call", startDate: "2026-10-20T10:30-07:00", endDate: "2026-10-20T11:30-07:00"}
  expected:
    - {title: "Design review", busy: true}
    - {title: "Vendor call", busy: true}
    - {dayLoad: {date: "2026-10-20", busyMinutes: 90, conflicts: [[a, b]]}}
  rule: Busy time is the union of intervals (90, not 120); overlap is recorded as a conflict, not double-counted.

- id: C15 same event in two calendars
  input:
    events:   # Apple lists this as a known duplicate case: created in a shared calendar and also invited
      - {externalId: "offsite-plan", title: "Offsite planning", startDate: "2026-10-20T14:00-07:00", endDate: "2026-10-20T15:00-07:00", calendar: {title: "Team (shared)"}, selfParticipantStatus: unknown}
      - {externalId: "offsite-plan", title: "Offsite planning", startDate: "2026-10-20T14:00-07:00", endDate: "2026-10-20T15:00-07:00", calendar: {title: Work}, selfParticipantStatus: accepted}
  expected:
    - {class: Event, title: "Offsite planning", calendarName: Work, attendance: accepted, busy: true}
  rule: One object per key; prefer the copy that carries Kaushik's own participant status, else his default calendar.

- id: C16 cancelled event
  input:
    events:
      - {externalId: "cxl", title: "Dentist", startDate: "2026-10-20T08:30-07:00", endDate: "2026-10-20T09:00-07:00", status: canceled}
  expected:
    - {class: Event, title: Dentist, cancelled: true, busy: false}
  rule: EKEventStatus.canceled is mirrored but never busy, same as declined.

- id: C17 window roll
  input:
    now: "2026-10-21T08:00-07:00"   # window is now Oct 20 to Nov 4
    previous: [{key: "standup-1@2026-10-19T16:30Z"}]
  expected:
    - {path: "/calendar/standup-1@2026-10-19T16:30Z", op: none, frozen: true}
  rule: Objects that fall out the back of the window are kept frozen (Day log may link them), not deleted; only in-window absence means delete.

- id: C18 write-only access
  input:
    authorizationStatus: writeOnly
    events: []   # write-only cannot read any event; calendars(for:) returns one virtual calendar
  expected:
    - {path: "/calendar", objects: 0, state: {calendarAccess: writeOnly}}
  ui: "Calendar is set to Add Events Only. Full access lets Tessera see your day." with a link to Settings
  rule: Treat as not connected. Calling events(matching:) once may show the system upgrade prompt (TN3153); do it only from the user's tap, never at launch.

- id: C19 access denied, restricted or not determined
  input:
    - {authorizationStatus: notDetermined}   # first run: requestFullAccessToEvents() from an explicit "Connect calendar" tap
    - {authorizationStatus: denied}
    - {authorizationStatus: restricted}
  expected:
    - {path: "/calendar", objects: 0, state: {calendarAccess: notDetermined | denied | restricted}}
  rule: Unlike Health, EventKit reports the real status, so say so plainly; day load falls back to tasks only, existing Event objects are kept frozen, not wiped.
```

## Health fixtures (slice 2): 17 cases

Window for "last night": samples whose end falls in 18:00 yesterday to 14:00 today (scouting). Asleep = `asleepCore + asleepDeep + asleepREM + asleepUnspecified` (= `HKCategoryValueSleepAnalysis.allAsleepValues`, verified as a type property; exact membership UNVERIFIED). `inBed` and `awake` never count. Source rule: Apple Watch if present, else the source with the most asleep minutes; never sum sources. Watch detection: `sourceRevision.productType` starts with "Watch" (UNVERIFIED that every Watch sample carries it).

```yaml
- id: H01 iPhone and Watch overlapping (dedupe)
  input:
    samples:
      - {type: sleepAnalysis, value: inBed, start: "2026-10-19T22:50-07:00", end: "2026-10-20T06:55-07:00", source: {bundle: "com.apple.health", productType: "iPhone18,1"}}   # iPhone sleep schedule
      - {type: sleepAnalysis, value: asleepCore, start: "23:10", end: "01:00", source: {bundle: "com.apple.health.W1", productType: "Watch7,1"}}
      - {type: sleepAnalysis, value: asleepDeep, start: "01:00", end: "02:10", source: W1}
      - {type: sleepAnalysis, value: asleepREM,  start: "02:10", end: "03:00", source: W1}
      - {type: sleepAnalysis, value: awake,      start: "03:00", end: "03:15", source: W1}
      - {type: sleepAnalysis, value: asleepCore, start: "03:15", end: "06:40", source: W1}
  expected:
    - {path: "/health/sleep/2026-10-20", class: SleepNight, date: "2026-10-20", asleepMinutes: 435, inBedMinutes: 485, source: "Apple Watch", stages: {core: 315, deep: 70, rem: 50}, awakeMinutes: 15}
  rule: Watch wins; asleep is its stage sum (7h15); the iPhone inBed only fills inBedMinutes.

- id: H02 two asleep sources overlapping
  input:
    samples:
      - {value: asleepCore/Deep/REM, total: 412 min, span: "23:20-06:50", source: {bundle: "com.apple.health.W1", productType: "Watch7,1"}}
      - {value: asleepUnspecified, start: "23:00", end: "07:05", source: {bundle: "com.tantsissa.AutoSleep", productType: "iPhone18,1"}}   # 485 min
  expected:
    - {class: SleepNight, asleepMinutes: 412, source: "Apple Watch"}
  rule: Never sum (would read 14h57); Watch beats a third-party app even when the app reports more.

- id: H03 no Watch, iPhone only
  input:
    samples:
      - {value: inBed, start: "2026-10-19T23:05-07:00", end: "2026-10-20T06:50-07:00", source: {bundle: "com.apple.health", productType: "iPhone18,1"}}
  expected:
    - {class: SleepNight, asleepMinutes: null, inBedMinutes: 465, source: iPhone, basis: inBed}
  ui: "In bed 7h45" (not "slept")
  rule: Ship list says asleep stages only; with no asleep samples at all, fall back to inBed, labelled as in bed, and never feed it to the under-6h cap. (UNVERIFIED that iPhone alone writes only inBed; it is what we expect.)

- id: H04 sleep crossing midnight goes to the wake day
  input:
    samples:
      - {value: asleepCore, start: "2026-10-19T23:40-07:00", end: "2026-10-20T07:05-07:00", source: W1}
  expected:
    - {path: "/health/sleep/2026-10-20", date: "2026-10-20", asleepMinutes: 445}
  rule: A night belongs to the local date it ends on; nothing is written for Oct 19.

- id: H05 nap
  input:
    now: "2026-10-20T16:00-07:00"
    samples:
      - {value: asleepCore, start: "2026-10-19T23:30-07:00", end: "2026-10-20T06:30-07:00", source: W1}   # 420
      - {value: asleepCore, start: "2026-10-20T12:40-07:00", end: "2026-10-20T13:20-07:00", source: W1}   # 40, ends inside the 14:00 window
      - {value: asleepCore, start: "2026-10-20T14:30-07:00", end: "2026-10-20T15:10-07:00", source: W1}   # 40, ends after 14:00
  expected:
    - {path: "/health/sleep/2026-10-20", asleepMinutes: 420}
  rule: Cluster samples with gaps under 90 min; the night is the cluster with the most asleep minutes; other clusters are naps and ignored in M4, even inside the window.

- id: H06 inBed vs asleep
  input:
    samples:
      - {value: inBed, start: "22:30", end: "07:00", source: W1}   # 510
      - {value: asleepCore, start: "23:05", end: "03:00", source: W1}
      - {value: awake, start: "03:00", end: "03:25", source: W1}
      - {value: asleepREM, start: "03:25", end: "06:35", source: W1}
  expected:
    - {class: SleepNight, asleepMinutes: 425, inBedMinutes: 510, awakeMinutes: 25}
  rule: Headline is asleep (7h05), not in bed (8h30); awake inside the night is subtracted by construction.

- id: H07 asleepUnspecified only (older or third-party writer)
  input:
    samples:
      - {value: asleepUnspecified, start: "2026-10-19T23:15-07:00", end: "2026-10-20T06:45-07:00", source: {bundle: "com.example.sleepapp", productType: "iPhone18,1"}}
  expected:
    - {class: SleepNight, asleepMinutes: 450, stages: null, source: "com.example.sleepapp"}
  rule: Unspecified counts as asleep; stages are null, not zero.

- id: H08 multiple non-Watch sources
  input:
    samples:
      - {value: asleepUnspecified, total: 390, source: {bundle: "com.example.ringapp"}}
      - {value: asleepUnspecified, total: 430, source: {bundle: "com.example.mattress"}}
  expected:
    - {class: SleepNight, asleepMinutes: 430, source: "com.example.mattress"}
  rule: No Watch, so the source with the most asleep minutes wins, whole; never mix samples across sources.

- id: H09 partial night (Watch battery died)
  input:
    now: "2026-10-20T08:00-07:00"
    samples:
      - {value: asleepCore/Deep/REM, start: "2026-10-19T23:30-07:00", end: "2026-10-20T03:10-07:00", total: 220, source: W1}
      - {value: inBed, start: "23:00", end: "06:55", source: iPhone}
  expected:
    - {class: SleepNight, asleepMinutes: 220, inBedMinutes: 475, partial: true}
  ui: "Slept 3h40 (tracking stopped at 3:10)"
  rule: partial = the chosen source's last asleep sample ends 2h or more before another source's inBed end or before 05:00; partial nights never trigger the under-6h cap.

- id: H10 late-synced samples
  input:
    - {foregroundAt: "2026-10-20T07:10-07:00", samples: []}            # Watch not synced yet
    - {foregroundAt: "2026-10-20T08:40-07:00", samples: "same as H06"}  # synced
  expected:
    - {after: "07:10", objects: none, ui: "no sleep data"}
    - {after: "08:40", op: insert, path: "/health/sleep/2026-10-20", asleepMinutes: 425}
  rule: Recompute last night on every foreground of the wake day and upsert by date; a Plan my day card not yet accepted re-reads it. After the wake day ends, the night is frozen.

- id: H11 no data at all
  input: {samples: [], authorizationRequested: true}
  expected: {objects: none, ui: "no sleep data"}
  rule: Absence is not an object; nothing is written for the date.

- id: H12 read denied
  input: {samples: [], authorizationRequested: true}   # identical to H11 by design
  expected: {objects: none, ui: "no sleep data"}
  rule: HealthKit hides read denial ("it simply appears as if there is no data"), so H11 and H12 must produce byte-identical results; never say "permission denied". A quiet "Check Health access" link in Settings is the only hint.

- id: H13 steps from two sources
  input:
    samples:
      - {type: stepCount, quantity: 6200, start: "2026-10-20T00:00-07:00", end: "now", source: iPhone}
      - {type: stepCount, quantity: 5800, start: "2026-10-20T00:00-07:00", end: "now", source: W1}
      # most of the walking overlaps (phone in pocket, Watch on wrist)
  expected:
    - {path: "/health/steps/2026-10-20", class: StepsDay, date: "2026-10-20", count: 7900}
  rule: Use HKStatisticsQuery .cumulativeSum over today (local midnight to now), which merges sources by the user's Health source priority; never add per-source totals (12,000). (UNVERIFIED in docs fetched; widely documented behaviour.)

- id: H14 resting HR without a Watch
  input: {type: restingHeartRate, samples: []}
  expected: {objects: none, ui: "row hidden"}
  rule: No sample means hide the row; do not show "no data" for resting HR (unlike sleep).

- id: H15 resting HR with a Watch, and stale
  input:
    - {type: restingHeartRate, quantity: "54 count/min", start: "2026-10-20T06:58-07:00", source: W1}
    - {type: restingHeartRate, quantity: "57 count/min", start: "2026-10-17T07:02-07:00", source: W1}   # alternative input: only this one exists
  expected:
    - {path: "/health/restingHR/2026-10-20", class: RestingHeartRate, bpm: 54}
    - {for_alternative: {objects: none, ui: "row hidden"}}
  rule: Latest sample from today or last night only; older than 36 h is stale and hidden, not carried forward.

- id: H16 body weight dedupe with M3
  input:
    tessera: {class: BodyWeight, date: "2026-10-20", kg: 78.4, loggedAt: "07:02"}
    samples:
      - {type: bodyMass, quantity: "78.6 kg", start: "2026-10-20T07:01-07:00", source: {bundle: "com.withings.wiScaleNG"}}
      - {type: bodyMass, quantity: "78.9 kg", start: "2026-10-19T07:05-07:00", source: {bundle: "com.withings.wiScaleNG"}}
  expected:
    - {class: BodyWeight, date: "2026-10-20", kg: 78.4, origin: tessera}   # unchanged
    - {class: BodyWeight, date: "2026-10-19", kg: 78.9, origin: health}    # only if Oct 19 had no Tessera entry
  rule: One BodyWeight per day (M3); Tessera's own entry wins that day, Health fills days without one.

- id: H17 Health store locked
  input: {foregroundWhileProtectedDataUnavailable: true, error: "HKError.errorDatabaseInaccessible"}
  expected: {ops: none}
  rule: A read error is not "no data": keep existing objects and retry on the next foreground (UNVERIFIED that foreground-from-Lock-Screen can hit this; widgets and Live Activities can).
```

## Verified API facts (developer.apple.com, fetched 2026-10-15)

| Fact | Status |
|---|---|
| Write-only access: "your app can't read or delete any events from the user's calendars, including the ones it creates" | Verified, TN3153 |
| Write-only: `calendars(for:)` returns one virtual calendar; `sources` one virtual source | Verified, TN3153 |
| Write-only app calling `events(matching:)` implicitly prompts once to upgrade to full; if denied, no results and no second prompt | Verified, TN3153 |
| `EKAuthorizationStatus` has `fullAccess` and `writeOnly`; `authorized` deprecated; request with `requestFullAccessToEvents()` | Verified, TN3152 |
| Old `NSCalendarsUsageDescription` alone: TN3153 says EventKit falls back to it, which contradicts the scouting line "fails silently". Add `NSCalendarsFullAccessUsageDescription` regardless | Verified (contradiction noted) |
| `predicateForEvents` caps at four years; events are in the default time zone | Verified |
| `calendarItemExternalIdentifier` is shared by all occurrences; duplicates can exist across calendars (shared plus invited, ICS import, delegate, subscribed) | Verified |
| `EKEvent.occurrenceDate` is "the original occurrence date"; `isDetached` marks an edited occurrence; `birthdayContactIdentifier` exists | Verified |
| HealthKit read denial is invisible: "your app cannot determine whether or not a user has granted permission to read data... it simply appears as if there is no data"; `authorizationStatus(for:)` is share status only | Verified |
| With share but not read permission, an app sees only its own samples | Verified (matters for `HealthExporter`'s workouts) |
| Sleep values: `inBed`, `awake`, `asleepCore`, `asleepDeep`, `asleepREM`, `asleepUnspecified`; `asleep` deprecated; `allAsleepValues` exists | Verified |
| Watch sleep samples only include awake between two sleep samples; stage samples overlap inBed but not each other | Verified |
| Health store is encrypted while locked | Verified |
| `.cumulativeSum` merges overlapping sources by priority | UNVERIFIED |
| iPhone without Watch writes only `inBed` | UNVERIFIED |
| Free/busy-only calendar titles ("Busy") | UNVERIFIED, server dependent |
| Watch detection via `productType` prefix | UNVERIFIED |
| Time zone change posts no `EKEventStoreChanged` | UNVERIFIED |

Sources: [TN3152](https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels), [TN3153](https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos), [EKEventStore](https://developer.apple.com/documentation/eventkit/ekeventstore), [predicateForEvents](https://developer.apple.com/documentation/eventkit/ekeventstore/predicateforevents(withstart:end:calendars:)), [calendarItemExternalIdentifier](https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemexternalidentifier), [EKEvent](https://developer.apple.com/documentation/eventkit/ekevent), [HKCategoryValueSleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis), [authorizationStatus(for:)](https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationstatus(for:)), [Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy).

## ASSUMED decisions

For Core:
1. Event key = `calendarItemExternalIdentifier@occurrenceDate(UTC)`; edits to one occurrence are updates (C02).
2. Extra `Event` fields: `busy`, `attendance` (accepted, tentative, pending, declined, unknown), `cancelled`, `eventTimeZone`, `kind` (event, birthday), `contactId`, `edited`, `countsForMe`, `marker`. `title` nullable.
3. Busy = owned or invited calendar, not declined, not cancelled, availability not free, not all-day; busy time is the interval union split at local midnight in the device zone.
4. Refetch on `EKEventStoreChanged` (debounced) and on system time zone change.
5. Out-of-window objects are frozen, in-window absence is a delete op.
6. Health class names `SleepNight`, `StepsDay`, `RestingHeartRate` under `/health/<kind>/<date>`; no object is written for absent data.
7. Night = largest sample cluster (gaps under 90 min) ending in the 18:00 to 14:00 window, dated by its local end date; recompute on every foreground of the wake day, then freeze.
8. Read errors (locked store) never overwrite existing objects.

For Product:
1. Declined, cancelled and other people's shared calendars are mirrored but not busy (visible, greyed).
2. No-Watch fallback shows "In bed 7h45" from iPhone inBed rather than "no sleep data", and never caps the plan.
3. Partial nights are shown with a note and never cap the plan.
4. Resting HR older than 36 h is hidden.
5. Write-only and denied calendar access are named plainly with a Settings link (unlike Health), and the upgrade prompt fires only from a tap.
6. Birthdays mirror now with `kind: birthday` for the later People area.
7. Health share usage string needs rewording to cover reading sleep, steps, heart rate and weight.
