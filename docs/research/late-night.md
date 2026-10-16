# Late-night use walk, 23:00 to 03:00 (board item 39)

Traced by hand on `origin/master` at `582700b` (no Swift toolchain). **Assumption:** every fix in `day-boundary.md` has
landed: the public `TesseraDay` helper (day runs 04:00 to 04:00, DST-safe), #165's four (`TaskList.today`, `week`,
`finishedWorkouts`, `DayLoad`), C1 to C20, A1 to A4 and B1 to B4. Section 3 of that file stays as it is (backup names,
"today"/"tonight", typed weekdays stay calendar). The question here is what is **still** wrong after all that.

Also read: `light-day.md`, `ask-lines.md`, `undo-lines.md`, `empty-states.md`, `lockscreen-lines.md`,
`fixtures/grammar-regression.md` (tonight/tomorrow rows), `../product/decisions.md`.

Running night: Friday 16 Oct 2026, Los Angeles. Push A starts 22:50 and ends Sat 00:40. "Pay rent" is set for Fri 23:00
and not done. Logical day until Sat 04:00 is **Friday**.

## Scenes

### S1. 22:50 to 00:40, Push A across midnight
**He does:** logs sets on both sides of midnight, hits a bench PR at 00:05, rests with the phone locked, finishes 00:40.
**Master after TesseraDay:** sets carry their own timestamps; PR hints compare against history, no day test. The
workout's date is `endedAt` (Sat 00:40), which `TesseraDay` files under Friday, so Home, Review, the month cell and
weekly sets all count it on Friday (C11 to C13, A1 to A3, B2). The rest Live Activity has no day logic and its alert
("Set 4 is up") rings with sound, which is right while he trains. After the finish Home shows DoneHero.
**He expects:** all of that, and a hero that reads like a person.
**Still wrong:**
- DoneHero says **"trained this night"** and Training says "done this night" (`SpokenTime.partOfDay` returns "night"
  for 22:00 to 04:59). Day-boundary noted this as a copy wart, outside its 28. Owner **Builder B**,
  `Features/Home/NowPage.swift:313` and `Features/Home/TrainingPage.swift:265`: map "night" to "tonight".
- If he goes Home mid-session after 23:00, Tess's glyph shows **resting** ("Tess is resting" in VoiceOver) while a
  workout runs. Owner **Builder B**, `Features/Command/BottomChrome.swift:92-95`: resting only when
  `model.session == nil`.

### S2. 23:10, "call mum tonight"
**Master after TesseraDay:** `TessGrammar.swift:502-507` sets today 20:00; that time has passed, so the passed-time
rule (`:554-558`) moves it to **Sat 20:00**. Unchanged by TesseraDay ("tonight" stays calendar).
**He expects:** tonight, soon. The 4:41 PM and 5:58 PM decisions say "tonight" said after 20:00 stays today until
23:30. Master breaks that from 20:00 to 23:30 (grammar-regression open question 2 flags it too).
**Verdict:** still wrong. Owner **Core**, `TessGrammar.swift:502-507`: when "tonight" has no time and now is 20:00 to
23:29, use the next whole hour today. From 23:30 to 03:59 keep master's Sat 20:00 (see S3).

### S3. 01:00, "call mum tonight", "dentist today 3pm", "dentist tomorrow 3pm"
**Master after TesseraDay:** "tonight" gives Sat 20:00 (calendar today, 20:00 not passed). "today 3pm" gives Sat 15:00.
"tomorrow 3pm" now gives Sat 15:00 too (C3: logical Friday + 1). The reply (C14) compares logical days, so all three
read "Dentist, tomorrow 3 pm." or "Call mum, tomorrow 8 pm."
**He expects:** the coming Saturday for all three. The dates are right.
**Still wrong (low):** he said "today" and Tess answers "tomorrow". After midnight both words are ambiguous, so the
reply should name the day. Owner **Core**, `TessCaptureEngine.swift:191-215` (`when`): when now is 00:00 to 03:59
and the date is not on the logical today, say the weekday: "Dentist, Saturday 3 pm." Same for Home's swipe line,
owner **Builder B**, `HomeQueue.swift:394`: "Pay rent, Saturday 11 pm." (also meets the undo-lines naming rule).

