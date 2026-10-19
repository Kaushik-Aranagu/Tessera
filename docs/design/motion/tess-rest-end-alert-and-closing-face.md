# Rest-end alert and the closing face (Live Activity)

Lab spec with Normal / Reduce Motion (RM) / Low Power (LP) columns. Docs only; Builder A builds from the rows. Low Power = Reduce Motion everywhere (150 ms crossfade where we draw anything). Rulings: decision, 8:09 AM PT Oct 19, hunt 26 CALL 1 A and CALL 7 A (`docs/research/fixtures/gap-hunt-26-widgets-live-activities.md`, WL16, WL17, WL29). Extends `tess-live-activity-lockscreen-widget-motion.md` sections 2 and 4 (its "Resolve it so" paragraph and the 60 s "all sets in" row).

Lab defaults are marked. Everything else is a ruling or an existing lab row.

## 1. Rest-end alert (CALL 1 A)

One alert path: a local notification. The Live Activity carries no alert.

| Moment | Normal | Reduce Motion | Low Power | Sound / haptic |
|---|---|---|---|---|
| Rest starts | one local notification is scheduled at `restEndsAt`; nothing is drawn for it | same | same | none |
| +15 | the notification is cancelled and rescheduled to the new `restEndsAt` in the same write that moves the countdown | same | same | none (`+15` has no haptic of ours) |
| Skip, a logged set, End workout | the notification is cancelled | same | same | none |
| T0, phone locked or app in the background | the notification rings: title "Timer", body "Rest is up". The activity flips to Go by `staleDate`, a system transition, nothing of ours | same | same; a scheduled notification costs nothing at rest | the notification's own sound and vibration; no in-app haptic |
| T0, workout in front, seen live within 2 s | the app's own Go moment; no notification shows (cancelled when the app sees the end live) | page crossfade 150 ms | as RM | `.timeUp` once, no sound |
| T0, notifications off | no notification; the activity's flip is the only signal | same | same | none from us |
| Quiet hours (23:00 to 07:00) | a rest he started rings at any hour; quiet hours hold only what Tess starts (WL17) | same | same | the notification's setting |
| VoiceOver | the notification reads "Timer, Rest is up"; the activity flip announces nothing of ours | same | same | n/a |

Wording is fixed and never carries the exercise name: title "Timer", body "Rest is up" (so there is nothing to mask and nothing private on a locked screen).

Removed in the same PR: the ActivityKit `AlertConfiguration` (`RestActivityController.swift:53, 149-154`), whose title was "Set N is up" and whose body named the exercise unmasked.

Lock Screen and Dynamic Island: the activity keeps its resting face, the Go flip at `staleDate`, and the +15 / Skip / Done keys. Nothing new is drawn for the alert; the Island does not expand or pulse for it (the system owns that motion).

### Build checks (Builder A)

1. `restEndRingsOnceAndNeverFromTheActivity`: one notification at `restEndsAt`; no `AlertConfiguration` in any update.
2. `restNotificationFollowsExtendAndSkip`: +15 moves it, Skip, a logged set and End workout cancel it.
3. `restNotificationHasFixedWords`: title "Timer", body "Rest is up", no exercise name.
4. `restEndSeenLiveRingsNoNotification`: a rest seen ending in front plays `.timeUp` once and no notification shows.
5. `restNotificationIgnoresQuietHours`: scheduled at 23:30, it still rings.
6. Grep: no `AlertConfiguration` in `RestActivityController.swift`.

## 2. The closing face when the last set logs (CALL 7 A)

When the final set logs, the activity does not end at once. It shows one still face for about a minute, then ends.

| Moment | Normal | Reduce Motion | Low Power | Haptic / sound |
|---|---|---|---|---|
| Last set logs | the resting face changes to the closing face: the line "<title>, ready to finish" (for example "Push A, ready to finish"), no countdown, no horizon, no keys | the same swap, a system crossfade | same as RM; no timer runs on it, so it costs nothing in Low Power | none from the activity (the app's own `.done` for the set is unchanged) |
| The minute | the face stays still; nothing animates (lab default: 60 s, from the set's log time, ended by one scheduled end) | same | same | none |
| After the minute | the activity ends with the default system dismissal | same | same | none |
| He finishes the workout in the app first | the activity ends at once with the workout | same | same | none |
| Undo of the last set (within its 10 s) | the face goes back to the resting face and the minute is cancelled | same | same | `.undo` only if the app is in front |
| Private title | the title is the masked form from the one private-text function; on the Lock Screen that reads "Private exercise" (CALL 2 A, decision 1103), so "Private exercise, ready to finish" | same | same | none |
| VoiceOver | the face reads "<title>, ready to finish"; no live region, no announcement of ours | same | same | n/a |

The face carries no keys: Done, +15 and Skip are gone with the last set, so no tap target competes with the app. Tapping the card opens the app to the workout wrap-up.

### What Home says at the same moment

Ruled by Product (Oct 19, 10:51 AM PT, mirror `decisions.md` line 1113; mirror only, the repo copy does not have it yet): Home's Training line stays "Ready to finish", and the closing face reads what Home reads at that moment: "<title>, ready to finish" with the masked title. Tess's line and Home never disagree, so the face never says "done" or "finished". The 60 s length stands.

### Build checks (Builder A)

1. `lastSetLeavesAClosingFaceOrSaysWhy`: after the last set, the activity is still alive with the closing face.
2. `closingFaceEndsAfterAboutAMinute`: one scheduled end, no repeating timer on the face.
3. `closingFaceEndsWithTheWorkout`: finishing in the app ends it at once.
4. `closingFaceUndoRestoresResting`: undo within 10 s returns to the resting face and cancels the end.
5. `closingFaceIsMasked`: a private title reads the masked form.
6. Grep: no `withAnimation` or `.animation(` in `Widgets/`.

## Asks

- **Design:** wording check on "Private exercise, ready to finish" for a masked workout title.

(Product's two asks, the length and Home's line, are ruled; see above.)
