# Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; #71 people and upkeep; #73 lists templates, habits, add a field, quiet interrupts, body weight trend; #76 habits citations checked; #78 Plan my day scenarios, questions eval, Calendar and Health fixtures, Shutdown and Day log copy, Reading draft ship list; #83 Tess model layer (Claude integration); #85 recipe paste corpus, cook-mode scenarios, Lists fixtures, grammar collisions; #87 model layer addendum (catalog tools, pitfalls); #90 Money draft, v1 gap audit, recipe link fetch; #94 Apple Watch, Tess voice for the model layer, Upkeep draft; #96 Claude capture eval set (80 rows); #99 Plan my day prompt pack, People draft, app from a sentence, eval for 10 tools; #100 context packing, huddle triage kit; #101 speech capture, photo/file/video capture modes.

**Now:** Keep the app alive under free signing. Done when `free-signing-survival.md` says:
- exactly what happens to his data when the 7-day profile expires and when the app is reinstalled from Xcode;
- the least-effort way to re-sign each week (wireless Xcode, or anything allowed and on-device);
- a one-file export and restore to Files that the app should offer, so a bad reinstall never loses his logs;
- the smallest Core slice for that export and restore.

**Next:**
1. A year of synthetic data. Done when `fixtures/year-of-data.md` specifies a generator for 12 months of realistic use (PPL workouts with progression, tasks, notes, groceries, cooks, chores, spends), its seed and its size, plus what to measure with it: launch time, Home ranker time, the Plans month view and scroll smoothness. Core can then build it as a test fixture.
2. Learning Tess without a manual. Done when `tess-discoverability.md` proposes how he picks up phrases in his first two weeks: hints inside the capture surface, ghost-row "you can also say", a phrase shown when he does something by hand, and how often each appears before it stops. Include 20 hint lines checked against `tess-voice.md`.
3. Ranker tuning from real use. Done when `ranker-tuning.md` lists what to log on the phone (the pick, its why, whether he followed it, overrides) so that after a week the weights in `context-packing.md` can be retuned. It must stay on the device and add nothing to the screen.

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.
