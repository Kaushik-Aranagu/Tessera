# Research lab briefs

Ranked idea briefs from the Research lab (round 1: 2026-10-15; round 2: 2026-10-16). Each file names the team it is for. Ideas are proposals, not decisions; owning teams decide.

**Start here:** [ship-now.md](ship-now.md) holds the research add-ons to Product's ship list (docs/product/ship-list.md).

| Brief | For |
|---|---|
| [object-model-and-data.md](object-model-and-data.md) | Core engine |
| [ai-and-tess.md](ai-and-tess.md) | Tess AI (future), Product lead, Core engine (syscall registry) |
| [fitness-and-workouts.md](fitness-and-workouts.md) | iOS build, Product lead |
| [design-and-motion.md](design-and-motion.md) | Design studio, iOS build |
| [personal-os-and-productivity.md](personal-os-and-productivity.md) | Product lead (cross-team) |
| **Round 2** | |
| [whats-running.md](whats-running.md) | Product lead (spec), Design studio, Core engine, iOS build |
| [tess-voice.md](tess-voice.md) | Tess AI (future), Design studio (copy), Product lead |
| [exercise-catalog.md](exercise-catalog.md) | Core engine (catalog), iOS build, Product lead |
| [instrument-robustness.md](instrument-robustness.md) | iOS build, Design studio |
| **Spikes** | |
| [storage-spike.md](storage-spike.md) | Kaushik (decision), Core engine |
| [next-areas.md](next-areas.md) | Product lead (planning): next app areas and cross-app links |
| [m4-scouting.md](m4-scouting.md) | Product lead, Core engine: M4 calendar and health mounts, Plan my day, Shutdown, focus block |
| [tess-routing.md](tess-routing.md) | Core engine (Tess engine): grammar first, then on-device model |
| [tess-eval-phrases.md](tess-eval-phrases.md) | Core engine: 200 capture phrases to test Tess |
| [kitchen-v2.md](kitchen-v2.md) | Kitchen lead, Core engine: a pantry with no counting, recipes from links |
| [widgets-and-snippets.md](widgets-and-snippets.md) | Product lead, iOS Builder A, Design studio: snippets first, the Now widget, the Capture control |
| [sticking-past-week-3.md](sticking-past-week-3.md) | Product lead, Design studio: 10 rules for retention, re-entry after a gap |
| [day-log.md](day-log.md) | Product lead, Core engine, Design studio: what the Day log shows, undo from a past day, the scrub rail |
| [m5-money-reading.md](m5-money-reading.md) | Product lead: smallest Money and Reading apps |
| [people-and-upkeep.md](people-and-upkeep.md) | Product lead: smallest People and Home upkeep apps |
| [lists-templates.md](lists-templates.md) | Kitchen lead (Lists), Product lead, Core: reset vs copy, pick one, paste into a list |
| [habits.md](habits.md) | Product lead, Core, Design: weekly targets, auto-filled check-ins, no guilt |
| [add-a-field.md](add-a-field.md) | Product lead, Core, Design: add a field by typing, type inference |
| [quiet-interrupts.md](quiet-interrupts.md) | Core, Product lead: holding notifications during a process |
| [body-weight-trend.md](body-weight-trend.md) | Core, Product lead, Design: smoothed trend weight |
| [plan-my-day-scenarios.md](plan-my-day-scenarios.md) | Core, Product: 20 Plan my day fixture days with expected plans (M4 slice 6) |
| [questions-eval.md](questions-eval.md) | Core: 60 questions and smart-list phrasings mapped to a query AST (M3 slices 4, 7) |
| [calendar-health-fixtures.md](calendar-health-fixtures.md) | Core: 36 Calendar and Health edge-case fixtures (M4 slices 1, 2) |
| [shutdown-daylog-copy.md](shutdown-daylog-copy.md) | Design, Core: 32 Day log and Shutdown lines in Tess voice (M4 slices 5, 7) |
| [ship-list-reading-draft.md](ship-list-reading-draft.md) | Product: DRAFT Reading ship list, 7 slices (M5) |
| [tess-model-layer.md](tess-model-layer.md) | Product, Core: Claude in Tess (official Swift package, Keychain key, $10 cap, grammar then on-device then Claude, first slices) |
| [fixtures/recipe-paste-corpus.md](fixtures/recipe-paste-corpus.md) | Core, Kitchen lead: 30 recipe paste fixtures with expected parse and parser gaps (kitchen 2, 3, 11) |
| [fixtures/cook-mode-scenarios.md](fixtures/cook-mode-scenarios.md) | Core: 15 cook mode timer, process and Now scenarios (kitchen 12) |
| [fixtures/lists-fixtures.md](fixtures/lists-fixtures.md) | Core, Kitchen lead: 40 list pastes and 60 list phrases (Lists 3, 8) |
| [grammar-collisions.md](grammar-collisions.md) | Core: 46 Tess grammar collisions across domains, precedence rules, 56 test rows |
| [ship-list-m5-money-draft.md](ship-list-m5-money-draft.md) | Product: DRAFT Money ship list, 7 slices, 15 phrases (M5) |
| [v1-gap-audit.md](v1-gap-audit.md) | Product, Builder A: v1 slices vs master 285b34a (15 on, 3 partly, 1 missing) |
| [recipe-link-fetch.md](recipe-link-fetch.md) | Core, Kitchen lead: recipe link fetch (JSON-LD, parser, Haiku fallback), slices L1-L3 |
| [apple-watch.md](apple-watch.md) | Product, Builder A, Core: Apple Watch without a Watch app first (Health reads, Smart Stack rest timer), slices W1-W4 |
| [ship-list-m5-upkeep-draft.md](ship-list-m5-upkeep-draft.md) | Product: DRAFT Home upkeep ship list, 7 slices, 15 phrases (M5) |
| [tess-eval-claude.md](tess-eval-claude.md) | Core: 80 grammar misses with expected Claude tool calls and context packs (model layer T4, T5) |
| [plan-my-day-prompt.md](plan-my-day-prompt.md) | Core: Plan my day prompt pack for T6 (instructions, proposePlan schema, validation, 20-scenario hand check) |
| [ship-list-m5-people-draft.md](ship-list-m5-people-draft.md) | Product: DRAFT People ship list, 8 slices, 15 phrases (M5) |
| [app-from-a-sentence.md](app-from-a-sentence.md) | Product, Core: make an app from a sentence via proposeClass; needs schema undo (A1) |
| [context-packing.md](context-packing.md) | Core, Builder B, Product: how Home and NowPicker pick what to show (signals, one ranker with why, 20 moments) |
| [huddle-triage.md](huddle-triage.md) | Coordinator, Product: one-page template to turn Kaushik review feedback into board items |
| [speech-capture.md](speech-capture.md) | Builder B, Core: on-device speech for Ask Tess (SpeechAnalyzer, spoken normaliser, 30 phrases, usage strings) |
| [capture-modes.md](capture-modes.md) | Builder B, Core, Kitchen: photo, file and video capture (on-device Vision text, receipt total, recipe, page to note; 15 examples) |
| [on-device-context-size.md](on-device-context-size.md) | Core, Product: on-device model window is 4,096 tokens; Tess prompt budget, trim order, when to route to Claude |
| [free-signing-survival.md](free-signing-survival.md) | Core, iOS build, Coordinator: 7-day expiry keeps data; weekly re-sign; .tessera export/restore and daily backups slice |
| [fixtures/year-of-data.md](fixtures/year-of-data.md) | Core, QA: deterministic 12-month generator, counts, performance targets and how to measure |
| [ranker-tuning.md](ranker-tuning.md) | Core, Product: on-device rank log (separate ranklog.sqlite), weekly retune with guardrails |
| [tess-discoverability.md](tess-discoverability.md) | Builder B, Design, Product: teaching Tess phrases in two weeks (context placeholder, ghost-row also-say, after-hand line), 20 hint lines |
| [fixtures/spoken-normaliser.md](fixtures/spoken-normaliser.md) | Builder B, Core: 80 spoken transcript to text rows, 17 normaliser rules, grammar gaps |
| [screen-fast-paths.md](screen-fast-paths.md) | Builder A, Builder B, Design, Product: primary action, two fast paths and Tess placeholder for all 20 screens; 5 cheapest fixes |
| [photo-field.md](photo-field.md) | Core: photo field kind (hash ref, media/ files, thumbnails, GPS strip, undo, export, never in Claude packs) |
| [breadth-map.md](breadth-map.md) | Product, Coordinator: every area vs master, smallest first version each, 9-wave breadth-first order |
| [lists-daily.md](lists-daily.md) | Builder B, Kitchen, Product: 20 daily list moments, slice coverage, 13 gaps with defaults |
| [day-log-first.md](day-log-first.md) | Core, Builder B, Product: Day log v1 as a pure fold over OpRecord actions, 12 rules, 10 sample days |
| [fixtures/reading.md](fixtures/reading.md) | Core: 40 reading phrases, 10 resume cases, 8 finish lines, grammar collisions on master |
| [fixtures/ranker.md](fixtures/ranker.md) | Core: 40 Now-pick contexts with expected pick, why and runner-up; 13 precedence rules |
| [m3-1-2-brief.md](m3-1-2-brief.md) | Core: M3 slices 1-2 (BodyWeight trend, Habit x-of-7), 30 weight and 20 check-in fixtures, grammar rows |
| [fixtures/upkeep.md](fixtures/upkeep.md) | Core: 40 upkeep phrases, collisions with tasks/groceries/Reading/Money, 16 rules |
| [fixtures/people.md](fixtures/people.md) | Core: 40 people phrases, collisions (called mum vs completeTask, names in shop runs), 18 rules |
| [fixtures/money.md](fixtures/money.md) | Core: 50 currency-neutral money rows, collisions with sets/groceries/tasks/Reading, rules M1-M11 |
| [speech-test-script.md](speech-test-script.md) | Builder B, Kaushik: 5-minute Speak phone test, 30 phrases with expected Tess lines (after V1, V2) |
| [build-a1-brief.md](build-a1-brief.md) | Core: schema ops with undo (retire/revive, rename by key), 20 fixtures, master blockers |
| [recovery-line.md](recovery-line.md) | Core, Builder B: Watch W3 recovery line from sleep, resting HR, HRV vs own baseline; 20 fixture days; never sent to Claude |
| [healthkit-reads.md](healthkit-reads.md) | Core: HealthKit read layer for W1 and W3 (HealthReading protocol + fakes, permissions in context, 15 fixture days) |
| [m3-3-6-10-brief.md](m3-3-6-10-brief.md) | Core: M3 slices 3, 6, 10 shapes and fixtures, mapped to the A1 blockers each clears |
| [pantry-light.md](pantry-light.md) | Kitchen lead, Core: "Usually have" line from repurchase intervals, 20 fixture weeks, slice U0 |
| [fixtures/grammar-misfires.md](fixtures/grammar-misfires.md) | Core: 238 everyday phrases traced through master grammar, 154 misfires, 16 root causes, top-10 fix list |
| [fixtures/day-log-days.md](fixtures/day-log-days.md) | Core: five real-shaped days of op logs with the exact DayStory lines, including the unfinished workout and the "Also:" cut-off |
| [fixtures/m5-parse-order.md](fixtures/m5-parse-order.md) | Core: 170 Reading, Money, People and Upkeep rows checked against the M5 parse order, 5 that change, guards per rule |
| [fixtures/show-photos.md](fixtures/show-photos.md) | Core: 25 Show mode photos (pages, recipes, receipts, whiteboard, blurry) with the text Vision reads, the route and the exact ghost row |
| [fixtures/reschedule-time-rows.md](fixtures/reschedule-time-rows.md) | Core: 40 reschedule rows (RC13) and 40 time-form rows (RC11) with expected parses under the 4:26 PM calls |
| [fixtures/hint-ledger.md](fixtures/hint-ledger.md) | Core: 15 days of Tess hints (max 3 a day, "Next time, this works"), with the no-hint cases |
| [fixtures/upkeep-starters.md](fixtures/upkeep-starters.md) | Core: 25 starter chores with intervals, logging phrases and collision checks against the M5 order |
