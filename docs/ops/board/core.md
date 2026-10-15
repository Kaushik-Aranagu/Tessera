# Core engine (Mac)

**Done:** Groceries screen, kitchen slice 13 (#58); kitchen engine hotfixes (#70, #80); data-safety D1–D4 (#84); recipe page and paste, slices 10/11 (PR open, merges after the install).

**Now:** Tess model layer T1 then T2 (spec in Later below; Kaushik wants Claude in the foundations as early as possible, and T1/T2 need no key). Done when T1 and T2 meet their rows in `../research/tess-model-layer.md` section 10.

**Next:**
1. Grammar collision fix, straight after T1/T2 because Kaushik types into Tess from tomorrow. Done when the three rules in `../research/grammar-collisions.md` are in (a prefix wins only if its argument resolves; questions are caught before tasks; the process in Now decides bare input, via a process field on TessContext), its test rows pass, and "p 42 of 80", "buy sun cream", "move dentist to friday", questions with dates and "squat 100 5, deadlift 140 3" all land in the right domain. Also "call mum thu" said on a Thursday means today (Product call, 18:58).
2. Groceries polish. Done when Design's and the kitchen lead's fixes to #58 are merged, plus anything Kaushik flags on Groceries at the huddle.
3. Tess model layer T3, then T4 with S1 Settings, then T6 Plan my day wording, once his key arrives.
4. Paste hardening, after the 10/11 PR merges. Done when the parser gaps from Research's paste corpus (`../research/fixtures/`) pass: oz, lb and pint units; pack sizes kept out of the name (new `packSize` field); blog noise skipped; worded durations ("twenty minutes"); "salt & pepper" not linking to peppers; ingredient `section` field.
5. Meal plan feeds groceries (the idle-time slice below).
6. Cook mode. Done when slice 12 in `ship-list-kitchen.md` is met: timers on the Lock Screen and a Cook entry on finish, and cooking has its own idle rule (tidyProcesses never suspends a cook while a timer runs or within 45 minutes of the last step; today it suspends after about 13 minutes), checked against Research's cook-mode scenarios. Core builds the live screen too, and Builder A reviews the shared instruments.
7. Kitchen shelf. Done when slice 14 in `ship-list-kitchen.md` is met.

**Idle-time slices** (from `../research/next-areas.md` part 2; each takes an afternoon, pull one whenever blocked):
- Meal plan feeds groceries. Done when "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task.
- Logs fill habits. Done when a habit can count itself each time a Workout or Cook finishes. Needs M3 slice 2.
- Body weight is the load. Done when pull-ups and dips use the latest body weight plus added weight for e1RM and volume. Needs M3 slice 1.

**Later:**
- **Tess model layer spec** (`tess-model-layer.md`; build plan = Research's `../research/tess-model-layer.md`, #83), now in Now and Next above. Full order: T1 TessModel + router + op-log route/model columns (confirm the beta Claude for Foundation Models package builds and reports usage, else the URLSession fallback), T2 shared tools, T3 Claude route + Keychain key + ledger with a $10/month hard cap, T4 + S1 Settings, T6 Plan my day wording (first visible win), T7. T1 and T2 need no key.
- **Lists engine.** `ship-list-lists.md` slices, in build order 1 → 3 → 2 → 4 → 5 → 7 → 6 → 8: housekeeping, lists from text, item paragraphs, reusable, run on Now, pick one, dated items in Today, list phrases. These replace kitchen slice 15.
- M3 slices 1 to 12 in `ship-list-m3.md`. Land the M3 List template on the kitchen `List` class.
- M4 engine slices in `ship-list-m4.md`, after Lists: 1 calendar, 2 Health, 3 day full, 5 Day log, 6 Plan my day (rules only), 7 Shutdown, 12 Tess on-device fallback (with the 200-phrase eval set), 4 interrupts, 9 first step. Slice 6b, Claude wording, is approved and runs through the Tess model layer.
