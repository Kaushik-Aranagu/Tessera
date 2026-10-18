# Live Activity, Lock Screen and widget motion (board 66)

Lab spec with Normal / Reduce Motion (RM) / Low Power (LP) columns for the rest timer, the cook timer and the workout on the
Lock Screen, the Dynamic Island, the notification and the widgets. Code read at `f0ebbf0b`. Sheets: `live-activity.md` (LA),
`lockscreen.md` (LS), `widget-states.md` (WS), `tess-cook-clock-lowpower-and-timer-end.md` (CK). The first Low Power and Reduce
Motion columns for these surfaces; none existed (LA:74 only says explicit animations are ignored).

## 1. The ground rule: the system owns the motion

An activity or widget cannot run our animation. Explicit animations are ignored (LA:74); what moves is a system timer
(`Text(timerInterval:)`, `ProgressView(timerInterval:)`), a content transition the system applies on a state change
(`.numericText`, `.push(from:)`) and the system's own face swap. So for these surfaces:

- **Reduce Motion** is the system's: it simplifies its own transitions. We author nothing, test nothing in the extension, and
  never fake it. What we control is what changes state (fewer, calmer state changes) and what we do not draw.
- **Low Power** is the system's throttling of updates. The extension can read `ProcessInfo.isLowPowerModeEnabled` but the app's
  cached `isReduced` flag is not reachable. We lean on absolute `endsAt` and system-drawn timers, which cost nothing in LP (CK:18).
- Nothing in these surfaces may depend on our own ticks. Every clock derives from `endsAt`; the face flips by `staleDate`.

Code today: none of the Widgets code reads RM, LP, reduce transparency or Dynamic Type (not found in `Widgets/`, `Shared/`,
`Features/Workout/LiveActivity/`). That is correct for RM and LP by the rule above, except where listed in section 6.

## 2. Rest timer Live Activity (`Widgets/RestLiveActivity.swift`)

