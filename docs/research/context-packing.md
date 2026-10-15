# Context packing: how Home picks what to show

For: Core (scoring), Builder B (Home), Product lead, Design studio
Date: 2026-10-15 · Research lab · Task: board item "Context packing"
Inputs: `../product/spatial-interaction.md` §0, `../product/whats-running.md`, `../product/ship-list-m2.md`, `../product/ship-list-m4.md`, `plan-my-day-scenarios.md`, `quiet-interrupts.md`, `next-areas.md`, `habits.md`, `sticking-past-week-3.md`, and master at 215f70e.

## 1. The principle

Section 0: "**The screen is the scarce resource.** At any moment, pack in only what is most meaningful for what he is doing now: the running process, the time of day, what he just did, the page he's on." And: "'context packing' means Home choosing what to show from context."
So Home gets one rule that turns a few on-device signals into 1 Now, at most 3 ledger rows, at most 3 Today lines and at most 1 Tess line. Every pick can explain itself.

## 2. What master does today (so this extends it)

- `NowPicker.pick` (Core, `Tasks/NowPicker.swift`): running process, else timed items by start, else untimed today with carried-over first. It is ordering only, with no scores and no reasons. Cook timers already feed Now's line.
- `ProcessTable.ledger` puts suspended processes (3-day window) and then waiting ones whose check time has passed on Home, at most 3. `tidy` and `wakeWaiting` apply the stale rules.
- **Gap:** Home's `NowPage` does not call `NowPicker`. Its hero comes from `AppModel.currentTask`, which only looks at timed tasks, and it caches for 60 s. So Home and NowPicker can disagree today. The first slice fixes this: one ranker, two readers.
- `DayLoad` (`isFull`, `couldMove`) and `TaskList.today` exist. `Event` (M4 slice 1) and `Habit` (M3) are not on master yet.

## 3. Lessons from elsewhere (public docs and reviews, not re-checked today)

