# Lock Screen, Siri and Shortcuts lines: every string, checked

Board item 26. Traced by hand on `origin/master` at `11f4648` (Merge #158). No build was run. Line numbers are
master's.

For: Builder A, Core, Builder B, Design (copy).

Checked against:
- `docs/research/tess-voice.md` and `TessVoice.violations` (`TesseraCore/Sources/TesseraTess/TessCapturing.swift:88`):
  one line, under 12 words, no "!", no emoji, none of should, must, missed, streak, great, awesome, sorry, oops.
- The undo rule, decisions.md 5:14 PM PT Oct 15: "Every line names the thing, then what happened to it ("Set 3
  logged", "Note deleted"). Undo answers with the same name plus "taken back" ("Set 3 taken back"), and an UNDO key
  always reverts the record its line names. "taken back" is the house word, so "Undone." goes."
- The widget copy decision, decisions.md 5:02 PM PT, from `docs/research/widget-states.md`: "All quiet." over
  "Nothing else is planned today."; "×" in sets; `FinishWorkoutIntent` uses the `WorkoutSummary.line` text; "Set 3
  taken back" over "Last set removed.".
- `undo-lines.md` (board item 23). Rows already there are cited by number (W1, W5...), not repeated.

**Bottom line.** 72 user-facing strings across five surfaces. Two surfaces are empty: master has no local
notifications and no Spotlight indexing. The Live Activity and the Shortcuts phrases are clean against the voice
rules. Every mismatch sits in the moments after an action: what Siri says after a write, and what the Lock Screen
says (nothing) after Done or Skip.

## What exists on master

| Surface | Where | Notes |
|---|---|---|
| Live Activity (rest timer) | `Widgets/RestLiveActivity.swift`, data from `Shared/RestActivityAttributes.swift`, driven by `Features/Workout/LiveActivity/RestActivityController.swift` | One activity, two phases: `resting` and `ready` (Go). Starts at the first rest, ends when nothing is left to log. |
| Live Activity buttons | `Shared/RestIntents.swift` | Four `LiveActivityIntent`s, all `isDiscoverable = false`. |
| Alert | `RestActivityController.swift:139` | An ActivityKit `AlertConfiguration`, not a notification. Plays once when rest runs out. |
| Local notifications | none | `git grep` finds no `UNMutableNotificationContent`, `UNUserNotificationCenter` or notification permission request. |
| Siri and App Intents | `TesseraCore/Sources/TesseraIntents/Intents.swift`, `Entities.swift` | Seven intents, two entities. No custom `requestValueDialog`, so Siri asks for missing values in its own words. |
| Shortcuts phrases | `App/AppIntentsPackageLink.swift:13` | One `AppShortcutsProvider`, six shortcuts, seven phrases. |
| Spotlight | none of our own | No `CSSearchableItem`, `IndexedEntity` or `NSUserActivity`. The system lists the six App Shortcuts (short titles) in Spotlight on its own; exercises and routines are not searchable. |

## 1. Every string

Running example from widget-states.md: Push A, Bench, set 4, planned 82.5 × 8, rest 2:30 ending 18:12.

### Live Activity (Builder A)

| # | String (as shown) | File:line | Lock Screen | Island compact | Island minimal | Island expanded | Shows when |
|---|---|---|---|---|---|---|---|
| 1 | `Text(timerInterval:)` "1:32" | `Widgets/RestLiveActivity.swift:106` | | trailing | | | resting |
| 2 | "Go" | `RestLiveActivity.swift:104` | | trailing | | | ready, or content stale at rest end |
| 3 | `Text(timerInterval:)` "1:32" (48 pt Light) | `RestLiveActivity.swift:231` | yes | | | leading (40 pt) | resting, screen awake |
| 4 | "Go" (pushes in from below) | `RestLiveActivity.swift:219` | yes | | | leading | ready or stale |
| 5 | "Ready at" | `RestLiveActivity.swift:224` | yes | | | leading | resting, Always-On (luminance reduced) |
| 6 | "18:12" (rest end, hour and minute) | `RestLiveActivity.swift:227` | yes | | | leading | same as 5 |
| 7 | "Bench" (`state.exercise`) | `RestLiveActivity.swift:256` | yes | | | trailing | always; the Done button |
| 8 | "82.5 × 8" (`state.plannedSet`) | `RestLiveActivity.swift:260`, text built at `Shared/RestActivityAttributes.swift:40` | yes | | | trailing | always; the Done button |
| 9 | "Rest, then set 4" | `RestLiveActivity.swift:154` | yes | | | | resting |
| 10 | "Rested 2:30" | `RestLiveActivity.swift:152` | yes | | | | ready |
| 11 | "+15" (button, `ExtendRestIntent`) | `RestLiveActivity.swift:299` | yes | | | | resting |
| 12 | "+15" (dimmed to 25%, not a button) | `RestLiveActivity.swift:297` | yes | | | | ready |
| 13 | "Skip" (`SkipRestIntent`) | `RestLiveActivity.swift:310` | yes | | | | resting |
| 14 | "Skip" (`SkipSetIntent`) | `RestLiveActivity.swift:308` | yes | | | | ready |
| 15 | VoiceOver: "Log Bench, 82.5 × 8" | `RestLiveActivity.swift:285` | yes | | | trailing | always |

Not shown anywhere: the minimal and compact leading regions draw only the tick (accessibility hidden, `:399`), and
`workoutTitle` ("Push A", `RestActivityAttributes.swift:8`) is set but never drawn. The Undo state from the design
("Set 3 logged" over "Undo", then "Set 3 taken back", widget-states.md:156) is not in code.

### Live Activity alert (Builder A)

| # | String | File:line | Shows when |
|---|---|---|---|
| 16 | Title "Set 4 is up" | `Features/Workout/LiveActivity/RestActivityController.swift:139` | once, when rest runs out while the app is alive (not on Skip) |
| 17 | Body "Bench, 82.5 × 8" | `RestActivityController.swift:139` | same |

### Live Activity button intents (Builder A)

All `isDiscoverable = false`: they do not appear in Shortcuts or Spotlight. The titles may surface in system UI such
as a failed-intent message; nothing else shows them.

| # | String | File:line |
|---|---|---|
| 18 | Title "Log Planned Set" | `Shared/RestIntents.swift:30` |
| 19 | Description "Logs the planned set of the running workout." | `RestIntents.swift:31` |
| 20 | Title "Add 15 Seconds of Rest" | `RestIntents.swift:42` |
| 21 | Title "Skip Rest" | `RestIntents.swift:53` |
| 22 | Title "Skip Set" | `RestIntents.swift:64` |

### Siri and App Intents (Core)

File: `TesseraCore/Sources/TesseraIntents/Intents.swift` unless noted. Titles and descriptions show in the Shortcuts
app and the action editor. Dialogs are spoken by Siri and shown on the Siri card.

| # | Intent | Kind | String | Line | Shows when |
|---|---|---|---|---|---|
| 23 | Log a Set | title | "Log a Set" | 10 | Shortcuts, Siri |
| 24 | | description | "Logs sets of an exercise into today's workout." | 11 | Shortcuts editor |
| 25 | | parameter | "Exercise" | 13 | editor; Siri asks for it (system prompt) |
| 26 | | parameter | "Weight (kg)" | 14 | same |
| 27 | | parameter | "Reps" (default 8) | 15 | editor |
| 28 | | parameter | "Sets" (default 1) | 16 | editor |
| 29 | | parameter summary | "Log 1 × 8 Bench Press at 80 kg" | 23 | Shortcuts editor row |
| 30 | | dialog | "Logged bench press 1×8 at 80 kg." (`record.summary`, `TrainingActions.swift:342`) | 31 | after the write |
| 31 | Log Next Set | title | "Log Next Set" | 37 | Shortcuts, Siri |
| 32 | | description | "Logs the next set of the workout in progress, as prefilled." | 38 | Shortcuts editor |
| 33 | | dialog | "No workout running." | 49 | no open workout |
| 34 | | dialog | "Logged 82.5 × 8." (`Prefill.swift:103`) | 51 | after the write |
| 35 | Undo Last Set | title | "Undo Last Set" | 57 | Shortcuts, Siri |
| 36 | | description | "Removes the most recently logged set. Undo brings it back." | 58 | Shortcuts editor |
| 37 | | dialog | "No set to undo." | 67 | nothing to undo (no open workout) |
| 38 | | dialog | "Last set removed." | 69 | after the undo |
| 39 | Start a Workout | title | "Start a Workout" | 74 | Shortcuts, Siri |
| 40 | | description | "Starts a workout from a routine, prefilled with today's targets." | 76 | Shortcuts editor |
| 41 | | parameter | "Routine" | 79 | editor; Siri asks (system prompt) |
| 42 | | dialog | "Pull A started. 5 exercises." | 89 | after start; opens the app (`.foreground`) |
| 43 | Finish Workout | title | "Finish Workout" | 94 | Shortcuts, Siri |
| 44 | | description | "Finishes the workout in progress, keeping every set." | 95 | Shortcuts editor |
| 45 | | dialog | "No workout running." | 104 | no open workout |
| 46 | | dialog | "Finished. 6 of 6 exercises." | 107 | after the finish |
| 47 | Add a Task | title | "Add a Task" | 112 | Shortcuts, Siri |
| 48 | | description | "Adds a task to Tessera." | 113 | Shortcuts editor |
| 49 | | parameter | "Task" | 115 | editor; Siri asks (system prompt) |
| 50 | | parameter | "When" (optional) | 116 | editor |
| 51 | | dialog | "Added “Dentist”." (`TrainingActions.swift:390`) | 125 | after the write |
| 52 | Tell Tess | title | "Tell Tess" | 131 | Shortcuts, Siri |
| 53 | | description | "Logs a set or adds a task from a phrase, like “bench 80 x 8”." | 133 | Shortcuts editor |
| 54 | | parameter | "Phrase" | 135 | editor; Siri asks (system prompt) |
| 55 | | dialog | Tess's capture line, "Set 4. 82.5 x 8." (see undo-lines capture table) | 144 | after the capture |
| 56 | Exercise entity | type name | "Exercise" | `Entities.swift:7` | pickers, disambiguation |
| 57 | | display | the class name, "Bench Press" | `Entities.swift:14` | pickers |
| 58 | Routine entity | type name | "Routine" | `Entities.swift:59` | pickers |
| 59 | | display | the routine title, "Pull A" | `Entities.swift:66` | pickers, the Start phrase |

### Shortcuts phrases and short titles (`App/AppIntentsPackageLink.swift`)

"Tessera" is `\(.applicationName)`. Short titles also show as the App Shortcuts tiles in Spotlight and the Shortcuts
app.

| # | String | Line | Intent |
|---|---|---|---|
| 60 | Phrase "Tell Tessera" | 15 | Tell Tess |
| 61 | Phrase "Log in Tessera" | 15 | Tell Tess |
| 62 | Short title "Tell Tess" | 16 | Tell Tess |
| 63 | Phrase "Log a set in Tessera" | 17 | Log a Set |
| 64 | Short title "Log a Set" | 18 | Log a Set |
| 65 | Phrase "Undo last set in Tessera" | 19 | Undo Last Set |
| 66 | Short title "Undo Last Set" | 20 | Undo Last Set |
| 67 | Phrase "Start Pull A in Tessera" | 21 | Start a Workout |
| 68 | Short title "Start Workout" | 22 | Start a Workout |
| 69 | Phrase "Finish my workout in Tessera" | 23 | Finish Workout |
| 70 | Short title "Finish Workout" | 24 | Finish Workout |
| 71 | Phrase "Add a task in Tessera" | 25 | Add a Task |
| 72 | Short title "Add Task" | 26 | Add a Task |

### Local notifications and Spotlight

None on master. Nothing to check.

## 2. Check results

**TessVoice violations.** None. Every dialog is one line under 12 words with no "!", emoji or banned word. The
longest is #46 at 5 words; #30 can reach about 8.

**Live Activity against the decisions.** Clean where it speaks: "×" in #8, #15, #17; no undo wording, no empty line
(the activity does not exist when nothing is planned, so "All quiet." has no slot). "Rest, then set 4" and "Go"
were kept on purpose (widget-states C7, C8). The gaps are what it does not say after Done and Skip (L1, L2).

**Shortcuts phrases.** No rule breaks. Two wording notes in open questions.

## 3. Mismatches

| # | Where | Before | After | Owner | Status |
|---|---|---|---|---|---|
| S1 | Undo Last Set dialog, `Intents.swift:69` | "Last set removed." | "Set 3 taken back." | Builder A hotfix (the intent itself is Core's) | **in flight**. Same row as undo-lines W1 and B1. |
| S2 | Undo Last Set description, `Intents.swift:58` | "Removes the most recently logged set. Undo brings it back." | "Takes back the last set you logged." | Core, best carried in Builder A's hotfix since it is the same intent | new. Nothing undoes this undo (undo-lines row 45: no redo), so the description promises a step that does not exist, and it uses "Removes" where the house word is "taken back". |
| S3 | Undo Last Set empty dialog, `Intents.swift:67` | "No set to undo." | "No set to take back." | Core, same carry as S2 | new. Follows "taken back is the house word". Low stakes; drop it if the hotfix already settles this line. |
| S4 | Finish Workout dialog, `Intents.swift:107` | "Finished. 6 of 6 exercises." | "Push A finished. 6 of 6 exercises, 22 sets, 1 record." | Core | cite undo-lines W11, with one fix: W11's after drops ", 1 record". The 5:02 decision says the intent uses the `WorkoutSummary.line` text (`WorkoutSummary.swift:30`) whole, and the 5:14 rule puts the name first. 9 words, passes. |
| S5 | Log a Set dialog, `Intents.swift:31` | "Logged bench press 1×8 at 80 kg." | see undo-lines W5 | Core | cited, not repeated. Note the "1×8" has no spaces, against "×" with spaces everywhere else. |
| S6 | Log Next Set dialog, `Intents.swift:51` | "Logged 82.5 × 8." | see undo-lines W6 ("Set 4. 82.5 × 8.") | Core | cited |
| S7 | Add a Task dialog, `Intents.swift:125` | "Added “Dentist”." | see undo-lines W7 | Core | cited |
| S8 | Tell Tess dialog, `Intents.swift:144` | "Set 4. 82.5 x 8." | see undo-lines W8 ("×") | Core (TesseraTess) | cited |
| L1 | Live Activity after Done (tap on #7 and #8) | nothing: the face jumps to the next rest, "Rest, then set 5" | bottom-left line "Set 4 logged" with an "Undo" key in place of "+15 / Skip" until the next change, then on Undo "Set 4 taken back" (the design strings, widget-states.md:156) | Builder A | new. Breaks the 5:14 rule: the most used Lock Screen write has no line, so nothing names what was logged and there is no Undo within reach. `UndoLastSetIntent` is already a `LiveActivityIntent` (`Intents.swift:153`), so the key can reuse it once S1 lands (it must undo one set, and the session must react, undo-lines B1). |
| L2 | Live Activity Skip when ready (#14) | nothing: the face moves to the next set | "Set 4 skipped" in the bottom-left slot | Builder A | new. Same rule: name it, then what happened. No Undo, since skip is in memory only (undo-lines B10); the line says so by not offering one. |
| P1 | Short titles, `AppIntentsPackageLink.swift:22, 26` | "Start Workout", "Add Task" | "Start a Workout", "Add a Task" (match the intent titles #39, #47 and the other tiles "Log a Set") | Core (the intents are Core's; the provider sits in the app target only so the metadata is extracted) | new, minor. Spotlight shows these tiles side by side with "Log a Set". |

No Builder B rows: nothing on these surfaces is drawn from Home, Command or RootView.

Counts: 11 rows. Builder A: 2 new (L1, L2) plus S1 in flight. Core: 3 new (S2, S3, P1), 1 corrected cite (S4),
4 cites (S5 to S8). Builder B: 0.

**Worst: L1.** Done on the Lock Screen is the one write people make without looking at the app, and it says nothing
and offers no Undo. A mistaken tap logs a set you only find later. S2 is second: the Undo intent's own description
promises a redo that does not exist.

## 4. Gaps worth knowing (not copy mismatches)

- No custom parameter prompts. Siri asks "What's the value for Weight (kg)?" style questions in its own voice. A
  `requestValueDialog` per required parameter would let Tess ask: "Which exercise?", "What weight?", "Which
  routine?", "What's the task?", "What to log?".
- No App Shortcut for Log Next Set, though it is the Siri form of the Lock Screen's Done. Two intents do the same
  act under two names: "Log Planned Set" (#18, Live Activity) and "Log Next Set" (#31, Siri).
- The Live Activity ends at once after the last set (widget-states open question 4), so the summary line never
  reaches the Lock Screen.
- No notifications at all. If one is added (for example a rest alert while the activity is off), it should reuse
  the alert's words, #16 and #17.
- No Spotlight indexing: "Bench Press" or "Pull A" typed in Spotlight finds nothing of ours. `IndexedEntity` on the
  two entities would fix it with no new copy.

## Open questions

1. Does Builder A's in-flight Undo Last Set hotfix also change the description (S2) and the empty line (S3)? If not,
   who takes them: the hotfix, or Core's next batch?
2. L1: should the Lock Screen Undo state replace "+15 / Skip" or sit in the bottom-left line beside them? The
   design file (`live-activity.md`) is still off master; decisions.md 5:14 says the strings live in
   widget-states.md until it lands.
3. L2: is "Set 4 skipped" wanted at all, or is the Skip silent like the other in-memory rest controls?
4. Tell Tess's description shows a typed example, "bench 80 x 8". Typed input uses "x", so it stays as is, unless
   the "×" decision is meant to cover examples too.
5. The phrase "Log in Tessera" (#61) can read as signing in. Keep it, or swap for "Tell Tess in Tessera"? Siri
   phrases must contain the app name, so "Tell Tess" alone is not allowed.
6. Who owns `App/AppIntentsPackageLink.swift`: Core (the intents) or whoever owns `App/`? P1 assumes Core.
7. Should Log Planned Set and Log Next Set become one intent, so the Lock Screen and Siri share one name and one
   dialog?
