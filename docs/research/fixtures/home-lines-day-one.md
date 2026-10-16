# Home lines, day one (Product item Q)

For: Product, Builder B, Core, Design. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Read by hand on #366's head `46dfd4d` ("Home keys read as label words"), nothing run. Rules from Design's `home-labels.md` (only on `claude/project-thread-b3tu3f` b21c36d, not on #366 or master), `docs/ai/home-lines.md`, `docs/research/house-copy-sweep.md` (master 2d8994d, with Product's 12:01 PM calls) and the caps in `HomeLines.swift:182-199` (context 6 words / 32 characters, detail 14 words / 80 characters).

**The day.** The pin build lands Friday Oct 16; the walk runs Friday 10:40 pm to Sunday 00:40 am, Pacific (PDT), his day turning at 4 am. History carries over from the old store; last session Legs B on Thursday, so Push A is next (PPL x2, kg). Saturday: "Call mom" 11:15 am (30 min), "Pay rent" 2 pm, Dentist 3:30 pm (a calendar event), Push A 5:50 to 7:40 pm (6 of 6 exercises, 18 sets, a bench best), Groceries at the store 8:05 pm, tacos (7 steps, 2 to buy) 8:30 to 9:20 pm, Shutdown 9 pm, quiet hours 11 pm to 7 am. Sunday: "Laundry" 9 am.

Every rules context and hero below fits its caps; none ends in "…", and no Home string carries an em-dash. Line refs are on `46dfd4d`.

