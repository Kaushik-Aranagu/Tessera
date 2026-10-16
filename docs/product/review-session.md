# Review session: what to try on this build

*Planning lead, updated 11:30 PM Pacific, Oct 15. **Installed: 444e72b, at 11:28 PM PT Oct 15, over the existing app with your data kept.** It folds in Research's `review-refresh-2.md` (#223) and QA's review-215 smoke step. Not in this build: Settings: Claude (items 33 to 36), Speak, the ink-line keys (#278) and Plan my day, so skip those. First, pick your iCloud Drive folder in Review > Backups. If something else here isn't in the build, skip it and tell us. Late-night items only apply between midnight and 4 AM, since your day ends at 4 AM.*

## Next build: 7b321d2 (install commit, pinned 1:09 AM PT Oct 16; installs only on your own "install it" in the iOS build thread)

It adds #320 (the Tess asks Claude switch), #330 (the icon and the closer soul), #337 (Training opens on today's plan), and the haptics (#317) and Speak (#312) merged since 444e72b. It also has #343: Return now saves in Notes instead of making a new line. Home still uses the old wording. Five minutes:
1. **The icon.** On the Home Screen, Tessera shows Tess's soul. Inside the app, the soul's dabs sit closer together.
2. **Tess asks Claude.** In Settings, CLAUDE, the first line reads "Tess asks Claude: yes." Tap it to switch to no ("Tess stays on this phone.") and back. Then type your key yourself in "Add a Claude key", if that row is there. Never paste it into chat.
3. **Finish a task.** Finish one. Expect one three-beat tap and the strike, all under a second. With System Haptics off in iPhone Settings, expect no tap at all.
4. **Training at rest.** Open Training. It should open on today's plan, with START and the routine name as an ink-line word. On the eve of a rest day, the done label still names the next routine ("Push A tomorrow"); "Rest day tomorrow" comes in the next build.
5. **Return in Notes.** In a note, press Return. It saves instead of starting a new line.
6. **Speak.** Tap the soul once to open Tess; a double tap goes Home. Hold the soul to speak "call mom at 7".
Not yet in this build: one plain line per thing on Home, the glass tabs, routines by day, recipe layouts and the week on Review. Those come in the build after, before Oct 22.

## 10-minute short path

1. Daytime: item 1 (white Home), then items 3 to 5 on Review (tap, then hold, then hold again). 2 min.
2. Item 2: flip Dark Mode and back. 30 s.
3. A short workout: item 6, then items 10, 11 and 12 typed to Tess, then lock for item 9. 4 min.
4. Item 15: glance at an empty routine for no Start word. 30 s.
5. Items 24 and 25 on Review. 1 min.
6. Item 29 on Backups, and item 32 in Tess. 1 min.
7. Items 33 to 35 only if Settings: Claude is in the build. 1 min.
8. If he is up after midnight, add items 20 and 26 (1 min); otherwise skip all late-night items.

## New in this build (about 25 minutes for all of it)

Every key is a painted stroke word, not a button. **Tess** is the soul in the corner: tap her to open the capture surface. UNDO is one vermilion word everywhere.

**The look** (on every screen, from the first open)
1. **White by day.** [#193, #195] Open the app in daytime. Home is white (Porcelain), no longer the cream paper.
   Expect: white ground, ink text, colour pooling only behind what is live. Nothing else to do.
2. **Black by night.** [#193, #199] *Night look.* Turn on Dark Mode with the app open. Expect: the page swaps at
   once to true black (Obsidian), with no paint flood, and the status bar text turns light.
3. **The LOOK sentence.** [#195, #199] On Review, open the full week and scroll to the foot, just above "Backups".
   Expect the label LOOK, then "**Porcelain** by day, **Obsidian** by night." and under it "Hold a name to keep it day
   and night."
4. **Change the day look.** [#193, #199] Tap "Porcelain". Expect: it becomes "Plein" and the page crossfades to cream
   in under a second, with a light tick. Tap again for "Celadon" (pale green), again for Porcelain. Tap "Obsidian"
   in daytime: the word becomes "Lacquer" and the page does not change.
5. **Pin one.** [#199, #203] Hold a name for half a second. Expect a firmer haptic and "**Obsidian** always." with
   "Hold it again to follow light and dark mode." Hold again: the sentence opens back out, the look in its own slot.
6. **The workout follows the look.** [#203, #207, #266] With Porcelain by day, start a workout. Expect the same
   white base as Home, with only the workout's layers on top. Flip to Obsidian and it follows.
7. **The workout holds its look.** [#203, #207] Mid-workout, flip Dark Mode. Expect: the workout does not change
   until you finish or close it; Home then shows the night look.
8. **Out of a workout, back to white.** [#215] Phone in Light, nothing pinned. Start a workout, tap an exercise name
   to open its page, go back, then finish or close the workout. Expect: Home is white with no glow around Tess's soul or the seams. (QA review-215 smoke step.)
9. **Rest on the Lock Screen.** [#215, #269] Log a set, lock the phone. Expect the rest card in Cobalt sky with the
   horizon timer in every look, Light or Dark. The Dynamic Island is black in every look.

**Workout**
10. **Weights the bar can't make.** [#205, #210] In a workout on a barbell lift, tap Tess, then Write "81 for 8".
    Expect "Set N. 80 x 8. 81 isn't loadable." (your set number).
11. **Effort with a set.** [#205] Write "100 for 5 at 8". Expect "Set N. 100 x 5 @8." Then "same at 9": expect
    "Same again @9, logged."
12. **Numbers that could be a weight.** [#205] Write just "81", then "+5". Expect: no set and no task for either.
    "call mum at 7" mid-workout still lands as a task.
13. **Dictated and comma phrases.** [#210] Use the keyboard mic to say "same at nine" (iOS adds a full stop). Expect
    the same line as typed. Type "8, 81": expect no sets (81 may be a weight). Type "100 for 5, at 8": one set @8.
14. **Set kinds and load words.** [#205, #210] Write "warmup 60x5" (a warmup set), "80 x 6 to failure", and on a
    plate-loaded lift "bar for 10" (20 x 10). On a pull-up, "bodyweight 12" logs 0 x 12.
15. **Empty routines can't start.** [#190, #195, #197] Open a routine with no exercises (make one in Plans, or empty
    one). Expect: no Start word on Now, on the rest day or in Training. Siri's Start refuses it too.
16. **Set aside on the Lock Screen.** [#190] Log a set, let the rest run out to "Go", leave the phone locked 10
    minutes. Expect the Lock Screen to read the routine name over "set aside", and "Aside" in the Island, instead of
    Go all night.
17. **No ghost rest.** [#190, #195] During a rest, take the set back from the Lock Screen Undo, then kill and reopen
    the app. Expect: no rest restored for the removed set. A rest dragged longer after a relaunch keeps its set.
18. **A forgotten empty workout.** [#187] *Only when it happens:* a workout opened and left 6 hours with no sets.
    Expect Tess to say "Closed Push A, nothing was logged" (your routine) and no trained day saved.

**Today and Now after midnight** (his day ends at 4 AM)
19. **"Today" still means tonight.** [#187, #219] *Late night.* Look at Today and the day strip. Expect: still the
    evening's day; items from midnight to 4 AM sit at the end of that day, not on the next one.
20. **Times typed after midnight.** [#187] *Late night* (say 12:30 AM Saturday). Write "coffee at 3". Expect
    "Coffee, Saturday 3 pm." (the weekday, never "tomorrow"). "remind me tomorrow at 9" lands Saturday 9 am, and the
    line ends "On Now then."
21. **A late workout stays on its day.** [#187, #219] *Late night.* Finish a workout started before midnight. Expect
    it on the day it started in Review and in Exercise history, and Now does not offer it as tonight's.
22. **Carried tasks.** [#187, #219] *After 4 AM* (and likely on the first open after install). With undone dated
    tasks from earlier days, expect one line by the soul, once: "Carried 2 tasks into today." (your count).
23. **Move a task late.** [#219] *Late night.* Drag a row left to move an untimed task. Expect "Moved to next week."
    and the task at 9 am on the same weekday of his day next week, not one day off.

**Review week**
24. **The session count.** [#184, #197] Swipe to Review. Expect a headline that counts sessions, such as "Four
    sessions this week", "All six sessions in" or "A quiet week so far", never "good" and never "of seven", and never
    one word alone on a line.
25. **Rest, misses and days ahead.** [#184, #197, #201, #219] Look at the week row, Monday first. Expect: trained
    days marked, planned rest as a dry ink stroke in the lower half, a ring only on a past day that was due, nothing
    on days ahead, nothing before you started. Two sessions in one day count as one day.
26. **No false miss after midnight.** [#219] *Late night.* On a day you haven't trained yet, open Review after
    midnight. Expect: that day has no ring (it is still today until 4 AM).
27. **Tess's fact.** [#184] *Only after more than 3 sessions in the week.* Expect a line like "Front delts: 3 sets
    this week, toward a usual 10."
28. **The full Review.** [#197] Open the full week. Expect the same marks, and "Something done on four days" style.

**Backups**
29. **The day's copy.** [#191, #211] Review, foot, "Backups". Expect "Kept on this iPhone" (or "Kept in two places"
    with a folder), and "A copy is made every day, the last one today. Seven are kept."
30. **Late copies count for the evening.** [#211] *Late night.* Leave the app, reopen. Expect "the last one today".
    In Files, On My iPhone, Tessera, Backups, the newest file carries the evening's date; *after 4 AM* the next
    leave adds a file with the new date.
31. **A folder that's gone.** [#211] *Optional.* Choose a test folder in iCloud Drive, delete it in Files, leave the
    app and come back. Expect "The folder you chose can't be reached, so copies are only on this iPhone. Choose it
    again." and the headline "Kept on this iPhone". Tell us if nothing shows (the folder may sit in Recently Deleted).

**Tess and the Claude key**
32. **A key typed in the wrong place.** [#218] Write "sk-ant-test" (a made-up key, never a real one). Expect "That
    looks like a Claude key. Paste it in Settings." and nothing saved.
33. **Settings: Claude, no key.** [if merged by install; key store #218] Open Settings: Claude. Expect "Tess thinks on
    this phone only." and **Add a Claude key**. The LOOK sentence may move there from Review.
34. **Paste something wrong.** [if merged by install] Tap Add, paste "hello". Expect "That doesn't look like a Claude
    key. Paste it again?" and nothing saved.
35. **Your key.** [if merged by install] Paste your key from the Console (typed by you, never in chat). Expect
    "Checking it with Claude." then "Key saved. Ends in ...a1B2." (your last four), "Key ends in ...a1B2 · works",
    and "This month $0.00 of $10." The Test costs nothing.
36. **Remove and undo.** [if merged by install] Tap REMOVE. Expect "Claude key removed. Everything stays on this
    phone." with UNDO for 10 s; UNDO says "Claude key is back."

## Still worth trying from the last guide

*Numbered A1 to A20 so they don't clash with the new items.*

**Today and Now**
A1. **Finish a task with a swipe.** [#116, #151] On Today, rest a finger still on a row in Next or Later for a moment, then drag it right. The name strikes through, the row leaves, and Tess says "Done. *title*." with UNDO, which brings it back.
A2. **Flick past the rows.** [#151] Flick quickly left or right across the same rows without pausing. Home pages to Review or Training, and no task is finished or moved.
A3. **Move a task.** [#116] Press still on a row, then drag it left. A timed task says "Moved to tomorrow." and an untimed one "Moved to next week.", both with UNDO.
A4. **Rest day.** [in b19fb4a] On a planned rest day, Now shows a quiet "Rest day" line instead of the next routine, which stays one tap away in Training. A running workout or anything timed in the next 15 minutes still comes first.

**Workout**
A5. **Start and log.** [#91, #108] Training, then today's routine. Each set opens filled in: hold to log it, turn the **weight dial** (plates per side beside it) and roll the **reps drum**. *Check:* the dial's clicks, and whether each hold lands as one clean clunk.
A6. **Fix a set.** [#109] Log two sets, tap set 1's stroke, change it, and tap "Save set 1". The other strokes dim, and Tess says "Set 1 is 80 × 7 now." (your numbers) with UNDO.
A7. **Remove a set mid-rest.** [#146] While a rest counts down, tap that set's stroke and tap REMOVE. Tess says "Set N removed.", and the countdown stops on the Lock Screen too.
A8. **Rest from the Lock Screen.** [#91] Lock the phone after a set: the rest runs there, and **Done** logs the next set without unlocking.
A9. **Swap, then leave.** [#121] During a rest, pull down on the exercise name, pick an alternative, then kill the app and reopen. Resume takes you back with the rest still counting.
A10. **Tess in the workout.** [#134, #146] Tap her soul in the bottom-right: a writing line with CLOSE as a word. Double tap her to go back to Today, where Now shows Resume. On the last set, "Last one. Hold to finish." stays until you finish.
A11. **Finish, and look at the exercise.** [#91, #122] Finish and see it saved. Tap an exercise name for its page, with your best set and history. *Only when it happens:* after a session where every set hit the top of the range, set 1 says "Up 2.5 kg from last time".

**Tell Tess** (tap her, then Write)
A12. **"coffee at 7"** [#153] before 7 PM lands "Coffee, today 7 pm." A bare 1 to 6 means PM; 7 to 11 means the next one that hasn't passed today.
A13. **"watered plants sat"** [#153] saves a note dated last Saturday ("Noted for Saturday."), not a task.
A14. **"get a haircut", then "get coffee".** [#153] The haircut lands as a task in Later; coffee goes on Groceries.
A15. **"are we out of milk"** [#117, #153] saves nothing. Questions are never filed as tasks or items.

**Kitchen**
A16. **Groceries.** [#118, #124, #131] Kitchen, then Groceries. Type "3 egg" on the Add line: "3 eggs" files under its aisle. Hold the "Groceries" title (about 0.7 s) to start the shop: the aisle you're in is the big word, with the next one peeking. Tap items to strike them into the basket.
A17. **Clear the basket.** [#124, #131] Mid-shop, tap the basket, hold "Clear the basket", then tap UNDO: everything goes back. Finish with the "Done" hold key. Tell us if the UNDO line ever shows a line from somewhere else.
A18. **Recipes (bonus).** [#86] In Kitchen, open Recipes and paste a recipe's text. It's read into ingredients and steps; then Save.

**Review**
A19. **Backups.** [#118, #124, #126] On Review, scroll to the foot and tap "Backups". Go back once with "‹ Review" and once with an edge swipe. An edge swipe on Review itself does nothing, and nothing freezes.
A20. **Restore, safely.** [#120] Only if a Tessera copy is in Files: tap Restore and pick it. You get a question first; tap "Keep what's here", which changes nothing. Don't hold Replace on the phone.

*After any reinstall (only if the app was ever deleted): restore first, reopen, then pick the iCloud Drive folder again, and paste a fresh Claude key. A normal re-sign installs over the app and needs none of this.*

*Install-day check, only once Speak is in the build: deny the mic, then turn it on in Settings > Tessera and come back. Tell us whether the app restarted or picked up where you were (Research `speak-first-use.md`, open question).*

*Install-day check for the Mac session (QA L2 on #274): "curls" now resolves to Dumbbell Curl; if his library has sets under an older "Curl" exercise, check that new curls don't land on a different exercise.*

*Install-day checks for the Mac session, not for him (Research `widget-states.md` questions 3 and 5): whether the widget blanks or keeps its last entries once the free profile lapses (only if it lapses before the re-sign), and whether `embedded.mobileprovision` is readable at runtime on this free-signed install.*

*If a calm note ever shows at launch, that's the data-safety guard protecting your data, not a crash.*

*Known gaps, already queued, so no need to report them:*
- *Changing the look crossfades; the paint flood from Tess's soul comes with Settings. Lacquer's sheen doesn't move
  with tilt yet. The look isn't in backups, so a reinstall starts on Porcelain and Obsidian again.*
- *Contrast fixes are proposed, not merged (`theme-contrast-fixes.md`): on Obsidian the process step text is dim, the
  seam under a waiting process is a bright white line, a held row glows instead of lifting, and the Paste Recipe band
  can't be seen; on Porcelain, Best e1RM on an exercise page is amber on white and hard to read, and the day stroke's
  sky and amber ends are faint.*
- *Set asks: "bench 80 for 8, 81" can still log 80 x 81; "4x8" on dumbbells logs 4 kg x 8; "warmup 60x5 @7" asks
  instead of logging. Spoken numbers ("eighty two and a half") wait for the normaliser.*
- *Sets logged from Siri or the Lock Screen don't trigger a backup until you next leave the app.*
- *There is no Day log yet; late-night lines for it are traced in `day-log-late-night.md`.*
- *Voice isn't in yet (Speak says "comes next"), and cook mode isn't built. [fix: not started, Builder B Speak; cook mode Builder A]*
- *A few typed phrases still land wrong: "buy a lightbulb" or "get a cake" can become a task; "move dentist to 3pm" can land in the past; a name ending in -ed ("Ahmed bday sat") can read as a past log. Undo fixes them. [fix: Core grammar batch]*
- *Some undo lines still use old words ("Undone." in the routine editor). [fix: Builder A undo batch]*

## Look and feel: what to notice (from Design studio)

*For the Oct 22 build (444e72b). Five things, about a minute each. Two changes you asked for are merged but **not in this build**: the thin ink line under action words (Log set, Finish and Start still sit on the thick band you didn't like, #278), and Speak (voice still says it comes next, #273). The Settings page, the Day log, Habits and the evening on Now aren't in it either, so skip judging those.*

1. **One base, day and night.** *Path:* by day, START today's workout from Now, log a set, finish, then turn on Dark Mode. Expect the workout on the same white as Home, with only its layers on top, and Home in true black once Dark Mode is on. Does anything still feel like a separate room? The Lock Screen rest card stays Cobalt sky in every look; that's your pick.
2. **Colour only in moments.** *Path:* on Home, drag a task right to finish it. Expect the strike to paint in the row's colour, then dry to ink, and no coloured dots anywhere at rest. Is the moment dramatic enough, or too quiet?
3. **The calmer capture.** *Path:* tap Tess's soul, tap Write, type something you'd really log, then Return. Expect smaller words, one question line, no suggestions, and the line drying for 2 s before Tess answers. Neat and peaceful, or still busy?
4. **Changing the look.** *Path:* Review, scroll to the foot, tap "Porcelain". Expect the paint to flood out from Tess's soul into Plein with a light tick. Tap back round to Porcelain, then hold a name to pin it. Is the flood worth seeing every time? (Next build moves this to a Settings page, and the flood starts from the name you tap.)
5. **The day stroke.** *Path:* on Home, look at the line under the day label, then swipe to Review and back. Expect a thin stroke that ends at now with a slow sheen, and a small carriage under the pages. This is the weight the action words get next build. Is it thin enough?

Screenshot anything that bugs you, or just say "this bit". Design takes your feedback first.

## Questions for the huddle

1. **What did you reach for first, and what didn't you find?** This tells us whether Home's layout and rail are right before we add more.
2. **Logging a set: is one hold, the dial and the drum fast enough between sets?** This decides gym polish versus new areas next week.
3. **Is Porcelain by day right, or should Plein come back as the default?** *Recommendation:* keep Porcelain by day and Obsidian by night; Plein stays one hold away.
4. **What should Tess do for you first now that Claude is coming in?** Plan the day, answer "what did I lift", read recipes from links, or something else.
5. **After the gym and the kitchen, which area would you open daily?** Day log, Reading, Money, People or Home upkeep.
6. **What's running: keep the ledger, or move to the plate stack?** Recording at `/mnt/project-files/tessera/design/plate-stack.mp4`. *Recommendation:* keep the ledger unless the stack feels clearly better.
7. **When Tess's grammar misses something, should it go to Claude automatically?** *Recommendation:* yes, with a small cloud mark, since it always lands as an undoable ghost row. If Settings: Claude is in the build, make a fresh key in the Console and type it in there yourself; never paste it in chat.
