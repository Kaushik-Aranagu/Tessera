# Codex handoff for Tessera

Written by Ops, 6:05 PM PT Oct 23, first version. Ops keeps this current when the coordinator says state changed. The "State now" and "Queued work" sections are the ones that go stale; check the update log at the bottom for the last time they were refreshed.

You are picking up work that Claude teams were doing, because Kaushik's Claude usage ran out. Kaushik is the only person you answer to. Where this file and Kaushik's words differ, his words win. Where this file and the code differ, the code wins and this file needs fixing.

## 1. What Tessera is

A personal, iPhone-only, native SwiftUI app for one person (Kaushik). It is an "OS inside an app": everything is a linkable, class-based object, with dense information revealed progressively. Training (workouts, plans, PRs, live workout) was the first domain; Kitchen, Notes, Lists, Routines, Money, Reading, People and Upkeep followed. The in-app assistant is called Tess.

Read these first, in this order:
1. `CLAUDE.md` at the repo root (stack, build, layout, launch flags, design pointers).
2. `docs/PRODUCT_VISION.md` (the object model and the product).
3. `docs/DESIGN_MOTION.md` and the design skill at `.claude/skills/tessera-design/`.
4. `docs/ai/architecture.md` (Tess, memory, the Claude seam).

Standing principle from Kaushik: the UI carries equal weight with the backend. It is a place for real invention. Never ship stock or card-based screens.

## 2. Repo layout

- `App/`: entry point, `AppModel`, `LaunchFlags`. `AppModel.asksClaude` is the one switch that gates all Claude use.
- `DesignSystem/`: `Theme` tokens (colors, type, spacing, radius, motion). Use these, never literals. All animation goes through `MotionPolicy` (`.tesseraAnimation`, `withTesseraAnimation`).
- `Features/<Feature>/`: one folder per screen or feature.
- `TesseraCore/`: local Swift package, module `TesseraCore`, the engine, no UI. `Model/`, `Engine/` (`ObjectStore`, `ClassResolver`, `Formula`, `ObjectPath`), `Catalog/` (`SystemCatalog`), `Training/` (`TrainingLedger`), plus `Tess/`, `Notes/`, `Export/`, and `Sources/TesseraTess/` (the Tess and harness code). The app never touches the database directly; read and write objects through `ObjectStore`, never raw `valuesData`.
- `Widgets/`, `Watch/`, `Shared/`, `Resources/`, `tools/`.
- `TesseraTests/` (app tests, Swift Testing), `TesseraUITests/`.
- `scripts/`: `test.sh` (the gate), `scripts/ops/` (docs and PR checks, see section 4).
- `docs/`: everything written down. `docs/README.md` and `docs/design/README.md` are the indexes.
- `project.yml` generates `Tessera.xcodeproj` through XcodeGen. The project file is gitignored. Run `xcodegen generate` after cloning or after adding or removing files. Never hand-edit the project file.

