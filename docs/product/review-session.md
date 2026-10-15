# Review session: what to try tonight

*Planning lead, 2026-10-15, updated 2:37 PM Pacific. For Kaushik's first build on his phone: master `21566b8`, installed over the first build. It adds #110 (Finish, Start and Resume full size, "21 min ago") and #107 (Home links as a zoom, Kitchen on the rail). If something here isn't in the build, skip it and tell us.*

## What to try (about 15 minutes)

Home has a word rail across the top: **Review · Today · Training · Kitchen**. Every key is a painted stroke word, not a button. **Tess** is the soul in the corner: tap her to open the capture surface.

1. **Start a workout.** Go to Home, then **Training**, and tap today's push/pull/legs routine. The workout rises as its own screen. *Check:* does it feel like an instrument rather than a form?
2. **Log a set with one hold.** In the workout, each set opens already filled in. Hold to log it, then turn the **weight dial**, where the plates per side show beside it, and roll the **reps drum** for the next set. *Check:* the feel of the dial's clicks and the hold timing.
3. **Rest from the lock screen.** After logging a set, lock your phone. The rest timer runs on the Lock Screen, and **Done** logs the next set without unlocking.
4. **Leave and come back.** Swipe the workout down or kill the app mid-set, even during a rest, then reopen it. Home's **Resume** should take you back to the exact set, with the rest still counting.
5. **Swap an exercise.** In the workout, pull down on the exercise name and pick an alternative from the same movement pattern.
6. **Finish, and look at the exercise.** Finish the workout and see it saved on Home. Then tap an exercise name to open its page, with your best set and history.
7. **Plans.** From **Training**, open the week view and the month view.
8. **Tell Tess.** Tap Tess and choose **Write**, then type "log bench 80x8", "buy milk, eggs, 2 lemons", "call mum thursday" or "note: bar felt heavy". Each shows as a faded ghost row that saves after 2 seconds, and you can undo it. Speak and Show say "comes next" for now.
9. **Groceries.** Go to **Kitchen**, then Groceries. The items from step 8 are sorted by aisle. Tap one to strike it, then finish with the "Done shopping" stroke.
10. **Notes and Review.** Open the note from step 8, then swipe to **Review** to see the week as a sentence and zoom into The week.

**Bonus: Recipes.** In **Kitchen**, open Recipes and paste a recipe's text from a website or Notes. Watch it get read into ingredients and steps, then Save.

*If a calm note ever shows at launch, that's the new data-safety guard (#84) protecting your data, not a crash.*

*Known gaps, already queued, so no need to report them:*
- *Tapping a logged set to fix it comes with #109. Undo of the last set works now.*
- *Voice isn't in yet (Speak says "comes next").*
- *Cook mode isn't built yet.*
- *The next session doesn't raise the weight yet after you hit the top of the range.*

## Look and feel: what to notice (from Design studio)

1. **Type and paint on Home.** Does Inter Tight at the big sizes feel like your app? Does the painted background with hairline seams feel premium or washed out? Name one thing that looks stock.
2. **The hands-on moments.** Hold to finish on Home, hold to log in a workout, the weight dial and the reps drum. Is each hold (about 0.7 s) worth holding, and does the haptic land as one clean clunk rather than a buzz?
3. **Moving between places.** Swiping Review, Today and Training, zooming into an exercise and back, and starting a workout. Does anything jump, fade flatly or feel slow? Which transition did you like most?
4. **Groceries strike and sink.** Is striking an item satisfying enough to use in a shop, and is the text readable at arm's length?
5. **Tess's presence.** The soul in the corner opening into the capture surface, and the ghost row drying in 2 s. Does it feel alive without being distracting, and does cobalt read clearly as Tess's colour?

Screenshot anything that bugs you, or just say "this bit". Design takes your feedback first after the review.

## Nine questions for the huddle

1. **What did you reach for first, and what didn't you find?** This tells us whether Home's layout and rail are right before we add more apps.
2. **Logging a set: is one hold, the dial and the drum fast enough between sets, or is anything in the way?** This decides how much of the next week goes into gym polish versus new areas.
3. **Does the look feel like yours?** That covers paint, type, seams and Tess's bloom. What would you change first? Design can redirect now, cheaply, before more screens are built.
4. **What should Tess do for you in the first week now that Claude is in?** For example: plan the day, answer "what did I lift", read recipes from links, or something else. This sets the order of the new Tess model layer.
5. **After the gym and the kitchen, which area would you open daily?** The candidates are the Day log, Reading, Money, People or Home upkeep. This orders everything after M4.
6. **What's running: keep the ledger, or move to the plate stack?** Design's plate stack concept is in `docs/design/plate-stack.md`, with a recording at `/mnt/project-files/tessera/design/plate-stack.mp4`. Builder B keeps the ledger until you choose. *Recommendation:* watch the recording first, and keep the ledger unless the stack feels clearly better in your hand.
7. **Claude's monthly cap?** *Recommendation:* $10 a month, hard stop. Expected use is under $1, and at the cap Tess falls back to the phone and tells you once.
8. **Can Claude see your sleep and energy?** *Recommendation:* no. The phone decides whether it's a light day and Claude only sees "light day: yes or no".
9. **When Tess's grammar misses something you typed, should it go to Claude automatically?** *Recommendation:* yes, with a small cloud mark on the bloom, since it always lands as an undoable ghost row. Also: paste your Claude API key in Settings once the model layer ships (the coordinator will ask for it).
