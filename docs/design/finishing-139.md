# Item 139: Finishing moments, build sheet (Oct 22)

Builds sheet 136 E. Review switch finishMoments (default Off). Each moment uses the app's
signature, writes its result into the app's sentence, and dries to ink. No scores, no
streaks, no counts of misses. One haptic per moment. Reduce Motion: the end state appears
with a 150 ms crossfade. Tess's Done state never changes.

1. Training (Builder A). Last working set logged: that set's ring closes (existing brush
   circle), then the session's set marks gather (house spring, 35 ms stagger) into one
   ring that travels to Today in the week row and fills ink; one rigid tap. Sentence:
   "{Session}, all sets in. {length}." ("Push A, all sets in. 52 min."). Warm-ups never
   count. A finished-early session: "{Session}, done. {length}." Never "missed".
2. Kitchen (Builder A, cook screens). Last timer and last step done: the time spine (132)
   draws together into the serve rule; the serve time rolls in ochre and dries:
   "Served at 7:02." Landing sentence after: "Tacos, served at 7:02."
3. Lists (Builder B). Last item struck: the filling line reaches the end, the name inks
   fully; line under: "All packed." / "All done." (by list kind word if set, else "All
   done."). Reusable: "Reset it for next time" ink word. Picks: no fill, no moment.
4. Routines (Builder A). Last step: the Thread draws through it and ties off in a small
   loop (one 14 pt circle stroke in rose that dries to ink); "{Routine}, {length}." and
   under it "Tomorrow, usually {start}." in ink 2.
5. Tasks (Builder B). Strike follows the finger (existing); on release the struck line
   folds up into the day sentence's tasks clause: "{n} done today." (no "of N").
6. The day (Builder B, Core). At shutdown (existing Shutdown): the day sentence is rebuilt
   in the past tense from what happened ("Pushed, cooked tacos, packed. Rent paid."),
   all ink, and becomes the day's line in Review. Core: HomeSentence.past(day), from
   DayStory and done processes only; money only as "Rent paid." words, never amounts.
