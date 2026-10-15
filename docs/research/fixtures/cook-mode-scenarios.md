# Cook mode scenarios (kitchen slice 12)

For: Core engine, iOS build, Product lead, QA · 2026-10-15 · Research lab

15 scenarios, each a YAML fixture: starting state, timed events, and after each event the expected Now, process
states, timers, Live Activity and local notifications. Names are from `origin/master` (fcad46c). Anything the
code does not do yet is tagged `ASSUMED-n` and listed at the end for Product and Core.

## What the code does today (read before the fixtures)

- `StartCooking(recipe, serves, time)` creates a `Cook` and calls `StartProcess(ownerApp: "Kitchen",
  resumePoint: ResumePoint(index: 0), nextStep: step 1 text)`. `StartProcess` suspends whatever was running
  (`suspendRunning`), so a running workout becomes `suspended`. Cooking the same recipe again resumes the open cook.
- `GoToCookStep(cook, step, time)` writes `resumePoint.index` and `nextStep`.
- `StartKitchenTimer(label, minutes, cook?, time)` creates a `Kitchen Timer` object: `startedAt`, `endsAt`,
  `minutes`, `cook` link. 0 < minutes <= 1440. No step link, no pause, no extend.
- `StopKitchenTimer(timer)` sets `isStopped`. `FinishCooking(cook, note, time)` stamps `cookedAt`, ends the process
  `.done`, and stops only the timers linked to that cook.
- `CookLog.timers()` returns every unstopped timer, soonest first, including ones past `endsAt` (they stay at 0
  until stopped). Its `at` parameter is ignored.
- `NowPicker.pick`: if the running process's subject has a timer with `endsAt > now`, Now's line is
  `"<label>, <ceil(remaining min)> min"` and its draining bar runs `startedAt...endsAt`; otherwise the line is the
  process's `nextStep`. Timers of a suspended cook, and timers with no cook, never reach Now.
- `AppModel.tidyProcesses()` runs on every `scenePhase == .active`: `suspendIfIdle(idleLimit: (session?.restSeconds
  ?? 180) + 600)`, then `tidy` (6 h wrap-up for workouts only; 7 days put away for anything). `wakeWaiting` (M2)
  does not touch cooks. A cook idle 13 min in the background is suspended on return. See S07.
- The rest Live Activity (`RestActivityAttributes`, `RestActivityController`, `Widgets/RestLiveActivity.swift`) is
  workout-shaped (exercise, set, weight, reps) and `RestActivityController.end()` ends every
  `Activity<RestActivityAttributes>`. Its "rest over" face uses `staleDate = restEndsAt`, so the Lock Screen flips
  with the app suspended. Buttons are `LiveActivityIntent`s relayed to the app (`RestIntentRelay`).
- There is no `UNUserNotificationCenter` code anywhere yet. `Features/Cooking/` does not exist yet.

## iOS limits that shape the fixtures

| Limit | What it means here | Status |
|---|---|---|
| A Live Activity is active for up to 8 h, then the system ends it; it can stay on the Lock Screen up to 4 h more (12 h max) [1] | A slow cook or a 10 h timer outlives its activity. The local notification is the alert of record (S15) | Verified |
| Number of concurrent activities "may depend on a variety of factors"; starting can fail with `targetMaximumExceeded` / `globalMaximumExceeded` [1][2] | No documented number. One cook activity for all kitchen timers, never one per timer; handle start errors silently | Verified (no number published) |
| An activity is started in the foreground, or from a `LiveActivityIntent`; it can be updated or ended from the background [1] | Start the cook activity when the first timer starts in cook mode | Verified |
| `staleDate` flips `isStale` at a date with no app code running [1] | The "done" face at `endsAt` works while suspended or killed, as rest does | Verified |
| `Text(timerInterval:pauseTime:countsDown:)` and `ProgressView(timerInterval:)` render against the clock without updates [3] | Timers are date-based (`endsAt`), never ticking. A paused timer can be drawn with `pauseTime` | Verified |
| `update(_:alertConfiguration:)` alerts; on iPhone it shows the expanded island or a banner, not a separate alert [1] | Needs the app running at `endsAt`. Use the local notification as the only timer alert (ASSUMED-3) | Verified |
| Activity data (static + dynamic) max 4 KB [1] | Content holds the soonest timer plus a count, not a list | Verified |
| On next launch, check `Activity.activities` and end ones no longer relevant [1] | Reconcile on relaunch (S06) | Verified |
| A person can remove the activity from the Lock Screen; state becomes `dismissed`; it does not cancel the task [1] | Timers keep running; restart the activity at the next timer start | Verified |
| `UNTimeIntervalNotificationTrigger` "use this type of trigger to implement timers" [4]; pending requests stay until fired or removed with `removePendingNotificationRequests(withIdentifiers:)` [5] | One request per timer, id `kitchen-timer.<timerID>`, removed on stop | Verified |
| A calendar trigger built from `DateComponents` matches wall-clock components [6] | Do not use it for timers: a time zone change would move the fire moment (S10) | Verified for the API; zone behaviour unverified |
| Whether a time interval trigger follows elapsed time or the wall clock when the user sets the clock by hand | S10 expectation is written for elapsed time | Unverified |
| A background or suspended scene "must do as little work as possible" and can be disconnected at any time [7] | No in-app tick, no background wake at `endsAt`. Everything the user sees at `endsAt` comes from the notification and `staleDate` | Verified |
| `applicationSignificantTimeChange` fires on time changes [7] | Re-run the reconcile on a clock or zone change (S10) | Verified |
| 64 pending local notifications per app | Far above kitchen use; only matters if quiet-interrupts queues share the budget | Unverified for iOS 27 |
| Force quit from the app switcher ends the app's Live Activities | S06 writes both outcomes | Unverified |
| `.timeSensitive` needs the Time Sensitive capability; Personal Team signing unknown (see `quiet-interrupts.md`) | Timers post `.active` | Unverified |