| Id | Time | State | Expected on Home | What #366 draws (builder) | Verdict |
|---|---|---|---|---|---|
| Q1 | Fri 10:40 pm | First launch after install, history moved over, nothing left today | "Friday night"; "Push A", ctx "tomorrow, first" (m4-steers §7, after Shutdown) | "Push A", ctx "tonight", Start Push A at 10:40 pm (`NowPage.swift:167-176`, `HomeLines.swift:341, 384`); the tomorrow fact is never built | wrong |
| Q2 | Sat 4:05 am | Day boundary; Push A planned, Call mom 11:15 am | "Saturday morning" (see questions); "Push A", ctx "today" (home-lines-day D1) | Label "Saturday night" (`HomeSpatialView.swift:675-682` puts 4 am in "night"); hero "Call mom", ctx "11:15 am", Finish "Hold · IN 7 H" (`NowPage.swift:25`, `AppModel.swift:493-496`) | wrong |
| Q3 | 7:05 am | Wake; same as Q2 | "Saturday morning"; "Push A", ctx "today", Start; Call mom in Next | Hero "Call mom" (next undone task wins over the routine, `NowPage.swift:24-25, 144`); Push A is nowhere on Now; Next reads "Nothing else today." | wrong |
| Q4 | 7:05 am | Training page, bench target raised to 82.5 | "Bench is ready for 82.5 kg today." | "Bench Press is ready for 82.5 today." (no unit, `TrainingPage.swift:349`) | wrong |
| Q5 | 11:10 am | Call mom in 5 min | ctx "next, at 11:15 am" (143 W13, sweep "Unsure") | ctx "11:15 am" (`HomeLines.swift:321`); meta "Hold · IN 5 MIN" | wrong |
| Q6 | 11:20 am | Call mom running | ctx "now, until 11:45 am" | ctx "11:15 am", the start, while it runs (`HomeLines.swift:321`); meta "Hold · 25 MIN LEFT" passes | wrong |
| Q7 | 11:31 am | Finish held on Call mom; Pay rent is next | Tess: "Call mom, done." | "Done. Next one is up." (`NowPage.swift:242`, sweep row 4) | wrong |
| Q8 | 11:32 am | Pay rent swiped to TOMORROW | Tess: "Pay rent, tomorrow." | "Moved to tomorrow." (`HomeQueue.swift:480`, sweep row 5) | wrong |
| Q9 | 11:32 am | Next row for Pay rent | time "2 pm"; VoiceOver "Pay rent, 2 pm" | "14:00" (`HomeQueue.swift:375`, VoiceOver `:283`) | wrong |
| Q10 | 3:30 pm | Dentist, a calendar event | Next row "Dentist 3:30 pm", or Now at 3:15 pm | Not on Home: the schedule is tasks and tonight's workout only (`AppModel.swift:474-490`) | miss |
| Q11 | 2:30 to 5:30 pm | Gap: nothing timed, Push A planned | "Push A", ctx "today", then "this evening" from 5 pm; Start | Same (`NowPage.swift:167-176`, `HomeLines.swift:381-386`) | pass |
| Q12 | 4 pm (variant) | Push A scheduled for 6 pm, a training day | "Push A at 6 pm", ctx "today", Start | "Nothing else is planned today." with Next row "Push A 18:00": the scheduled hero only shows on a rest day (`NowPage.swift:30-31, 72-83`; `todaysRoutine` is nil, `AppModel.swift:595-599`) | wrong |
| Q13 | 6:10 pm | Live, bench set 3 | "Push A, bench set 3", ctx "now", Resume Push A | Same (`HomeLines.swift:285-287, 338`; `NowPage.swift:41-50`) | pass |
| Q14 | 6:40 pm | Paused at incline 4 min | "Push A, paused at incline", ctx "paused 4 min ago", Resume | Same (`NowPage.swift:51-58`, `HomeLines.swift:291, 336`) | pass |
| Q15 | 7:45 pm | Push A done, bench best | "Push A done", ctx "7:40 pm", no key | Same (`NowPage.swift:177-181`, `HomeLines.swift:284, 333`) | pass |
| Q16 | 7:45 pm | Tess's count line for the same workout | One wording across Tess and the lens | Training's Tess line "6 of 6 exercises, 18 sets, 1 best." (`WorkoutSummary.swift:30`) vs SO FAR "6 exercises, 18 sets, 1 new best." (`HomeLines.swift:363-366`) | wrong |
| Q17 | 8:05 pm | Groceries running at the store, 6 left | "Groceries, 6 left", ctx "at the store"; receipt "Basket, 3 cleared." | Now has no branch for a running cook or shop and keeps "Push A done" (`NowPage.swift:41-58`); receipt "Cleared 3 from the basket." (`GroceriesView.swift:260`) | miss |
| Q18 | 8:05 pm | Tacos planned tonight, 2 to buy | "Tacos tonight", ctx "2 to buy" | Not built: `HomeFacts.fact(plannedCook:)` (`HomeLines.swift:563`) has no caller; with a 7 pm due it would read "Tacos at 7" (`:272`) | miss |
| Q19 | 8:35 pm | Cooking tacos, step 3 of 7 | "Tacos, step 3", ctx "now" | Same gap as Q17: a running cook isn't Now | miss |
| Q20 | 8:50 pm | Tacos paused at step 3, 8 min | "Tacos, step 3", ctx "paused 8 min ago", Resume Tacos | Same, through the ledger (`NowPage.swift:51-58`) | pass |
| Q21 | 9:00 pm | Shutdown | Shutdown opener (e.g. "Did 1 workout, 2 tasks."), then "Pull A", ctx "tomorrow, first" | No Shutdown on Now in Swift; from 9:01 pm Sunday's 9 am Laundry enters the 12 h window and becomes the hero: "Laundry", ctx "9 am", Finish "Hold · IN 11 H" (`AppModel.swift:476, 496`) | miss |
| Q22 | 9:20 pm | Tacos done | "Tacos done", ctx "9:20 pm" (Research G1) | `fact(doneCook:)` (`HomeLines.swift:542`) has no caller; the cook leaves Now | miss |
| Q23 | 11:30 pm | Quiet hours, nothing asks | "Saturday night"; "Push A done", ctx "7:40 pm" (or Q21's look ahead) | Label passes; hero is still Sunday's Laundry with no "tomorrow" | wrong |
| Q24 | Sun 00:40 am | Late night, still Saturday | "Saturday night"; Saturday's lines | "Sunday night": the label reads the wall clock (`HomeLineHero.swift:101`, `DayStrip.swift:61`); master read his day via `HomeData.lanes`. Hero: Laundry | wrong |
| Q25 | any (variant) | Empty day: no plan, no tasks | One line and the label word LOOK BACK AT THE WEEK, no arrow | "Nothing else is planned today." over "Nothing else today." (`NowPage.swift:184`, `HomeQueue.swift:103`), and "Look back at the week →" (`NowPage.swift:191`) | wrong |
| Q26 | Sun (variant) | Planned rest day | "Rest day", ctx "today", Start Pull A in ink | Same (`NowPage.swift:59-71`, `HomeLines.swift:283, 327`) | pass |

**Counts:** 26 moments: 6 pass, 14 wrong, 6 miss.

## Top gaps

1. **Now ignores the ranker unless it picks a task.** `NowPage.swift:24-25` falls back to `currentTask`, which takes the next undone task anywhere in a now-14 h to now+12 h window (`AppModel.swift:476, 493-496`). Any task beats the planned routine and the done workout (Q2, Q3), and after 9 pm tomorrow's tasks become Now with no "tomorrow" (Q21, Q23, Q24).
2. **The day label is on the wall clock.** `HomeLineHero.swift:101` builds `DayLane(date: now)`, so 12 to 4 am reads the new weekday (Q24), and `SpokenTime.partOfDay` (`HomeSpatialView.swift:675-682`) calls 4 am "night" (Q2). It also says "evening" until 10 pm while the lens says "tonight" from 9 pm (`NowRanker.swift:29-40`). This one is new in #366: master took the date from `HomeData.lanes`.
3. **Lens facts with no caller.** `fact(process:)` (`HomeLines.swift:502-531`) builds a running cook or shop, but `NowPage.swift:41-58` only puts a running workout or a paused process on Now (Q17, Q19). `fact(doneCook:)` (`:542`), `fact(plannedCook:)` (`:563`) and the `tomorrow:` look ahead (`:534`) have no caller in the app (Q1, Q18, Q21, Q22).
4. **A scheduled workout on a training day shows the empty state** (Q12): `NowPage.swift:30-31` only shows it on a rest day, and `todaysRoutine` steps aside for it (`AppModel.swift:595-599`).
5. **Receipts verb first:** `NowPage.swift:242`, `HomeQueue.swift:480`, `GroceriesView.swift:260` (Q7, Q8, Q17).
6. **24-hour times on Home:** `HomeQueue.swift:375, 283`, ghost row `NowPage.swift:340, 394` (Q9, Q12).
7. **Empty day says it twice, with an arrow:** `NowPage.swift:184, 191`, `HomeQueue.swift:103` (Q25). Core's `HomeLine.quiet` "All quiet." (`HomeLines.swift:157`) is unused.
8. **Two wordings for one count:** `WorkoutSummary.swift:30` vs `HomeLines.swift:363-366` (Q16). The ledger row's own `ago` (`NowPage.swift:446-455`) rounds 1 h 50 min to "1 h ago" while the hero's (`HomeLines.swift:421-430`) says "2 h ago".
9. **Calendar events never reach Home** (`AppModel.swift:474-490`, Q10). **No kg** on Training's target line (`TrainingPage.swift:349`, Q4).

## Questions for Product

1. A task's context line: just "11:15 am", or "next, at 11:15 am" before it and "now, until 11:45 am" while it runs (Q5, Q6)?
2. The day label's word for 4 to 7 am ("Saturday morning"?), and should 9 to 10 pm say "evening" or "night" to match "tonight" (Q2)?
3. After Shutdown, should Now turn to "Pull A, tomorrow, first", and may a task dated tomorrow ever be Now before 4 am (Q21, Q23)?
4. Is a running cook or shop Now, or is it only shown on Kitchen (Q17, Q19)?
5. Do calendar events show on Home in v1 (Q10)?
6. The empty day line: "Nothing else is planned today." or Core's "All quiet." (Q25)?
7. "The v9 pin build" isn't named anywhere in the repo; this sheet takes it to be #366's head. Correct me if it's another commit.
