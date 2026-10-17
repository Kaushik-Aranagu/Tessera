# Review: App Intents and HealthKit on master (bb7f082)

Static review only (no toolchain), Oct 16, 2026. A QA subagent traced every finding to the code paths named; QA re-read H1, I1 and I3 line by line. Line numbers are on master.

## What checks out
- Every Core intent (LogSet, LogNextSet, UndoLastSet, StartRoutine, FinishWorkout, CreateTask, TellTess) writes
  through `ActionEngine.perform(..., by: .intent)` or `takeBackLatestSet(by: .intent)`, so it lands in the op log and can be undone.
- Claude is unreachable from Siri/Shortcuts: `TellTessIntent` passes `TessContext(commitImmediately: true)`
  (Intents.swift:150), `ClaudeTessModel.run` returns `.missed` on it before the inbox `add` (ClaudeTessModel.swift:51,
  111), and `readWaiting` refuses it (TessInbox.swift:57). Phrases from intents never enter the Claude inbox.
- Tell Tess goes through the same `TessRouter`, so the key refusal and the secret-word grammar-only rule
  (TessModel.swift:69-75) apply exactly as in the Bar.
- No `ProcessInfo`, `LaunchFlags` or `UserDefaults` reads in TesseraIntents or Shared/RestIntents.swift.
- Missing classes don't crash: entity queries `guard` on `engine.classes[...]`; actions throw `ActionError`,
  which Siri shows as a failure. `TesseraRuntime` is always built before it is registered (AppModel.swift:125).
- HealthKit is write-only (`read: []`, HealthExporter.swift:37). No health value is ever read, so none can reach a
  Claude pack, memory, Spotlight (there is no Spotlight indexing) or backups. A failed or denied authorization returns
  `false` and nothing is written; the error is swallowed with no UI.

## Findings

### H1 (high): "Finish early" workouts never reach Apple Health
- File: App/Health/HealthExporter.swift:17, which matches only `FinishWorkout.descriptor.name` ("finishWorkout").
- Live mode's finish from the running order performs `FinishWorkoutEarly` (Features/Workout/WorkoutSession.swift:619)
  whenever any exercise is unfinished. That records an OpRecord with action "finishWorkoutEarly". It calls
  `FinishWorkout.apply` inside the same transaction (TrainingActions.swift:290), so no "finishWorkout" record is ever made.
- Scenario: plan 5 exercises, do 3, hold Finish in the running order. Tessera saves the workout and Health gets nothing.
  This is probably the most common way a real session ends.
- Fix: match both action names (or add a `finishesWorkout` flag on the descriptor). Owner: Builder A.

### I1 (medium): Siri "Finish my workout" leaves a live session that Lock Screen Done still logs into
- Files: TesseraCore/Sources/TesseraIntents/Intents.swift:112; Features/Workout/LiveActivity/LiveWorkout.swift:38-39;
  LogSet / LogNextSet have no `endedAt` guard (TrainingActions.swift:14, Training/Prefill.swift:71).
- Scenario: a workout is running with the app in the background and the rest Live Activity on the Lock Screen. He says
  "Finish my workout in Tessera". The workout gets `endedAt`, and Health saves it with N sets. Nothing clears
  `model.session` or updates the activity until the next `.active` scene phase (AppModel.swift:341). He taps Done on
  the Lock Screen. `LiveWorkout.handle` returns the stale `model.session`, and `logSet` performs LogNextSet into the
  finished workout. Tessera now has N+1 sets after the end time, and Health's copy says N.
- Fix: have `resumeSession` drop a session whose workout has `endedAt`. Also end the activity when FinishWorkout
  lands (observe the engine as HealthExporter does), and reject LogSet into a finished workout unless `on:` is set.
  Owner: Builder A (session/activity), Core (action guard).

### I2 (medium): Siri "Start <routine>" during a live workout splits the app and Siri onto different workouts
- Files: Intents.swift:93-97 (no open-workout check); AppModel.swift:631-634 (`pickUpRunningWorkout` returns early when
  `session != nil`).
- Scenario: workout A is live in the app and he says "Start Pull Day in Tessera". StartRoutine makes B, and
  `StartProcess` suspends A (ProcessActions.swift:43). The app opens in the foreground, but `model.session` is still A.
  So the live screen and the Lock Screen Done (LiveWorkout relay) log into A, while Siri's "Log next set", "Undo last
  set" and "Finish workout" act on B, the running process. Sets end up spread across two workouts.