## Fixture format

```yaml
id: S00                       # stable id, used by tests
title: one line
clock: {date: 2026-10-15, tz: Europe/London}   # fixture default; S10 changes tz
start:
  processes:                  # ProcessTable rows; subject title, ownerApp, state, nextStep, resumePoint.index
    - {subject: "Push Day A", app: Workouts, state: suspended, next: "Bench, set 3: 80 kg × 8", touched: "18:40"}
  timers: []                  # Kitchen Timer objects: label, cook, step (ASSUMED-2), startedAt, endsAt, stopped
  now: none                   # NowPicker.pick().now: none | {title, line} where line is Now's one line
  live_activity: none         # see content shape below
  notifications: {pending: []}
events:
  - at: "18:00:00"            # app clock, local time
    do: StartCooking(Carbonara, serves 2)   # an engine action, or: background, lock, kill, relaunch,
                                            # foreground, la_tap(body|stop|plus1), notif_tap, timer_fires,
                                            # clock_set, tz_change
    expect:
      now: {title: Carbonara, line: "Bring a large pot of salted water to the boil."}
      processes: [{subject: Carbonara, state: running, step: 0}]
      timers: []
      live_activity: none
      notifications: {pending: [], delivered: []}
      ui: optional, one line (cook mode screen, haptic, Tess line)
```

Live Activity content (ASSUMED-1), the cook face of the rest activity's language:

```yaml
live_activity:
  kind: cook                  # cook | rest (the existing workout one)
  title: Carbonara            # cook title; "Timers" when the soonest timer has no cook
  label: Pasta                # the soonest unstopped timer
  ends_at: "18:22:00"         # real clock, moved off AppClock like RestActivityController.contentState
  total: 600                  # seconds, for the horizon line
  phase: counting             # counting | done (stale at ends_at) | paused
  more: 1                     # other unstopped timers, drawn as "+1"
  stale_date: "18:22:00"
  relevance: 100              # 100 when its cook is Now, 50 otherwise
```

Notification (ASSUMED-3): `id: kitchen-timer.<timerID>`, `trigger: interval <endsAt - now>`, title `"<Label> is
done"`, body `"<Cook title>, step <n>"` (or `"Timer"` with no cook), `thread: tessera.kitchen`, interruption
`.active`, sound default. In fixtures: `{id: pasta, fires: "18:22:00"}`.

## Scenarios

### S01. A timer from a step's duration

```yaml
id: S01
title: Step 3 says "cook the pasta for 10 min"; hold the cadmium key to start it
start: {processes: [], timers: [], now: none, live_activity: none, notifications: {pending: []}}
events:
  - at: "18:00:00"
    do: StartCooking(Carbonara, serves 2)
    expect:
      now: {title: Carbonara, line: "Bring a large pot of salted water to the boil."}
      processes: [{subject: Carbonara, app: Kitchen, state: running, step: 0}]
      timers: []
      live_activity: none
  - at: "18:12:00"
    do: GoToCookStep(cook, step 2)     # third step; RecipeBook.Step.timers == [10...10]
    expect:
      now: {title: Carbonara, line: "Cook the pasta for 10 min, until al dente."}
      processes: [{subject: Carbonara, state: running, step: 2}]
      ui: hold-to-start key "10 min" in cadmium
  - at: "18:12:30"
    do: StartKitchenTimer(label "Pasta", minutes 10, cook, step 2)   # label and step: ASSUMED-2
    expect:
      now: {title: Carbonara, line: "Pasta, 10 min"}
      timers: [{label: Pasta, step: 2, endsAt: "18:22:30"}]
      live_activity: {kind: cook, title: Carbonara, label: Pasta, ends_at: "18:22:30", total: 600, phase: counting, more: 0}
      notifications: {pending: [{id: pasta, fires: "18:22:30"}]}
      ui: one horizon line across the top
  - at: "18:16:00"
    do: none
    expect:
      now: {title: Carbonara, line: "Pasta, 7 min"}   # 6.5 min rounded up
notes: A range like "1-2 hours" (60...120) offers the lower bound, 60 (ASSUMED-2).
```