| Moment | Normal | Reduce Motion | Low Power | Code |
|---|---|---|---|---|
| Resting face | cream countdown (system `Text(timerInterval:)`), horizon drains by `ProgressView(timerInterval:)` through the curve mask; washes static | same; the system replaces `.numericText` rolls with a crossfade | same; system timers draw seconds with no app work | `:247`, `:376-388`; match |
| Go (rest over) | flips by `staleDate` (or the app's flip if alive): "Go" pushes up from the bottom; washes switch to cadmium/vermilion | system softens the push; washes switch with no fade we author | same as RM | `:237`, `:258`, `:173/:179`; partial: 700 ms, blur and the 1.4 s wash fade are not authored and cannot be (LA:74) |
| Go glow behind the tick | static ellipse | static | static | `:287-293`; the sheet's 2.2 s breathing (LA:43) is dropped: it cannot run in an activity. Remove it from the sheet. |
| Always-On (`isLuminanceReduced`) | still "Ready 6:26 pm", no ticking | same | same | `:238-245`. Gap: horizon and washes still draw (LS:19 says none). Build: under `isLuminanceReduced` drop the washes and the horizon, keep the word and the time. |
| Dynamic Island compact | tick + 17 pt time; "Go" swaps in place | system | system | `:70-86`; compact "Go" has no transition (`:77-79`): add `.id` + the same push so it matches the Lock Screen |
| Island expanded / minimal | countdown 40, Done, horizon / tick | system | system | `:54-69`, `:87-89`; match |
| +15 / Skip / Done buttons | intent runs in the app process, state updates, countdown re-bases | same | same | `RestIntents`, `LiveWorkout.swift:12-33`; no animation of ours |
| End | `activity.end(nil, .immediate)`: the card is gone at once | same | same | `RestActivityController.swift:175-177` (`endAll`); see section 5 for the 60 s "all sets in" face (unbuilt) |

Haptic and sound for the rest end:

- **In the app** (workout in front): `.timeUp` once (`WorkoutModeView.swift:140`), plays in RM and LP. See the training pass: only if seen live within 2 s of T0.
- **Locked or backgrounded**: today a silent flip. The Live Activity sends an `AlertConfiguration` with the default sound only when the app is alive
  (`RestActivityController.swift:149-153` (`restEndAlert`, sent at `:53`)), so a locked phone is silent. LS:12 and :24 say the activity's updates are silent and
  the notification N2 is what rings. Resolve it so: **N2 rings, the activity never carries an alert** (remove the `AlertConfiguration`);
  if notifications are off, N2 is skipped and the activity is the only signal, by its flip alone. This also removes the foreground double
  (haptic + alert sound).
- **Privacy of N2** (QA, #957): same shape as the kitchen timer: fixed title, masked body. Title "Rest is up", body "Set 3 is next." or "Next set is ready." when the exercise name is private or empty. Today the alert is titled "Set N is up" with the body `"<exercise>, <planned set>"` (`RestActivityController.swift:152`), which carries the exercise name onto the Lock Screen unmasked (`RestActivityController.swift:149-153` (`restEndAlert`, sent at `:53`)); check the body against the masking rule before N2 is built.

## 3. Cook timer (Live Activity and notification) - unbuilt

Nothing exists in code: no activity, no `tessera://cook` link, no local notification (`Cooking.swift:251` has the actions only).
Spec per CK:46 and LS:28-31, made explicit:

| Moment | Normal | Reduce Motion | Low Power | Haptic / sound |
|---|---|---|---|---|
| Started (lead timer) | label (masked as "Timer" when private/empty/number-only), system countdown, "Step 2 of 3", +1 and Stop | same | same | none |
| Another timer starts | the lead stays the soonest end; the others sit as a count ("+1 more") | same | same | none |
| T0, app in front | the cook page does the flare/ring (CK:48-56); the activity flips on its own | page: 150 ms crossfade; activity: system | page: as RM | **`.timeUp`** once |
| T0, locked | the activity flips to "<label> is done." by `staleDate`, system default transition, nothing of ours; **the timer line rings** (fixed title "Timer", body "<label> is done." / "Timer is done.") | same | same | the timer line's sound and vibration; no in-app haptic |
| Stop | clears the activity and cancels the timer line | same | same | none |
| Quiet hours | his own started timers ring at any hour (LS:52, CK:46) | same | same | follows the notification's setting |

Rules: the activity is silent (no `AlertConfiguration`, test `liveActivityUpdateCarriesNoAlert`, CK:77); one tap target opens the cook
page at that step; two timers ending within 600 ms play one haptic and one timer line (stacked count in the body "2 timers are done.": new copy, Design to rule before it ships).

## 4. Workout activity - none beyond the rest activity

The rest activity is the workout's only surface; it starts at the first rest, ends with the workout or when no set is planned
(`plannedSet(of:)` returns nil for `.workoutDone`, `RestActivityController.swift:87-89`, then `endAll()`, `:164`). Two sheeted faces are unbuilt: **Undo after Done** ("Set N taken back", LA:67, LS:20-21, no
`UndoLastSet` intent yet) and the **60 s "Push A, all sets in."** face (WS:80-84, LS:22, :74). Both are state changes only:

| Face | Normal | RM | LP | Notes |
|---|---|---|---|---|
| Undo after Done | one state change, Undo as a button for 10 s, then back to resting | system | system | one UNDO slot (matches the app's 10 s change window); plays `.undo` only if the app is in front |
| All sets in | the activity does not end at once: a still face for 60 s ("Push A, all sets in."), then default dismissal | system | system | no timer, no countdown on it, so it costs nothing in LP |

The set-aside face (ready for 10 min, then "<title> set aside", `RLA:206-222`, `RestActivityController.swift:124` (`readyLife`) and `:130` (the `staleDate`)) is code-only; add it to LA so the sheet and the build agree. It may stay on the Lock Screen until the system ends it (a push to end it needs a paid account); it shows "<title> set aside" and ticks nothing (G338, DEC:1051 item 2).

**Lock Screen keys (G346, DEC:1051 item 5).** Done, +15 and Skip stay tap keys (none is a hold key, so none is named-action-only). Done has the 10 s UNDO above; Skip set has no UNDO face; +15 has none (it re-bases, and +15 again is the inverse). Each speaks one line to VoiceOver: "Set 3 done, undo available", "Fifteen seconds added", "Set skipped" *(wording for Design)*.

## 5. Widgets (home and lock screen) - unbuilt

Per WS:13-26 and :105; the motion rules are the same system-owned set.

| Part | Normal | RM | LP |
|---|---|---|---|
| Ground and seam | from the App Group; the seam is a `ProgressView(timerInterval:)` | same | same; no extra timeline entries beyond one at `restEndsAt` |
| Word change (Resting → Go) | second timeline entry at `restEndsAt`; `.push(from: .bottom)` on the word | system softens | system throttles; the entry still lands at the end time |
| Numbers | `.numericText` | system crossfade | system |
| Circular lock widget | `Text(timerInterval:)`, no gauge (WS:146) | same | same |
| Tinted / Always-On | keeps type, drops the ground (WS:26) | same | same |

**Reloads (G340, DEC:1051 item 3).** `reloadTimelines` is called only after an app write or a widget button; the pre-scheduled entry at `restEndsAt` is a countdown he started, not a reload. Test: grep shows no other `reloadAllTimelines` / `reloadTimelines` caller (background task, push, timer).

**Quiet hours (G341, DEC:1051 item 3).** No entry changes its words from 23:00 to 07:00 except a countdown he started (the rest and cook countdowns still flip at their end). Test: a widget timeline built at 22:50 has no entry between 23:00 and 07:00 other than `restEndsAt` or a started timer's end. The data day turns at 04:00, but new-day widget words appear at 07:00 (ruled, DEC:1053); the 04:00 turn changes only what "today" means for the next write.

**Masked words (G348, DEC:1049).** Every free-text field in an extension (widget row, rest-activity exercise name, cook label) is the masked form from the one private-text function, not `.privacySensitive` alone; a private row reads "Private item / recipe / list / workout / habit / spend / book", with no tap-to-reveal. Test: with a private workout running, no extension payload contains its title.

Nothing in a widget may poll or tick. No App Group exists yet, which blocks the whole row; it is Core's call, not the lab's.

## 6. What the build owes (in order)

1. Remove the rest `AlertConfiguration`; build N2 (title "Rest is up", masked body) via Core's G217 path. Until N2 exists, keep today's alert and say so in the receipt notes.
2. Under `isLuminanceReduced` drop washes and the horizon.
3. Add `.id` + push to the compact trailing "Go".
4. Delete `lookDay`/`lookNight` from the activity state (`Shared/RestActivityAttributes.swift:33-34`, written by the controller at `RestActivityController.swift:118`, unused by the drawing).
5. Cook activity and the timer line, silent activity, one `.timeUp` in front.
6. Undo-after-Done and 60 s "all sets in" faces.
7. Remove from LA: the Go glow breathing, the 700 ms/blur timing and the 1.4 s wash fade (not buildable), so the sheet stops promising them.

## 7. Tests

1. The activity update never carries an `AlertConfiguration` (rest and cook).
2. Rest end locked: one N2 at `restEndsAt`, none when the app saw the end live; foreground plays `.timeUp` once and no sound.
3. N2 and the timer line have fixed titles; the body is masked for private, empty or number-only labels.
4. `isLuminanceReduced` draws no wash and no horizon.
5. Two cook timers within 600 ms produce one timer line.
6. Grep: no `withAnimation` or `.animation(` in `Widgets/`.
