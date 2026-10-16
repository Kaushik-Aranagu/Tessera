# M4 scouting: Calendar, Health, Plan, Shutdown, Focus

For: Product lead (planning), Core engine
Date: 2026-10-15

## 1. Calendar mount (slice 1)

**Recommendation.** Ask for full read access once, fetch a rolling window (yesterday to +14 days), and mirror occurrences as read-only `Event` objects. On every `EKEventStoreChanged` notification, refetch the window and diff. Never write back in M4.

**Smallest version.** One `EKEventStore` in the engine, `requestFullAccessToEvents()`, `predicateForEvents(withStart:end:calendars: nil)`, map to `Event { title, start, end, allDay, calendarName, location, isRecurring }` under `/calendar`.

**Gotchas.**
- Since iOS 17 there are two prompts: write-only (`requestWriteOnlyAccessToEvents`) cannot read anything. We need full access and the `NSCalendarsFullAccessUsageDescription` key; the old key alone fails silently.
- The change notification says nothing about what changed. Refetch and diff; debounce, it can fire in bursts.
- The predicate expands recurring events into occurrences and is capped at 4 years. Each occurrence shares an `eventIdentifier`, so key objects by `calendarItemExternalIdentifier + occurrenceDate`.
- Skip declined invites (`participationStatus == .declined`) and all-day events from the day-load free time.

Sources: [EventKit access levels (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10052/)

## 2. Health mount (slice 2)

**Recommendation.** Read four types on app foreground only (no background delivery in M4), and store one daily value each under `/health`. "Last night" is a fixed window, not clever logic.

**Smallest version.** Request read for `sleepAnalysis`, `stepCount`, `restingHeartRate`, `bodyMass`. Steps: `HKStatisticsQuery` cumulative sum for today. Resting HR and weight: latest sample. Sleep: samples ending between 18:00 yesterday and 14:00 today; sum the asleep stages (`asleepCore`, `asleepDeep`, `asleepREM`, `asleepUnspecified`), ignore `inBed` and `awake`.

**Gotchas.**
- Sleep samples overlap across sources (Watch, iPhone, third-party apps). Prefer the Apple Watch source if present, else the source with the most asleep minutes. Never sum sources together.
- Read permission is hidden: a denied read looks exactly like "no data". Show "no sleep data" calmly, never "permission denied".
- Resting HR only exists with an Apple Watch. Hide the row if there is none.
- Health data is unreadable while the phone is locked; reads from a widget or Live Activity will fail.
- Background delivery needs its own entitlement and is throttled (hourly at best for most types). Skip it.
- Needs the HealthKit capability in `project.yml`. It should work on a free Personal Team but this is the first entitlement in the project; verify on the first device build.
- Weight: dedupe against M3 slice 1 by timestamp, keep Tessera's own entry if both exist.

Sources: [HKCategoryValueSleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis), [Protecting user privacy (HealthKit)](https://developer.apple.com/documentation/healthkit/protecting-user-privacy)

## 3. Plan my day (slice 6) and Shutdown (slice 7)

**What the field does.** Sunsama: a guided morning flow (pull tasks in, estimate, workload warning) and an evening shutdown that reviews and rolls; loved, but users say the full ritual takes 10 to 20 minutes and gets skipped. Motion auto-schedules and reshuffles; users stop trusting it. Structured and Tiimo: a visual timeline with time you can see; low effort, sticks. Amie and Akiflow: one inbox, drag onto the calendar. Cal Newport: review the inbox, check the next days, say "shutdown complete" out loud; the value is a hard close, not the review.

**What sticks vs chore.** Sticks: under a minute, defaults pre-filled, one tap to accept, a clear end ("done"). Chore: estimates for every task, reviewing what failed, streaks, red overload.

**Plan my day, 60-second flow.** Now card at 08:00: "Today: 3 meetings, 4h free, slept 6h40." Below, a ghost plan of 3 lines max; each line has accept or skip. Last line: "Start with: X" which becomes the one next thing on Now. Done.

**Without a model call (first version, rules only).**
1. Fixed items: calendar events and any planned workout.
2. Carry-overs: tasks rolled from last Shutdown first.
3. Then due today, then oldest touched.
4. Fill until free time is used (from slice 3); if sleep < 6h or energy <= 2, cap at 2 tasks and offer the lighter top set.
5. "Start with" = the first non-meeting item before the next event.
Deterministic and testable; a model can later reword and reorder it.

**Shutdown, 60-second flow.** Now card at 21:00: counts only ("Did 4 tasks, 1 workout, cooked once"). Unfinished items pre-selected to roll to tomorrow (one tap to unselect any). One optional line for tomorrow. Button "Shutdown complete" ends it and writes to the Day log. No list of what did not happen.

Sources: [Sunsama daily planning](https://help.sunsama.com/docs/daily-planning), [Sunsama shutdown](https://help.sunsama.com/docs/daily-shutdown), [Motion review](https://www.morgen.so/blog-posts/motion-review), [Newport, shutdown ritual](https://calnewport.com/drastically-reduce-stress-with-a-work-shutdown-ritual/), [Tiimo](https://www.tiimoapp.com/newsroom)

## 4. Focus block and body double (slice 8)

**Evidence.** arXiv 2509.12153 (VR bricklaying, 12 adults with ADHD): with a human or AI body double, people finished faster and reported better sustained attention than alone; small sample, VR, so treat it as a direction, not proof. Other evidence is mostly anecdotal: presence plus gentle accountability.

**Apps.** Focusmate and Flow Club: live humans on video, strong but needs other people. Forest: a tree grows if you stay off the phone; simple stakes. Opal: blocks apps. Endel: background sound. Solo pattern that transfers: visible timer, one start ritual, one soft check-in, a short wrap-up.

**Recommendation.** A focus block is a process on any task: a Live Activity with a draining bar, one local notification at halfway ("Still on X?" with Yes / Switch), and a one-line wrap-up written to the Day log. No app blocking, no sound in v1.

**Smallest version.** Durations 25 / 50 min. Live Activity uses `ProgressView(timerInterval:)` and `Text(timerInterval:)` so it updates itself with no pushes. The halfway check-in is a scheduled local notification, not a Live Activity update.

**Gotchas.**
- The app is suspended during the block; it cannot update the Live Activity locally without push. Design so nothing needs updating.
- Needs a widget extension target and `NSSupportsLiveActivities`.
- End the activity with a stale date so a forgotten block does not sit on the Lock Screen.
- Slice 4 masking: during the block, queue low-priority Tessera notifications; a Focus filter (`SetFocusFilterIntent`) can come later.

Sources: [arXiv 2509.12153](https://arxiv.org/abs/2509.12153), [Understood on body doubling](https://understood.org/articles/body-doubling-for-adhd-what-it-is-and-how-it-works), [ActivityKit](https://developer.apple.com/documentation/activitykit)

## Needs Kaushik's yes/no

1. **Plan my day with a model call (slice 6).** Already flagged in the ship list. Proposal: ship the rules-only version now (no OK needed), ask about the model later.
2. **Does he wear an Apple Watch?** Not a blocker; it only decides whether resting HR and sleep stages show. The code handles both.