### S02. Two timers at once

```yaml
id: S02
title: Pasta 10 and guanciale 4 running together; the soonest leads everywhere
start:
  processes: [{subject: Carbonara, app: Kitchen, state: running, step: 2}]
  timers: [{label: Pasta, step: 2, startedAt: "18:12:30", endsAt: "18:22:30"}]
  now: {title: Carbonara, line: "Pasta, 10 min"}
  live_activity: {kind: cook, label: Pasta, ends_at: "18:22:30", more: 0}
  notifications: {pending: [{id: pasta, fires: "18:22:30"}]}
events:
  - at: "18:14:00"
    do: StartKitchenTimer(label "Guanciale", minutes 4, cook, step 3)
    expect:
      now: {title: Carbonara, line: "Guanciale, 4 min"}       # soonest endsAt wins (18:18 < 18:22:30)
      timers: [{label: Guanciale, endsAt: "18:18:00"}, {label: Pasta, endsAt: "18:22:30"}]
      live_activity: {kind: cook, label: Guanciale, ends_at: "18:18:00", total: 240, phase: counting, more: 1}
      notifications: {pending: [{id: guanciale, fires: "18:18:00"}, {id: pasta, fires: "18:22:30"}]}
      ui: two stacked horizon lines, Guanciale on top
  - at: "18:18:00"
    do: timer_fires(Guanciale)            # app in foreground, cook mode on screen
    expect:
      now: {title: Carbonara, line: "Pasta, 5 min"}            # ended timer has endsAt <= now, so Pasta leads
      timers: [{label: Guanciale, endsAt: "18:18:00", remaining: 0}, {label: Pasta, endsAt: "18:22:30"}]
      live_activity: {kind: cook, label: Pasta, ends_at: "18:22:30", more: 0}   # app is alive, so it re-points
      notifications: {pending: [{id: pasta}], delivered: [{id: guanciale, presented: none}]}  # willPresent -> [] in cook mode
      ui: Guanciale line flares cadmium, haptic
  - at: "18:18:20"
    do: StopKitchenTimer(Guanciale)       # tap the flared line
    expect:
      timers: [{label: Pasta, endsAt: "18:22:30"}]
```

### S03. A timer ends mid-step

```yaml
id: S03
title: Pasta ends while he is reading step 5; step 3 slides back
start:
  processes: [{subject: Carbonara, state: running, step: 4, next: "Whisk the eggs with the pecorino."}]
  timers: [{label: Pasta, step: 2, endsAt: "18:22:30"}]
  now: {title: Carbonara, line: "Pasta, 1 min"}
  live_activity: {kind: cook, label: Pasta, ends_at: "18:22:30"}
  notifications: {pending: [{id: pasta}]}
events:
  - at: "18:22:30"
    do: timer_fires(Pasta)
    expect:
      now: {title: Carbonara, line: "Whisk the eggs with the pecorino."}   # falls back to nextStep
      processes: [{subject: Carbonara, state: running, step: 4}]           # resume point does not move by itself
      timers: [{label: Pasta, remaining: 0, stopped: false}]
      live_activity: {kind: cook, label: Pasta, phase: done}               # stale at ends_at; ended at Stop
      notifications: {delivered: [{id: pasta, presented: none}]}
      ui: Pasta line flares, step 3 slides into view above step 5 as an overlay; haptic
  - at: "18:22:40"
    do: StopKitchenTimer(Pasta)
    expect:
      timers: []
      live_activity: none                   # end(dismissalPolicy: .immediate), no timers left
      ui: step 3 overlay slides away, step 5 stays at eye level
notes: The step slide is a view state, not GoToCookStep (ASSUMED-4), so the resume point stays at step 5.
```

### S04. The Lock Screen: timer ends with the phone locked

