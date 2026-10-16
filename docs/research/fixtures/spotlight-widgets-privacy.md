# Spotlight, widgets and Lock Screen: privacy trace

Traced at origin/master `68c9a19` on Oct 16, 2026 (Product item P). Every surface outside the app's own screens:
what data can reach it, against the rules (secret-word and private notes never leave the app; money and body facts
never on Lock Screen or Spotlight; private Tess memory stays private; the Claude key never appears, presence only).

What exists today: one widget extension with only the rest Live Activity, App Intents with dialogs, App Shortcuts,
an App Group holding look names, and the Health export. No Spotlight indexing, no Home or Lock Screen widgets, no
controls, no notifications.

| id | surface | what data | path (file:line) | rule | result | fix (gaps) |
|---|---|---|---|---|---|---|
| P1 | Spotlight: CoreSpotlight | nothing indexed | no CSSearchableItem in the repo | money/body/secret off Spotlight | not built | |
| P2 | Spotlight: IndexedEntity, NSUserActivity | nothing donated | no IndexedEntity, no NSUserActivity | same | not built | |
| P3 | App Shortcuts in Spotlight and Siri suggestions | every routine title, from `suggestedEntities` behind "Start (routine)" | Entities.swift:95-103 (TesseraIntents); App/AppIntentsPackageLink.swift:21 | secret words, money/body off Spotlight | gap (low) | Drop titles where SecretWords.mentions or PrivateFacts.isWalled (as PlanWording.swift:37 does) |
| P4 | Shortcuts and Siri entity picker | exercise class names | Entities.swift:43-53 | same | OK | |
| P5 | Home and Lock Screen widgets | none: the bundle holds only the Live Activity | Widgets/TesseraWidgetsBundle.swift:7 | Lock Screen rules | not built | |
| P6 | App Group shared defaults | look names only (look.day, look.night, look.pinned) | DesignSystem/Looks.swift:121-128 | nothing private in the group | OK | |
| P7 | Live Activity: attributes | workout title (routine title, free text) | Features/Workout/LiveActivity/RestActivityController.swift:59; Widgets/RestLiveActivity.swift:42, 212 | secret/money/body off Lock Screen | unsure | Same filter as P3 on the title, or show "Workout" when it trips |
| P8 | Live Activity: content state | exercise name, set number, planned weight x reps, rest end | RestActivityController.swift:89-94, 108; Shared/RestActivityAttributes.swift:19-25; RestLiveActivity.swift:273, 277, 302 | training is not a body fact (load lifted, not body weight) | OK | |
| P9 | Live Activity alert banner | "Set N is up", exercise and planned set | RestActivityController.swift:146 | same | OK | |
| P10 | Locked Lock Screen redaction | no `.privacySensitive`, `.redacted` or `widgetAccentable` anywhere; always-on uses `isLuminanceReduced` | RestLiveActivity.swift:230-244 | Lock Screen rules | OK today | Rule for any future widget: walled fields get `.privacySensitive` |
| P11 | Live Activity buttons (Done, +15, Skip) and Undo | write sets from a locked phone | Shared/RestIntents.swift:29-70; Intents.swift:172-173 | none broken; unlock policy | unsure | Product call (Q1) |
| P12 | Siri/Shortcuts dialog: Log a Set | the saved set's summary (exercise, sets, load) | Intents.swift:28-31 | training only | OK | |
| P13 | Dialogs: Start, Finish, Undo, Log Next Set | routine title, counts, set number | Intents.swift:50-51, 76, 96, 114 | as P3 for the title | OK | |
| P14 | Dialog: Add a Task | Claude key refused (137); secret with a value becomes a private note, title not echoed (140-142); money or body fact becomes a plain task and is read back | TesseraIntents/Intents.swift:136-145 | money/body off Lock Screen | gap | If PrivateFacts.isWalled(title): save a private note and say "Kept, private." |
| P15 | Dialog: Tell Tess | capture line from Siri's own TessCaptureEngine, which has no Claude route | Intents.swift:161-163; TesseraRuntime.swift:15; TessCaptureEngine.swift:14 | all four rules | OK | |
| P15a | Tell Tess: secrets, key, body facts | key gets a fixed line (TessModel.swift:69-70); secret skips every model route (74-79); private note never repeats the value (TessCaptureEngine.swift:298-300); body fact read as a task first echoes its title (TessGrammar.swift:141; TessCaptureEngine.swift:296) | as cited | money/body off Lock Screen | unsure | Check `parseTask` order against PrivateFacts; walled task lines say "Task added." |
| P16 | Siri on a locked phone | every intent runs locked: no `authenticationPolicy` set anywhere, so P14 and P15 dialogs show and speak on the Lock Screen | grep: zero hits for authenticationPolicy | money/body off Lock Screen | gap | `authenticationPolicy = .requiresAuthentication` on Tell Tess and Add a Task |
| P17 | Shortcuts outputs | no intent returns a value; only dialog strings | Intents.swift (all `ProvidesDialog`) | all | OK | |
| P18 | Control Center and Lock Screen controls | none | no ControlWidget | | not built | |
| P19 | Notifications | none; no UserNotifications import, kitchen timers do not notify | grep | all | not built | |
| P20 | Tess memory marked private | no out-of-app surface reads TessMemory | grep TesseraIntents, Widgets, Shared | private memory stays in | OK | |
| P21 | Claude key | no surface shows the key or its presence; pasted key text gets a fixed line | TesseraCore/Diagnostics/ClaudeKeyGuard.swift:6; Intents.swift:137 | key never out | OK | |
| P22 | Apple Health export | finished workout: start, end, set count, volume, brand; no titles or notes | App/Health/HealthExporter.swift:59-65 | training only | OK | |

