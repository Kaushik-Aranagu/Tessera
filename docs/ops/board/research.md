# Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; #71 people and upkeep; #73 lists templates, habits, add a field, quiet interrupts, body weight trend; #76 habits citations checked; #78 Plan my day scenarios, questions eval, Calendar and Health fixtures, Shutdown and Day log copy, Reading draft ship list; #83 Tess model layer (Claude integration); #85 recipe paste corpus, cook-mode scenarios, Lists fixtures, grammar collisions; #87 model layer addendum (catalog tools, pitfalls); #90 Money draft, v1 gap audit, recipe link fetch; #94 Apple Watch, Tess voice for the model layer, Upkeep draft; #96 Claude capture eval set (80 rows); #96 Claude capture eval set; #99 Plan my day prompt pack, People draft, app from a sentence, eval for 10 tools.

**Now:** Context packing, or how Home picks what to show (Kaushik's principle, `../product/spatial-interaction.md` section 0). Done when `context-packing.md` proposes:
- the signals: running process, time of day, last action, place in the app, calendar;
- a small scoring rule that NowPicker and Home can share;
- 20 moments in a day, with what the one screen should show at each;
- the smallest first version.

**Next:**
1. On-device speech to text for the Ask Tess capture surface. Done when `speech-capture.md` covers Apple's on-device speech framework on iOS 27: whether it runs offline, latency, how it handles gym noise and numbers ("eighty for seven"), the mic and speech usage strings, and free signing. It should also cover cleaning the transcript into a sentence (grammar normaliser first, then the model layer), give 30 spoken phrases with expected transcripts and parses, and say what Builder B needs.
2. Photo, file and video modes for the capture surface. Done when `capture-modes.md` says what Tess does with each input, smallest first version first: a receipt photo gives the shop total (on-device Vision text), a recipe photo or screenshot gives a recipe, and a photo of a page gives a note. It should state what stays on the device and what may go to Claude through the model layer, and give 15 example inputs with expected results.
3. Huddle follow-through kit. Done when `huddle-triage.md` is a one-page template that turns Kaushik's review feedback into board items. It should have a row per remark with the area, the owner team, size, and whether it's a bug, polish or a new idea, plus a pre-filled row for each of the 9 huddle questions in `../product/review-session.md`, so feedback becomes board items within minutes.

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.
