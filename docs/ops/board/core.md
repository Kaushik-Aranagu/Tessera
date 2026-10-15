# Core engine (Mac)

**Done:** Groceries screen, kitchen slice 13 (#58); kitchen engine hotfixes (#70, #80); data-safety D1–D4 (#84); recipe page and paste, slices 10/11 (PR open, merges after the install).

**Now:** Tess model layer T2 (T1 done as #89, held with #86 until after the install), then the #86 follow-up PR once #86 merges. The follow-up has to land before Builder B wires the kitchen screens into Home. It's done when the three bugs in `../qa/review-86.md` are fixed (doubled grocery share, Cook doing nothing after a paste, tap-to-fix stuck) along with the polish items there that touch the same files. T2 is done when it meets its row in `../research/tess-model-layer.md` section 10. T2 ships 10 tools: Research's 8 plus `completeTask` and `rescheduleTask`, both by name (Product, 19:12).

**Next:**
1. Backup and restore, straight after T2 and #98 because his real logs start tomorrow (`../research/free-signing-survival.md`). Done when the app writes a `.tessera` file with GRDB's backup API every day and keeps the newest 7, copies go to an iCloud Drive folder he picks once (so they survive deleting the app), a picked backup is checked and restored at the next launch, and the doc's done-when tests pass. This also wires up the unused `TesseraExport.swift`.
2. v1 engine gaps (small, before the gym tomorrow if possible), from `../research/v1-gap-audit.md` and iOS build's ship-2 notes. Done when:
   - `Prefill.swift` prefers the raised `targetWeight` from `Progression.nextTarget` over last time's weight, with a test. This is slice 14: set 1 opens at the new load.
   - A `RemoveSlot` action exists with undo. The builders use DeleteObject for now.
   - `EditSet` can clear RPE.
   - `week(containing:)` returns rest days.
   - There's an API that groups the exercise library, by movement pattern and then equipment.
3. Grammar collision fix, straight after T2 and the #86 follow-up, because Kaushik types into Tess from tomorrow. Done when the three rules in `../research/grammar-collisions.md` are in (a prefix wins only if its argument resolves; questions are caught before tasks; the process in Now decides bare input, via a process field on TessContext), its test rows pass, and "p 42 of 80", "buy sun cream", "move dentist to friday", questions with dates and "squat 100 5, deadlift 140 3" all land in the right domain. Also "call mum thu" said on a Thursday means today (Product call, 18:58).
4. Context ranker (Kaushik's "the screen is the resource", `../research/context-packing.md`). Done when NowPicker is rebuilt around one shared `rank()` with overrides and weighted scores, every pick carries `Pick.why`, the doc's 20 moments pass as fixtures, and Home can read it in place of `AppModel.currentTask`, so Home and Now never disagree. Builder B wires NowPage to it.
5. Apple Watch quick wins from `../research/apple-watch.md`. Done when `RestLiveActivity.swift` declares `supplementalActivityFamilies` with a small layout, so the Watch Smart Stack shows the countdown, planned set, Done and +15 (W2), and the workout summary shows average and max heart rate from Health when the Watch was worn, with no line at all otherwise (W1). No Watch app.
6. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). After the install and once Design's `docs/design/no-buttons.md` lands. Done when every button on Core's screens (Notes, Review, Groceries, recipe page, Settings), reusing Builder A's DesignSystem button style uses Design's replacement language and the audit's rows for those files are ticked, with a recording.
7. Groceries polish. Done when Design's and the kitchen lead's fixes to #58 are merged, plus anything Kaushik flags on Groceries at the huddle.
8. Photo field type. Done when a `.photo` field kind exists, with images stored on the device beside the database (not in it), thumbnails, deletion with undo, and exclusion from anything sent to Claude. Builder B's Show mode and recipe photos need it.
9. Tess model layer T3, then T4 with S1 Settings, then T6 Plan my day wording, once his key arrives. T6 uses Research's `../research/plan-my-day-prompt.md`. Watch the light-day risk: "lighter top set" trips the banned-word and health-hint checks. On a timeout or failure, show the rules plan with one quiet line, "Here's your usual plan" (Product, 19:22), not silence. Use the model-layer lines in `../research/tess-voice.md` for every message Tess shows.
10. Paste hardening, after the 10/11 PR merges. Done when the parser gaps from Research's paste corpus (`../research/fixtures/`) pass: oz, lb and pint units; pack sizes kept out of the name (new `packSize` field); blog noise skipped; worded durations ("twenty minutes"); "salt & pepper" not linking to peppers; ingredient `section` field; "10 minutes mins", "Prep: 10 M", and "Dal ingredients" read as a section heading, not an ingredient.
11. Meal plan feeds groceries (the idle-time slice below).
12. Cook mode. Done when slice 12 in `ship-list-kitchen.md` is met: timers on the Lock Screen and a Cook entry on finish, and cooking has its own idle rule (tidyProcesses never suspends a cook while a timer runs or within 45 minutes of the last step; today it suspends after about 13 minutes), checked against Research's cook-mode scenarios. Core builds the live screen too, and Builder A reviews the shared instruments.
13. Kitchen shelf. Done when slice 14 in `ship-list-kitchen.md` is met.

**Idle-time slices** (from `../research/next-areas.md` part 2; each takes an afternoon, pull one whenever blocked):
- Meal plan feeds groceries. Done when "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task.
- Logs fill habits. Done when a habit can count itself each time a Workout or Cook finishes. Needs M3 slice 2.
- Body weight is the load. Done when pull-ups and dips use the latest body weight plus added weight for e1RM and volume. Needs M3 slice 1.

**Later:**
- **Tess model layer spec** (`tess-model-layer.md`; build plan = Research's `../research/tess-model-layer.md`, #83), now in Now and Next above. Full order: T1 TessModel + router + op-log route/model columns (confirm the beta Claude for Foundation Models package builds and reports usage, else the URLSession fallback), T2 shared tools, T3 Claude route + Keychain key + ledger with a $10/month hard cap, T4 + S1 Settings, T6 Plan my day wording (first visible win), T7. T1 and T2 need no key.
- **Lists engine.** `ship-list-lists.md` slices, in build order 1 → 3 → 2 → 4 → 5 → 7 → 6 → 8: housekeeping, lists from text, item paragraphs, reusable, run on Now, pick one, dated items in Today, list phrases. These replace kitchen slice 15.
- M5 Money engine slices 1, 2, 4, 3 in `ship-list-m5-money.md`, after M5 Reading. Then M5 Upkeep engine slices 1 to 4 in `ship-list-m5-upkeep.md` (needs M3 slice 2). Then M5 People engine slices in `ship-list-m5-people.md`.
- Apple Watch W3 (recovery line on Now from sleep, resting HR and HRV, with M4 slice 2) and W4 (one session, one workout), from `../research/apple-watch.md`.
- Build (make an app from a sentence) A1 to A5 in `ship-list-build.md`, after M3 slices 3, 6 and 10 and model-layer T1 to T3. A1 first: schema ops in the op log with undo.
- Year of data (`../research/fixtures/year-of-data.md`): build the generator as a test fixture and hold the device performance targets with QA.
- M3 slices 1 to 12 in `ship-list-m3.md`. Land the M3 List template on the kitchen `List` class.
- M4 engine slices in `ship-list-m4.md`, after Lists: 1 calendar, 2 Health, 3 day full, 5 Day log, 6 Plan my day (rules only), 7 Shutdown, 12 Tess on-device fallback (with the 200-phrase eval set), 4 interrupts, 9 first step. Slice 6b, Claude wording, is approved and runs through the Tess model layer.
