# Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; #71 people and upkeep; #73 lists templates, habits, add a field, quiet interrupts, body weight trend; #76 habits citations checked; #78 Plan my day scenarios, questions eval, Calendar and Health fixtures, Shutdown and Day log copy, Reading draft ship list; #83 Tess model layer (Claude integration); #85 recipe paste corpus, cook-mode scenarios, Lists fixtures, grammar collisions. #85 recipe paste corpus, cook mode scenarios, Lists fixtures, grammar collision audit. #87 Tess model layer addendum (catalog tools, pitfalls).

**Now:** Claude capture eval set for model-layer T4 and T5. Done when `tess-eval-claude.md` has 80 phrases the grammar misses today, each with the expected strict tool calls from the 8 tools in `tess-model-layer.md` section 2, or "no tool, clarify". Include the 36 collisions from `grammar-collisions.md`, run-ons with two or three intents, and voice-dictation noise. For 10 of the phrases, also give the expected context pack: what leaves the phone and what must not.

**Also running in parallel:** Next 1 to 3.

**Next:**
1. Money draft ship list for M5 (after Reading). Done when `ship-list-m5-money-draft.md` follows the shape of `ship-list-reading-draft.md`: a `Spend` class, "spent 12.40 lunch" in the grammar, the receipt total asked when a shop finishes, a month line with no budgets screen, 15 eval phrases, and amounts stored as typed (Kaushik's default, no home currency yet). Check `m5-money-reading.md` and master so nothing repeats.
2. v1 gap audit. Done when `v1-gap-audit.md` lists each of the 19 slices in `../product/ship-list.md` as on master, partly or missing, with the file that shows it, read from master after tonight's build. This feeds the post-huddle plan.
3. Recipe link fetch scouting (approved 18:41; builds with kitchen v2 after a week of use). Done when `recipe-link-fetch.md` covers fetching a pasted URL on the phone, reading schema.org Recipe JSON-LD first, the deterministic parser next, and Claude (Haiku, `createRecipe`) last, with 10 real recipe URLs' expected results and the failure cases (paywalls, no JSON-LD, video-only).
4. Apple Watch in Tessera (Kaushik wears one, 18:41). Done when `apple-watch.md` says what we get with no Watch app (sleep stages, resting HR, HRV and workout heart rate read from Health after the fact) versus what needs one (live heart rate during a set, logging from the wrist), with a recommendation, the smallest first version, and whether free Personal Team signing can install a Watch app.
5. Tess voice for the model layer. Done when `tess-voice.md` gains the lines for key saved, Claude paused at the cap, "1 waiting for Tess", "via Claude" receipts, the cloud mark's accessibility label and a Claude timeout, each checked against the voice rules.
6. Home upkeep draft ship list (M5, after Money; Kaushik put upkeep before People). Done when `ship-list-m5-upkeep-draft.md` follows the Reading draft's shape: `Chore` as a habit with an interval, "watered plants" resets it, "6 days ago" rather than overdue red, the stalest drifting toward Now, and 15 eval phrases. Check `people-and-upkeep.md`.

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.
