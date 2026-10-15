# Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; #71 people and upkeep; #73 lists templates, habits, add a field, quiet interrupts, body weight trend; #76 habits citations checked; #78 Plan my day scenarios, questions eval, Calendar and Health fixtures, Shutdown and Day log copy, Reading draft ship list; #83 Tess model layer (Claude integration); #85 recipe paste corpus, cook-mode scenarios, Lists fixtures, grammar collisions. #85 recipe paste corpus, cook mode scenarios, Lists fixtures, grammar collision audit.

**Now:** Claude capture eval set for model-layer T4 and T5. Done when `tess-eval-claude.md` has 80 phrases the grammar misses today (include the 36 collisions from `grammar-collisions.md`, run-ons with two or three intents, voice-dictation noise), each with the expected strict tool calls from the 8 tools in `tess-model-layer.md` section 2 or "no tool, clarify", plus the expected context pack for 10 of them (what leaves the phone and what must not).

**Next:**
1. Money draft ship list for M5 (after Reading). Done when `ship-list-m5-money-draft.md` follows the shape of `ship-list-reading-draft.md`: a `Spend` class, "spent 12.40 lunch" in the grammar, the receipt total asked when a shop finishes, a month line with no budgets screen, 15 eval phrases, and amounts stored as typed (Kaushik's default, no home currency yet). Check `m5-money-reading.md` and master so nothing repeats.
2. v1 gap audit. Done when `v1-gap-audit.md` lists each of the 19 slices in `../product/ship-list.md` as on master, partly or missing, with the file that shows it, read from master after tonight's build. This feeds the post-huddle plan.
3. Recipe link fetch scouting (approved 18:41; builds with kitchen v2 after a week of use). Done when `recipe-link-fetch.md` covers fetching a pasted URL on the phone, reading schema.org Recipe JSON-LD first, the deterministic parser next, and Claude (Haiku, `createRecipe`) last, with 10 real recipe URLs' expected results and the failure cases (paywalls, no JSON-LD, video-only).

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.
