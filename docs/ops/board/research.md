# Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; #71 people and upkeep; #73 lists templates, habits, add a field, quiet interrupts, body weight trend; #76 habits citations checked; #78 Plan my day scenarios, questions eval, Calendar and Health fixtures, Shutdown and Day log copy, Reading draft ship list; #83 Tess model layer (Claude integration); #85 recipe paste corpus, cook-mode scenarios, Lists fixtures, grammar collisions; #90 Money draft, v1 gap audit, recipe link fetch; #94 Apple Watch, Tess voice for the model layer, Upkeep draft. #85 recipe paste corpus, cook mode scenarios, Lists fixtures, grammar collision audit. #87 Tess model layer addendum (catalog tools, pitfalls). #90 Money draft ship list, v1 gap audit, recipe link fetch; #94 Apple Watch, Tess model-layer voice lines, upkeep draft.

**Now:** Claude capture eval set for model-layer T4 and T5. Done when `tess-eval-claude.md` has 80 phrases the grammar misses today, each with the expected strict tool calls from the 8 tools in `tess-model-layer.md` section 2, or "no tool, clarify". Include the 36 collisions from `grammar-collisions.md`, run-ons with two or three intents, and voice-dictation noise. For 10 of the phrases, also give the expected context pack: what leaves the phone and what must not.



**Next:**
1. Plan my day prompt pack for model-layer T6. Done when `plan-my-day-prompt.md` has the instructions text Sonnet gets, the `proposePlan` schema, 3 worked examples, and the validation rules (same object ids, at most 3 lines, `TessVoice` rules). Hand-check it against the 20 scenarios in `plan-my-day-scenarios.md` and list which would fail validation and why, so Core can paste it straight into T6.
2. People draft ship list (M5, after Upkeep). Done when `ship-list-m5-people-draft.md` follows the Reading, Money and Upkeep drafts: a `Person` class, "last talked" from @mentions in notes and tasks, birthdays as dated tasks with no Contacts access (Kaushik's default), 15 eval phrases, and open questions with defaults. Check `people-and-upkeep.md`.
3. Make an app from a sentence, the long-term "building blocks" goal. Done when `app-from-a-sentence.md` scouts how Tess (Claude, through the model layer) turns "I want to track my plants" into a class, fields, a List or a page, using schema-as-data and ghost-preview rules. Include the tool schema, what the kernel validates, how undo works, 15 example sentences with expected classes, and the smallest first version.

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.
