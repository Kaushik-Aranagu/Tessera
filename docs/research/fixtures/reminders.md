# Reminder phrases (board item 46)

For: Core (`TessGrammar`, `TessDates`, `TessCaptureEngine`, the `alerts` field), Builder B (lines), Product (open
questions). Research lab, 2026-10-16. Traced by hand on `origin/master` at `2473436` (no Swift toolchain, nothing run).
The grammar files last changed in `82c51d9`, the same code `grammar-regression.md` traced, so its rows still hold.
Reads with `notifications.md` (N1, the `alerts` field, quiet hours, "On Now then."), `late-night.md`,
`day-boundary.md` (C3, C14), `claude-first-uses.md` (use 1), `grammar-regression.md` and `../product/decisions.md`.

## Rules the expected column uses

- **Clock.** Fri 16 Oct 2026 17:40 America/Los_Angeles (PDT) unless the row says otherwise. Store: open task Dentist
  Sat 17 10:00; rows R32 to R34 add "Call mom" Fri 18:00 with `alerts = true` (R34 is said at 18:02, after it rang).
- **alerts** is true when he said a reminder lead (remind me, nudge me, ping me, don't let me forget, set a reminder)
  or gave a clock time, and only when the task has an instant. A date with no time keeps 09:00 and alerts
  (`notifications.md` N1; see open question 1). Later tasks and groceries never alert.
- **Times.** Relative durations are exact (17:40 + 20 min = 18:00). Bare hours follow decision 4:26 PM PT: 1 to 6 PM,
  7 to 11 the next one not yet passed today, 12 noon, passed lands tomorrow. "tomorrow" before 04:00 is the coming
  daytime and the reply names the weekday (6:07 PM PT). "tonight" after 20:00 is the next whole hour until 23:30.
- **Quiet hours** 23:00 to 07:00: every time in this file was set by him, so all ring (`notifications.md` §4).
- **Lines.** Master's `when` format (`TessCaptureEngine.swift:191-214`): "Call mom, today 6 pm." Undo is "Call mom
  taken back." (5:14 PM PT). The first alert-worthy capture of a day may also show the pre-ask "Want me to buzz you at
  6 pm?" (A7); not repeated per row. **No permission** (pending, Not now, denied): the same line plus "On Now then."
  when the task has a time and alerts; otherwise the line is unchanged.
- **Master** is the parse only (action, title, instant). No row is fully built: master has no `alerts` field, no
  notifications and no "On Now then." (`git grep` finds none). **Route** is where the phrase should end up once this
  file's changes land: grammar, or the model (on-device first, Claude Haiku 5.5 with the cloud mark when that fails).

## Rows

| id | said | phrase | expected parse | line, permission | line, no permission | master today | route, why |
|---|---|---|---|---|---|---|---|
| R01 | Fri 17:40 | remind me in 20 minutes | task "Reminder" Fri 18:00, alerts T | Reminder, today 6 pm. | Reminder, today 6 pm. On Now then. | fail: task "In 20 minutes" Later. No "in N" in `TessDates.find` (`TessGrammar.swift:500-527`) | grammar: fixed shape |
| R02 | Fri 17:40 | remind me in 20 minutes to take the chicken out | task "Take the chicken out" Fri 18:00, T | Take the chicken out, today 6 pm. | ... today 6 pm. On Now then. | fail: "In 20 minutes to take the chicken out" Later (B338, RELT) | grammar |
| R03 | Fri 17:40 | remind me in an hour to call mom | task "Call mom" Fri 18:40, T | Call mom, today 6:40 pm. | ... On Now then. | fail: "In an hour to call mom" Later (C424, C425) | grammar |
| R04 | Fri 17:40 | remind me to stretch in half an hour | task "Stretch" Fri 18:10, T | Stretch, today 6:10 pm. | ... On Now then. | fail: "Stretch in half an hour" Later | grammar |
| R05 | Fri 17:40 | remind me in 2h to move the car | task "Move the car" Fri 19:40, T | Move the car, today 7:40 pm. | ... On Now then. | fail: "2h" fails `parseTime` (`:628-645`); "In 2h to move the car" Later | grammar |
| R06 | Fri 17:40 | ping me in 5 | task "Reminder" Fri 17:45, T (bare N after "in" is minutes, cap 180 as cook timers) | Reminder, today 5:45 pm. | ... On Now then. | fail (miss): "ping" is no lead, no date, nil (`:431`), goes to the model | grammar |
| R07 | Fri 23:40 | remind me in 30 minutes to lock the door | task "Lock the door" Sat 00:10, T; rings in quiet hours | Lock the door, Saturday 12:10 am. | ... On Now then. | fail: "In 30 minutes to lock the door" Later | grammar |
| R08 | Fri 17:40 | remind me at 6 to call mom | task "Call mom" Fri 18:00, T | Call mom, today 6 pm. | Call mom, today 6 pm. On Now then. | pass (`:516-518`, 1 to 6 PM `:539-540`; "to" dropped `:425`) | grammar |
| R09 | Fri 17:40 | remind me to call mom at 6 | task "Call mom" Fri 18:00, T | Call mom, today 6 pm. | ... On Now then. | pass (A295 shape) | grammar |
| R10 | Fri 17:40 | remind me at 7 to do push day | task "Do push day" Fri 19:00, T | Do push day, today 7 pm. | ... On Now then. | pass (07:00 passed, 19:00 not, `:541-552`) | grammar |
| R11 | Fri 17:40 | remind me at 5 to pay rent | task "Pay rent" Sat 17:00, T (passed, lands tomorrow) | Pay rent, tomorrow 5 pm. | ... On Now then. | pass (`:554-558`) | grammar |
| R12 | Fri 17:40 | set a reminder for 6 to call mom | task "Call mom" Fri 18:00, T | Call mom, today 6 pm. | ... On Now then. | fail (miss): "6" without "at" is not read, no lead, nil | grammar: add the lead and "for N" after it |
| R13 | Fri 17:40 | Remind me at 6 PM to call Mom. | task "Call Mom" Fri 18:00, T | Call Mom, today 6 pm. | ... On Now then. | fail: "PM" is left in, title "PM to call Mom." (RC11 `7 pm`) | grammar |
| R14 | Fri 17:40 | remind me tomorrow to call mom | task "Call mom" Sat 09:00, T | Call mom, tomorrow 9 am. | ... On Now then. | pass (A224) | grammar |
| R15 | Fri 17:40 | remind me tonight to take my pills | task "Take my pills" Fri 20:00, T | Take my pills, today 8 pm. | ... On Now then. | pass (`:502-507`) | grammar |
| R16 | Fri 21:15 | remind me tonight to take my pills | task "Take my pills" Fri 22:00, T | Take my pills, today 10 pm. | ... On Now then. | fail: 20:00 passed, Sat 20:00 (`:554-558`; late-night #3) | grammar |
| R17 | Fri 17:40 | remind me sat to book the MOT | task "Book the MOT" Sat 09:00, T | Book the MOT, tomorrow 9 am. | ... On Now then. | pass | grammar |
| R18 | Fri 17:40 | remind me next fri to pay rent | task "Pay rent" Fri 23 Oct 09:00, T (5:58 PM PT call 3) | Pay rent, next Friday 9 am. | ... On Now then. | fail: "fri" is today, next hour; "Next to pay rent" Fri 16 18:00 (RC7, A222) | grammar |
| R19 | Fri 17:40 | remind me this weekend to clean the car | task "Clean the car" Sat 09:00, T | Clean the car, tomorrow 9 am. | ... On Now then. | fail: "This weekend to clean the car" Later | grammar |
| R20 | Fri 17:40 | remind me in 3 days to call the bank | task "Call the bank" Mon 19 09:00, T | Call the bank, Monday 9 am. | ... On Now then. | fail: "In 3 days to call the bank" Later | grammar |
| R21 | Sat 00:30 | remind me tomorrow at 9 to call mom | task "Call mom" Sat 09:00, T | Call mom, Saturday 9 am. | ... On Now then. | fail: calendar today + 1, Sun 09:00, line "tomorrow 9 am" (`:510`, day-boundary C3) | grammar |
| R22 | Fri 23:30 | remind me at 2am to take the bread out | task "Take the bread out" Sat 02:00, T; rings in quiet hours | Take the bread out, Saturday 2 am. | ... On Now then. | pass on the parse; line says "tomorrow 2 am" (late-night Q1) | grammar |
| R23 | Sat 01:00 | remind me tonight to call mom | task "Call mom" Sat 20:00, T | Call mom, Saturday 8 pm. | ... On Now then. | pass on the parse; line says "today 8 pm" (`TessCaptureEngine.swift:194`, late-night #9) | grammar |
| R24 | Fri 17:40 | nudge me tomorrow | task "Reminder" Sat 09:00, T | Reminder, tomorrow 9 am. | ... On Now then. | fail: "nudge" is no lead, title "Nudge me" Sat 09:00 | grammar |
| R25 | Fri 17:40 | ping me at 8 about the parcel | task "The parcel" Fri 20:00, T | The parcel, today 8 pm. | ... On Now then. | fail: title "Ping me about the parcel" (time right) | grammar |
| R26 | Fri 17:40 | don't let me forget to take my pills tonight | task "Take my pills" Fri 20:00, T | Take my pills, today 8 pm. | ... On Now then. | fail: title "Don't let me forget to take my pills" | grammar |
| R27 | Fri 17:40 | remind me later to call mom | task "Call mom" Later, alerts F (no instant) | Call mom, in Later. | Call mom, in Later. | fail: title "Later to call mom" | grammar |
| R28 | Fri 17:40 | remind me later | no write | Remind you about what? | Remind you about what? | fail: task "Later" in Later | grammar: empty title after "later" |
| R29 | Fri 17:40 | remind me when I get home to take the bins out | task "Take the bins out" Later, F | Take the bins out, in Later. No place reminders yet. | same | fail: title "When I get home to take the bins out" | grammar: no geofence; the model can't place it either, so Claude would cost money for the same honest line |
| R30 | Fri 17:40 | remind me when I leave work to buy eggs | groceries [Eggs] | Eggs, on the list. No place reminders yet. | same | fail: task "When I leave work to buy eggs" Later | grammar (R35 rule) |
| R31 | Fri 17:40 | remind me every sunday to plan the week | task "Plan the week" Sun 18 09:00, T (first one only) | Plan the week, Sunday 9 am. Once, not weekly yet. | ... Once, not weekly yet. On Now then. | fail: title "Every to plan the week" Sun 09:00 | grammar; repeats wait for Upkeep |
| R32 | Fri 17:40 | cancel the 6pm reminder | SetTaskAlerts Call mom false (task kept) | Call mom, no alert. Undo: Call mom taken back. | same | fail: task "Cancel the reminder" Fri 18:00 ("6pm" read, `:519`). "6 pm" with a space misses instead | grammar: one open alerting task at that time or title |
| R33 | Fri 17:40 | move the call mom reminder to 7 | reschedule Call mom Fri 19:00, alerts kept T | Call mom, today 7 pm. | ... On Now then. | fail (miss): bare "7" after "to" not read, nil (`:158`, `:92`; C387, RC13); "reminder" also blocks the title match (`:163-166`) | model until the RC13 batch (Claude's `rescheduleTask`, claude-first-uses use 1), then grammar |
| R34 | Fri 18:02 | remind me again in 10 | MoveTask Call mom Fri 18:12, T (the alert that fired in the last 30 min) | Call mom, today 6:12 pm. | ... On Now then. | fail: task "Again in 10" Later | grammar: needs the last fired alert in `TessContext` |
| R35 | Fri 17:40 | remind me to buy eggs | groceries [Eggs] (food, no time: the list is where he sees it at the shop) | Eggs, on the list. | same | fail: task "Buy eggs" Later (`TessGrammar+Kitchen.swift:34` skips kitchen for "remind") | grammar; open question 3 |
| R36 | Fri 17:40 | remind me to buy eggs at 6 | task "Buy eggs" Fri 18:00, T | Buy eggs, today 6 pm. | ... On Now then. | pass (A295) | grammar |
| R37 | cook, 18:00 | remind me in 20 minutes to take the chicken out | timer "Take the chicken out" 20, linked (D464); N3, not N1 | Take the chicken out, 20 min. | ... 20 min. Timers alert in the app only. | fail: task "In 20 minutes to take the chicken out" Later (D464, RC15) | grammar |
| R38 | Fri 17:40 | uh remind me to um call the dentist tomorrow | task "Call the dentist" Sat 09:00, T | Call the dentist, tomorrow 9 am. | ... On Now then. | fail: no lead at word 1, title "Uh remind me to um call the dentist" | grammar after the spoken normaliser drops uh/um (NRM) |
| R39 | Fri 17:40 | remind me to call mom at 6, actually 7 | task "Call mom" Fri 19:00, T | Call mom, today 7 pm · via Claude | ... On Now then. | fail: "Call mom actually 7" Fri 18:00; grammar claims it, so no model sees it | Claude: a self-correction needs judgement; grammar must return nil on actually / I mean / no wait |
| R40 | Fri 17:40 | remind me at quarter to 7 to call mom | task "Call mom" Fri 18:45, T | Call mom, today 6:45 pm · via Claude | ... On Now then. | fail: "quarter" is no clock, title "At quarter to 7 to call mom" Later | Claude: spoken clock forms are use 1's "task times"; grammar returns nil on quarter / half past in a remind phrase |

## Totals

| | rows |
|---|---|
| Master parse pass | **10** (R08 to R11, R14, R15, R17, R22, R23, R36); R22 and R23 still need the weekday line |
| Master wrong write | **27** |
| Master miss (nil, goes to the model today) | **3** (R06, R12, R33) |
| Route: grammar | **37** |
| Route: model, ending at Claude | **3**: R39 and R40 by design, R33 until Core's RC13 reschedule batch |
| alerts true / false / no task | 31 / 3 (R27, R29, plus R32 turning one off) / 6 (R28, R30, R35, R37 timer, R33 and R34 keep or move an existing one) |

## Grammar changes Core needs (smallest first by rows fixed)

1. **`alerts` on the parse.** `Parse.task(title:startsAt:alerts:)`, true for a reminder lead or a clock time; "tonight"
   alone is not a clock time, so `Found` needs `saidClock` apart from `saidTime` (`:505-506`). Model writes get it from
   Core reading the text, never from the model (`notifications.md` Q3). Reply adds "On Now then." when `alerts`,
   `startsAt` set and not authorized (`TessCaptureEngine.swift:109`). All 31 alerting rows.
2. **Relative times in `TessDates`.** "in N min/minutes/mins/m", "in N h/hr/hours", "in an hour", "in half an hour",
   "in N days" (09:00), and bare "in N" after a lead as minutes (cap 180). R01 to R07, R20, R34, R37 (with the cook
   rule of D464). Also closes `notifications.md` conflict 5 and grammar-regression RELT.
3. **Leads.** Add nudge, ping, alert, "don't let me forget (to)", "set a reminder (for|to)" to `:411`; drop "about"
   after the lead; "later" after the lead means Later, no alert, and an empty title means "Remind you about what?".
   R12, R24 to R28.
4. **am/pm as its own word** after a number ("6 PM", "6:00 PM.", "p.m."). R13 (RC11).
5. **Day words.** "next <weekday>" is next week's; "this weekend" is Saturday 09:00; "every <day|morning>" is the
   first one with the "Once, not weekly yet." line. R18, R19, R31.
6. **The 04:00 day and "tonight".** C3 at `:510`, the 20:00 to 23:29 window at `:502-507`, and the weekday in the
   reply from 00:00 to 03:59 (C14). R16, R21, R22, R23.
7. **Place phrases.** Strip "when I get home / leave work / get to X", Later, alerts false, "No place reminders yet."
   R29, R30.
8. **"remind me to buy" food with no day or time is groceries**: `TessGrammar+Kitchen.swift:34` skips kitchen for
   "remind" only when a day or time is said. R30, R35 (R36 stays a task).
9. **Alert edits.** "cancel/turn off the <time or title> reminder" sets `alerts` false on exactly one open alerting
   task (new `SetTaskAlerts`, undoable); "again in N" moves the task whose alert fired in the last 30 min. R32, R34.
10. **Guards to the model.** Return nil for a remind phrase holding actually / I mean / no wait, or quarter / half
    past. R39, R40. Plus the normaliser's filler drop (R38) and RC13's bare hour after "to" (R33).

## Open questions (recommended default first)

1. **09:00 for a date with no time.** Decision 6:20 PM PT says "a task with no time is never saved as 9:00", while
   `notifications.md` N1 keeps 09:00 and alerts for "remind me". Default: "remind me" plus a day alerts at 09:00 (else
   he is never buzzed); a plain "call mom sat" is dated with no time and alerts false. Product to confirm.
2. **Title with no subject** ("remind me in 20 minutes", "nudge me tomorrow"). Default: "Reminder". Asking "About
   what?" costs a turn when the buzz alone is the point.
3. **"remind me to buy eggs".** Default: groceries, as `buy` stays Groceries (4:26 PM PT call 3), with a time it is a
   task (R36). Alternative: keep master's task "Buy eggs" in Later, which he only sees in the app.
4. **Place reminders.** Default: Later, no alert, the honest line. A geofence needs Always location, a new ask and
   more battery; revisit only if he says it often.
5. **Repeats.** Default: the first one only, with the line; real repeats come with Upkeep's intervals.
6. **Relative reply wording.** Default: the clock ("today 6 pm"), so he can check the instant; "in 20 min" drifts.
7. **Cancel.** Default: keep the task and drop its alert; "delete the call mom task" stays a separate phrase.
8. **"again in N" with no recent alert.** Default: nil to the model, which has no tool for it, so the miss line.
9. **"next Friday" in replies.** Master's `when` prints "Friday 9 am" for 23 Oct, which reads as today on a Friday.
   Default: "next Friday" when the date is 7 or more days away and the weekday matches today's.