### S4. 00:30, "remind me tomorrow at 9"
**Master after TesseraDay:** C3 makes "tomorrow" Saturday; bare 9 on another day is AM (`TessGrammar.swift:530-552`,
`hourToday` false), so the task is **Sat 09:00**, reply "Call mum, tomorrow 9 am." The human reading (before 04:00,
"tomorrow" means the coming daytime) is what master now does. Model path: C5 tells the model it is still Friday.
**He expects:** a buzz at 9.
**Still wrong:** master has **no notification code at all** (ask-lines A7: "Not built"). "Remind me" writes a task he
only sees if he opens the app. Owner **Core** (notifications behind the quiet-interrupts mask) with **Builder B** for
the ask line. Smallest honest fix until then: when the phrase starts "remind me", the reply says where it lives:
"Call mum, Saturday 9 am. On Now then." (`TessCaptureEngine.swift:106-109`). See Q4.

### S5. 00:30, bare hours: "call mum at 9", "at 1", "at 12"
**Master after TesseraDay:** "at 9": today is calendar Saturday, 09:00 has not passed, so **Sat 09:00**. "at 1":
1 to 6 mean PM, **Sat 13:00**. At 23:30 Fri, "at 12" is noon, passed, so **Sat 12:00**; "at 11" at 23:10 gives
**Sat 11:00**.
**He expects:** all of these, given the bare-hour decision. "at 1" at 00:30 could mean 30 minutes from now, but the
decision says PM and the ghost row shows "Saturday 1 pm", so a wrong pick is one tap.
**Verdict:** right. "midnight" is not a time word yet (`parseTime`, row C439 miss); Core's grammar batch already has it.

### S6. 01:00, Not now on Pay rent and on an undated row
**Master after TesseraDay:** C2 gives base `max(Fri 23:00, Fri 04:00)`, plus one logical day: **Sat 23:00**, line
"Moved to tomorrow." B1 sends the undated row to next Fri 09:00, "Moved to next week."
**He expects:** exactly that. **Verdict:** right, with two leftovers:
- `MoveTask` reads `.now`, not the app clock (`Tasks.swift:118`, undo-lines B14), so a `-demoTime 01:00` demo still
  moves from the real hour. Owner **Core**: take `time` as an input defaulting to `.now`; the app passes `AppClock.now`.
- **The 04:00 roll never runs on master.** `TaskList.rollForward(engine:)` (`RollForward.swift:86`) has no caller in the
  app. If he does not tap Not now, Pay rent stays at Fri 23:00 for ever as "carried from Fri", `rolls` never counts and
  nothing goes to Later after 7. Day-boundary's X7 ("the one place that is right") never happens on the phone. Owner
  **Core**: call it from `AppModel.tidyProcesses` (`App/AppModel.swift:240-260`, runs on every foreground) and put its
  line in `processNotes`.

### S7. 00:15, Review
**Master after TesseraDay:** C16 to C18 put the window on logical days: Sat 10 04:00 to now, seven dabs Sat to Fri,
Friday labelled "today". Push A, still running, does not count yet; at 00:41 Friday's dab fills. The hero is still
WeekReview's "Four good days of seven" over a rolling 7 days, labelled "the week so far".
**He expects:** Friday is today; the session counts once finished. **Verdict:** right for the night. The rolling window
under a "week" label is a daytime issue already in Builder B's Review week fix (4:58 PM decision).

### S8. 02:00, Day log entry
**Master:** no Day log yet (Core's `DayStory`, Builder B's page). A note typed at 02:00 is stored with `createdAt`
Sat 02:00; "watered plants today" now writes a note dated Fri 12:00 (C4).
**He expects:** both on Friday's page, with Push A.
**Guard for the build (not counted):** `DayStory` must bucket by `TesseraDay.day(of:)` from its first commit; a
past-dated note goes on its `on` date, not its `createdAt` day ("watered plants yesterday" at 01:30 belongs to
Thursday); and `day-log-first.md` says a workout belongs to the day it **started** while the ledger dates it by
**end**. Only a session crossing 04:00 differs (see Q7). Owner **Core**.

### S9. Backups' daily copy: open at 00:10 vs 04:10
**Master:** `BackupKeeper.runDaily` runs on the first move to the background each **calendar** day and names the file
by calendar date (kept on purpose, day-boundary section 3). Seven files are kept.
- Used Fri 22:35, again 00:10: Fri copy at 22:35 (before Push A), **Tessera-2026-10-17** at 00:15 holding Friday
  night. Nothing more is written until Sun 00:xx, so Saturday daytime work waits about a day. Same for any rhythm.
- Not opened between 00:00 and 04:10: the Sat copy is taken at 04:10. Same name either way. Seven dailies still
  cover seven days. **Verdict:** names and count are fine. Still wrong:
- At 00:10 Backups says **"the last one yesterday"** for a copy made 95 minutes ago. To him yesterday is Thursday.
  Owner **Core**, `Features/Backup/BackupView.swift:274-280`: under 12 hours, say the clock ("the last one at
  10:35 PM"); also `isDateInYesterday` ignores `now`, so pass the app clock.
- **"Save a copy" names the file in UTC**: `.iso8601` defaults to GMT, so from 17:00 PT the shared file reads
  tomorrow (Fri 23:00 saves **Tessera-2026-10-17**). Same for the restore undo file "Before-restore-...".
  Owner **Core**, `BackupKeeper.swift:77` and `TesseraBackup.swift:199-200`: set `.timeZone(.current)` or build the
  name from calendar components as `writeRolling` does.
- The first lock after midnight is usually **mid-session** for him (locking in a rest), so the daily copy is often a
  half workout, written on the main actor during a rest. Owner **Core** (low), `App/TesseraApp.swift:73-76` and
  `BackupKeeper.runDaily`: skip while a workout process is running; the next background after the finish takes it.

### S10. 04:30, the 6 h wrap-up of a workout he left
**Case:** at 22:30 he opens Push A, logs 2 sets or none, gets distracted and goes to bed. Phone on the nightstand.
**Master:** nothing runs while suspended. At the next open after 04:30, `tidy` wraps it up with `endedAt` = last touch
(22:30, logical Friday), so Friday counts it.
**He expects:** it quietly saved on Friday, and told once. **Still wrong:**
- The wrap-up line ("Saved Push A, 1 of 6 exercises") goes into `processNotes`, which nothing shows (undo-lines B11).
  Owner **Builder B**, `App/AppModel.swift:252`: show it once as Tess's line.
- A **zero-set** opened workout is wrapped up and saved, so Friday reads "trained" against the 5:14 PM decision
  ("no sets, not saved"). Owner **Core**, `ProcessTable.swift:122-128`: if no entry has a logged set, end the
  process and delete the workout instead of `FinishWorkout`.
- The **rest Live Activity** stays on the Lock Screen all night reading "Set 3 is up · Go", since the ready state has
  no stale date (`RestActivityController.swift:116-118`) and the app never wakes to end it. He sees it at 07:00.
  Owner **Builder A**: give the ready state a `staleDate` of last set plus the idle limit (rest plus 10 min) and draw
  stale as "Push A, set aside" with no Go.
- Known elsewhere, not counted: the Health sheet can appear at that 04:30 open, from a background finish
  (ask-lines A1, rule 6, Core).

### S11. Now at 03:55 vs 04:05
**03:55, logical Friday:** Push A finished at 00:40, so DoneHero (S1 copy). Day strip reads "Friday night" (B2).
Right. **04:05, logical Saturday:** DoneHero leaves; Home offers Pull A (plan rolls on), or the "Rest day" line if
Saturday is a planned rest. Right. Two leftovers:
- If Push A was **left open** (S10), `findTonightWorkout` (`App/AppModel.swift:421-428`) uses a ±12 h window, so from
  04:00 until the 6 h wrap Saturday's Now offers **Friday's half-done Push A** and hides Pull A. Owner **Core**
  (rule) with Builder B (call site): skip a started workout whose `startedAt` is on an earlier logical day; it stays
  in the ledger as set aside. See Q5.
- `DayPart(hour:)` calls 00:00 to 03:59 **early** (`NowRanker.swift:28-38`). A task at 02:00 gets "Your early slot"
  as its why at 01:30, and late-evening tasks lose the day-part bonus at midnight. Owner **Core** (low): 00 to 03 is
  `.late`, `.early` is 04 to 06.

### S12. Notifications, quiet hours, Tess's voice at 2 AM
**Master:** no notifications, so nothing can buzz at night; the only sound is the rest-end alert during a live set,
which is right. Tess has no greeting anywhere (no "Good morning"/"Good night" string in the app), and the Shutdown
late-night F rows ("Filed under Friday.") are research only. **Verdict:** right today. When notifications land
(Core), quiet-interrupts' hold rule must also hold `normal` and `low` items from 23:00 to his first open after 04:00,
and a task reminder set for 02:00 is the only thing allowed through. Guard, not counted.

## Still wrong after TesseraDay

| # | Scene | What | Owner | Smallest fix | File:line | Sev. |
|---|---|---|---|---|---|---|
| 1 | S6 | 04:00 roll never runs; carried tasks pile up, never reach Later | Core | Call `TaskList.rollForward` from `tidyProcesses`, show its line | `App/AppModel.swift:240-260`; `RollForward.swift:86` | high |
| 2 | S4 | "remind me ... at 9" makes no reminder (no notifications) | Core (+B line) | Reply says "On Now then." until notifications ship | `TessCaptureEngine.swift:106-109` | high |
| 3 | S2 | "tonight" at 20:00 to 23:29 rolls to tomorrow 20:00 | Core | Next whole hour today in that window | `TessGrammar.swift:502-507, 554-558` | med |
| 4 | S10 | Zero-set wrap-up saved as trained | Core | Drop the workout when no set is logged | `ProcessTable.swift:122-128` | med |
| 5 | S11 | Left-open Push A offered as Saturday's workout after 04:00 | Core (+B) | Ignore a started workout from an earlier logical day | `App/AppModel.swift:421-428` | med |
| 6 | S9 | "Save a copy" and "Before-restore" names in UTC | Core | `.timeZone(.current)` or calendar components | `BackupKeeper.swift:77`; `TesseraBackup.swift:199-200` | med |
| 7 | S9 | "the last one yesterday" for a 95-minute-old copy | Core | Under 12 h say the clock; use `now` | `BackupView.swift:274-280` | low |
| 8 | S9 | Daily copy taken mid-session at the first lock after midnight | Core | Skip while a workout runs | `App/TesseraApp.swift:73-76` | low |
| 9 | S3 | Reply says "tomorrow" when he said "today" after midnight | Core | Weekday name 00:00 to 03:59 | `TessCaptureEngine.swift:191-215` | low |
| 10 | S11 | 00:00 to 03:59 ranked as "early" | Core | 00 to 03 is `.late` | `NowRanker.swift:28-38` | low |
| 11 | S6 | `MoveTask` ignores the app clock | Core | `time` input, app passes `AppClock.now` | `Tasks.swift:116-119` | low |
| 12 | S10 | Rest Live Activity says "Go" all night after an abandoned session | Builder A | `staleDate` on ready; stale draws "set aside" | `RestActivityController.swift:116-118` | med |
| 13 | S10 | Wrap-up line never shown | Builder B | Show `processNotes` once as Tess's line | `App/AppModel.swift:252` | med |
| 14 | S1 | "trained this night" / "done this night" | Builder B | "night" reads "tonight" | `NowPage.swift:313`; `TrainingPage.swift:265` | low |
| 15 | S1 | Tess glyph resting during a live workout after 23:00 | Builder B | Resting only with no session | `BottomChrome.swift:92-95` | low |
| 16 | S3 | "Moved to tomorrow." after midnight | Builder B | Name the task and weekday | `HomeQueue.swift:394` | low |

**By owner:** Core 11, Builder A 1, Builder B 4 (16). Not counted: Day log and notification guards (S8, S12), the
Health ask from a wrap-up (ask-lines A1), and "midnight" as a time word (grammar batch).

**Worst:** #1. The 04:00 roll is the only code that already knows his day, and no screen calls it, so every unfinished
late task stays "carried" for ever. Close second: #2, the most natural thing to say at 00:30 lands on the right date
and then nothing reminds him.

## Open questions (recommended default first)

1. **"tomorrow" before 04:00.** Default: the coming daytime (Saturday at 01:00), as C3 does. "tomorrow at 2am" said
   at 23:30 or 00:30 is the next 02:00, which is still logically today; the reply names it ("Saturday 2 am").
2. **Where "tonight" ends.** Default: 20:00 to 23:29 means tonight (next whole hour); 23:30 to 03:59 means the coming
   evening at 20:00, as master does now. Needs a 21:00 and a 23:45 row in the regression table.
3. **Bare 1 to 3 after midnight.** Default: keep the decision (PM). The ghost row's "Saturday 1 pm" makes a wrong pick
   one tap.
4. **Reminders.** Default: "remind me" with a time becomes a local notification once A7 is granted, and A7's trigger
   also fires on his first "remind me ... at" (still one ask a day). Until then the reply says "On Now then."
5. **A workout left open across 04:00.** Default: keep the 6 h wrap, but after 04:00 it no longer counts as today's
   workout (#5). Wrapping at the day change is the stronger option if #5 still feels wrong.
6. **Backup file names.** Default: stay calendar dates (true timestamps); the screen shows clock times when recent.
7. **Which day owns a session crossing 04:00.** Default: the logical day it started, for both the Day log and the
   ledger; the ledger change waits until it happens once for real.