```yaml
id: S04
title: Phone locked on the counter while the sauce reduces
start:
  processes: [{subject: Ragù, state: running, step: 3}]
  timers: [{label: Reduce, step: 3, startedAt: "17:30:00", endsAt: "17:50:00"}]
  now: {title: Ragù, line: "Reduce, 20 min"}
  live_activity: {kind: cook, title: Ragù, label: Reduce, ends_at: "17:50:00", total: 1200, phase: counting}
  notifications: {pending: [{id: reduce, fires: "17:50:00"}]}
events:
  - at: "17:31:00"
    do: lock
    expect:
      processes: [{subject: Ragù, state: running}]     # no code runs; nothing changes in the engine
      live_activity: {kind: cook, label: Reduce, phase: counting}   # countdown and horizon drawn by the system
  - at: "17:50:00"
    do: timer_fires(Reduce)        # app suspended
    expect:
      live_activity: {kind: cook, label: Reduce, phase: done}       # isStale at staleDate, no update needed
      notifications: {delivered: [{id: reduce, title: "Reduce is done", body: "Ragù, step 4", sound: default}]}
      ui: Lock Screen shows the notification and the cook face on "Done"
  - at: "17:52:00"
    do: la_tap(body)               # widgetURL tessera://cook (ASSUMED-5)
    expect:
      now: {title: Ragù, line: "<step 4 text>"}
      processes: [{subject: Ragù, state: running, step: 3}]
      ui: cook mode opens at step 4 with the Reduce line flared (needs ASSUMED-7; today idle 22 min suspends it)
```

### S05. Lock Screen buttons

```yaml
id: S05
title: Stop and +1 on the Lock Screen, without opening the app
start:
  processes: [{subject: Carbonara, state: running, step: 2}]
  timers: [{label: Pasta, endsAt: "18:22:30"}, {label: Guanciale, endsAt: "18:24:00"}]
  live_activity: {kind: cook, label: Pasta, ends_at: "18:22:30", more: 1}
  notifications: {pending: [{id: pasta}, {id: guanciale}]}
events:
  - at: "18:21:00"
    do: la_tap(plus1)              # ExtendKitchenTimerIntent: LiveActivityIntent, runs in the app process (ASSUMED-6)
    expect:
      timers: [{label: Pasta, endsAt: "18:23:30"}, {label: Guanciale, endsAt: "18:24:00"}]
      live_activity: {kind: cook, label: Pasta, ends_at: "18:23:30", more: 1}
      notifications: {pending: [{id: pasta, fires: "18:23:30"}, {id: guanciale}]}   # same id, replaced
  - at: "18:23:30"
    do: timer_fires(Pasta)
    expect:
      live_activity: {kind: cook, label: Pasta, phase: done, more: 1}
      notifications: {delivered: [{id: pasta}]}
  - at: "18:23:40"
    do: la_tap(stop)               # StopKitchenTimerIntent on the done face
    expect:
      timers: [{label: Guanciale, endsAt: "18:24:00"}]
      live_activity: {kind: cook, label: Guanciale, ends_at: "18:24:00", phase: counting, more: 0}
      notifications: {pending: [{id: guanciale}], delivered: []}   # removeDeliveredNotifications for pasta
      processes: [{subject: Carbonara, state: running}]            # a Lock Screen action touches lastTouchedAt
```

### S06. App killed with a timer running

```yaml
id: S06
title: Killed from the switcher at 18:15 with Pasta due 18:22:30; relaunched 18:30
start:
  processes: [{subject: Carbonara, state: running, step: 2, touched: "18:14:00"}]
  timers: [{label: Pasta, step: 2, endsAt: "18:22:30"}]
  live_activity: {kind: cook, label: Pasta, ends_at: "18:22:30"}
  notifications: {pending: [{id: pasta, fires: "18:22:30"}]}
events:
  - at: "18:15:00"
    do: kill
    expect:
      processes: [{subject: Carbonara, state: running}]     # written through to SQLite already
      live_activity: "stays (or ends if force quit ends activities: unverified)"
      notifications: {pending: [{id: pasta}]}               # owned by the system, survives the kill
  - at: "18:22:30"
    do: timer_fires(Pasta)
    expect:
      notifications: {delivered: [{id: pasta, title: "Pasta is done"}]}
      live_activity: {phase: done}   # if it survived
  - at: "18:30:00"
    do: relaunch
    expect:
      # tidyProcesses: idle 16 min > 13 min limit, so suspendIfIdle suspends it at lastTouchedAt (code today).
      # ASSUMED-7 changes the cook limit; with it the cook stays running.
      processes: [{subject: Carbonara, state: running, step: 2}]
      now: {title: Carbonara, line: "Cook the pasta for 10 min, until al dente."}
      timers: [{label: Pasta, remaining: 0, stopped: false}]
      live_activity: "reconciled: one cook activity for the soonest unstopped timer (Pasta, done); extra ones ended"
      notifications: {pending: []}   # reconcile: every unstopped future timer has exactly one pending request
      ui: cook mode reopens at step 3 with Pasta flared (ASSUMED-8)
```

