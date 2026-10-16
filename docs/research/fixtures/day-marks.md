# Day marks: skip or rest today (board item 147)

For: Core, Builder B, QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific). Master 9fb27ab, traced by hand, nothing was run.

Sources: decisions "Rest day today is a day mark" (6947f88) and "A planned session beats a rest day" (96db137);
`new-feature-phrases.md` V-R and V-T12 to V-T15 (this file replaces V-T14 and V-T15's "no write"); Q10 (statements,
never yes/no asks) and AQ15 (10 s UNDO on a change). The rest weekday setting is Research 146's `rest-weekday.md`.
Made-up state: a rolling PPL x2 plan, 6 a week, Legs A next; Sunday is rest where the engine places it.

## Rules

- **DM1 Phrases that mark today.** "rest day today", "rest today", "skip today", "skip the gym today", "no gym today",
  "day off today", "sick today", "feeling sick, no gym", "travel day", and "skip {today's routine} today". Default
  proposed: a bare "rest day" or "travel day" means today. The kind (rest, skip, sick, travel) stays on the phone.
- **DM2 Near-misses stay what they are.** A weekday ("rest day Sunday") is the weekday setting, never a mark. Skip plus
  something that isn't training ("skip the gym email", "skip lunch today") stays a task or goes to the model. "rest 90"
  in a workout is the rest timer; "remember I rest on Sundays" is memory (V-R1).
- **DM3 What the roll does (decided).** A mark is a day fact, not a plan write; restWeekday never changes. The next
  routine waits for the next training day ("Legs A waits for tomorrow"); on fixed days it names the next fixed day.
  Nothing counts as missed: the sessions still due spread over the days left.
- **DM4 Already trained today.** No mark: "Pull B is in for today, so no rest mark." Default proposed.
- **DM5 A workout running.** No mark. Any skip phrase gets "Skip is on the workout screen." Default proposed.
- **DM6 Before 04:00 the mark lands on his day** (TesseraDay): at 01:30 Saturday, "today" is Friday. Default proposed.
- **DM7 Tomorrow and yesterday.** "rest tomorrow", "skip tomorrow" mark his tomorrow; "rest yesterday", "was sick yesterday" mark
  his yesterday. Yesterday, today and tomorrow only, nothing further back (Product, 11:55 AM PT). A yesterday mark moves
  nothing in the plan; it only turns the miss ring into the rest dab. Receipt "Yesterday, rest day." with UNDO (Design to confirm).
- **DM8 Tess's line, the thing first.** "Today, rest day. Legs A waits for tomorrow." with UNDO for 10 s; UNDO says
  "Legs A, back on today." (decided). "Tomorrow, rest day." for DM7. Thing-first form: Default proposed.
- **DM9 Un-marking later.** "back on today", "train today", "not resting today" clear the mark with the UNDO line's
  words and their own 10 s UNDO. Default proposed.
- **DM10 A timed session on the day** (Push A at 7 pm): the mark takes it off today (decided) and it moves to the same
  time tomorrow; one UNDO puts both back. Move target: Default proposed.
- **DM11 Home, Now, widget.** Hero "Rest today", context "Legs A waits for tomorrow", no Start until 04:00 (decided).
  Widget "Rest today." with the weekday as meta, as for a planned rest day. Widget words: Default proposed.
- **DM12 Review and WeekFacts.** A marked day gets the rest dab, never the miss ring, and isn't counted due (decided).
- **DM13 Privacy.** "sick" is a body fact: the grammar reads every mark phrase on the phone, so none reaches Claude.
  Outside the phone and in memory a mark is only "rest day" ("Fri: rest day."); the kind never is. Default proposed.