- **iOS Smart Stack:** widgets hand the system a relevance score plus how long it holds (`TimelineEntryRelevance`, and relevance contexts such as date or location). Many people switch off Smart Rotate because the stack shuffles. Lesson: scores need a hold time, and the order must not churn.
- **Siri Suggestions:** they learn from donated intents and routine, but there's no way to ask why something showed up. Lesson: every pick carries its reason.
- **Google At a Glance:** one slot, a calm default (date, weather), overridden by something urgent (a meeting soon, a flight, a timer). Lesson: a short ladder of hard overrides on top of a quiet default.
- **Things and Sunsama:** Today is what you chose plus what is dated today, split by day part (Things' "This Evening"). Sunsama warns when the day's planned time goes past your capacity but leaves the cutting to you. Lesson: be deterministic, respect his own order, and treat day load as an offer, never an automatic move.

## 4. Signals (all on device; nothing leaves the phone)

| Signal | Source in code or data | Cost | Privacy |
|---|---|---|---|
| Running process | `ProcessTable.running()`; cook timer via `CookLog.timers()` | In memory | Own data |
| Time of day, day part | `AppClock.now` (honours `-demoTime`); parts: early <07, morning 07-12, midday 12-14, afternoon 14-17, evening 17-21, shutdown 21-22, late ≥22; weekend flag | Free | None |
| Last action, recency | Newest `OpRecord` by `.user` (class of subject, owner app, age in min) | In memory, one lookup | Own data |
| Place in the app | The page or app he came Home from (`HomeSpatialView.Page`, last opened app); a new in-memory `lastPlace` on `AppModel`, not persisted | Free | Not stored |
| Next calendar event, gap | `Event` objects under `/calendar` (M4 slice 1): next non-all-day, not declined; gap = start minus now | Diffed on `EKEventStoreChanged` | Read-only, mirrored locally |
| Day load | `TaskList.load` → `DayLoad.isFull`, `couldMove` (calendar-aware after M4 slice 3) | Cheap sum | Own data |
| Due or dated items | `TaskList.today` (`due`, `startsAt`, `isCarriedOver`, `rolls`); workout `scheduledFor` | In memory | Own data |
| Habit closeness | `Habit.count(week)` vs `target`, days left in the week (M3) | Cheap count | Own data |
| Groceries count | Open items on `Groceries.listID` | Cheap count | Own data |
| Re-entry gap | Days since the last `.user` op | Free | Own data |
| Focus / Do Not Disturb | `INFocusStatusCenter` only gives "some Focus is on" and needs a capability (see quiet-interrupts.md). Skip it; use our own focus block process (M4 slice 8) | n/a | n/a |
| Sleep, energy (M4, optional) | Health mount, energy check-in | On foreground | Health read-only |

## 5. The scoring rule (shared by NowPicker and Home)

Three hard overrides, then a weighted sum over candidates (timed and untimed today items, the workout, suspended processes as resumable items, offers such as Shop, Shutdown and Plan my day). Ties go to the stalest item (oldest `lastTouched`), then title. The current Now holds unless a challenger beats it by 15 (hysteresis). Only one item marked `isAsk` survives.

```swift
struct Pick { let item: Candidate; let score: Int; let why: String }

func rank(_ items: [Candidate], _ s: Signals) -> [Pick] {
    // 1. Hard overrides, in order.
    if let r = s.running { return [Pick(item: r, score: .max, why: "Running since \(hm(r.startedAt))")] + rest(items, s) }
    if let e = s.nextEvent, e.start.timeIntervalSince(s.now) <= 15 * 60 {
        return [Pick(item: e, score: .max, why: "Starts at \(hm(e.start))")] + rest(items, s)
    }
    if s.daysAway >= 3, let small = items.filter({ $0.fits(s.dayPart) }).min(by: { $0.minutes < $1.minutes }) {
        return [Pick(item: small, score: .max, why: "Welcome back. Small on purpose")]  // nothing else on Today
    }
    return rest(items, s)
}

func rest(_ items: [Candidate], _ s: Signals) -> [Pick] {
    var picks = items.map { c -> Pick in
        var p = 0; var why: [String] = []
        if let t = c.startsAt { let m = max(0, Int(t.timeIntervalSince(s.now) / 60))
            if m <= 90 { p += 40 - m / 3; why.append("at \(hm(t))") } }
        if c.dueToday { p += 20; why.append("due today") }
        if c.carriedOver { p += 10; why.append("carried from \(c.rolledFrom)") }
        if c.fits(s.dayPart) { p += 15; why.append("your \(s.dayPart) slot") }
        if c.app == s.lastAction?.app, s.lastAction!.minutes < 30 { p += 15; why.append("you were just in \(c.app)") }
        if c.app == s.place { p += 10 }
        if let h = c.closesHabit, h.left == 1 { p += 10; why.append("1 more for \(h.name)") }
        if s.dayFull, c.startsAt == nil { p -= 10 }
        if c.id == s.incumbent { p += 15 }  // hysteresis; never shown in why
        return Pick(item: c, score: p, why: why.prefix(2).joined(separator: ", "))
    }
    picks.sort { ($0.score, $1.item.lastTouched, $0.item.title) > ($1.score, $0.item.lastTouched, $1.item.title) }
    var askSeen = false
    return picks.filter { !$0.item.isAsk || !askSeen && { askSeen = true; return true }() }
}
```

- **Home reads it as:** pick[0] → Now; `ProcessTable.ledger` unchanged (minus anything that is Now); the next picks that are not in the ledger → Today, with ledger rows + Today lines ≤ 4 so the page stays one screen tall.
- **Why this:** `why` (at most two reasons, plain facts) feeds a long-press "Why is this here?" on Now and on each Today line, for example "at 18:00, your evening slot". Hysteresis and penalties are never shown as reasons.
- **Offers are candidates with a gate:** Shop exists only when Groceries ≥ 8, it's evening and nothing is running (next-areas link 4); Plan my day from 07:00 to 10:00 on the first open; Shutdown at 21:00 if opted in. Each is `isAsk`, and each shows at most once a day.

## 6. When to re-rank (anti-flicker)

Re-rank only on events: foreground, a `.user` op, a process state change, a timer end, a calendar diff, and scheduled boundaries (an event start minus 15 min, a timed item's start, a day-part edge). Never on a minute tick. The 60 s `schedule` cache in `AppModel` goes away. Between events, Now's drain bar and clock text move, but the pick doesn't.

## 7. Twenty moments in one Tuesday, plus other days

Base day (from plan-my-day d01): gym 07:15 (Push A), Standup 09:30, Design review 11:00, 1:1 Priya 15:00; tasks Reply to landlord (carried), Book physio (due), Expense report (due 17:00); Carbonara planned 19:00.

| # | Time, situation | Signals | Now | Ledger | Today (1 to 3) | Tess line |
|---|---|---|---|---|---|---|
| 1 | 06:50 waking up | early, first open, workout 07:15 (25 min), event 09:30 | Push A at 07:15 ("at 07:15") | none | Reply to landlord · Standup 09:30 · Book physio | none |
| 2 | 07:05 pre-gym | workout in 10, last action opened Workouts 1 min ago | Push A, first set "Bench 80 kg × 8", Start | none | Standup 09:30 · Reply to landlord | none |
| 3 | 07:25 mid-set | running workout | Live set at eye level, Bench set 3 | none | Standup 09:30 | none (low items held; Live Activity "2 waiting") |
| 4 | 07:28 rest | running, rest dial 1:45 | Dial counting down, next set ghosted | none | Standup 09:30 | none |
| 5 | 08:15 post-workout | workout done 0 min ago, last action finish | The compressed Push A for one settle, then Reply to landlord | none | Standup 09:30 · Book physio · Expense report 17:00 | "Counts for Train 3×/week (2 of 3)" |
| 6 | 08:35 commute | morning, last action 20 min, event in 55 min | Reply to landlord, 15 min ("carried from Mon, fits before 09:30") | none | Standup 09:30 · Book physio | none |
| 7 | 09:20 meeting in 10 | event ≤15 min override | Standup at 09:30, draining to start | Reply to landlord "Left at draft, 12 min ago" | Book physio · Design review 11:00 | none |
| 8 | 12:30 lunch | midday, gap 2h30 to 15:00, Book physio due | Book physio, 20 min | Reply to landlord | Expense report 17:00 · 1:1 Priya 15:00 | none |
| 9 | 15:40 afternoon slump | afternoon, last action 50 min ago, Expense report untouched 3 days | Expense report ("due 17:00") | none | Call mum · Carbonara 19:00 | "First step: open last month's receipts, 2 min?" (the one ask) |
| 10 | 18:15 groceries trip | evening, Groceries 9, offer taken at 18:05, shop running | Groceries, "Dairy, 6 of 9 left" | none | Carbonara 19:00 · Call mum | none |
| 11 | 19:10 cook timer | running cook, pasta timer 6 min | Carbonara: "Pasta, 6 min" drain | none | Call mum · Shutdown 21:00 | none |
| 12 | Thu 17:30 overbooked evening | day full (planned 3h40, free 2h), Push B 18:00 | Push B at 18:00 | none | Dinner with Sam 20:00 · Call bank; day strip reads "full" | "Tonight is full. Move Call bank and Sort the garage to Later?" |
| 13 | 21:00 Shutdown | shutdown part, opted in | Shutdown: "Did 3 tasks, 1 workout, cooked once"; unfinished preselected to roll | none | Tomorrow: Standup 09:30 | "One line for tomorrow?" (optional) |
| 14 | 23:40 late night | late, nothing running, day closed | Quiet: "Tomorrow starts with Standup 09:30", dimmed | none | none | none |
| 15 | Mon 10:05, back after 4 days | daysAway 4, morning | "Short Push day, 30 min, this evening?" (re-entry override) | none (older than 3 days left Home) | none | "Good to see you. Here is today." |
| 16 | Sat 09:30 weekend morning | weekend, no events, Legs date-only, Groceries 9 | Legs, any time today ("weekend, nothing booked") | none | Water plants (6 days) · Call mum | none (Shop waits for evening) |
| 17 | Wed, empty day | no events, no tasks, rest day | "Nothing planned. Rest day." with the Ask Tess glyph | none | From Later: Sort the garage (stalest) | none |
| 18 | Wed 08:00, workout missed yesterday | Push A not finished Tue; plan rolls on | Push A, today 18:00 ("your evening slot") | none | Standup 09:30 · Book physio | none (never "missed"; plan simply rolls on) |
| 19 | Fri 18:40, two processes suspended | workout left at set 3 (40 min), cook at step 4 (15 min), nothing running | Next timed: Call bank 19:00 (suspended items never take Now) | Carbonara "Step 4 of 7, 15 min ago" · Push B "Set 3 of 5, 40 min ago" | Shutdown 21:00 (2 ledger + 1 line ≤ 4) | none |
| 20 | Sun 16:30, habit close to target | Train 3×/week at 2 of 3, last day of week, no events | Short Legs, 30 min ("1 more for Train 3×/week") | none | Prep lunches · Call mum | none (the why line is enough; no nudge) |

## 8. Anti-patterns (hard rules)

- **Never flicker.** Re-rank on events only (§6), and the incumbent keeps a +15 margin. A Now that changes without anything happening is a bug.
- **One ask per screen, one Tess suggestion per day.** Offers (Shop, Plan my day, first step, move to Later, plan reset) compete for one slot. A declined offer doesn't come back that day.
- **Never red, never a debt.** No "overdue", no "missed", no counts of what didn't happen. Carried-over items say where they came from, as a fact. Stale items fade to Later under the existing `ProcessTable` rules.
- **Never more than one screen.** Ledger rows plus Today lines ≤ 4. Anything else sits one level down (z).
- **Never guess what we can't read.** No location, no Focus state, no inferred mood. Signals come from his own data, the clock and the calendar he mounted.
- **Never a black box.** Every pick has a `why`. If a reason can't be written as a plain fact, it doesn't score.

## 9. Smallest first version and slices

**V0:** one `rank` in Core from signals that already exist on master (running process, cook timer, timed items, due and carried-over, workout slot, stalest tie-break, incumbent hysteresis, `why`). Home reads it instead of `AppModel.currentTask`. No calendar, habits or day parts yet. That covers moments 2 to 8, 10, 11, 18 and 19.

| Slice | Owner | Done when |
|---|---|---|
| 1. `NowPicker.rank` with `Pick.why` | Core | `NowPicker.pick` is a thin wrapper over `rank(_:_:)`; `NowPickerTests` cover the V0 moments above as fixtures (same pinned clock as plan-my-day), plus ties going to stalest and an incumbent holding within 15; old `pick` tests still pass |
| 2. Home reads the ranker | Builder B | `NowPage` hero and Today lines come from `rank`, not `currentTask`; re-rank only on the events in §6 (the 60 s cache is removed); long-press on Now or a Today line shows "Why is this here?" with `why`; with `-demoTime 07:05` and `-demoTime 19:10 -demo` the screen matches rows 2 and 11, and nothing moves after 10 idle minutes |
| 3. Context signals | Core | Adds day part, last action, place, Groceries offer, re-entry and day-full penalty; then the calendar override (when M4 slice 1 lands) and habit closeness (M3). All 20 moments pass as fixtures |

## Yes/no for Kaushik (defaults taken, nothing blocked)

1. Should a meeting 15 min away take Now from an untimed task? Default: yes, but never from a running process.
2. Should the "why" line show on long-press only, not inline? Default: long-press only.