### S07. Long background, the idle-suspend rule

```yaml
id: S07
title: 45 min braise; he goes to another app and comes back at 18:50
start:
  processes: [{subject: Beef stew, state: running, step: 4, touched: "18:05:00"}]
  timers: [{label: Braise, step: 4, startedAt: "18:05:00", endsAt: "18:50:00"}]
  live_activity: {kind: cook, label: Braise, ends_at: "18:50:00"}
  notifications: {pending: [{id: braise}]}
events:
  - at: "18:06:00"
    do: background
    expect: {processes: [{subject: Beef stew, state: running}]}
  - at: "18:50:00"
    do: timer_fires(Braise)
    expect:
      notifications: {delivered: [{id: braise}]}
      live_activity: {phase: done}
  - at: "18:51:00"
    do: notif_tap(braise)
    expect:
      # Code today: idle 46 min > 180 s + 600 s, so the cook is suspended, Now falls to tasks, ledger shows Beef stew.
      # ASSUMED-7: a cook is never idle-suspended while it has an unstopped timer, or within 30 min of its last timer end.
      processes: [{subject: Beef stew, state: running, step: 4}]
      now: {title: Beef stew, line: "<step 5 text>"}
      ui: cook mode at step 5 with Braise flared
```

### S08. Pause a timer

```yaml
id: S08
title: Pause the rice while the doorbell goes, resume 3 min later
start:
  processes: [{subject: Biryani, state: running, step: 5}]
  timers: [{label: Rice, startedAt: "19:00:00", endsAt: "19:15:00"}]
  live_activity: {kind: cook, label: Rice, ends_at: "19:15:00"}
  notifications: {pending: [{id: rice, fires: "19:15:00"}]}
events:
  - at: "19:05:00"
    do: PauseKitchenTimer(Rice)        # ASSUMED-6: sets pausedAt, keeps endsAt
    expect:
      now: {title: Biryani, line: "Rice, paused at 10 min"}     # ASSUMED-6 copy
      timers: [{label: Rice, endsAt: "19:15:00", pausedAt: "19:05:00"}]
      live_activity: {kind: cook, label: Rice, phase: paused, pause_time: "19:05:00", stale_date: none}
      notifications: {pending: []}
      ui: horizon line holds still, dimmed
  - at: "19:08:00"
    do: ResumeKitchenTimer(Rice)       # endsAt += paused length
    expect:
      now: {title: Biryani, line: "Rice, 10 min"}
      timers: [{label: Rice, endsAt: "19:18:00", pausedAt: null}]
      live_activity: {kind: cook, label: Rice, ends_at: "19:18:00", phase: counting}
      notifications: {pending: [{id: rice, fires: "19:18:00"}]}
notes: While paused, the soonest-timer rule skips a paused timer (ASSUMED-6). CookLog.timers() and NowPicker need it.
```

### S09. Extend a timer, before and after it ends

```yaml
id: S09
title: +1 min while counting, then +2 min after it has ended
start:
  processes: [{subject: Focaccia, state: running, step: 6}]
  timers: [{label: Bake, startedAt: "16:00:00", endsAt: "16:20:00"}]
  notifications: {pending: [{id: bake, fires: "16:20:00"}]}
events:
  - at: "16:18:00"
    do: ExtendKitchenTimer(Bake, minutes 1)      # ASSUMED-6: endsAt += 1 min, minutes += 1
    expect:
      now: {title: Focaccia, line: "Bake, 3 min"}
      timers: [{label: Bake, endsAt: "16:21:00"}]
      live_activity: {kind: cook, label: Bake, ends_at: "16:21:00", total: 1260}
      notifications: {pending: [{id: bake, fires: "16:21:00"}]}
  - at: "16:21:00"
    do: timer_fires(Bake)
    expect: {notifications: {delivered: [{id: bake}]}, live_activity: {phase: done}}
  - at: "16:22:00"
    do: ExtendKitchenTimer(Bake, minutes 2)      # on an ended timer: restarts from now
    expect:
      now: {title: Focaccia, line: "Bake, 2 min"}
      timers: [{label: Bake, endsAt: "16:24:00"}]
      live_activity: {kind: cook, label: Bake, ends_at: "16:24:00", phase: counting}
      notifications: {pending: [{id: bake, fires: "16:24:00"}]}
```

### S10. Clock and time zone change

