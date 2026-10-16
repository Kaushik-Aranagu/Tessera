# Habits and body weight: one week after the privacy calls (board item AI)

For: Builder B (Habits UI, Home), Builder A (body weight, Health), Core (grammar, router, privacy walls, the 4 am
day). Research lab. Date: Oct 16, 2026 (Pacific). Master `cb9b1d7`, read by hand from `origin/master`. Nothing was
built or run. The pin `a36b161` has the same code in every file cited here except `AppModel.swift` (6 lines higher on
the pin) and `ReviewWeek.swift`.

A 7-day walk, Mon Oct 19 to Sun Oct 25 (PDT all week; the clocks change Nov 1), of habits and weigh-ins as Kaushik
would use them now that #451 (PrivateFacts, MU2 + A2) and #471 (privacy follow-ups) are on master. The rule this walk
checks first: body facts (weight, vitals, sleep, medicines, symptoms, and the no-number health words) never go to
Claude, and Tess still reads them on the phone.

This file doesn't repeat the phrase suites. It links them:
- Habit phrases: [`habits-grammar.md`](habits-grammar.md) (L819 to L848, HP1 to HP7).
- Logs that fill habits: [`habits-from-logs.md`](habits-from-logs.md).
- The first week with habits: [`../habits-first-use.md`](../habits-first-use.md).
- Weigh-in phrases: [`body-weight.md`](body-weight.md) (M849 to M873, BP1 to BP6).
- Every line and empty state: [`../m3-lines.md`](../m3-lines.md) (B1 to B16, T1 to T16, H1 to H12, A1 to A20).
- Review with habits and weight: [`review-m3.md`](review-m3.md).
- Day marks: [`day-marks.md`](day-marks.md) (DM1 to DM16, D1 to D26).
- The privacy walls: [`money-body-wall.md`](money-body-wall.md), [`siri-privacy-parity.md`](siri-privacy-parity.md),
  [`spotlight-widgets-privacy.md`](spotlight-widgets-privacy.md), [`secret-words.md`](secret-words.md).
- Health reads: [`../calendar-health-fixtures.md`](../calendar-health-fixtures.md) (H16) and
  [`../healthkit-reads.md`](../healthkit-reads.md).
- Undo and receipts: [`../undo-windows-audit.md`](../undo-windows-audit.md) and
  [`../receipts-thing-first.md`](../receipts-thing-first.md).
- Quiet hours and late nights: [`../quiet-interrupts.md`](../quiet-interrupts.md),
  [`asks-after-close.md`](asks-after-close.md) and [`../day-log-late-night.md`](../day-log-late-night.md).

## Counts

| Status | Steps | Which |
|---|---|---|
| pass | 8 | HW2, HW20, HW22, HW32, HW33, HW34, HW35, HW36 |
| wrong (built, not as ruled) | 7 | HW7, HW11, HW15, HW17, HW18, HW25, HW29 |
| miss (a rule, nothing does it) | 3 | HW9, HW13, HW19 |
| not built | 20 | HW1, HW3, HW4, HW5, HW6, HW8, HW10, HW12, HW14, HW16, HW21, HW23, HW24, HW26, HW27, HW28, HW30, HW31, HW37, HW38 |
| **Total** | **38** | |

The short version:
- Master has no habit code and no body weight code. There's no `Habit`, `HabitCheckIn`, `BodyWeight` or `LogBodyWeight`
  in Swift. `TessTools.swift:91-243` has no habit or weight tool, and the Habits page, the body page, the Shutdown
  check-in and Review's habit lines don't exist.
- The privacy wall does hold for weigh-ins. Every bare or unit weigh-in he types becomes a private note on the phone,
  and the router never sends it to Claude.
- Three leaks or near-leaks remain. "feeling sick, no gym" still reaches Claude (HW19). Siri's Add a Task saves a
  weight as a task and reads it back (HW13). A past-tense weigh-in becomes an ordinary note (HW11).

## Gaps by owner

**Core** (grammar, router, privacy walls, the 4 am day)