- **DM14 Two marks in a row.** Each reads the same line; no streak, no nudge, no count of rest days.
- **DM15 A mark on a rest day** (his rest weekday, or the engine's): no write, "Sunday is already a rest day."
- **DM16 Trips.** The day is the day where he is when he says it, keyed by the day label like T3.

## Rows

| # | When (PDT) | He says | Expected: mark, Tess line, next | Master today |
|---|---|---|---|---|
| D1 | Fri Oct 16 7:40 am | rest day today | Rest. "Today, rest day. Legs A waits for tomorrow." UNDO. Legs A Sat | Task "Rest day", today 9 am (`TessGrammar.swift:141`, `:490-519`) |
| D2 | Fri 6:40 pm | skip today | Skip, as D1 | Task "Skip", today 7 pm (`:665-670`) |
| D3 | Fri 6:40 pm | no gym today | Skip, as D1 | Task "No gym", 7 pm |
| D4 | Fri 12:10 pm | sick today | Sick, phone only. The D1 line; never says "sick" | Task "Sick", 1 pm |
| D5 | Fri 12:10 pm | feeling sick, no gym | Sick, as D4. Never the model or Claude | Model, so Claude when the switch is on (no date, `:514`); MU2 not on master |
| D6 | Fri 9:15 am, Legs A due | skip legs today | Skip, as D1 (replaces V-T14) | Task "Skip legs", 10 am |
| D7 | Fri 9:15 am, Legs A due | skip push today | No mark. "Today is Legs A. Say "skip today" to rest." | Task "Skip push", 10 am |
| D8 | Fri 7:40 am + 6 s | UNDO on D1 | Mark gone. "Legs A, back on today." | Undo removes the task |
| D9 | Fri 2:00 pm, D1 set | back on today | Mark cleared. "Legs A, back on today." UNDO | Task "Back on", 3 pm |
| D10 | Fri 6:40 pm, Pull B done 6:05 pm | rest day today | No mark (DM4). Next unchanged | Task "Rest day", 7 pm |
| D11 | Fri 6:40 pm, Pull B running | skip today | No mark. "Skip is on the workout screen." | Likely task "Skip", 7 pm: only bare "skip" is caught (`TessGrammar+Live.swift:119`) |
| D12 | Sat Oct 17 1:30 am | rest day today | Rest on his Friday. "Today, rest day. Legs A waits for tomorrow." | Task "Rest day", Sat 9 am ("today" is `startOfDay`, `:586`) |
| D13 | Fri 9:30 pm | rest tomorrow | Rest on Sat. "Tomorrow, rest day." Training reads "Rest day tomorrow" | Task "Rest", Sat 9 am (`:593-595`) |
| D14 | Sat 8:00 am, D13 set | (opens Home) | Hero "Rest today", "Legs A waits for Monday", no Start. Widget "Rest today.", meta "Saturday" | Engine's reading only: "Rest day", "Legs A is a tap away.", Start (`NowPage.swift:396-414`) |
| D15 | Sat 8:00 am, Fri and Sat marked | (opens Home) | As D14. No streak words (DM14) | As D14 |
| D16 | Sun Oct 18 10:00 am, engine rest | rest day today | No write. "Sunday is already a rest day." | Task "Rest day", 11 am |
| D17 | Mon Oct 19 8:00 am | (opens Review) | Fri and Sat: rest dab, not the ring; not counted due | Past empty days recomputed from the spread: ring (`WeekView.swift:89-92`, `ReviewPage.swift:137-140`) |
| D18 | Fri 7:40 am, Push A at 7 pm | rest day today | Rest. Push A moves to Sat 7 pm. "Today, rest day. Push A waits for tomorrow." | Task "Rest day"; Home keeps "Push A at 7 pm" (`HomeLines.swift:578`) |
| D19 | Fri 9:00 am, fixed days (Legs A Fri, Tue) | skip today | Skip. "Today, rest day. Legs A waits for Tuesday." | Task "Skip", 10 am |
| D20 | Fri 9:00 am | rest day Sunday | Not a mark: the weekday setting (`rest-weekday.md`) | Task "Rest day", Sun 9 am (V-T12) |
| D21 | Fri 9:00 am | skip the gym email | Not a mark: the model makes the task | Model ✓ |
| D22 | Fri 9:00 am | skip lunch today | Task "Skip lunch", 10 am. Not training | ✓ |
| D23 | Fri 6:45 pm in Pull B | rest 90 | The rest timer | ✓ (`TessGrammar.swift:224`) |
| D24 | Sat 4:05 am, D4 set | (turnover) | Recent line "Fri: rest day." Never "sick" | No line for a day with nothing done (`TessMemory+Turnover.swift:61-63`); if he ticks D4's task, "Fri: done sick." can be written |
| D25 | Mon Oct 26 7:10 am EDT (4:10 am PDT) | travel day | Travel, on Mon Oct 26 in New York. The D1 line | Model (no date) |
| D26 | Fri 9:00 am | was sick yesterday | Thu marked rest. "Yesterday, rest day." UNDO. Review: Thu rest dab, not the ring; nothing moves. Memory: "Thu: rest day." (DM7, DM13) | Note "Sick", Thu noon (`TessGrammar.swift:307-315`) |

## Gaps

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| DG1 | No mark is stored; past empty days are recomputed, so a marked day gets the ring | `WeekView.swift:89-96`, `RestDay.swift:20-30` | A day mark object (day label, kind) that week() reads for today and past days: isRest, not wasDue | Core |
| DG2 | Every mark phrase becomes a task or goes to the model | `TessGrammar.swift:141`, `:490-519` | A mark rule before parseTask, after the live rules (DM1, DM2, DM7, DM9) | Core |
| DG3 | Body words reach Claude ("feeling sick, no gym"); a ticked "Sick" task can reach memory | `TessGrammar.swift:141`, `TessMemory+Turnover.swift:59-87` | Mark rule first (DG2); MU2's screen; recent line says "rest day" | Core |
| DG4 | Home on a mark shows the planned-rest hero with Start | `NowPage.swift:396-414`, `HomeLines.swift:283` | A `marked` flag on the rest fact: "Rest today", "waits for", no Start | Core, Builder B |
| DG5 | A timed session beats rest, so a mark can't clear it | `HomeLines.swift:577-581` | The mark moves the session to the same time tomorrow (DM10) | Core |
| DG6 | "today" before 04:00 is the calendar day | `TessGrammar.swift:586` | The mark rule uses TesseraDay (DM6) | Core |
| DG7 | restWeekday isn't read by week(), so DM15 can't tell his rest weekday | `TesseraSettings.swift:25`, `WeekView.swift:34` | Read with Research 146's fixture | Core |
| DG8 | V-T14 and V-T15 said "no write" | `new-feature-phrases.md:92-93` | Done: they point here | Research |

Ruled (Product, decisions.md 11:55 AM PT): he can mark yesterday as well as today and tomorrow, nothing further back,
so a sick day never shows as a miss (DM7, D26). DG3 folds into MU2's body screen; DG7 folds into the RG items (146).