```yaml
id: S10
title: Zone change mid-timer (travel), then the clock set by hand
start:
  clock: {tz: Europe/London}
  processes: [{subject: Dal, state: running, step: 2}]
  timers: [{label: Simmer, startedAt: "2026-10-15T17:00:00Z", endsAt: "2026-10-15T17:30:00Z"}]
  notifications: {pending: [{id: simmer, trigger: "interval 1800 s"}]}
events:
  - at: "2026-10-15T17:10:00Z"
    do: tz_change(Asia/Kolkata)
    expect:
      timers: [{label: Simmer, endsAt: "2026-10-15T17:30:00Z"}]   # Date is absolute; nothing moves
      now: {title: Dal, line: "Simmer, 20 min"}
      live_activity: {label: Simmer, remaining_shown: "20:00"}
      notifications: {pending: [{id: simmer}]}                    # still fires 17:30Z (23:00 IST)
      ui: clock-time copy ("ready at 23:00") re-renders in the new zone
  - at: "2026-10-15T17:15:00Z"
    do: clock_set(+60 min)         # user sets the clock forward by hand
    expect:
      now: {title: Dal, line: "<step 3 text>"}  # Date.now is past endsAt; timer reads ended
      timers: [{label: Simmer, remaining: 0}]
      live_activity: {phase: done}              # staleDate passes on the device clock
      notifications: "unverified: an interval trigger may still fire 15 min later (elapsed) rather than now"
      ui: applicationSignificantTimeChange runs the reconcile (ASSUMED-8)
notes: >
  Never schedule timer notifications with UNCalendarNotificationTrigger. With -demoTime, endsAt is app time; the
  notification interval and the activity's ends_at must use endsAt - AppClock.now, as RestActivityController does.
```

### S11. Cooking while a workout is suspended

```yaml
id: S11
title: Leaves Push Day mid-way to start dinner
start:
  processes: [{subject: Push Day A, app: Workouts, state: running, next: "Bench, set 3: 80 kg × 8", touched: "18:40"}]
  timers: []
  now: {title: Push Day A, line: "Bench, set 3: 80 kg × 8"}
  live_activity: {kind: rest, exercise: Bench, setNumber: 3, phase: ready}
events:
  - at: "18:45:00"
    do: StartCooking(Carbonara)
    expect:
      now: {title: Carbonara, line: "Bring a large pot of salted water to the boil."}
      processes:
        - {subject: Carbonara, app: Kitchen, state: running, step: 0}
        - {subject: Push Day A, app: Workouts, state: suspended, next: "Bench, set 3: 80 kg × 8"}
      ledger: ["Push Day A"]                   # ProcessTable.ledger, one row
      live_activity: none                      # rest activity ended: its process is no longer Now (ASSUMED-1)
  - at: "18:57:00"
    do: StartKitchenTimer(Pasta, 10, cook)
    expect:
      live_activity: {kind: cook, label: Pasta, ends_at: "19:07:00"}
      notifications: {pending: [{id: pasta}]}
  - at: "19:25:00"
    do: FinishCooking(cook)
    expect:
      now: {title: <next timed task or top of today>}   # NowPicker never promotes a suspended process
      processes: [{subject: Carbonara, state: done}, {subject: Push Day A, state: suspended}]
      ledger: ["Push Day A"]
      live_activity: none
      ui: Tess line "Carbonara, third time this month."
  - at: "00:41:00 (+1 day)"
    do: foreground
    expect:
      processes: [{subject: Push Day A, state: done, endReason: wrappedUp}]   # 6 h after its last touch
      ui: Tess "Saved Push Day A, 2 of 5 exercises"
```

### S12. Starting a workout while cooking

```yaml
id: S12
title: The stew braises for 90 min, so he starts Pull Day
start:
  processes: [{subject: Beef stew, state: running, step: 4}]
  timers: [{label: Braise, cook: Beef stew, endsAt: "19:30:00"}]
  live_activity: {kind: cook, label: Braise, ends_at: "19:30:00", relevance: 100}
  notifications: {pending: [{id: braise}]}
events:
  - at: "18:05:00"
    do: StartWorkout(Pull Day)
    expect:
      now: {title: Pull Day, line: "<first set>"}
      processes:
        - {subject: Pull Day, app: Workouts, state: running}
        - {subject: Beef stew, app: Kitchen, state: suspended, next: "<step 5 text>"}
      timers: [{label: Braise, endsAt: "19:30:00"}]              # timers never pause with their process
      ledger: ["Beef stew"]                                       # row line "Braise, 85 min" (ASSUMED-9)
      live_activity: [{kind: cook, label: Braise, relevance: 50}] # rest activity joins at the first rest
  - at: "18:08:00"
    do: log first set (rest 150 s starts)
    expect:
      live_activity:
        - {kind: rest, exercise: Row, phase: resting, relevance: 100}   # Dynamic Island shows rest
        - {kind: cook, label: Braise, relevance: 50}                    # second card on the Lock Screen
  - at: "19:30:00"
    do: timer_fires(Braise)        # mid-set, workout on screen
    expect:
      notifications: {delivered: [{id: braise, presented: banner}]}  # not in cook mode, so willPresent shows it
      now: {title: Pull Day}
      ui: banner "Braise is done · Beef stew, step 5"; tap resumes the stew and suspends Pull Day
notes: At most two Tessera activities ever (one rest, one cook). If the second start fails, skip it silently.
```

