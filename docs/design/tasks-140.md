# Item 140: Tasks, the seventh app, build sheet (Oct 22)

Builds sheet 136 F. Review switch tasksApp (default Off). Builder B. Core has the engine:
Tasks, NowPicker, RollForward, FirstStep, DayPlan, MoveTask; HomeQueue swipes.

## Character (127 B)
Accent: ink (no hue; the action underline is ink, 2 pt). Ground: the look's base. Lead:
one thing in large words. Numbers: none on the landing. Signature: the strike (an ink
line that follows the finger). Motion: calm. Haptic: soft tap on a strike.
Its Home edge (137) is an ink stroke at rest tint.

## Landing (LandingPage frame)
```
 < Home
 Tasks                                                <- title
 One thing at a time.                                 <- subtitle, ink 2
 Send the trip plan to Sam                            <- NowPicker's pick, title role
 First, two minutes: open the plan and copy the dates. <- FirstStep, ink 2 (only when offered)
 Do it                                                <- ink underline; starts it (focus)
 After that                                           <- label
 Call the dentist
 Renew the parking permit             from Tuesday    <- carried: "from {weekday}", ink 3
                                        Today  Soon  Later   <- doors, ink words
```
- Swipe right on any line finishes (strike), left is not now (MoveTask), as on Home.
- Nothing ever says overdue, late or missed. A task rolled 7 times sits in Later quietly.
- Private tasks: "Private task" everywhere.
- Nothing to do: "Nothing next." and the three doors; no "all clear" celebration.

## Rail (RailPage, sheets 119, 123)
Pinned: Now. Knob: none in v1 (All). Dial: Today, Soon (planned after today), Later
(engine's Later). Row value: the time ("6:30 pm"), "from {weekday}" for carried ones, or
nothing. Write word at the foot: "New task". Long press: the task's side.
(Board 136 showed This week / Someday / Waiting and an Area knob; this sheet wins:
those need fields Core doesn't have. Core ask, later: an optional area and a waiting-on.)

## Words
Tasks, One thing at a time., First, two minutes:, Do it, After that, from {weekday},
Today, Soon, Later, Nothing next., New task, Private task.