- Fix: the intent should refuse when `openWorkout()` exists, or the app should swap `session` when the running process
  subject changes. Owner: Builder A (app side), Core (intent guard).

### I3 (medium): "Add a Task" skips the secret-word and Claude-key guards that the Bar applies
- File: Intents.swift:131. It performs `CreateTask(title:)` directly, with no router.
- In the app, "garage code 4471" becomes a Private note (TessGrammar.swift:471-487), and a pasted key is refused
  (TessModel.swift:69, whose comment says it "would become a note, then every backup").
- Scenario: Shortcuts "Add a task in Tessera" with "wifi password is hunter22", or a pasted key. The result is a plain
  task titled with the secret, shown in the clear on Home and in the Day log, and written to every daily backup.
- Fix: in CreateTaskIntent, refuse `looksLikeClaudeKey`, and route `SecretWords.hasValue` text to a private note (or to
  `runtime.tess.capture`). Owner: Core.

### I4 (low): "Add a Task" dates ignore the 4 AM day
- File: Intents.swift:131 passes Siri's resolved `startsAt` unchanged.
- The grammar's "tomorrow" is `TesseraDay.day(1, after:)` (TessGrammar.swift:593-595). At 01:00 Saturday (still his
  Friday), Tess's "tomorrow" is Saturday, but Siri resolves "tomorrow 9am" to Sunday 09:00.
- Scenario: at 01:30 he says "Add a task call mom tomorrow at 9". The task lands a day later than the same phrase typed
  in the Bar. Fix: have the dialog read back the weekday via `TessCaptureEngine.when`, or route it through Tell Tess.
  Owner: Core.

### I5 (low): A Siri Tell Tess that asks a question leaves a dangling ask in the app
- File: TesseraTess/TessCaptureEngine.swift:45-52. `pendingAsk` / `pendingDatedLift` are stored on the shared engine
  even when `commitImmediately` is set.
- Scenario: "Tell Tessera 2 x 10" mid-workout. Siri speaks "2 sets, or 2 kg?" and ends, because it can't take the
  answer. The ask stays on the app's capture engine (AppModel.swift:215/227 surface it). His next Bar phrase is either
  read as the answer or silently drops the ask. "bench 80x8 mon" by Siri logs nothing, and the dialog asks LOG / NOT NOW.
- Fix: when `commitImmediately` is set, don't store the ask, and return a dialog saying to open Tessera. Owner: Core.

### I6 (low): Intents write to the in-memory fallback store as if it were saved
- Files: AppModel.swift:116 (`settingsAreReal` gates Claude, but not the runtime) and TesseraApp.swift:34-36.
- Scenario: the store fails to open and falls back to memory. "Log a set" by Siri replies "Logged …", and the set is
  lost when the process exits. Only the in-app calm note tells him. Fix: skip registering the runtime, or make the
  dialog say "not saved", when `lastOpenOutcome == .inMemoryFallback`. Owner: Core.

### H2 (low): Undo, take-back or a later edit of a finished workout never updates the Health copy
- Files: HealthExporter.swift:16-23; `ActionEngine.undo` / `redo` don't call `notify` (ActionEngine.swift:142-156).
- Scenario: he uses LOG … AND FINISH and taps take-back within 10 s (WorkoutSession.swift:439). The workout is already
  in Health and is running again in Tessera. Re-finishing replaces it (same `HKMetadataKeySyncIdentifier`, with a higher
  version), so that path heals. But if he then deletes the workout, or deletes or edits sets after finishing, Health
  keeps a workout or set and volume metadata that Tessera no longer has.
- Fix: re-save on edits to a finished workout's sets, and delete by sync identifier when a finish is undone and the
  workout is deleted. Owner: Builder A.

### H3 (low): The Health permission copy claims reads that never happen
- File: project.yml:74. `NSHealthShareUsageDescription` says Tessera "reads your workouts, heart rate and body weight",
  but the code requests no read types. It is harmless today. If a future read is added, it should pass the same
  privacy review as everything else (no health values in Claude packs or memory). Fix: trim the copy until reads ship.
  Owner: Builder A.