Persistence is SQLite through GRDB 7.11.1 behind the engine. The whole object graph lives in memory (`TesseraContext`) and writes through to `Application Support/Tessera/tessera.sqlite`. The catalog is at v9; v10 (#407) waits until every rider is on his phone. Migrations are additive. The app must never crash on launch.

## 3. Build and test

Needs a Mac with Xcode (iOS 27 SDK), XcodeGen, SwiftLint and SwiftFormat.

```bash
xcodegen generate
scripts/test.sh                  # engine package tests, then app build and tests on the simulator
scripts/test.sh --package-only   # swift test inside TesseraCore/ only
scripts/test.sh --app-only
scripts/test.sh --scale          # adds the 5-year history test
swiftformat . && swiftlint       # before committing; fix lint errors
```

- There is no CI. A PR is opened only when `scripts/test.sh` ends "All green". The simulator is iPhone 17 (iOS 27).
- Swift Testing for new tests. Swift 6 strict concurrency. iOS 27 only, no `#available` fallbacks.
- Demo and QA runs use launch flags, read only through `LaunchFlags` and honored only on the simulator (a phone build ignores them, Debug included): `-demoTime HH:mm`, `-demo`, `-resetDemo`, `-theme <name>`. Example: `-demoTime 18:10 -resetDemo`. Never add another way to read flags.
- Verify Apple APIs against Apple's documentation (the Xcode docs search or the sosumi docs MCP), never from memory.
- Do not commit build products, DerivedData or `xcuserdata`.

## 4. Branch, PR and release rules

Names and flow as they stand:
- `master` is the trunk. Merges to master land as merge commits.
- Feature branches carry the owner's lane in the name (`core/...` for the engine, `ios/...` for the app, `claude/...` for docs).
- `integ/NN` is an integration branch that holds several passed PRs so they are tested together (`integ/77` is the one the PRs below were based on; `integ/77-next` is its successor).
- `release/NN` is a release. Release 76 is `release/76`. A release is a git export of one exact SHA; ignored asset folders need the export step. Release builds come from that export, not from a working tree.
- Stacked PRs are normal: a PR can have another PR's branch as its base. When the parent merges and the child is retargeted to master, it can read as dirty; merge master into the child, get it re-checked, then merge.

Rules that Kaushik and the leads set:
- **QA gates everything.** A PR is reviewed on one exact head SHA. A pass applies to that SHA only. If the head moves after a pass, the pass is void until it is re-checked.
- **Frozen PR.** Once a PR number has gone to review, push only a requested fix. Small extras ride the next PR.
- **One purpose per PR.** Docs PRs touch `docs/` only.
- **App code merges only after one green `scripts/test.sh` on a branch that holds the exact heads being merged.** The release is that branch's SHA.
- **Installing on his phone** names an exact SHA, and only that SHA is installed. Gates for a release: QA pass (plus Design for UI), `scripts/test.sh` on the SHA, v9 catalog only. The phone is signed with a free account that lapses about every 7 days; if nothing has installed for 6 days, the device owner re-signs. Never delete Tessera from the phone. Bundle id `com.kaushikaranagu.tessera`.
- **Release gate:** #1111 turns "Tess asks Claude" off; never install a release that holds #1111 without #1123. Both are on master.
- **Docs PR gates** (scripts in `scripts/ops/`, run `git diff --cached | python3 -I scripts/ops/premerge_check.py` and expect RESULT CLEAN): ASCII only on added lines; no thread or session ids in docs except the ops address files; no secrets of any shape; existing lines that mention pin, install, reinstall, signing or release stay byte-identical (add a correction line instead of editing); never reword text just to get past a guard.
- A denied or blocked step: stop and say so. Never find another route around a guard.
- Do not merge your own PR without Kaushik's say-so. In the Claude setup, a separate merge step ran after QA; you have no QA team, so ask Kaushik to review or to tell you he accepts the risk.
- Dates and times are Pacific (PDT), US English, plain words.

## 5. State now (5:52 PM PT Oct 23, from the coordinator; check GitHub for the live state)

- **Phone:** release 76 (`release/76` at 29568759).
- **master:** aa6d64a4 (the merge of #1349, release 76).
- **integ/77-next:** at 6d0f56ff, in its final gate. It holds the integ/77 QA fixes. After it passes, it becomes release 77.
- **Open PRs and QA status:**

| PR | What | Head | Base | QA |
|---|---|---|---|---|
| #1361 | Repeats: one recurrence rule for tasks, routines, occasions (sheet 173) | 1c71c1d4 | master | passed |
| #1364 | Harness H1a + H0: Brain seam, ClaudeBrain, AppleBrain, RunTrace, latency bench | 6454b00c | master | passed |
| #1365 | Harness H1b: Door, router, lab/strict policy, hedge | cea320a6 | #1364's branch | passed |
| #1367 | Harness H2: PlaybookDirector, PlaybookStore, PlaybookJob | 11b2834e | #1365's branch | passed |
| #1366 | integ/77 QA list and gestures review | 409666be | integ/77 | passed; open against integ/77 but already merged into integ/77-next (6d0f56ff) |

#1368 to #1370 came after this snapshot (#1368 is the playbook lows on #1367); all three passed QA.

Merge order for the stack: #1364, then #1365, then #1367. #1361 is independent.

Open QA findings for the integ/77 line are in `qa/open-findings-integ77.md` and the hands-on test plan is `qa/integrated-build-test-plan.md`, both in the project folder (see section 9). Nothing installs until QA says the integrated build is clean.

## 6. Queued work

Order is roughly the order Kaushik wants it.

**Harness H3, Tess streaming loop (Core, `TesseraCore/Sources/TesseraTess/Harness/`).** `TessRun` (one per ask, an `AsyncStream` of waiting / words / ghost / finished / failed), a `pickRung` rule (open questions to Sonnet 5.5 with a Haiku hedge, small asks to Haiku 5.5), a fixed cache-friendly pack order, the read-only `open(handle, depth)` tool, a three-round tool loop with parallel reads and serial writes, resumable checkpoints in `tess-runs.json`, run ids on trace spans, warm-ups, conversation storage, and the `tessAsks` flag. Spec: `docs/ai/harness/h3-wiring-build.md`, Part B. It builds on #1364, #1365 and #1367. The memory and context work (M0 to M6, in `docs/ai/harness/memory-context-m0-m6.md`) follows; M0 must land before H3 merges.

**Harness app wiring and the cobalt Training accent (Builder A's lane, app target).** Part A of the same spec: one harness per app run (`App/AppModel+Harness.swift`), `AppModel.director`, filling the playbook at the first foreground after 4 am, and three read-only Developer mode rows (Run latency bench, Trace, Today's playbook). Spec: `docs/ai/harness/h3-wiring-build.md`, Part A. The Training accent moves to cobalt (0B62AE light, 3B8CF2 dark); see sheets 226 and 227. Crimson never shipped: the phone and build 77 are on C4472A, and cobalt is next.

**Room landings (Design approved, then build).**
- 226 room landings, layout first: `docs/design/room-landings-layout-226.md`. Approved by Kaushik 5:40 PM Oct 23, with reviewer fixes listed at the bottom of the sheet. Four bands per room (headline, brief, body, foot), one fine-line drawing per room, no pixel art inside rooms.
- 227 landing elements for Kitchen and Training: `docs/design/landing-elements-kt-227.md`. Approved the same time. The loaded bar, the Kitchen headline.
- 228 landing elements for Notes, Lists, Routines and Money: `docs/design/landing-elements-rooms-228.md`. In review with Kaushik; follows 226 and 227 and uses the same rules.
- These supersede the pixel lintels in sheets 210 and 217 to 225 (coordinator, 4:28 PM Oct 23). Pixels are for the Home mosaic only.

**Other known items:** the integ/77 findings that ride the next build (night rule for #1345, #1361 repeats lows, #1358 pounds snap, #1356 doc wording); the Settings wiring in finding 8; bills are not in #1361 (no bill model exists yet).

## 7. Privacy walls (never relax)

The Claude key:
- Kaushik has a Claude API key. Never copy it into the repo, docs, memory or any message. Never ask him to paste it. Nothing prints, echoes, logs or stores any part of it (not its length, not a prefix). Presence is a yes or no only. Docs say "the Claude key prefix", never the literal. The key is read inside `ClaudeBrain` from the keychain into a local used only for the `x-api-key` header.
- Nothing key-shaped goes in fixtures; build fakes from pieces. A key-shaped string in any outgoing text is refused under both policies. The refusal line is `claudeKeyLine` (`ClaudeKeyGuard.swift`).
- Every Claude request refuses redirects (`NoRedirects`).
- Do not read or relay any thread named for the key check.
- An agent should never type even a made-up secret into the simulator, and never work around a safety check that blocks it.

Claude calls and the walls:
- `AppModel.asksClaude` gates all Claude use. The "Tess asks Claude" switch off means nothing is sent and the phone does everything.
- Spend: $100 per month in-app cap, checked before any network call, through `TessUsageLedger`. Every call writes a ledger row.
- Every Claude request is recorded in the "What was sent" log with the exact words (a key-shaped string never goes in).
- **No privacy filtering of what is sent to Claude (Kaushik, 11:59 AM Oct 27, `docs/product/decisions.md`; code #1488).** Money, calories, weight, health, body and private items go to Claude as they are; nothing is filtered or masked on the send side. This supersedes lab mode as the gate (flag `tessLabPolicy`) and every older "never reaches Claude" line in the docs, which are stale for the send side. Older docs say otherwise; the decisions entry wins. Check the code before you rely on a detail.
- Unchanged by that ruling: the Claude key and key-shaped text never leave the phone; Siri, Shortcuts and App Intents never send to Claude; the capture-miss route sends a whole unreadable phrase only (phrases the grammar can answer stay on the phone, more than 600 characters are refused); backups never include the key, bookmarks, flags or `claude-spend.json`; the harness trace file (`harness-trace.json`), the director playbook and run checkpoints are excluded from backups and never sent; trace spans hold numbers and names only, never request text.
- Model choice: Haiku 5.5 and Sonnet 5.5 only, no Opus. Smallest model that fits each job. On-device first where it fits (Apple Foundation Models). No other cloud LLM.
- Titles: `ObjectPrivacy.isPrivateTitle` is the one title check. Dentist, physio and PT titles read plain; "dr" and "dr." plus a word are walled; when unsure, wall. `SecretWords` refusal runs first in `TessRouter`. Private fixtures use lexapro and therapy.
- The UI must not claim that notes, places, health or money "never go" to Claude, because they now do (Oct 27 ruling). Money tools are offered to Claude as they exist since Kaushik's 12:28 PM Oct 27 card answer (today that is logSpend; the rest have no tool yet); each change lands pending with a 10 s Undo worded "Reversed". Room agents still have no money tools. Screen copy that still says otherwise (for example the Settings walls line) needs an app change.
- Health, body, calendar and calorie facts never reach backups, logs or widgets. The calendar and Health mirrors, held notices, Tess's conversation and the exact "What was sent" log are in no backup copy, including the local one. The Oct 27 ruling is about what a live Claude call may carry, not about those stores.
- Money has no amount on the doorway or on Home. Money undo is worded "Reversed".

## 8. Look rules

- Everything visual goes through the swappable `ThemeConcept` and `Theme` tokens. Animate only through `MotionPolicy`. Liquid Glass on the navigation layer only. Reduce Motion, Low Power and Dynamic Type (through AX5) are respected; at Reduce Motion each change lands in one step.
- Fit rule (Kaushik, 4:09 PM Oct 23): fixed layouts never wrap or shift. Use shorter words, never a smaller font or "...". No middle dots, and no cards or pills.
- Nothing fades. Things arrive by a clip or a slide. A line keeps a fixed length and changes only colour or weight. No ticks or marks off a line. Undo lasts 10 seconds.
- Pixel art is for the Home mosaic only, never inside a room.
- Type: no new fonts; roughly three sizes per screen (Outfit for numbers, Figtree for words in the room sheets). Stage-coloured bolder titles, done items strike through, hairline underlines, top bar without a band at the top. Small images only where the screen is uncluttered. A recipe image is his own photo or nothing.
- Tess is Ember. Never show a faded or diffused Tess. No soft or blurred patches except the tab neighbour words.
- Training accent: cobalt per 226 and 227. Check any colour next to Ember's palette (the delta-E rule in `qa/open-findings-integ77.md`, item 20).
- Reading layouts sit behind a "Reading layout" switch. New opinions ship behind a Settings Review switch (key `review.<id>`, default on today, no writes under `-demo`, never in settings, catalog or backups).
- Copy: one plain line per thing; receipts name the thing first; every screen declares its side swipe; a switch never names what is not drawn; finishing a thing is easy and rewarding, with one haptic per moment; the closing face says "<title>, ready to finish". Say "best", never "record".
- ADHD-friendly: dense information stays one reveal away, not on the surface.

## 9. Where specs live

Two copies exist, and they should match.
- The project folder `tessera/` (shared with the Claude project): `product/` (ship lists, decisions, build sheets), `design/` (numbered sheets 1 to 228), `ai/` (Tess and harness specs), `core.md`, `motion.md`, `product.md`, `qa/` (QA verdicts per PR, `review-<N>.md`, the test plan, open findings), `research/`, `ops/` (team addresses, board, checklists), and `handoff/CODEX.md` (this file).
- The repo mirror under `docs/`. It is behind the project folder for the newest sheets; the harness specs are under `docs/ai/harness/` and this PR adds sheets 226 to 228. Sheets 210 to 225, the Oct 22 build sheets in `product/` and the two QA files named above are still project-folder only.

Key paths:
- Decisions log: `docs/product/decisions.md` (newest at the bottom, with Kaushik's words and times).
- Harness (one copy, owned by the harness thread): the folder `docs/ai/harness/`. Start with `HANDOFF.md`; the build specs `h0-h2-build.md`, `h3-wiring-build.md` and `memory-context-m0-m6.md` sit beside it. Also `docs/ai/architecture.md`.
- Room sheets: `docs/design/room-landings-layout-226.md`, `landing-elements-kt-227.md`, `landing-elements-rooms-228.md`.
- Ops: `docs/ops/` (board, address files, checklists).
- Product vision: `docs/PRODUCT_VISION.md`. Motion: `docs/DESIGN_MOTION.md`.

## 10. Working with Kaushik

He drops asks between meetings and reads summaries. Lead with the answer. One recommendation per question; options as pictures when possible. Away from him, pick the default, say which, and batch the questions into one list. He wants a short update every 2 to 3 hours and a daily deck of today, next, and the week. Ask before anything hard to undo. Usage is paced: aim for steady progress rather than a burst; the old plan was a 90% weekly ceiling.

When you are near your own limits, write a short handoff note in `ops/rotation-handoffs.md` (project folder) and keep this file current so the next agent can start cold.

## Update log

- 6:05 PM PT Oct 23: first version (Ops). State and queued work as of the coordinator's 5:52 PM note.
- Oct 27: section 7 rewritten for the 11:59 AM no-filtering ruling (Kaushik's own words, decisions.md).
- 6:20 PM PT Oct 23: section 7 (health, body, calendar, calorie facts and what is in no backup), crimson never shipped, the 4:09 PM fit rule, and #1368 to #1370 noted (QA fix and lows on #1371).
- 6:10 PM PT Oct 23: #1366 worded as open against integ/77 and merged into integ/77-next; harness specs now point to docs/ai/harness/ (one copy).