Counts: 23 rows. OK 12 (P10 is OK today only), gap 3, not built 5, unsure 3 (P7, P11, P15a).

## Top gaps

1. **P16, Siri runs locked.** No intent sets `authenticationPolicy` (zero hits). Tell Tess and Add a Task write and
   read their line back from a locked phone, so any task title is spoken and shown on the Lock Screen.
2. **P14, Add a Task skips the body/money wall.** TesseraIntents/Intents.swift:136-145 checks the Claude key and
   secret words, not PrivateFacts. "Add a task: took advil 400mg" (or rent 4417) becomes a plain task and is read back
   at line 144. The Ask bar turns a body fact into a private note (TessGrammar.swift:153-157).
3. **P3, routine titles go to Spotlight unfiltered.** RoutineQuery.suggestedEntities (Entities.swift:95-103) feeds
   the parameterized App Shortcut (AppIntentsPackageLink.swift:21), which the system lists in Spotlight. A routine
   titled with a secret word or a body fact would appear there. Low risk today.

## Unsure

- Whether the system's default `authenticationPolicy` is "always allowed" on iOS 27 (P16 assumes it is; not
  checked on a device).
- P15a: whether `parseTask` claims a walled phrase before `parseBodyFact` (TessGrammar.swift:141 tries task first).
- P7: workout titles are free text; no test covers a secret word in one.

## Questions for Product

1. Should Siri and Shortcuts writes (Tell Tess, Add a Task, Undo Last Set) need Face ID when locked, while the Live
   Activity's Done, +15 and Skip stay usable locked?
2. Is the planned set (exercise, weight x reps) fine on a locked Lock Screen and in the alert banner, or should the
   locked face drop to "Set 4 is up"?
3. Should routine and workout titles that trip SecretWords or PrivateFacts be hidden from Spotlight, Siri and the
   Live Activity, or just blocked as titles?
4. Before the first Home or Lock Screen widget ships: which classes may appear at all (tasks, plan, groceries), and
   is `.privacySensitive` on every free-text field the rule?
