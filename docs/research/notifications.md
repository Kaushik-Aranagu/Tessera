# Notifications: the smallest local set

For: Core, Builder A, Builder B, Design (copy), Product lead. Research lab, board item 42, 2026-10-16.
Traced by hand on `origin/master` at `9b85986` (no Swift toolchain, nothing run). Sources: `ask-lines.md`,
`late-night.md`, `quiet-interrupts.md`, `lockscreen-lines.md`, `widget-states.md`, `undo-lines.md`, `day-boundary.md`,
`tess-voice.md`, `free-signing-survival.md`, `fixtures/cook-timer-phrases.md`, `fixtures/cook-mode-scenarios.md`,
`fixtures/dst-travel.md`, `../product/decisions.md`.

**Bottom line.** Three local notifications and nothing else: a timed task at its time, the rest timer when the app is
not on screen, and a kitchen timer. All are local (`UNUserNotificationCenter`, no push, fine on the free Personal
Team), all `.active` with the default sound, one request per object with the object's id in the identifier, and one
Core reconcile that rebuilds the pending set from the store. Until the permission is granted, "remind me" gets
"On Now then." (decision 6:07 PM PT).

## 1. What master has (`9b85986`)

| Thing | Where | State |
|---|---|---|
| Local notifications | `git grep UNUserNotification` | None. No delegate, no app delegate (`App/TesseraApp.swift:72` uses `scenePhase` only) |
| Rest alert | `Features/Workout/LiveActivity/RestActivityController.swift:139` | ActivityKit `AlertConfiguration` "Set 4 is up" / "Bench, 82.5 × 8". Fired by an in-app `Task.sleep` (`:128`), so it plays **only while the app is alive**. Suspended or killed: the face flips via `staleDate` (`:117`) with no sound |
| Kitchen timers | `TesseraCore/.../Kitchen/Cooking.swift:155, 202, 248` | `StartKitchenTimer` writes `startedAt`, `endsAt`, `minutes`; `StopKitchenTimer` sets `isStopped`; `FinishCooking` stops linked timers. No alert of any kind when one ends |
| Timed tasks | `Tasks.swift:76`, `TrainingActions.swift:345-382` | `startsAt` (and `due`) are plain dates. Nothing says whether the time was explicit: a date with no time is written as 09:00 |
| Roll-forward | `RollForward.swift:52-62` | Keeps the clock time when it rolls; decision 5:41 PM PT says a rolled task is flexible. No caller in the app (`late-night.md` #1) |
| Op-log hook | `ActionEngine.swift:87` `observe` | Fires on commit only. `undo` and `redo` (`:137-151`) do not notify observers |
| Entitlements | `App/Tessera.entitlements` | HealthKit only. No Time Sensitive |
| "On Now then." | `TessCaptureEngine.swift:106-109` | Not on master; "remind me" writes a task he only sees in the app |

## 2. The three notifications

Shared rules:
- **Identifiers** are `<kind>.<uuid>`: `task.<taskID>`, `rest.<workoutID>`, `kitchen-timer.<timerID>` (the last as in
  `cook-mode-scenarios.md`). Adding with the same id replaces; edit, move, done, delete and undo all go through one
  reconcile (section 6), never ad hoc removes.
- **Real clock.** Fire moments come from stored absolute dates, moved off the `-demoTime` shift exactly as
  `RestActivityController.contentState` does, or the demo rings at the wrong hour.
- **Interruption level `.active`, sound `.default`.** `.timeSensitive` needs the
  `com.apple.developer.usernotifications.time-sensitive` entitlement. Whether a Personal Team profile signs it is
  **unverified** (Apple's capability table did not render for us, as with HealthKit in `free-signing-survival.md`).
  Don't add it: a refused entitlement blocks the 7-day reinstall, and nothing here needs to break through Focus.
- **Threads** `tessera.tasks`, `tessera.rest`, `tessera.kitchen`. No badge, ever.
- **Lines** follow `tess-voice.md`: plain, under 12 words, no "!", no emoji. iOS prints "Tessera" above each one.

### N1. Timed task at its time

| Field | Value |
|---|---|
| Fires for | An undone task with `alerts = true` and a `startsAt` in the future. `alerts` is a new Task field (Core), true only when he gave a clock time ("call mom 9am", a time edited by hand) or said "remind me" (a date with no time alerts at 09:00). A plain dated task without "remind me" gets no alert and, per the 6:20 PM call, no 09:00 time (Core storage change). False for times from Plan my day, the model without "remind", roll-forward, `due`-only tasks and events |
| Lead time | **0 min.** Now already lifts a timed task 15 min ahead (decision 4:01 PM PT), so a 10 min lead would be a second cue for the same thing. See Q2 |
| Trigger | `UNCalendarNotificationTrigger(dateMatching:repeats: false)` with year, month, day, hour, minute **and `timeZone`** taken from `startsAt` in the zone at scheduling. A pinned zone makes it a fixed instant (dst-travel rule 6: "call mom tue 9am" set in LA rings at 12:00 in New York); 9:00 on 2 Nov is 9:00 PST because the components come from the stored instant. Zone behaviour on device is unverified; the reconcile on `NSSystemTimeZoneDidChange` covers it either way |
| Title / body | Title: the task title, "Call mom". Body: "It's 9 am." With a length: "It's 9 am. 30 min." |
| Category `TASK` | **Done** writes `SetTaskDone(done: true)` by `.intent`. **Not now** writes `MoveTask` (same time tomorrow, keeps `alerts`) by `.intent`. Both run in the background without unlocking, like the Live Activity's Done |
| Undo | Next foreground, Tess's line once, with UNDO for 4 s: "Call mom done." Undo: "Call mom taken back." Not now: "Call mom moved to Saturday." Undo: "Call mom taken back." (decision 5:14 PM PT) |
| Foreground | `willPresent` returns `[.banner, .list]`, no sound (Now is already showing it) |
| Tap | Opens Home with the task as Now |
| Removed when | Done, Later, delete, `alerts` false, rolled (rolls > 0 means flexible), or its undo. Moved: replaced at the new time. A delivered one is cleared on done |
| DST and trips | Fixed instant, never floating wall time. "1:30am" on 1 Nov is the first one (decision 6:06 PM PT) |

### N2. Rest timer done, app not on screen

| Field | Value |
|---|---|
| Fires for | Every rest with a `restEndsAt`, scheduled at rest start, whatever the app state. One per workout |
| Trigger | `UNTimeIntervalNotificationTrigger(restEndsAt - realNow)`. Durations are absolute (dst-travel rule 3) |
| Title / body | The Live Activity's words, as `lockscreen-lines.md` asks: "Set 4 is up" / "Bench, 82.5 × 8" |
| Actions | None. The Live Activity carries Done, +15 and Skip; two sets of buttons would log twice |
| Replaced / removed | +15 or extend: replaced. Skip, a logged set, finish, discard, the 6 h wrap-up, Siri "Undo Last Set" (which must also tell the session, undo-lines B1): removed |
| Foreground | `willPresent` returns `[]`; the workout screen shows rest ending |
| Tap | Opens the live workout |

**Live Activity: one alert, not two.** Recommend: when notifications are authorized, the notification is the sound
and the Live Activity is the face; `restEndAlert` returns nil. When they are not, keep master's `AlertConfiguration`.
Reason: the ActivityKit alert needs the app running at `restEndsAt` (verified in `cook-mode-scenarios.md`), so a locked,
suspended phone flips silently today; with both on, a locked phone with the app still alive would ring twice. This
reverses `ask-lines.md` Q5 ("rest keeps the ActivityKit alert"); Product to confirm (Q1).

### N3. Kitchen timer done

| Field | Value |
|---|---|
| Fires for | Each `StartKitchenTimer`, in or out of a cook. The alert of record, since a Live Activity lives at most 8 h |
| Trigger | `UNTimeIntervalNotificationTrigger(endsAt - realNow)` (not a calendar trigger: a zone change must not move it) |
| Title / body | "Pasta is done" / "Carbonara, step 3". With no cook: "Pasta is done" / "10 min." |
| Category `KITCHEN` | **Stop** writes `StopKitchenTimer` by `.intent`. Line on return: "Pasta stopped." Undo: "Pasta taken back." **+1 min** waits for slice 12b (`ExtendKitchenTimer`) |
| Replaced / removed | Stop, `FinishCooking`, delete, undo of the start: removed (pending and delivered). Restart by label: replaced |
| Foreground | `[]` when cook mode is on screen (the scenarios' S03); else `[.banner, .sound]` |
| Tap | Opens cook mode (`tessera://cook`) |

## 3. Permission

- **Which ask.** `ask-lines.md` A7, priority 3 in the one-ask-a-day queue (after Health write and Calendar).
- **When it fires.** At the first of: a kitchen timer start, a "remind me" capture, or a task saved with an explicit
  clock time. Never at a rest (the first rest already spends the day's slot on the Live Activity choice, A8), never at
  launch, onboarding or from a background path. Rule 2 does not apply: this is a pushed ask.
- **Pre-ask line (exact).** Timer trigger: "Want timers to alert you when locked?" **Allow** · Not now (A7 as
  approved). Task trigger: "Want me to buzz you at 9 am?" **Allow** · Not now. Allow shows the iOS sheet.
- **Slot used today.** Mark A7 pending in `TessAskLedger`; the timer alerts in the app and on the Live Activity; the
  task reply gets the fallback. It fires at the next trigger on a later day.
- **Fallback (exact).** "remind me" with no permission, for any reason (pending, Not now, denied): the reply ends
  "On Now then." ("Call mom, Saturday 9 am. On Now then."). Timer, after Not now or denied: "Timers alert in the app
  only." A plain timed task with no "remind": no extra words. Re-ask: Not now once more 7 days later at a trigger;
  denied never.
- **Provisional: no.** `.provisional` delivers silently to Notification Center, which is useless for timers, and iOS
  adds its own Keep / Turn Off card, a second ask-shaped thing. Request `[.alert, .sound]` only.

## 4. Quiet hours

- **Window:** 23:00 to 07:00 local wall clock (late-night use is normal for him).
- **Rule:** in the window, only what he timed rings: rest and kitchen timers (he started them) and N1 tasks (he gave
  the clock time, `late-night.md` S12: "a task reminder set for 02:00 is the only thing allowed through"). "remind me"
  with a date and no time lands at 09:00, outside the window. Anything Tessera would post on its own (the future
  quiet-interrupts digest, any `normal` or `low` item) is held until his first open after 04:00 and shown on Now, not
  buzzed.
- **Masking.** During a running workout or cook, N1 still posts (explicit time beats the mask); everything else
  follows `quiet-interrupts.md`.
- **Focus.** We never read Focus. `.active` items are held by any Focus that does not allow Tessera; that is his
  setting to change, and the timers' Live Activity still counts down on the Lock Screen. No Focus filter, no
  `INFocusStatusCenter`.

## 5. What never notifies

Streaks or counts; Review or the week; PRs and bests; plan or deload changes; missed or carried tasks and the 04:00
roll; Later; rest days; the 6 h wrap-up; Health saves or the Health ask; backups and restore; grammar misses, ghost
rows and hints; Plan my day; Tess suggestions or check-ins; a second alert for the same object (no repeats, no snooze
chains, no "still waiting"); `due` deadlines; calendar events (Calendar does that); anything with a sound in quiet hours
except section 4; badges.

## 6. Scheduler and the 64 budget (Core)

- `NotificationPlan` in TesseraCore, pure: store plus now in, a list of `(id, fireDate, kind, title, body, category)`
  out. App-side `NotificationScheduler` diffs it against `pendingNotificationRequests()`: add new or changed ids,
  remove gone ones, clear delivered ones whose object is done or stopped.
- **Runs:** after every committed op (`engine.observe`), after every `undo`/`redo` (which do not notify on master: add
  `notify` there or call the scheduler from the undo paths), on foreground, on `NSSystemTimeZoneDidChange` and on a
  significant time change, after grant, and after `-resetDemo`.
- **Budget:** iOS keeps 64 pending per app (unverified for iOS 27). Order: the rest (1), running kitchen timers (cap
  8), then N1 tasks soonest first, at most **40** and only within 14 days. That leaves 15 spare for the digest's safety
  net and later kinds. Every reconcile refills, so a task on day 15 is scheduled once he opens the app in the next
  fortnight; tasks are never skipped silently because the plan is rebuilt from the store each time.
- **Fixtures:** one plan test per row of section 2, plus the 1 Nov fall-back and the LA to New York trip from
  `fixtures/dst-travel.md`, and a 70-task case that schedules exactly 40.

## 7. Owners and status

| Owner | Work | On master |
|---|---|---|
| Core | `alerts` field; `NotificationPlan` and identifiers; scheduler, delegate (`willPresent`, `didReceive` performing by `.intent`), categories; observer on undo/redo; `TessAskLedger` A7; "On Now then." in `TessCaptureEngine` | Nothing built |
| Builder A | N2 at rest start, removal on skip/log/finish; `restEndAlert` nil when authorized; N3 calls in cook mode and its foreground rule; Live Activity `staleDate` on ready (`late-night.md` #12) | LA alert only, in-app only |
| Builder B | Pre-ask lines on Home and Command, fallback lines, the once-per-open action lines with UNDO; Settings row "Notifications: off" | Nothing built |

## 8. Conflicts with master and other files

1. `undo`/`redo` skip observers, so a commit-only hook leaves a stale reminder after Undo.
2. No way to tell an explicit time from the 09:00 default, so `alerts` is needed before N1.
3. Roll-forward keeps the time against decision 5:41 PM PT; N1 skips any task with `rolls > 0` until Core drops it.
4. `ask-lines.md` Q5 (rest keeps the ActivityKit alert) and A7's trigger (kitchen timer only) are both widened here.
5. "remind me in 20 minutes ..." still writes a task titled "In 20 minutes ..." (`cook-timer-phrases.md` row 26); N1
   needs `TessDates` to read "in N min".
6. Cook acceptance says "Stopped simmer."; the undo rule asks for the name first: "Simmer stopped."

## 9. Open questions (recommended default first)

1. **Rest alert:** the notification when authorized, the ActivityKit alert otherwise. Never both.
2. **Lead time for N1:** 0 min. Revisit only if he asks for "10 min before" in use; then add it as a per-task word
   ("remind me 10 min before"), never a global setting.
3. **Model-made tasks:** `alerts` only when his text says "remind" or holds a clock time.
4. **Actions without unlock:** yes for Done, Not now and Stop, like the Live Activity buttons.
5. **Pre-ask on a task trigger:** the task line, not A7's timer line, so the ask names the thing he just did.
6. **Time Sensitive:** don't request. Try it once on the phone only if Focus ever eats a timer.
7. **Quiet window:** 23:00 to 07:00, fixed, no setting.
8. **Budget:** 40 tasks within 14 days.