| # | Gap | Steps | Where on master | Board |
|---|---|---|---|---|
| C1 | "sick" isn't in the body screen, so "feeling sick, no gym" goes to the model chain and to Claude when the switch is on | HW19 | `PrivateFacts.swift:55-58` (no "sick"), `TessModel.swift:77-79` | DG3, `core.md` day marks |
| C2 | Siri's Add a Task skips PrivateFacts. It saves "weighed 82.2" as a task and says `Added "weighed 82.2"` | HW13 | `Intents.swift:136-146`, `TrainingActions.swift:445` | P14 (0l), not in the pin |
| C3 | Siri writes don't ask for Face ID | HW9 | `Intents.swift:118`, `:149` (no `requiresAuthentication`) | P16 (0l) |
| C4 | A past-tense weigh-in ("weighed 82.3 yesterday") becomes an ordinary dated note "82.3", because parsePastLog runs before the body check | HW11 | `TessGrammar.swift:126`, `:141`, `:322-331` | 0l-2, 0j R1 |
| C5 | No day mark. "was sick yesterday" is a plain note, "skip today" is a task, and Review keeps the miss ring | HW17, HW25 | `TessGrammar.swift:126`, `:141`; `ReviewPage.swift:140` | DG1, DG2 |
| C6 | "today" before 4 am is the calendar day, and the receipt names the wall weekday | HW7, HW25 | `TessGrammar.swift:609`, `TessCaptureEngine.swift:399-411` | DG6 |
| C7 | A bare past form with a weekday ("meditated monday") becomes a task for next Monday | HW18 | `TessGrammar.swift:324-326`, `:620-622`, `:676-683` | new; habits HP3 |
| C8 | "skip read today" becomes a task "Skip read" | HW29 | `TessGrammar.swift:141`, `:608-610` | L846, HP7 |
| C9 | No habit grammar or engine: create, check in, pause, past days, logs that fill habits | HW3, HW4, HW6, HW8, HW16, HW26, HW27 | none | M3 slice 2, `core.md:180` |
| C10 | No weigh-in grammar rule (ghost, prefix commit, `bw`, day words) | HW1, HW10, HW12, HW14, HW23, HW38 | `TessGrammar.swift:141`, `:153-157` (private note instead) | M3 slice 1, `core.md:212` |
| C11 | No ask exists, and the 11 pm to 7 am gate isn't built. It has to ship before the first app ask (CL1 to CL3) | HW5, HW21, HW28, HW31 | none | AQ6 |

**Builder A** (body weight, Health)

| # | Gap | Steps | Where on master |
|---|---|---|---|
| A1 | No body weight page: trend, stroke, context line, weekly rate, "since" line | HW23, HW38 | none |
| A2 | No BodyWeight class: same-day replace with a 10 s UNDO, ghost, lb setting | HW1, HW12, HW14, HW38 | none |
| A3 | Health: no bodyMass write or read. The share string promises body weight reads that nothing makes | HW37 | `HealthExporter.swift:42`, `project.yml:74` |

**Builder B** (Habits UI, Home)

| # | Gap | Steps | Where on master |
|---|---|---|---|
| B1 | No Habits page: count, dabs, history line, pause hold, clear a done day with a 10 s UNDO, the HABITS word on Review's link line | HW24, HW30 | none |
| B2 | Review has no habit lines or habit marks | HW30 | `ReviewWeek.swift:46-83`, `ReviewPage.swift:120-142` |
| B3 | No Shutdown habits check-in ("Read today?" DONE / NOT TODAY) | HW5, HW21, HW31 | none |
| B4 | The Ask bar's UNDO counts from commit, not from when the line shows, and undoing says nothing ("X, taken back." is ruled) | HW15 | `AppModel.swift:265-287`, `BottomChrome.swift:736-745` |

## The setup

- **Habits**, all made before Oct 19:
  - Gym: 3 a week, rule `workout`.
  - Cook: 4 a week, rule `cook`.
  - Read: 5 a week, by hand.
  - Meditate: 3 a week, by hand.
- The habit week runs Mon Oct 19 4 am to Mon Oct 26 4 am (decisions 7:53 pm PT Oct 15).
- **Body weight** is in kg. The trend going into the week is 82.7, with 20 weigh-ins since Sep 3. The trend is the
  10% EWMA (`../body-weight-trend.md`).
- His weigh-ins this week:
  - Mon 82.4
  - Tue 82.3, told on Wed
  - Wed 82.2, then 82.0 the same morning
  - Fri 82.0
  - Sun 81.9
- That puts the trend near 82.7 on Mon, 82.6 on Fri and 82.5 on Sun.
- **Plan**: rolling PPL, Gym due Mon, Wed and Sat. He finishes Push A on Mon and Pull A on Sat. He's sick on Wed and
  Thu, and marks both (HW17, HW19).
