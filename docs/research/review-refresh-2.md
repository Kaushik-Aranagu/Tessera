# Review refresh 2: what changed since the install, and what to try

*Research lab, board item 84, Oct 16. For Product to fold into `product/review-session.md` before the Oct 22 re-sign.
Covers every app PR merged after the install commit b19fb4a (#183), up to master 4518c48. Docs-only PRs (#185, #186,
#188, #189, #192, #194, #196, #198, #200, #202, #204, #206, #208, #209, #212, #213, #214, #216, #217, #220, #222) are
left out. Lines are quoted from master's code or QA's reviews. All times are Pacific. Nothing here was run on a
phone; every expected line is read from code.*

**Time marks.** *Late night* = after midnight, before 4 AM. *After 4 AM* = the first open of the new day.
*Night look* = when the phone is in Dark appearance (with Automatic, after sunset, about 6:15 PM Pacific this week),
or any time by flipping Dark Mode in Control Center. The look never reads the clock.

## What to try

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
6. **The workout follows the look.** [#203, #207] With Porcelain by day, start a workout. Expect: a plum-black
   ground (not the old purple paper), cream keys you can read. Pin Porcelain and start again: keys still cream.
7. **The workout holds its look.** [#203, #207] Mid-workout, flip Dark Mode. Expect: the workout does not change
   until you finish or close it; Home then shows the night look.
8. **Out of a workout, back to white.** [#215] Phone in Light, nothing pinned. Start a workout, tap an exercise name
   to open its page, go back, finish. Expect: Home is white with no glow around Tess's soul or the seams.
9. **Lock Screen in the look.** [#215] Log a set, lock the phone. Expect: in Light the rest card is plum-black with
   an amber timer; in Dark it is pure black with a warmer amber. The Dynamic Island is black in every look.

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

*Known gaps in this build, already queued, so no need to report them:*
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

## Drop or change in the current guide
- *Known gap* "Days still cut at midnight...": done by #187 and #219. Replace with items 19 to 23.
- *Known gap* "Review still marks rest days and half sessions like misses...": done by #184, #197, #201 and #219.
  Replace with items 24 to 28.
- *Known gap* "A workout finished with no sets still saves": empty routines can't start (#190, #195, #197) and a
  forgotten empty one closes after 6 h (#187). Keep only the "Undone." line in the routine editor; not checked here
  whether finishing an empty workout by hand still saves.
- Item 4 (Rest day): branch ios/now-rank is in b19fb4a, so the tag is stale; drop it if he has tried it.
- Look and feel 1 and Question 3 ("painted background", "Paint, type, seams"): superseded by the five looks. Ask
  instead: "Is Porcelain by day right, or should Plein come back as the default?"
- Questions 7 and 8 (Claude's cap, Health): decided and built ($10 fixed cap in #218; Health never sent). Drop.
- Question 9: keep the key part only if Settings: Claude lands; the key never goes in chat either way.

## 10-minute short path
1. Daytime: item 1 (white Home), then items 3 to 5 on Review (tap, then hold, then hold again). 2 min.
2. Item 2: flip Dark Mode and back. 30 s.
3. A short workout: item 6, then items 10, 11 and 12 typed to Tess, then lock for item 9. 4 min.
4. Item 15: glance at an empty routine for no Start word. 30 s.
5. Items 24 and 25 on Review. 1 min.
6. Item 29 on Backups, and item 32 in Tess. 1 min.
7. Items 33 to 35 only if Settings: Claude is in the build. 1 min.
8. If he is up after midnight, add items 20 and 26 (1 min); otherwise skip all late-night items.
