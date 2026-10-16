# Widget and snippet states: the exact lines

For: iOS Builder A (board item 22, widgets), Design studio, Product. 2026-10-15. Research lab.
Code read: origin/master `db049cb`. Reads with `widgets-and-snippets.md`, `fixtures/ranker.md`, `free-signing-survival.md`,
`tess-voice.md`, `../product/decisions.md` (3:37 PM and 4:01 PM PT), and `docs/design/live-activity.md` (on branch
`claude/project-thread-b3tu3f`, not on master).

**Bottom line.** Master has one widget surface: the rest Live Activity (`Widgets/RestLiveActivity.swift`, Cobalt sky,
horizon line). It has no Home Screen widget, no Lock Screen accessory widget, no App Group, no `WidgetCenter` call
and no snippet (`SnippetIntent` appears nowhere). App Intents exist, with one-line dialogs. Every line below for a
surface that does not exist yet is proposed copy taken from Now. Where Now itself says two different things, the
conflict is flagged and the widget follows the product rule.

## Where the lines come from

| Source on master | What it says |
|---|---|
| `NowRanker.swift` (`NowPicker.rank`) | Precedence: running process, then a timed task within 15 min, then a planned rest day, then re-entry, then the scored rank. Why lines: "Running since 18:32", "At 18:00", "Rest day. Pull A is a tap away", "Welcome back. Small on purpose". Empty rank means "All quiet." (doc comment only, no string constant). |
| `RestDay.swift` | `RestDay.line = "Rest day"`. |
| `Features/Home/NowPage.swift` | Running: "running now, Push A", hero "Bench, set 4 of 5", key "Resume", state "Resting / 1:32", "Set 4 / is up", "Next / exercise", "Ready / to finish". Routine: "today's training", key "Start", "5 EXERCISES / 15 SETS". Done: "trained this evening", hero "Push A", Tess line. Empty: "Nothing else is planned today." and "Look back at the week →". Task: "now, until twenty to four" or "next, at half past five", "Hold · 14 MIN LEFT". |
| `WorkoutSummary.line` (Core) | "6 of 6 exercises, 22 sets, 1 record." |
| `TessVoice` | One line, under 12 words, digits, no "!", no emoji, never "should", "must", "missed", "streak", "great", "awesome", "sorry", "oops". Offers start "Want...?". |
| `RestLiveActivity.swift` | See the Live Activity section. |
| `TesseraIntents/Intents.swift` | Dialogs, see the snippets section. |

**Important:** `NowPage` does not call `NowPicker` yet (`git grep NowPicker` finds no use in `Features/` or `App/`).
The Now screen builds its hero from `currentTask`, `todaysRoutine` and `finishedToday`. So on a rest day the screen
still shows "today's training / Pull A / Start", while Core says "Rest day". The widget must read `NowPicker.pick`,
the same as the screen will once Builder B wires it, so the two never disagree for long.

## The running example

Thu 18:10. Plan Push A, Pull A, Legs A. Push A started 18:00. Bench, set 4 of 5, planned 82.5 × 8, rest 2:30 ends
18:12:30. Next routine Pull A (Fri). Times are 24-hour clock in labels, spoken clock in the voice line, as Now does.

The six states:

1. **Running.** A workout is running and a set is up (not resting).
2. **Resting.** Running, between sets, rest counting down.
3. **Rest day.** `NowPicker` returns `kind == .rest`. A timed task within 15 min still beats it (rule 2), and then the
   widget shows that task, not "Rest day".
4. **Nothing planned.** `rank` returns empty, nothing trained today.
5. **Day done.** Trained today and nothing left (`finishedToday` is not empty), or the day closed by Shutdown.
6. **Signing expired.** The 7-day free profile has lapsed. The app and the extension will not run.

## Home Screen widgets (proposed, nothing on master)

Type: one line in the top tier, a hairline seam under it, the label tier for meta. The context line is lowercase,
as on Now. No red anywhere; vermilion only on the Resume key and the tick, exactly as in the app.

### Medium (the "Now" widget)

