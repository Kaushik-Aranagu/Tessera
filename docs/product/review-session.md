# Review session: what to try on the next build

*Planning lead, updated 6:20 PM Pacific, Oct 15. For the next install, over 34665f0. This build is master from #151 onward plus Builder B's rest-day hookup on Now, which is the last thing the install waits on. It folds in Research's `review-refresh.md`. If something here isn't in the build, skip it and tell us.*

## What to try (about 20 minutes)

Home has a word rail across the top: **Review · Today · Training · Kitchen**. Every key is a painted stroke word, not a button. **Tess** is the soul in the corner: tap her to open the capture surface. UNDO is now one vermilion word everywhere.

**Today and Now**
1. **Finish a task with a swipe.** On Today, rest a finger still on a row in Next or Later for a moment, then drag it right. The name strikes through, the row leaves, and Tess says "Done. *title*." with UNDO, which brings it back.
2. **Flick past the rows.** Flick quickly left or right across the same rows without pausing. Home pages to Review or Training, and no task is finished or moved.
3. **Move a task.** Press still on a row, then drag it left. A timed task says "Moved to tomorrow." and an untimed one "Moved to next week.", both with UNDO.
4. **Rest day.** On a planned rest day, Now shows a quiet "Rest day" line instead of the next routine, which stays one tap away in Training. A running workout or anything timed in the next 15 minutes still comes first.

**Workout**
5. **Start and log.** Training, then today's routine. Each set opens filled in: hold to log it, turn the **weight dial** (plates per side beside it) and roll the **reps drum**. *Check:* the dial's clicks, and whether each hold lands as one clean clunk.
6. **Fix a set.** Log two sets, tap set 1's stroke, change it, and tap "Save set 1". The other strokes dim, and Tess says "Set 1 is 80 × 7 now." (your numbers) with UNDO.
7. **Remove a set mid-rest.** While a rest counts down, tap that set's stroke and tap REMOVE. Tess says "Set N removed.", and the countdown stops on the Lock Screen too.
8. **Rest from the Lock Screen.** Lock the phone after a set: the rest runs there, and **Done** logs the next set without unlocking.
9. **Swap, then leave.** During a rest, pull down on the exercise name, pick an alternative, then kill the app and reopen. Resume takes you back with the rest still counting.
10. **Tess in the workout.** Tap her soul in the bottom-right: a writing line with CLOSE as a word. Double tap her to go back to Today, where Now shows Resume. On the last set, "Last one. Hold to finish." stays until you finish.
11. **Finish, and look at the exercise.** Finish and see it saved. Tap an exercise name for its page, with your best set and history. *Only when it happens:* after a session where every set hit the top of the range, set 1 says "Up 2.5 kg from last time".

**Tell Tess** (tap her, then Write)
12. **"coffee at 7"** before 7 PM lands "Coffee, today 7 pm." A bare 1 to 6 means PM; 7 to 11 means the next one that hasn't passed today.
13. **"watered plants sat"** saves a note dated last Saturday ("Noted for Saturday."), not a task.
14. **"get a haircut", then "get coffee".** The haircut lands as a task in Later; coffee goes on Groceries.
15. **"are we out of milk"** saves nothing. Questions are never filed as tasks or items.

**Kitchen**
16. **Groceries.** Kitchen, then Groceries. Type "3 egg" on the Add line: "3 eggs" files under its aisle. Hold the "Groceries" title (about 0.7 s) to start the shop: the aisle you're in is the big word, with the next one peeking. Tap items to strike them into the basket.
17. **Clear the basket.** Mid-shop, tap the basket, hold "Clear the basket", then tap UNDO: everything goes back. Finish with the "Done" hold key. Tell us if the UNDO line ever shows a line from somewhere else.
18. **Recipes (bonus).** In Kitchen, open Recipes and paste a recipe's text. It's read into ingredients and steps; then Save.

**Review**
19. **Backups.** On Review, scroll to the foot and tap "Backups". Go back once with "‹ Review" and once with an edge swipe. An edge swipe on Review itself does nothing, and nothing freezes.
20. **Restore, safely.** Only if a Tessera copy is in Files: tap Restore and pick it. You get a question first; tap "Keep what's here", which changes nothing. Don't hold Replace on the phone.

*If a calm note ever shows at launch, that's the data-safety guard protecting your data, not a crash.*

*Known gaps, already queued, so no need to report them:*
- *Voice isn't in yet (Speak says "comes next"), and cook mode isn't built.*
- *A few typed phrases still land wrong: "buy a lightbulb" or "get a cake" can become a task; "tonight" with no time after 8 PM lands tomorrow; "move dentist to 3pm" can land in the past; a name ending in -ed ("Ahmed bday sat") can read as a past log. Undo fixes them.*
- *Days still cut at midnight, so "tomorrow" typed after midnight and Now after midnight behave oddly. The 4 AM day fix is next for Core.*
- *Review still marks rest days and half sessions like misses, and the week page doesn't show rest days yet. The Review fix is queued for Builder B.*
- *A workout finished with no sets still saves, and some undo lines still use old words ("Undone.", "Last set removed."). Both are queued.*

## Look and feel: what to notice (from Design studio)

1. **Type and paint on Home.** Does Inter Tight at the big sizes feel like your app? Does the painted background with hairline seams feel premium or washed out? Name one thing that looks stock.
2. **The hands-on moments.** Hold to finish, hold to log, the dial and the drum. Is each hold worth holding, and does the haptic land as one medium clunk with the softer stroke bloom?
3. **Moving between places.** Swiping Review, Today and Training, zooming into an exercise and back, starting a workout. Does anything jump, fade flatly or feel slow? Which transition did you like most?
4. **The shop.** Is striking an item satisfying in a real shop, and is the aisle word readable at arm's length?
5. **Tess's presence.** The soul in the corner, the writing line, the ghost row drying in 2 s. Alive without being distracting? Does cobalt read clearly as Tess's colour?

Screenshot anything that bugs you, or just say "this bit". Design takes your feedback first.

## Questions for the huddle

1. **What did you reach for first, and what didn't you find?** This tells us whether Home's layout and rail are right before we add more.
2. **Logging a set: is one hold, the dial and the drum fast enough between sets?** This decides gym polish versus new areas next week.
3. **Does the look feel like yours?** Paint, type, seams and Tess's bloom. What would you change first?
4. **What should Tess do for you first now that Claude is coming in?** Plan the day, answer "what did I lift", read recipes from links, or something else.
5. **After the gym and the kitchen, which area would you open daily?** Day log, Reading, Money, People or Home upkeep.
6. **What's running: keep the ledger, or move to the plate stack?** Recording at `/mnt/project-files/tessera/design/plate-stack.mp4`. *Recommendation:* keep the ledger unless the stack feels clearly better.
7. **Claude's monthly cap?** *Recommendation:* $10 a month, hard stop; expected use is under $1.
8. **Can Claude see your sleep and energy?** *Recommendation:* no. The phone decides "light day: yes or no" from your plan and calendar, never Health.
9. **When Tess's grammar misses something, should it go to Claude automatically?** *Recommendation:* yes, with a small cloud mark, since it always lands as an undoable ghost row. Your key goes into Settings: Claude on the phone, typed by you, once that screen ships; never paste it in chat.
