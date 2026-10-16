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
| [fixtures/people.md](fixtures/people.md) | Core: 40 people phrases, collisions (called mom vs completeTask, names in shop runs), 18 rules |
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
| [fixtures/cook-timer-phrases.md](fixtures/cook-timer-phrases.md) | Core and Builder A: 40 cook timer phrases (RC15) with expected parses, Tess lines and look-alike guards |
| [fixtures/review-sentence.md](fixtures/review-sentence.md) | Builder B and Core: 30 weeks with the expected Review hero sentence and dabs, 22 guilt flags with replacement copy |
| [widget-states.md](widget-states.md) | Builder A: exact widget, Live Activity and snippet lines for six states, drawn from NowPicker and the ranker |
| [fixtures/people-names.md](fixtures/people-names.md) | Core: 40 names that are also words (Will, Rose, Bill, June...) through the M5 order, with 12 guards |
| [undo-lines.md](undo-lines.md) | All teams: 47 write paths with their Tess line and Undo, 33 mismatches, one wording rule |
| [empty-states.md](empty-states.md) | All teams: 14 screens with no data, what they show now and what they should say, owner per fix |
| [starter-content.md](starter-content.md) | Core and Builder A: everything a fresh install seeds, checked against the decisions, 3 mismatches |
| [lockscreen-lines.md](lockscreen-lines.md) | Builder A and Core: 72 Live Activity, Siri and Shortcuts strings checked against Tess voice and the undo rule |
| [accessibility.md](accessibility.md) | All teams: 80 VoiceOver, Dynamic Type and Reduce Motion fixes by screen, 9 high |
| [restore-drill.md](restore-drill.md) | QA and Core: 10-step backup and restore drill on the simulator, 5 edge cases, 10 code-vs-rule gaps |
| [oplog-health.md](oplog-health.md) | Core: every write that skips the op log or cannot be undone, with risk, fix and owner, ahead of Build A1 |
| [training-week-one.md](training-week-one.md) | Product and Core: 12 counts to pull from the op log in his first training week, gaps, three end-of-week questions |
| [speak-first-use.md](speak-first-use.md) | Builder B: Speak first-use script, permission paths and lines (draft, copy proposed until the Design sheet lands) |
| [plan-my-day-dryrun.md](plan-my-day-dryrun.md) | Core: 7 real-shaped days with the exact Plan my day context pack, privacy and size checks, expected wording |
| [light-day.md](light-day.md) | Core: on-phone rule for the Plan my day "light day" flag, 20 fixture days |
| [calendar-pack.md](calendar-pack.md) | Core + Builder B: smallest EventKit read for Plan my day, permission line, 10 fixture days |
| [day-boundary.md](day-boundary.md) | Core + Builders: every midnight day cut on master, fix via a 4 AM TesseraDay helper, 12 fixture moments |
| [ask-lines.md](ask-lines.md) | All teams: every permission ask, exact lines, one ask per day rule, first-week walkthrough |
| [fixtures/grammar-regression.md](fixtures/grammar-regression.md) | Core: one deduplicated grammar regression table (736 rows) with expected parse and master status |
| [fixtures/dst-travel.md](fixtures/dst-travel.md) | Core: 20 DST and time zone moments for TesseraDay tests |
| [late-night.md](late-night.md) | Core + Builders: 11 PM to 3 AM use walk after the TesseraDay fix, 16 leftover bugs |
| [review-refresh.md](review-refresh.md) | Product: 16 phone review items for everything merged since 34665f0 |
| [claude-key-test.md](claude-key-test.md) | Core + Builder B: Claude key Test call, outcome lines, ledger, key-leak test |
| [notifications.md](notifications.md) | Core + Builders: the three local notifications, permission slot, quiet hours, what never notifies |
| [install-check.md](install-check.md) | Coordinator + Product: 5-minute check that the review guide matches an install commit |
| [claude-first-uses.md](claude-first-uses.md) | Core + Builder B: first three Claude uses, screen lines, cost, fallbacks, gating |
| [fixtures/reminders.md](fixtures/reminders.md) | Core: 40 reminder phrases with expected parse, alerts flag, no-permission line, model routing |
| [decisions-index.md](decisions-index.md) | Product: Oct 15 decisions by area with pointers, 13 contradictions flagged |
| [week-one-checkin.md](week-one-checkin.md) | Product, Core: first-week morning check-in from the iCloud backup copy (7 queries, 3 warning signs) |
| [themes-token-audit.md](themes-token-audit.md) | Builder A, Builder B, Design: every hard-coded colour the Themes PR must touch, mapped to themes.md tokens (102 hits) |
| [miss-counts.md](miss-counts.md) | Core: counts-only capture-miss table written into each .tessera copy, fixtures, check-in Q8 |
| [grammar-open-defaults.md](grammar-open-defaults.md) | Product, Core: 20 proposed defaults for the open grammar questions (relative times, workout extras, Money, Reading, People, upkeep) |
| [inplace-number.md](inplace-number.md) | Builder A, Design: in-place number scrub feel for the set logger (detents, acceleration, haptics, VoiceOver, 19 fixtures) |
| [capture-type.md](capture-type.md) | Design, Builder B: Ask Tess capture surface type audit (21 elements) and the calmer set |
| [theme-checks.md](theme-checks.md) | Design, Builder A: proportions and WCAG/APCA contrast for all five themes, Live Activity and widget needs, proposed hex fixes |
| [lists-copy.md](lists-copy.md) | Builder B, Core: Lists 9-12 copy audit against voice, undo and empty-state rules (37 rows) |
| [settings-claude.md](settings-claude.md) | Design, Core: Settings: Claude, 26 states with exact lines, money format, Tess fallbacks, 17 contradictions |
| [theme-names.md](theme-names.md) | Design, Builder A: look names, the LOOK switch copy, Live Activity and widgets per look, storage and backup |
| [week-one-dryrun.md](week-one-dryrun.md) | Coordinator, Core: week-one check-in run on sample copies; 8 query bugs fixed, partial-copy gap |
| [fixtures/set-logger.md](fixtures/set-logger.md) | Core, Builder A: 40 set-logger phrases (group K in the grammar suite), defaults S701-S706 |
| [theme-schedule.md](theme-schedule.md) | Builder A, Design: when the day look switches to the night look, pins, Live Activity; 25 fixtures against master |
| [backup-logical-day.md](backup-logical-day.md) | Core, QA: daily backup copy by the 4 AM day, 12 timelines with test names and phone steps |
| [day-log-copy.md](day-log-copy.md) | Builder B: Day log page copy for 12 states, empty states, 4 AM day |
| [m3-lines.md](m3-lines.md) | Design, Core: body weight and habits lines, empty states, VoiceOver (about 75 lines) |
| [habits-first-use.md](habits-first-use.md) | Builder B, Core: his first habit week walked step by step (73 steps, a paused week, 20 gaps) for the Habits page and M3 slice 2 |
| [fixtures/plan-my-day-claude.md](fixtures/plan-my-day-claude.md) | Core: 20 Plan my day packs for the Claude gate, checks, Haiku vs Sonnet, pass bar, eval steps |
| [day-log-late-night.md](day-log-late-night.md) | Builder B, Core: Day log late-night traces (six days, 8 wrong-day cases, 19 test names) |
| [day-log-acceptance.md](day-log-acceptance.md) | Core, QA: Day log v1 acceptance pack, 71 numbered tests (DL1 to DL71) with expected lines for the DayStory PR |
| [day-log-v1-check.md](day-log-v1-check.md) | Design, Builder B, Core: Design's day-log-v1.md (8ceb4e5) checked line by line against DL1 to DL71 |
| [set-logger-rerun.md](set-logger-rerun.md) | Core: set-logger rerun on the live-workout guard (group K 38/0/2) |
| [fixtures/habits-grammar.md](fixtures/habits-grammar.md) | Core: 30 habit grammar rows (suite group L) |
| [fixtures/body-weight.md](fixtures/body-weight.md) | Core: 25 body weight rows against S701 (suite group M) |
| [plan-my-day-blind-read.md](plan-my-day-blind-read.md) | Kaushik, Product: Plan my day Haiku vs Sonnet blind-read sheet (use 2 gate) |
| [zone-per-item.md](zone-per-item.md) | Core: storing a time zone per op (write now, read later) |
| [themes-leftovers.md](themes-leftovers.md) | Builder A, Builder B: 52 theme leftovers on master with owners and Obsidian risks |
| [fixtures/habits-from-logs.md](fixtures/habits-from-logs.md) | Core: 15 fixture days for logs filling habits |
| [theme-contrast-fixes.md](theme-contrast-fixes.md) | Design, Builder A, Builder B: proposed contrast values for the Obsidian misses and Best e1RM |
| [fixtures/grammar-miss-claude.md](fixtures/grammar-miss-claude.md) | Core, QA: use 1 gate, 185 grammar misses on Haiku |
| [review-refresh-2.md](review-refresh-2.md) | Product: next-install review items since b19fb4a |
| [claude-first-run.md](claude-first-run.md) | Builder B, QA: Claude first-run walk with key-leak flags |
| [training-week-one-questions.md](training-week-one-questions.md) | Coordinator: Mon Oct 19 training check-in questions |
| [fixtures/review-m3.md](fixtures/review-m3.md) | Builder B, Core: 12 Review weeks with habits and body weight |
| [colour-at-rest.md](colour-at-rest.md) | Design, Builders A and B: every coloured dot, badge and always-on colour on master, checked against no-dots.md |
| [install-day-script.md](install-day-script.md) | QA: simulator script plus a one-minute Speak check on the phone for the install commit before the Oct 22 re-sign |
| [install-readiness-oct22.md](install-readiness-oct22.md) | Product: Oct 22 install readiness, merged PRs since b19fb4a with QA verdicts, open fixes, recommended install commit |
| [set-loss-rerun-274.md](set-loss-rerun-274.md) | Core, QA: the ten set-loss rows re-traced on #274's head (all pass) |
| [grammar-miss-blind-read.md](grammar-miss-blind-read.md) | Kaushik: 30-row unlabelled read of use 1 once his Claude key is in |
| [lines-audit-2.md](lines-audit-2.md) | Core, Builders A and B: 61 Tess, UNDO and empty-state lines since #158, 24 fixes |
| [oct-22-list.md](oct-22-list.md) | Coordinator: Kaushik's Oct 22 morning message, Kitchen and Money one-word questions |
| [resign-day.md](resign-day.md) | Coordinator, iOS build: what survives the Oct 22 re-sign and what to check after |
| [restore-walk.md](restore-walk.md) | Core, Builders A and B: restore after a reinstall, what comes back and what does not, 8 fixes |
| [plan-my-day-flow.md](plan-my-day-flow.md) | Builder B, Core: Plan my day morning flow on use 2, 17 steps, 9 branches, m4-steers disagreements |
| [settings-object.md](settings-object.md) | Core: every preference outside the database, which moves into the settings object, which never travels in a backup |
| [settings-place-check.md](settings-place-check.md) | Design, Builder B: every line in Design's settings-place.md (231b15e) checked against tess-voice, settings-claude and #246 |
| [debug-paths.md](debug-paths.md) | Builder A, QA: every launch flag and debug path that could touch his data on a Debug phone build, gate and 14-item checklist |
| [ai5-home-lines-eval.md](ai5-home-lines-eval.md) | AI architecture, Core, QA: the AI-5 gate for Claude Home lines, 14 phone checks, truth and voice scores, 20 moments with 45 probes in fixtures/home-lines-eval.json |
| [living-colours-learning.md](living-colours-learning.md) | Core, AI architecture, Design: how Design 48's rule table bends to his day, Claude picking among the rules' candidates, 5 conflicts, 12 day-shape fixtures |
| [ai11-week-story-eval.md](ai11-week-story-eval.md) | Core, AI architecture, QA: the AI-11 week story eval, 7 checks, truth and voice, 12 weeks with 32 probes in fixtures/week-story-eval.json |
| [fixtures/home-lines-day.md](fixtures/home-lines-day.md) | Core, Design, Builder B: his Tuesday hour by hour through #334's HomeLines, 27 rows, 12 gaps (done cook vanishes, paused shop "at the store", record vs best, zero counts) |
