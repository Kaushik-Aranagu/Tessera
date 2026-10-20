# Review choices (Settings, Review section), Oct 19

Product. One ReviewChoices type app-side; not in the catalog, not in backups. Default is always today's behavior. Off or default must look and act exactly like master today.

| # | Name | Values | Default | Screen it changes |
|---|------|--------|---------|-------------------|
| 1 | Reading layout | Today / Sheet 99 | Today | Groceries, Home/Now, Exercise page, Backup (type sizes 5 to 3, tokens) |
| 2 | Rest timer | On / Off | On | Live workout: rest timer after a set, rest-end alert |
| 3 | Swap exercise | One tap / Two taps | Two taps | Live workout exercise row |
| 4 | Forgot Finish nudge | Off / On | Off | Workout left unfinished: one quiet nudge |
| 5 | Page turn | Slide / Turn / Soften / Rotate | Slide | Page changes and paged long lists |
| 6 | Top bar | Removed: Kaushik decided, ships directly, no switch | - | - |
| 7 | Stage titles | Removed: Kaushik decided, ships directly, no switch | - | - |
| 8 | Area colours | Removed: Kaushik decided, ships directly, no switch | - | - |
| 9 | Small images | Removed: Kaushik decided, ships directly, no switch | - | - |
| 10 | Tess eyes and mouth | Off / Eyes / Eyes and mouth | Today's setting | Tess on Home |
| 11 | Tess motion picks | Removed: Kaushik decided, ships directly, no switch | - | - |
| 12 | Plan my day | Off / On | Off | Now at 8 AM |
| 13 | Shutdown | Off / On | Off | Now at 9 PM |
| 14 | Energy check-in | Off / On | Off | Morning rep drum |
| 15 | Quiet interrupts | Off / On | Off | Notice grouping during workout or cook |
| 16 | Calendar | Off / On | Off | Calendar mount |
| 17 | Health | Off / On | Off | Health mount |
| 18 | Areas shown | per area on/off: Body weight, Habits, Money, Reading, People, Upkeep | Today's set | Area index |
| 19 | Link fetch | Off / On | Today | Recipe from a website |

Settings becomes its own page: Review, LookSentence, RestDaySentence and the Claude section move into it. Copy rules: plain words, no "at" before a clock time, one before/after line per row.


## As built (#1096 ReviewChoices ids, Oct 19)

readingLayout (Today | Sheet 99, Today); restTimer (On | Off, On); swapExercise (Two taps | One tap, Two taps); finishNudge (Off | On, Off); pageTurn (Slide | Turn | Soften | Rotate, Slide); tessFace "Tess has eyes" (Off | Eyes | Eyes and mouth, Off); planMyDay, shutdown, energyCheckIn, linkFetch (Off | On, Off, need Claude); quietInterrupts (Off | On, Off); calendar, health (Off | On, Off, later); areasShown (Today's | All, Today's; one switch, not six); cookTimerVoice, pantryState, canCookShelf, handsFreeCook (Off | On, Off). Rows 6 to 9 and 11 stay removed (decided).