### S13. Cooking two recipes

```yaml
id: S13
title: Rice for one recipe, curry for another; switching between them
start:
  processes: [{subject: Jeera rice, state: running, step: 1}]
  timers: [{label: Rice, cook: Jeera rice, endsAt: "19:20:00"}]
  live_activity: {kind: cook, title: Jeera rice, label: Rice, ends_at: "19:20:00"}
events:
  - at: "19:05:00"
    do: StartCooking(Chana masala)
    expect:
      now: {title: Chana masala, line: "<step 1 text>"}          # Rice is not Now: it belongs to the suspended cook
      processes:
        - {subject: Chana masala, state: running, step: 0}
        - {subject: Jeera rice, state: suspended, step: 1}
      ledger: ["Jeera rice"]
      live_activity: {kind: cook, title: Jeera rice, label: Rice, ends_at: "19:20:00", relevance: 50}  # soonest of all cooks
  - at: "19:08:00"
    do: StartKitchenTimer(Onions, 8, cook Chana masala)
    expect:
      now: {title: Chana masala, line: "Onions, 8 min"}
      live_activity: {kind: cook, title: Chana masala, label: Onions, ends_at: "19:16:00", more: 1, relevance: 100}
      notifications: {pending: [{id: onions, fires: "19:16:00"}, {id: rice, fires: "19:20:00"}]}
      ui: in cook mode, the rice line shows dimmer with its recipe name (ASSUMED-9)
  - at: "19:20:00"
    do: timer_fires(Rice)          # foreground, cooking the masala
    expect:
      notifications: {delivered: [{id: rice, presented: banner}]}   # not this cook's timer, so it is shown
      ui: tap the rice line or banner: ResumeProcess(Jeera rice), masala suspended
  - at: "19:21:00"
    do: StartCooking(Jeera rice)   # same recipe again: resumes the open cook, no second Cook object
    expect:
      processes: [{subject: Jeera rice, state: running, step: 1}, {subject: Chana masala, state: suspended}]
```

### S14. Finishing with a timer still running

```yaml
id: S14
title: Hold Finish while the oven timer still has 4 min, plus a ghost-row timer with no cook
start:
  processes: [{subject: Lasagne, state: running, step: 7}]
  timers:
    - {label: Oven, cook: Lasagne, endsAt: "20:04:00"}
    - {label: Tea, cook: null, endsAt: "20:10:00"}    # "timer tea 15" typed before cooking started
  live_activity: {kind: cook, title: Lasagne, label: Oven, ends_at: "20:04:00", more: 1}
  notifications: {pending: [{id: oven}, {id: tea}]}
events:
  - at: "20:00:00"
    do: FinishCooking(cook)
    expect:
      now: {title: <next task>}
      processes: [{subject: Lasagne, state: done, endReason: done}]
      timers: [{label: Tea, endsAt: "20:10:00"}]          # FinishCooking stops linked timers only
      live_activity: {kind: cook, title: Timers, label: Tea, ends_at: "20:10:00", more: 0, relevance: 50}
      notifications: {pending: [{id: tea}]}               # oven request removed
      ui: Tess "Lasagne, first time this month."; no warning about the stopped oven timer (ASSUMED-10)
  - at: "20:10:00"
    do: timer_fires(Tea)
    expect:
      notifications: {delivered: [{id: tea, title: "Tea is done", body: "Timer"}]}
      live_activity: {phase: done}
  - at: "20:11:00"
    do: StopKitchenTimer(Tea)       # from the Lock Screen or the top seam
    expect: {timers: [], live_activity: none}
```

### S15. Past the 8 hour Live Activity limit