- **Settings**: "Tess asks Claude: yes". The on-device model is available. lb is off.
- **Quiet hours** run 11 pm to 7 am (decisions 6:20 pm PT Oct 15). The day closes at 10 pm, and asks hold from the
  close until 7 am (AQ6).

How to read the rows: "Ruled" gives the decided behavior with its source. "Master" says what `cb9b1d7` does, with a
file and line. TG is `TesseraCore/Sources/TesseraTess/TessGrammar.swift`.

## The walk

### Monday, Oct 19

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW1 | Mon 7:05 am | Types `82.4 this morning` in the Ask bar | A bare number with a day word stays a ghost (BP2, M851): "Body weight **82.4** kg?" and "Tap to keep it." (T1). The trend is 82.7, so no "above trend" note (T2 needs more than 3 kg). A tap keeps it: "Body weight logged. 82.4 kg." with a 4 s UNDO "Body weight taken back." (T3) | TG:141 falls to `parseBodyFact` (TG:153-157), so it's a private note "82.4 this morning". The line is "Private note, kept." (`TessCaptureEngine.swift:297-300`), and it dries in 2 s (`AppModel.swift:181`). Nothing waits for a tap. Safe, but not a weigh-in | not built |
| HW2 | Mon 7:05 am | Same phrase, with "Tess asks Claude" on | It never reaches Claude, and Tess reads it on the phone (MU2, #451; decisions 11:35 am PT Oct 16) | The grammar takes it, so no model runs. If it ever fell through, `PrivateFacts.isBodyShaped` is true (a decimal and only day words, `PrivateFacts.swift:84-88`). The router then skips Claude (`TessModel.swift:77-79`), Claude's route refuses it (`ClaudeTessModel.swift:54`), and the inbox never keeps it (`TessInbox.swift:30`). The Day log shows "Private note" only (`DayStory.swift:345`) | pass |
| HW3 | Mon 7:40 am | Types `meditated` | CheckInHabit(Meditate): "Meditate, 1 of 3 this week." with a 4 s UNDO "Meditate check-in taken back, 0 of 3." (A3, L831) | A past verb with no day isn't a log (TG:324-326), there's no date for a task (TG:537), and it isn't body. So it goes to the model chain, and it isn't walled, so Claude sees it. No habit tool exists (`TessTools.swift:91-243`) | not built |
| HW4 | Mon 6:20 pm | Finishes Push A with 18 sets | Gym ticks from the finish: "Push A counted for Gym, 1 of 3." (A8). It counts on its `startedAt` day, with at least one logged set (decisions 7:53 pm PT Oct 15) | FinishWorkout writes nothing for habits. "Logs fill habits" is still on the Core board (`core.md:180`) | not built |
| HW5 | Mon 9:00 pm | Shutdown, with Read not in today | Tess's band asks "Read today?" with DONE and NOT TODAY. That's one habit at a time, never during a workout, and never on a day a log already counts (CL10, decisions 3:43 am PT Oct 16). He taps NOT TODAY, and nothing is written | No Shutdown and no check-in ask. Shutdown appears only as words in `HomeLines.swift` and `NowRanker.swift` | not built |

### Tuesday, Oct 20

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW6 | Tue 1:05 am | In bed, types `read 30 pages` | It belongs to Monday, because the 4 am day puts 12:00 am to 3:59 am on the day before (decisions 8:07 pm PT Oct 15: "A Read logged at Mon 12:05 am counts for Sunday"). One write fills the Read habit for Monday (RF18, G3): "Read, 1 of 5 this week." with a 4 s UNDO. It's his own capture, so quiet hours don't hold the receipt (CL11) | It goes to the model chain (as L829: a number with no reps, no date, not body). No habit or Reading code. The day itself is right in the engine (`TesseraDay.swift:10`, `:22-31`) | not built |
| HW7 | Tue 1:06 am | Or types `read today` instead | "today" at 1:06 am is his Monday (DM6, HP3), so it checks in Read for Monday. The receipt names Monday, because every weekday comes from the 4 am day (decisions 12:35 pm PT Oct 16) | Task "Read" for 2 am. The `find` rule takes "today" from the calendar day (TG:608-610) and moves it to the next whole hour (TG:689-694). The line names the wall weekday: "Read, Tuesday 2 am." (`TessCaptureEngine.swift:399-411`, "small" hours skip today and tomorrow). The task sits on his Monday night while the line says Tuesday | wrong |
| HW8 | Tue 7:15 am | In the car: "Hey Siri, tell Tess meditated" | The same pipeline as the Ask bar (decisions 12:30 pm PT Oct 16): "Meditate, 2 of 3 this week." Siri undo has no window (decisions 12:45 pm PT Oct 16) | `TellTessIntent` sends it through the capture (`Intents.swift:149-165`), then as HW3. Siri says the model's line, or "Didn't catch that." (`TessModel.swift:101`) | not built |
| HW9 | Tue 7:15 am | The phone is locked in the mount | Siri writes (Tell Tess, Add a Task) need Face ID (decisions 12:26 pm PT Oct 16, P16) | Neither intent sets `requiresAuthentication` (`Intents.swift:118`, `:149`), so a locked phone writes | miss |

### Wednesday, Oct 21

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW10 | Wed 6:55 am | "Hey Siri, tell Tess weighed 82.2" | A prefix commits: "Body weight logged. 82.2 kg." (T6). It stays on the phone. Siri never echoes a walled title (decisions 12:26 pm PT Oct 16). Whether Siri may say the number is Q2 | "weighed" has no day, so it isn't a past log (TG:324-326). `isBodyShaped` is true (`PrivateFacts.swift:81-83`), so it's a private note "Weighed 82.2", and Siri says "Private note, kept." (`TessCaptureEngine.swift:300`). Safe | not built |
| HW11 | Wed 6:58 am | Types `weighed 82.3 yesterday` (he forgot Tuesday) | A weigh-in for Tue (BP2, M856): it commits and says "Oct 20 body weight now 82.3 kg." with a 10 s UNDO (T11). It's a body fact, so it's private on the phone (decisions 12:02 pm PT Oct 16) | parsePastLog runs first (TG:126, before TG:141). "weighed" is a past verb and "yesterday" a past day (TG:703-708), so it's an ordinary dated note "82.3" at Tue noon. The line is "Noted for Tuesday." (`TessCaptureEngine.swift:301-304`). Claude never gets it (the grammar took it), but the note isn't private: it goes into the iCloud copy and any future Spotlight index. Core 0l-2 already names the reorder | wrong |
| HW12 | Wed 7:02 am | Types `82.2 kg` | A unit commits after 2 s: "Body weight logged. 82.2 kg." (T6, M851) | Private note "82.2 kg" (`PrivateFacts.swift:84-88`, TG:153-157) | not built |
| HW13 | Wed 7:03 am | Tries Siri "Add a Task" with `weighed 82.2` | P14: Add a Task checks PrivateFacts, saves a walled title as a private note, and doesn't read it back (decisions 12:26 pm PT Oct 16) | `CreateTaskIntent.add` checks only `SecretWords.hasValue` (`Intents.swift:140`). It makes a task "weighed 82.2", and Siri says `Added "weighed 82.2"` (`TrainingActions.swift:445`), out loud, on a phone that may be locked (HW9). P14 isn't in the pin (decisions 1:08 pm PT Oct 16) | miss |
| HW14 | Wed 7:20 am | Weighs again and types `82.0` | A second entry the same day replaces the first: "Body weight now 82.0 kg." with a 10 s UNDO "Body weight taken back, 82.2 kg again." (T9; AQ15, a change gets 10 s) | `82.0` is a bare decimal with nothing else, so it's a private note "82.0" (`PrivateFacts.swift:84-88`). Wednesday now holds two private notes and nothing replaces | not built |
| HW15 | Wed 7:20 am, 6 s later | Taps UNDO on HW14 | It's a change, so the window is 10 s. The window counts from when the line shows, and the line names the thing: "Body weight taken back, 82.2 kg again." (decisions 12:45 pm PT Oct 16) | The Ask bar's UNDO lasts 4 s from commit (`AppModel.swift:265-287`), and commit comes 2 s after the line (`AppModel.swift:245-256`). So the window runs from 2 s to 6 s after the line, and a tap at 6 s may find it gone. When it works, it says nothing (`BottomChrome.swift:736-745`). See `../undo-windows-audit.md` | wrong |
| HW16 | Wed 7:30 pm | Cook mode on tacos, taps DONE | Cook ticks on its `cookedAt` day: "Tacos counted for Cook, 1 of 4." (A8 form; habits-from-logs) | FinishCooking says "Tacos, done." Nothing counts for a habit | not built |

### Thursday, Oct 22 (sick)

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW17 | Thu 6:45 am | Types `was sick yesterday` | Day marks may go back one day only (decisions 11:55 am PT Oct 16). Wed is marked rest: "Yesterday, rest day." with a 10 s UNDO "Yesterday, unmarked." (DM7, DM8). Review shows the rest dab for Wed, not the miss ring. "sick" stays on the phone, and memory only says "Wed: rest day." (DM13). He cooked on Wed but didn't train, so the mark stands (DM4) | "was" is a past verb (TG:310-312), so it's an ordinary note "Sick" at Wed noon: "Noted for Wednesday." (TG:322-331). There's no mark object, so Review keeps the miss ring on a due day (`ReviewPage.swift:140`). Same as D26 | wrong |
| HW18 | Thu 6:50 am | Types `meditated monday` | A past day in this week checks in that day (HP3). Monday is already in, so: "Meditate is already in for Monday." Nothing is written (A6b). Note the difference: habit check-ins reach back to Monday, but day marks reach back one day | The past log needs words left after the day (TG:326: `!rest.isEmpty`), and there are none, so it falls to the task rule. "monday" becomes next Monday (TG:620-622, TG:676-683): a task "Meditated" for Mon Oct 26 9 am, "Meditated, Monday 9 am." | wrong |
| HW19 | Thu 6:52 am | Types `feeling sick, no gym` | It marks today sick: "Rest today. Pull A waits for tomorrow." (DM1, DM8). The body word never reaches the model or Claude (decisions 11:55 am PT Oct 16, DG3) | It isn't a set or a task (no date, TG:537). `isBodyShaped` is false, because "sick" isn't in `symptoms` (`PrivateFacts.swift:55-58`). So it isn't walled, and the router lets Claude run (`TessModel.swift:77-79`). On master after #451 and #471, a sick day still leaves the phone | miss |
| HW20 | Thu 5:40 pm | Types `gym locker code 4417` | A secret word with a value is a private note. It never reaches the model, Claude, memory or the miss log (NE1/NE2). "Private note, kept." | Secrets are read first (TG:72-74, TG:487-511), then `.privateNote`, "Private note, kept." (`TessCaptureEngine.swift:300`). The router keeps secrets on the grammar (`TessModel.swift:74`, `:79`). Through Siri Add a Task the value branch catches it too (`Intents.swift:140-143`) | pass |
| HW21 | Thu 9:00 pm | Shutdown | Read and Meditate aren't in. Meditate is at 2 of 3. The check-in asks once per habit ("Read today?"), and he taps NOT TODAY. The sick mark doesn't stop the habits ask: marks are for training | Nothing (as HW5) | not built |

### Friday, Oct 23

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW22 | Fri 6:30 am | Opens Home | The Home line never names a habit or a weight: no habit surface in M3 (`m3-lines.md` §5 note, taken 7:34 pm PT Oct 15). Habits open from Review, and Home has no foot word (decisions 3:12 am PT Oct 16) | `HomeLines.swift` has no habit or weight fact | pass |
| HW23 | Fri 7:00 am | Types `bw 82.0`, then `bw trend` | `bw` commits: "Body weight logged. 82.0 kg." (T6). Then `bw trend` opens the body page and Tess says nothing (T15). The page reads "82.0 this morning, 0.1 kg less than last week" (B4, B8). The hero is the trend, 82.6. The change line reads "since Sep 3" (B11) | `bw 82.0` becomes a private note "Bw 82.0" (`PrivateFacts.swift:81-83`). `bw trend` has no number, so it isn't walled and goes to the model chain and Claude. No page exists | not built |
| HW24 | Fri 8:10 pm | On the Habits page, taps Thursday's Read dab, which he tapped by mistake on Thursday | It clears that day: "Read Thursday cleared, 1 of 5." with a 10 s UNDO "Read Thursday is back, 2 of 5." (A17; a delete gets 10 s) | No Habits page | not built |

### Saturday, Oct 24

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW25 | Sat 1:20 am | Types `skip today` | It marks his Friday, because it's before 4 am (DM6). Fri was free anyway, so per DM15 there's no write. The line names the day from the 4 am day | A task "Skip" for 2 am Saturday on the wall clock (TG:608-610, TG:689-694): "Skip, Saturday 2 am." (`TessCaptureEngine.swift:399-411`). That's a wrong write and the wrong weekday | wrong |
| HW26 | Sat 10:40 am | Finishes Pull A | "Pull A counted for Gym, 2 of 3." (A8). Wed was marked, so Review counts it as rest, not due (DM12) | Nothing for habits (as HW4) | not built |
| HW27 | Sat 11:20 pm | Types `read 10 pages` after the day closed | He gets his own receipt even when the day is closed and quiet hours are on (CL11): "Read, 2 of 5 this week." No haptic after 11 pm for moments the app raises (CL9) | Goes to the model chain, as HW6 | not built |
| HW28 | Sat 11:25 pm | Leaves the app open | No habits ask: asks hold from the 10 pm close to 7 am, and a closed day never asks (AQ6, CL11). Habits send no notifications in v1 (`m3-lines.md` §5) | No ask and no notification code at all. Nothing in Swift uses `UNUserNotificationCenter`. Nothing breaks the rule, but the gate that must ship before the first ask (CL1 to CL3) doesn't exist | not built |

### Sunday, Oct 25

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW29 | Sun 8:15 am | Types `skip read today` | Writes nothing and says nothing (G12, HP7; decisions 7:50 pm PT Oct 15). Habits have no skip. An empty day is already blank | Task "Skip read" at the next whole hour (TG:141, TG:608-610, TG:689-694): "Skip read, today 9 am." Same as L846 | wrong |
| HW30 | Sun 8:00 pm | Opens Review, then HABITS | Review: the session hero, then the week line "Gym 2 of 3, Cook 1 of 4, Read 2 of 5." (at most 3 habit clauses, rule habits first; Meditate 2 of 3 is on the Habits page). It never has a weight clause, because "weight down 0.4 kg" left the story and stays on the body page only (decisions 1:00 pm PT Oct 16, superseding the 8:07 pm PT Oct 15 clause). It shows at most 3 habit marks, with no streaks and no red. Wed and Thu show the rest dab. The HABITS word sits beside NOTES on the link line and opens the Habits page, "< REVIEW", with the context line "Sunday, the last day" (H2) and Read at "**2** of 5" (H3) | Review has no habits (`ReviewWeek.swift:46-83`). Wed and Thu were due with nothing done, so both get the miss ring (`ReviewPage.swift:140`). No Habits page and no HABITS word | not built |
| HW31 | Sun 9:00 pm | Shutdown | Read and Meditate are behind. The check-in asks "Read today?" and stays quiet about the week ("no streaks, no red", H5) | Nothing | not built |
| HW32 | Sun 8:00 pm | Review's week story goes to Claude | The pack carries counts and titles only, never body weight, health, notes or money (WeekFacts, decisions 1:00 pm PT Oct 16). The sick days go as "rest day" at most | `WeekFacts` holds no weight, notes or health (`WeekFacts.swift:3-5`). The private weigh-in notes never enter it. The tapped-day lines read "Private note" for them (`DayStory.swift:345`, `ReviewWeek.swift:66-70`) | pass |

### All week

| id | When | He does | Ruled | Master (file:line) | Status |
|---|---|---|---|---|---|
| HW33 | All week | Looks at the widget, the Lock Screen and the rest Live Activity | No habit or weight surface in M3 (`m3-lines.md` §5). Free text on any future widget gets `.privacySensitive` (decisions 12:26 pm PT Oct 16). The planned set may show, since training load isn't a body fact | The only widget is the rest Live Activity (`Widgets/RestLiveActivity.swift`). It never shows a habit or a weight | pass |
| HW34 | All week | Searches Spotlight for "82" or "sick" | A walled or secret title never shows in Spotlight (decisions 12:26 pm PT Oct 16) | Nothing indexes notes or tasks. Only routine entities reach Spotlight (`Entities.swift:95-103`) | pass |
| HW35 | Each 4 am | The memory turnover writes the day's recent line | Memory never holds a weight or a health value (`../../ai/architecture.md` §4). A mark reads only "rest day" | The turnover line runs `TessMemoryScreen.refusal` (`TessMemory+Turnover.swift:104`), which refuses weight words and health words, "sick" included (`TessMemory.swift:96-104`). Private notes are skipped at turnover (Q1, SW2) | pass |
| HW36 | All week | Reads every receipt | Receipts name the thing first: "Meditate, 1 of 3 this week.", "Body weight logged. 82.4 kg.", "Private note, kept." (decisions 12:35 pm PT Oct 16) | The lines that exist here follow it: "Private note, kept." (`TessCaptureEngine.swift:300`). "Noted for Wednesday." (HW17) is the Day log grammar RC18 flags; it's counted with HW17, not here | pass |
| HW37 | Mon 7:05 am and every weigh-in | Expects his weigh-ins in Apple Health, and his scale's weigh-ins in Tessera | **No Product ruling.** Research proposed reading only, one entry per day, with Tessera's own entry winning (H16 in `../calendar-health-fixtures.md`). Writing bodyMass was never decided (Q1) | Health access is write-only and covers workouts only (`HealthExporter.swift:42`). The share string promises body weight reads that nothing makes (`project.yml:74`; `../ask-lines.md` A1) | not built |
| HW38 | Sun 7:30 am | Types `81.9` with nothing in front | A ghost "Body weight **81.9** kg?" that waits for a tap (T1, BP5). Once kept, the body page reads "81.9 this morning, 0.2 kg less than last week" (B8), and the hero trend is 82.5 | Private note "81.9", which dries in 2 s with no tap (`PrivateFacts.swift:84-88`, `AppModel.swift:245-256`) | not built |

Not counted as a row: Review's old count line (`ReviewView.swift:114-123`) would count the private weigh-in notes as
"notes". That screen isn't the live Review (`ReviewPage.swift`, `ReviewWeek.swift`), so it isn't scored here.

## What may show where (privacy summary)

| Surface | A habit name and count | His weight | "sick" | A secret value (4417) |
|---|---|---|---|---|
| Ask bar receipt | yes | yes once BodyWeight lands ("Body weight logged. 82.4 kg."); "Private note, kept." today | no ("Rest today.") | never ("Private note, kept.") |
| Siri reply | yes | Q2 (pick: no number) | no | never |
| Home line, widget, Lock Screen, Live Activity | no (none in M3) | no | no ("Rest today" only) | never |
| Spotlight | no | no | no | never |
| Review | yes (week line, up to 3 marks) | no (body page only) | no (rest dab) | never |
| Body page | n/a | yes | n/a | n/a |
| Claude (any job) | counts only ("Gym 2 of 3") in WeekFacts | **never** | **never** (HW19 leaks today) | **never** |
| Tess memory | no values | never | "rest day" only | never |

## Questions for Product

1. **Body weight and Apple Health.** Should a weigh-in typed to Tess be saved to Health as bodyMass, and should
   Tessera read his scale's weigh-ins? Nothing is ruled.
   - **Pick:** read only for v1, as H16 in `../calendar-health-fixtures.md`: one entry per day, Tessera's own wins, and
     Health fills days without one. Writing waits until the read exists. Then the two don't echo each other, and the
     share string can say exactly what's read. Builder A, after Core's M3 slice 1.
2. **Siri saying his weight.** Siri replies hide walled titles (12:26 pm PT Oct 16), but T3 says "Body weight
   logged. 82.4 kg."
   - **Pick:** Siri says "Body weight logged." with no number. Siri can speak on a locked phone, in the car or on a
     speaker. The Ask bar keeps the number.
3. **Questions about his weight.** `what did i weigh monday` and `bw trend` have no number, so they aren't walled and
   reach Claude, which can't answer (`answerQuery` never counts a body class, `TessTools.swift:236-237`).
   - **Pick:** a body-shaped question ("weigh", "weight", "bw", "trend" with "weight") stays on the phone. It opens the
     body page or is answered there, and never goes to Claude. The question gives away what he's tracking even
     without a number.
4. **A sick day further back.** `was sick monday` said on Thursday can't be a mark (one day back only). Today it's an
   ordinary note "Sick".
   - **Pick:** a private note dated Monday, with no mark and no line about the miss: "Private note, kept." The body
     word stays private, and the week isn't rewritten.
5. **"sick" in the wall.** Should "sick", "unwell" and "feeling sick" join `PrivateFacts.symptoms` now, ahead of the
   mark rule?
   - **Pick:** yes, as a pin rider beside P14. It's one word list, and it closes HW19 today. The mark rule (DG2) still
     comes later.
6. **The habits check-in on a sick day.** Does Shutdown still ask "Read today?" on a day marked sick?
   - **Pick:** no. A sick mark holds every habits ask that day. Rest and skip marks don't, since he may still read on
     a rest day.
