# Item 176: Routines Pause, Busy and habit marks (lane: data and architecture, for Core; Oct 23)

Answers the gaps in #1254 (162 routinesDayV2, 168 weekThreadV2). Behind the same switches. No
streak talk, no red, no counts of misses. All on the phone.

## Pause
Pause stops a routine for a stretch without it counting as missed.
- Field `pausedUntil` (date, empty = not paused). "Pause" asks one thing: "Until when?" with
  plain choices "Tomorrow", "This week", "Until I say" (empty-ended, stored as far date flag).
- While paused: the routine leaves Now, Home's day sentence, the process table and the week
  thread's day count; its row on Routines reads "Paused until Mon." in ink 2 with a plain
  "Resume". On the date it resumes by itself and nothing is announced.
- Actions pauseRoutine(until), resumeRoutine; both undoable (164). A paused day is bridged: it
  never breaks a habit count.

## Busy
Busy skips today only, kindly. Beside Pause at the foot.
- Field `busyDays` (list of dates). Busy marks today: the routine drops from Now and Home for
  today, row reads "Busy today." in ink 2. Tomorrow it is back, nothing said.
- Works on a routine not yet run; if already run today the word is hidden.
- A busy day is bridged like a paused day: it never counts as missed and never breaks a count.
- Action markRoutineBusy(day), undoable. Tess says nothing about it.

## Habit marks
A habit is a routine he wants a count on. Off for every routine until he turns it on.
- Field `isHabit` (bool, default false). Long press a routine > "Count this one" /
  "Stop counting". Only marked routines show the small count.
- The count is consecutive scheduled days done, as "4 days" in Outfit ink 3 after the name.
  Paused and busy days are bridged (neither add nor break). A real miss restarts it silently
  at nothing: the count simply is not shown at 0 or 1.
- Computed from run history, not stored, so editing past days stays honest. Never in a widget
  or shared; never "streak", never a best-ever number.
- The week thread (168) is unchanged by habit marks: it draws every routine the same way.