```yaml
id: S15
title: Overnight dough, a 10 h timer, cook left open
start: {processes: [], timers: []}
events:
  - at: "21:00:00"
    do: [StartCooking(Sourdough), GoToCookStep(cook, 3), StartKitchenTimer(Proof, 600, cook, step 3)]
    expect:
      now: {title: Sourdough, line: "Proof, 600 min"}       # ASSUMED-11: hours copy "Proof, 10 h"
      timers: [{label: Proof, endsAt: "07:00:00 (+1 day)"}]
      live_activity: {kind: cook, label: Proof, ends_at: "07:00:00", total: 36000}
      notifications: {pending: [{id: proof, fires: "07:00:00"}]}
  - at: "21:05:00"
    do: background
  - at: "05:00:00 (+1 day)"
    do: none                       # system ends the activity at 8 h
    expect:
      live_activity: "ended by the system; gone from the island, may stay on the Lock Screen up to 4 h"
      notifications: {pending: [{id: proof}]}
  - at: "07:00:00 (+1 day)"
    do: timer_fires(Proof)
    expect: {notifications: {delivered: [{id: proof, title: "Proof is done", body: "Sourdough, step 4"}]}}
  - at: "07:05:00 (+1 day)"
    do: notif_tap(proof)
    expect:
      processes: [{subject: Sourdough, state: running, step: 3}]   # ASSUMED-7; code today suspends it
      live_activity: none          # not restarted for an ended timer
      ui: cook mode at step 4 with Proof flared
```

## ASSUMED (for Product and Core)

1. **Cook face of the rest activity.** Either a `kind` on `RestActivityAttributes.ContentState` or a sibling
   `CookTimerAttributes` drawn by the same widget language (horizon line, countdown, Done face). One cook activity
   for all kitchen timers (soonest leads, "+N"), separate from the workout's rest activity; at most two Tessera
   activities. `RestActivityController.end()` must stop ending every activity of its type if they share attributes.
   The rest activity ends when its workout is suspended. Core + Product.
2. **Timers know their step.** `Kitchen Timer` gains `step` (index). A step key's minutes are the lower bound of
   `RecipeBook.Step.timers`; the label is the step's first verb ("Simmer"), else "Step n". Core.
3. **Local notifications are the only timer alert.** One `UNTimeIntervalNotificationTrigger` per timer, id
   `kitchen-timer.<id>`, `.active`, thread `tessera.kitchen`, scheduled on start, replaced on extend or resume,
   removed on stop, pause, finish. Activity updates are silent (no `alertConfiguration`) so nothing alerts twice.
   In cook mode `willPresent` returns `[]` for the running cook's timers (the in-app flare replaces it); elsewhere
   banner and sound. Timers are never held by the quiet-interrupts mask. Core (iOS build for the delegate).
4. **A timer ending does not move the resume point.** The step slides back as an overlay; `GoToCookStep` only on
   swipe. Product.
5. **Deep link `tessera://cook`** opens cook mode on the cook in the activity (today only `tessera://workout`
   exists, handled only when a session is live). iOS build.
6. **New actions:** `PauseKitchenTimer` / `ResumeKitchenTimer` (`pausedAt`; resume adds the paused length to
   `endsAt`), `ExtendKitchenTimer(minutes)` (on an ended timer it restarts from now). `CookLog.timers()` and
   `NowPicker` skip paused timers for "soonest"; Now copy "Rice, paused at 10 min". Lock Screen buttons Stop and +1
   as `LiveActivityIntent`s through a relay like `RestIntentRelay`. Core.
7. **Idle-suspend rule for cooks.** Today `tidyProcesses` uses the workout rest (180 s default) + 10 min for any
   running process, so a cook is suspended after 13 min in the background. Proposed: a cook is not idle-suspended
   while it has an unstopped timer or within 30 min of its last timer end; otherwise 30 min. Product decides the
   number; Core moves the limit into `ProcessTable` per owner app.
8. **Reconcile on launch, foreground and significant time change:** pending notifications equal the unstopped,
   unpaused, future timers; one cook activity for the soonest; stray activities ended. Ended-but-unstopped timers
   stay flared until stopped. Core + iOS build.
9. **A suspended cook's ledger row** shows its soonest timer ("Braise, 85 min") instead of the next step while one
   runs; in cook mode, other cooks' timers show as dimmer lines with the recipe name. Product + Design.
10. **Finish stops this cook's timers silently,** without a confirm; timers with no cook survive. Product.
11. **Copy over 90 min** reads in hours ("Proof, 10 h"); `NowPicker` today prints minutes only. Product.
12. **Fixture default zone** `Europe/London`; only S10 depends on it.

## Sources (developer.apple.com, checked 2026-10-15)

1. documentation/activitykit/displaying-live-data-with-live-activities (8 h + 4 h, 4 KB, start in foreground or
   `LiveActivityIntent`, staleDate, relevanceScore, concurrent limit unspecified, reconcile on launch, dismissed)
2. documentation/activitykit/activityauthorizationerror/targetmaximumexceeded
3. documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:)
4. documentation/usernotifications/untimeintervalnotificationtrigger
5. documentation/usernotifications/scheduling-a-notification-locally-from-your-app
6. documentation/usernotifications/uncalendarnotificationtrigger
7. documentation/uikit/managing-your-app-s-life-cycle (background work, scene disconnection, significant time change)
