# QA audit of master at bb7f0820 (Oct 16, 2026)

QA, static read; there is no Swift toolchain in this container. Master is `bb7f082` (#424 on top of #422, #425, #423, #400, #421, #418). The audit has three parts: every path that sends text to Claude, the data-safety grep, and the review lows nobody owns yet. Each finding names an owner.

## Summary

- **Live today:** two paths reach Claude. The first is a capture miss (`ClaudeTessModel`, through `TessRouter`). The second is the key check in Settings (`ClaudeKeyCheck`). Both pass the switch and the $50 cap, and the capture path also passes the secret-word wall.
- **Live gap:** no money, body or health screen exists yet. A missed phrase like "spent $23.47 at trader joe's" or "slept 6 hours" goes to Claude today whenever the switch is on. This is MU2, already Core's next PR (A1).
- **Built but not wired:** plan wording (`ClaudePlanWording`), recipe link L3 (`ClaudeRecipeReader`) and the offline inbox retry (`readWaiting`). No app code constructs or calls them on master. Each has a wall missing that must land before or with its wiring (A2 to A5).
- **Data safety:** clean. Every launch-argument read goes through `LaunchFlags`. Each `#if DEBUG` block also checks `LaunchFlags`. All 7 UI test classes subclass `SimulatorOnlyTestCase`. GRDB migrations v1 to v3 only add, and catalog seeding only adds.

## 1. Every path that sends text to Claude

| Path | Wired in the app? | Switch (`asksClaude`) | Secret-word wall | Money/body wall | $50 cap ledger |
|---|---|---|---|---|---|
| Capture miss: `ClaudeTessModel.run`, ClaudeTessModel.swift:48 | Yes, AppModel.swift:128-136 (off under demo flags) | Yes: `isAvailable` reads `sendsMisses()`, which is `asksClaude` (ClaudeTessModel.swift:46, AppModel.swift:58-60) | Yes, in the router only (TessModel.swift:74-75) | **No** (A1) | Yes: reserve × 3 rounds, then a row per call (ClaudeTessModel.swift:56-62, 105-118) |
| Offline retry: `TessCaptureEngine.readWaiting`, TessInbox.swift:56-65 | No caller | Yes, through `claude.isAvailable` | **No: it calls `claude.run` directly and skips the router** (A2) | **No** (A2) | Yes, via `run` |
| Plan my day: `ClaudePlanWording.word`, PlanWording.swift:432 | No caller | **Only if the caller sets it: `allowed` defaults to `{ true }`** (PlanWording.swift:412; A3) | **No: task titles go verbatim** (PlanWording.swift:77; A4) | Health words are checked on the reply only (PlanWording.swift:289); **titles go out unscreened** (A4) | Yes (PlanWording.swift:444-458) |
| Recipe link L3: `ClaudeRecipeReader.read`, RecipeLinkReader.swift:349 | No caller (`RecipeLinkReader` is never constructed) | Yes: `allowed` is a required init argument (RecipeLinkReader.swift:323, 351) | **No** (A5; already flagged on #422 and queued as Core's paste/link wall) | **No** (A5) | Yes (RecipeLinkReader.swift:354-370) |
| Key check: `ClaudeKeyCheck.test`, ClaudeKey.swift:209 | Yes, Settings: Claude (ClaudeSection.swift:333) | Not checked, by design: he pressed TEST, and it sends only "Hi" | n/a (the payload is "Hi") | n/a | The free `count_tokens` call is not reserved; the 1-token fallback is (ClaudeKey.swift:236-241) |

Not on this list: the on-device model, which never leaves the phone, and memory. Memory and turnover use the on-device path and send nothing to Claude on master.

### Findings

**A1. Money, body and health phrases reach Claude as capture misses. Severity: high, live. Owner: Core (MU2, in flight).**
- The grammar returns `nil` (a miss) for money said: TessGrammar.swift:116-121 ("never a task or a list until Money exists").
- The router then tries the on-device model and Claude. It has no money screen; the only wall is `SecretWords.mentions` (TessModel.swift:74-75).
- The same happens to body and health phrases the grammar misses: "82,4" goes to the model per the decided BP rows, and so would "slept 6 hours".
- docs/ai/architecture.md §7 says body weight numbers, health values and money never leave the phone, and decisions.md:65 says the same of money (MU2).
- Fix: the router screens money, body weight numbers and health values before `isAvailable`, the same way it handles secret words. Tests: "spent $23.47 at trader joe's", "costco 212.37" and "weighed 82,4" each never reach a stub Claude.
- MU2 covers money. Body and health should ride the same PR, or Product names a follow-up.
- This is live on the next pin only if the switch is on. The switch defaults to yes (#320), so it is on unless he turned it off.

**A2. The offline inbox retry skips every router wall. Severity: medium, latent. Owner: Core.**
- `readWaiting` (TessInbox.swift:56-65) sends each waiting phrase straight to `claude.run`.
- `TessInbox.add` refuses only a Claude key (TessInbox.swift:28), not a secret word or money.
- Phrases queued after #422 have already passed the router. Phrases queued by the build on his phone (7b321d2, which has no secret-word wall) or by any build before MU2 have not. Once a build wires the retry, those go to Claude unscreened.
- Fix: run the same screens in `readWaiting`, so a phrase that trips them leaves the inbox unsent. Do the same in `add`.
- Better: move the screens into `ClaudeTessModel.run` (or AI-2's `ClaudeClient`, as architecture.md §7 plans), so every caller gets them. The router check stays as the first wall.

**A3. Plan wording is on by default. Severity: medium, latent. Owner: Core.**
- `ClaudePlanWording.allowed` defaults to `{ true }` (PlanWording.swift:412), unlike `ClaudeRecipeReader`, which requires the closure.
- A caller that forgets to set it sends the plan with "Tess asks Claude: no".
- Fix: make `allowed` a required init argument, as `ClaudeRecipeReader` does.
- Builder B, when wiring Plan my day: pass `{ model.asksClaude }`.

**A4. The plan pack sends task titles unscreened. Severity: medium, latent. Owner: Core.**
- `PlanPack.init` copies `block.title` into the wire JSON (PlanWording.swift:77).
- A task he typed as "pay rent $1,800" or "reset bank password" goes to Claude.
- decisions.md:103 allows task titles, but MU2 (decisions.md:65) says anything money-shaped never goes, and the secret-word rule keeps those lines on the phone.
- Fix: a block whose title trips `SecretWords.mentions` or the money screen goes as "busy" (the same form as an event with `includesEventTitles: false`). Add a snapshot test of the pack.
- Related: `includesEventTitles` defaults to `true` (PlanWording.swift:39) while his Oct 22 call is still open. Builder B passes it explicitly when wiring.

**A5. Recipe link L3 has no secret, money or body wall. Severity: low, latent. Owner: Core (already queued as the paste/link wall after MU2).**
- `RecipeLinkReader.read` hands the page text to Claude (RecipeLinkReader.swift:146). A page is third-party text, not his, so the risk is small.
- The rule on master still says secret words never leave. The fix and its test are the queued Core PR. No new work is needed; it is listed here so the audit is complete.

**A6. An unknown model costs zero against the cap. Severity: low, latent. Owner: Core.**
- `TessUsageLedger.estimate` and `cost` return 0 for a model with no price row (ClaudeKey.swift:144, 150). A model rename without a new price row would make every call free to the cap.
- Fix: `reserve` refuses a model with no price row. Add a test that every `static let model` has a row.
- This becomes urgent with AI-2, where the model is chosen per job.

**A7. Some recording flags leave Claude wired on the simulator. Severity: low, simulator only. Owner: Builder B.**
- AppModel.swift:119 counts only `-demo`, `-resetDemo`, `-theme` and `-fakeClaudeKey` as demo flags.
- A recording with `-tessScript`, `-speakScript`, `-demoKitchen` or `-demoNotes` and a real key in the simulator Keychain sends the scripted phrases to Claude.
- Fix: any `LaunchFlags.allowed` launch with a recording flag counts as demo, or one shared list in LaunchFlags.

**A8. Dead path: the "Not today" pause. Info. Owner: Builder B.**
- `ClaudeMissFlags.pauseUntilTomorrow` has no caller in the app; Settings: Claude has no "Not today" word.
- Either wire it (Design 32) or drop it from `isAvailable` when AI-2 lands. Product decides.

## 2. Data-safety grep

| Check | Result |
|---|---|
| Raw `ProcessInfo` / `CommandLine` reads | **Pass.** All five sites are default arguments that feed `LaunchFlags` or a guarded caller: LaunchFlags.swift:18, :25; AppClock.swift:18 (`LaunchFlags.value`); Theme.swift:282 (`LaunchFlags.value`); DemoData.swift:14, which guards on `allowed && LaunchFlags.allowed` (DemoData.swift:18). |
| `#if DEBUG` used as the only guard | **Pass.** Each of the 22 sites reads its flag through `LaunchFlags.has` or `LaunchFlags.value`. Sites: TesseraApp.swift:44, WorkoutModeView.swift:172, ReviewView.swift:322, NotesView.swift:28, PasteRecipe.swift:138, GroceriesView.swift:745, SpeechListener.swift:211, BottomChrome.swift:115/579/680, HomeSpatialView.swift:53/130, HomeQueue.swift:306, BackupKeeper.swift:69, ClaudeSection.swift:41. |
| UI tests not subclassing `SimulatorOnlyTestCase` | **Pass.** All 7 classes in TesseraUITests subclass it (SimulatorOnly.swift:5). |
| Non-additive migrations | **Pass.** GRDB v1 creates; v2 and v3 only `ALTER TABLE … ADD COLUMN` (TesseraDatabaseSchema.swift:46-55). Catalog seeding only adds fields. It refreshes names and specs only when `packageVersion < package.version` (SystemCatalog.swift:385), so an older build leaves newer rows alone. `upgradeExpression` rewrites only a listed retired expression (SystemCatalog.swift:451-457). |
| Device-test status | Catalog v9 (#422) is on master. It is not yet on his phone and not yet gate-tested. The v9 gate rerun is on the pin checklist (Builder A), and v10 (#407) reruns it after the pin. No new action from this audit. |

## 3. Open lows with no owner yet

Each was checked on master at bb7f0820. An owner is proposed for each; Product can reassign.

| Low | Where | Owner |
|---|---|---|
| `previousBest` has no callers | Features/Workout/WorkoutSession+Prefill.swift:42 | Builder A |
| `.target` comment says "only when the plan moved the target" (#397 L1) | Features/Home/TrainingPage.swift:345-347 | Builder A |
| `bestE1RM` tie keeps the oldest set, not the newest (#399 L1) | TesseraCore OpZones/ledger index; seen in RecordHint.swift:32-34 | Core |
| Three soul router tests wait on real time, about 12 s (#402 L4) | TesseraTests/SoulRouterTests.swift:56-80 | Builder A |
| `isAskWaiting` can stick if BottomChrome leaves mid-ask (#402 L5) | Features/Tess/SoulRouter.swift:52, 140-142 | Builder A (already on the working PR; listed so it isn't lost) |
| Demo clamp lands in the past from 03:55 to 04:00 (#405 L1) | Features/Demo/DemoData.swift | Builder A |
| Comments still say "$10" (#422) | TesseraCore/Sources/TesseraTess/ClaudeKey.swift:7, :83 | Core (sent 11:12 AM; listed until it lands) |
| "wifi-password" isn't split into words (#422 L2) | TesseraCore/Sources/TesseraCore/Notes/SecretWords.swift | Core |
| False positives become private notes without warning (#422 L1) | SecretWords | Product to rule; Core builds |
| `OpZones(store:)` built twice per row (#391 L1) | Features/Exercise/ExerciseViews.swift:131, :148 | Builder A |
| OpZones and `StoreDayLookup.zones` duplicate one rule (#377 L1) | TesseraCore | Core |
| `wroteRecent` true on an in-place update (#377 L3) | TesseraCore turnover | Core |
| Literal `Theme.voice(size: 21)` in place of a type token (#381 L4) | Features/Plans/RoutinesPage.swift:50, :109, :130 | Builder A |
| Long custom exercise names cut at two lines, never recorded (#381 L2) | Workout name step | Builder A |
| Groceries `summary` counts rows by `Date.now - createdAt < 60` (#380 L1) | Groceries | Core |
| Plan lows L1 to L6 (#363): two words for one moment, plan line with no fixed day, first record kind only, next calendar week not 7 days, static `firstUseCache`, `take` across plans | TesseraCore plans | Core |
| Editor lost the plan's ObjectHandle link (#359) | Plans editor | Builder A |

Already owned elsewhere, so not repeated here: the #366 lows (Builder B, on the open PR), the #403 eyes lows (closed at 3099412), the paste/link secret wall (Core, A5), and the after-#407 notes for Builders A and B.

## What QA does next

- **Lane 1:** reviews MU2 against A1, with the three test phrases above, and A2 if it rides along.
- **Lane 1:** checks A3 and A4 on Builder B's Plan my day PR before it can pass.
- **Lane 2:** re-runs this audit at each pin.