| State | Context line (voice, 21) | Hero (top tier) | Meta (label tier) | Key | Tap |
|---|---|---|---|---|---|
| Running | running now, Push A | Bench, set 4 of 5 | SET 4 / IS UP | Resume | live workout at that set |
| Resting | running now, Push A | Bench, set 4 of 5 | RESTING / `Text(timerInterval:)` "1:32" | Resume | live workout |
| Rest day | Rest day | Pull A is a tap away | none | Pull A | opens Pull A (the routine page, not Start) |
| Nothing planned | (none) | Nothing else is planned today. | none | none | Home, Now page |
| Day done (trained) | trained this evening | Push A | 6 of 6 exercises, 22 sets, 1 record. (Tess colour) | none | Training |
| Day done (closed, late) | (none) | Tomorrow starts with Pull A | 07:30, dimmed | none | Home |
| Signing expired | (none) | Paused until the next Run from Xcode. | Everything is still on this phone. | none | nothing (the app won't open) |

- Resting: the meta flips to "SET 4 / IS UP" at 18:12:30 without a reload. The app writes two timeline entries, one
  now and one at `restEndsAt`, the same trick the Live Activity does with `staleDate`.
- Exercise done: meta "NEXT / EXERCISE". All sets done: "READY / TO FINISH". Both copied from `RunningHero.state`.
- Rest day: the hero is the ranker's why with the "Rest day." lead moved up to the context line, so the words are
  exactly `"\(RestDay.line). \(next.title) is a tap away"`, split in two.
- A timed task within 15 min (rule 2, also on a rest day): context "next, at six", hero "Call landlord", meta
  "IN / 10 MIN". These are `NowPage.contextLine` and `NowPage.timeLeft`.
- Late, closed day: "Tomorrow starts with ..." is fixture R24 and context-packing moment 14. It is not in master code.

### Small

Same states, two lines only, no key (the whole widget is the tap).

| State | Line 1 (voice) | Line 2 (top tier) |
|---|---|---|
| Running | running now | Bench, set 4 of 5 |
| Resting | resting | `Text(timerInterval:)` 1:32 |
| Rest day | Rest day | Pull A is a tap away |
| Nothing planned | (none) | Nothing else is planned today. |
| Day done | trained this evening | Push A |
| Signing expired | paused | Run from Xcode to wake it. |

### Large

The medium layout, then a "Later" window of up to 3 rows from `pick(next: 3)`, each "title" left and "18:30" right,
in the label tier. Same six states for the top half. Later rows:

| State | Later window |
|---|---|
| Running, Resting | the next 3 picks, for example "Call landlord 19:00" |
| Rest day | the scored items under the rest line (R01: "Renew passport", no time) |
| Nothing planned | empty, no placeholder row |
| Day done | empty |
| Signing expired | removed (a stale list would look current) |

## Lock Screen accessory widgets (proposed, nothing on master)

Monochrome, vibrant. No colour at all, so state is carried by words and the one timer. During rest, the Live Activity
owns the Lock Screen; the accessories must still agree with it.

### Rectangular (3 lines)

| State | Line 1 (bold) | Line 2 | Line 3 |
|---|---|---|---|
| Running | Push A | Bench, set 4 of 5 | Set 4 is up |
| Resting | Push A | Bench, set 4 of 5 | Resting `Text(timerInterval:)` 1:32 |
| Rest day | Rest day | Pull A is a tap away | (none) |
| Nothing planned | Nothing else is planned today. | (none) | (none) |
| Day done | Push A | trained this evening | 6 of 6 exercises, 22 sets |
| Signing expired | Tessera is paused | Run from Xcode to wake it | (none) |

### Circular

| State | Content |
|---|---|
| Running | "4/5" over a still ring at 3 of 5 |
| Resting | `ProgressView(timerInterval:)` gauge draining, "1:32" in the centre |
| Rest day | "Rest" |
| Nothing planned | the tick glyph only, no text |
| Day done | the tick glyph, "22" under it (sets) |
| Signing expired | "Paused" |

VoiceOver labels: "Bench, set 4 of 5", "Resting, 1 minute 32 left", "Rest day", "Nothing else is planned today",
"Push A, done, 22 sets", "Tessera is paused".

### Inline (one line above the clock, about 20 characters)

| State | Line |
|---|---|
| Running | Bench, set 4 of 5 |
| Resting | Resting 1:32 (timer text) |
| Rest day | Rest day |
| Nothing planned | All quiet. |
| Day done | Push A, done |
| Signing expired | Tessera paused |

"All quiet." is used here only because "Nothing else is planned today." does not fit. See conflict C2.

## Rest Live Activity (on master)

Quoted from `Widgets/RestLiveActivity.swift` and `Features/Workout/LiveActivity/RestActivityController.swift`. It
starts at the first rest, updates on every change, and ends when the workout ends or has nothing left to log.

| State | Lock Screen | Dynamic Island | Agrees with Now? |
|---|---|---|---|
| Resting | Countdown `Text(timerInterval:)` (Inter Tight 48 Light). Right column "Bench" over "82.5 × 8" with the tick (the Done button). Bottom left "Rest, then set 4". Bottom right "+15", "Skip". Always-On: "Ready at 18:12". | Compact: tick, then "1:32". Expanded: countdown, "Bench", "82.5 × 8", horizon line. Minimal: tick. | Mostly. Now says "Resting" where the activity says "Rest, then set 4" (C8). |
| Running (rest over, set up) | "Go" replaces the countdown, washes warm to cadmium and vermilion. Bottom left "Rested 2:30". "+15" dims to 25%. "Skip" skips the set. Alert, once: title "Set 4 is up", body "Bench, 82.5 × 8". | Compact trailing "Go". | Yes. The alert title matches Now's "Set 4 / is up". "Go" is the activity's own word (C7). |
| Rest day | No activity. | none | Yes. |
| Nothing planned | No activity. | none | Yes. |
| Day done | Ends at once with `dismissalPolicy: .immediate` when the last set is logged (`plannedSet` returns nil on `.workoutDone`). No closing face. | none | Now shows "Ready / to finish" while the app still shows the workout; the activity is already gone. See open question 4. |
| Signing expired | Expiry mid-workout is unlikely (7 days). If it happens, the face keeps showing and the timer keeps running, because the system draws them. Done, +15 and Skip do nothing, because a `LiveActivityIntent` performs in the app process, which cannot launch. The system ends the activity after its 8 hour limit. | same | n/a |

Design doc lines that are not in master code: the Undo state after Done ("Set 3 logged" over "Undo", then "Set 3
taken back"). If Builder A builds it, use those exact strings, and see C6.

Proposed for the expired case only: none. The activity cannot know, and a workout spanning the expiry minute is rare.

## App Intents and snippets

### Dialogs on master today (quoted)

| Intent | Dialog |
|---|---|
| `LogSetIntent` | "\(record.summary)." |
| `LogNextSetIntent` | "\(record.summary)." or "No workout running." |
| `UndoLastSetIntent` | "Last set removed." or "No set to undo." |
| `StartRoutineIntent` | "Pull A started. 5 exercises." |
| `FinishWorkoutIntent` | "Finished. 6 of 6 exercises." or "No workout running." |
| `CreateTaskIntent` | "\(record.summary)." |
| `TellTessIntent` | Tess's capture line, for example "Set 4. 82.5 x 8." |

No snippet views exist. The dialogs never mention rest days or the day being done.

### Proposed snippet 1: "What's now" (new `ShowNowIntent`, Siri "What's now in Tessera")

Same words as the medium widget, drawn on the system platter (no painterly ground, type only).

| State | Snippet | Buttons | Spoken dialog (TessVoice rules) |
|---|---|---|---|
| Running | running now, Push A / **Bench, set 4 of 5** / Set 4 is up | Same again (logs 82.5 × 8), Resume | "Bench, set 4 of 5. 82.5 × 8." |
| Resting | running now, Push A / **1:32** timer / Rest, then set 4 | +15, Skip | "Resting. Set 4 in 1:32." |
| Rest day | Rest day / **Pull A is a tap away** | Open Pull A | "Rest day. Pull A is a tap away." (the ranker's why, verbatim) |
| Nothing planned | **Nothing else is planned today.** | none | "All quiet." |
| Day done | trained this evening / **Push A** / 6 of 6 exercises, 22 sets, 1 record. | none | "Push A done. 6 of 6 exercises, 22 sets." |
| Signing expired | none: the system cannot run the intent. Siri gives its own failure line; we cannot change it. | none | none |

### Proposed snippet 2: "Log a set" (`LogNextSetIntent` returning a `SnippetIntent`)

| State | Snippet | Buttons | After a tap |
|---|---|---|---|
| Running | **82.5** hairline **8**, "Bench, set 4 of 5" under | Same again, +2.5, +1 rep | numerals roll; dialog "\(record.summary)." |
| Resting | same numerals, "Resting 1:32" under | same | logging ends the rest, like hold to log |
| Rest day | "Rest day. Pull A is a tap away." | Start Pull A | `StartRoutineIntent`, dialog "Pull A started. 5 exercises." |
| Nothing planned | "No workout running." (master) | Want to start Pull A? | same as above |
| Day done | "Push A is done. 22 sets." | Undo last set | "Last set removed." |
| Signing expired | cannot run | none | none |

"Start Pull A" on a rest day is allowed: decisions.md 3:37 PM says starting it anyway is fine. No "anyway" in copy,
it reads as a judgement.

## Signing expired: what each surface can and cannot do

What we know (`free-signing-survival.md`): on day 7 iOS will not launch the app. The data stays. A Run from Xcode
brings it back. The widget extension is signed with the same Personal Team (App ID `com.kaushikaranagu.tessera.widgets`),
so it stops too (inferred, verify on the phone).

| Surface | Can show | Cannot do |
|---|---|---|
| Home and Lock widgets | Whatever WidgetKit already holds: the timeline entries the app wrote before expiry. Inferred: WidgetKit archives rendered entries and keeps showing them on schedule; **verify** with one expired build. | Reload, read new data, open the app on tap, run a button. |
| Live Activity | The last face, with the system-drawn timer. | Run Done, +15 or Skip. |
| Snippets, Shortcuts, Siri | Nothing of ours. | Run any intent. |
| Controls | The system-drawn symbol. | Act on tap. |

**The fix is to write the expiry into the timeline ahead of time.** At each launch the app reads `ExpirationDate`
from `embedded.mobileprovision` (present in development-signed builds; **verify** it is readable at runtime) and
adds it to `now.json`. The provider then:

1. Ends every timeline with an entry at the expiry time showing the "Signing expired" lines above, with all live
   timers removed (a ticking rest timer on a dead app reads as current).
2. From 24 hours before expiry, adds one label-tier line under the hero on medium and large: "Re-sign by Thu 18:10".
   Plain, no colour, no count of days. It replaces the checklist's calendar reminder.
3. Drops the Later window at expiry, so nothing stale looks like a plan.

If verification shows WidgetKit blanks the widget once the extension cannot run, step 2 still helps, and step 1
does nothing harmful.

## Conflicts

| # | Where | What disagrees | Widget follows |
|---|---|---|---|
| C1 | `NowPage.hero` vs `RestDay.line` and decisions.md 3:37 PM | On a rest day the Now screen shows "today's training / Pull A / Start". Core and Product say "Rest day", next routine a tap away. | "Rest day". The screen needs wiring to `NowPicker` (Builder B). |
| C2 | `NowPage` empty hero vs ranker doc comment, `tess-voice.md`, context-packing moment 17 | "Nothing else is planned today." vs "All quiet." vs "Nothing planned. Rest day." | The screen's string where it fits, "All quiet." on inline and in Siri's voice. Needs one decision. |
| C3 | `RunningHero` vs ranker why | "running now, Push A" vs "Running since 18:00". | The screen's "running now". |
| C4 | Live Activity and app `Summary.line` vs Tess capture and `TessVoice` examples | "82.5 × 8" vs "82.5 x 8". | "×" on drawn surfaces; Tess's spoken lines keep "x" until decided. |
| C5 | `FinishWorkoutIntent` vs `WorkoutSummary.line` | "Finished. 6 of 6 exercises." vs "6 of 6 exercises, 22 sets, 1 record." | Propose the intent says "Finished. " + `WorkoutSummary.line`. |
| C6 | `UndoLastSetIntent` vs live-activity.md Undo state | "Last set removed." vs "Set 3 taken back". | Needs one string; "Set 3 taken back" names the set. |
| C7 | Live Activity vs Now | "Go" vs "Set 4 / is up". The alert already says "Set 4 is up". | Keep both; "Go" is the activity's one big word. |
| C8 | Live Activity vs Now | "Rest, then set 4" vs "Resting". | Widgets use "Resting" (Now's word); the activity keeps its line. |
| C9 | Ranker vs `NowPage` on a done day | Ranker returns empty ("All quiet.", R29); the screen shows the DoneHero. | The DoneHero lines. "Tomorrow starts with ..." (R24) is in no code yet. |
| C10 | App `WorkoutSession.Summary.line` vs Core `WorkoutSummary.line` | "6 exercises, 22 sets. New best: 85 × 5." vs "6 of 6 exercises, 22 sets, 1 record." | Core's line (the widget has no live session). |
| C11 | `widgets-and-snippets.md` | Assumes an App Group and `now.json`; master has neither. | Builder A adds both; confirm App Groups on the free team with one build. |

## Open questions

1. Which empty line wins everywhere: "Nothing else is planned today." or "All quiet."? (C2)
2. On a rest day, does the widget's key open Pull A's page or start it? The rule says "a tap away", which reads as open.
3. Does WidgetKit keep showing archived entries after the extension's profile expires, or blank them? One expired
   test build settles it.
4. Should the Live Activity stay for a minute after the last set with "Push A done. 22 sets." instead of ending at
   once? Today it vanishes while Now still says "Ready / to finish".
5. Is `embedded.mobileprovision` readable at runtime on a free-signed install, so the app knows its expiry?
6. "Re-sign by Thu 18:10" on the widget: wanted, or does it feel like a nag? It is the only line here that asks for
   something.
7. Spoken set notation: "x" or "×"? (C4)
8. After 22:00 on a closed day, "Tomorrow starts with Pull A 07:30" is fixture copy only. Ship it in the widget
   before the Now screen has it, or wait?
9. Undo wording: "Last set removed." or "Set 3 taken back"? (C6)
