# Oct 22 install readiness (board item 103)

*Research, draft for Product. Date 2026-10-16 (UTC); first checked at 8:55 PM PT on Thu 15 Oct against
`92078ee` (#252, 8:52 PM PT), updated for item 110 against `origin/master` at `5e91c56` (#263, 9:06 PM PT), then
for #269 against `444e72b` (#269's merge, 9:19 PM PT) with `origin/master` at `410403c` (#272, 9:24 PM PT). All
times Pacific (PDT). Static read only: no Swift toolchain, no simulator run, no install made. Sources:
`git log --first-parent b19fb4a..410403c`, `git diff 444e72b^1 444e72b`, GitHub open PRs (#273, #274 at 9:30 PM PT),
QA reviews in `docs/qa/` on master and
`../qa/review-*.md`, `debug-paths.md` (After #244), `install-day-script.md`, `resign-day.md`, `oct-22-list.md`,
`fixtures/grammar-regression.md` (on master, #260), `../ops/board/ios-a.md` and `../ops/board/qa.md`. Product's
call on the targets: 9:06 PM PT Oct 15.*

**Context.** The phone runs b19fb4a (fallback d0154a9). Free signing runs out Thu 22 Oct. His phone gets Debug
builds, so `#if DEBUG` does not protect it. #244 (`806b085`) put `-demo` and `-resetDemo` behind
`targetEnvironment(simulator)`. **#269 (launch flags, Builder A) is merged at `444e72b`** and puts every other demo
and test flag behind the same gate (section 2a). Per Product, `444e72b` is the Oct 22 install target once QA's
review-269 passes. **QA review-269: PASS** ("Safe to install on his phone", no blockers), merged to master as
`docs/qa/review-269.md` by #272 (`410403c`, 9:24 PM PT). One Mac check before the install, I1: build the
TesseraUITests target once (`xcodebuild -scheme TesseraUITests -destination 'platform=iOS Simulator,name=iPhone 17'
build-for-testing`), since `scripts/test.sh` doesn't compile it.

## 1. App PRs merged since b19fb4a, with QA verdict

69 merges sit between b19fb4a and 92078ee (first-parent). 32 are app code (Swift in `App/`, `Features/`,
`DesignSystem/`, `Shared/`, `Widgets/`, `TesseraCore/` or tests). The other 37 are the `claude/project-thread-*`
Research PRs, which touch only `docs/`, so they carry no install risk and are left out of the table.

| PR | Merge commit | What it changes | QA verdict (source) |
|---|---|---|---|
| #184 | ab45919 | Review week: session count, rest as a dry stroke, rings only for open days | PASS, R1 to R3 should-fix, all closed by #197 (`review-184.md`, `review-195-197.md`) |
| #187 | dc8d1d2 | His day ends at 4 AM (TesseraDay) across the engine, Review, Notes, recipes | PASS (`review-187.md`) |
| #190 | 71c9dac | Late-night fixes: ghost rest, 4 AM day, set-aside Lock Screen, empty routines | PASS, U1 closed (`review-190.md`) |
| #191 | 966636f | Backups say when a daily copy fails; Undo skips the 04:00 roll | PASS (`review-191.md`) |
| #193 | 30aa845 | Themes part 1: five looks, theme store, look sentence | PASS with should-fixes, closed by #199 (`review-193.md`, `review-199.md`) |
| #195 | b273a41 | Empty routines can't start; rest set id survives a relaunch; look sentence on Review | PASS (`review-195-197.md`) |
| #197 | d9411a5 | Review follow-up: real misses only, Monday weeks, full Review marks, canStart | PASS (`review-195-197.md`) |
| #199 | 0532d73 | Looks: pinned contrast, LOOK copy, look-table test | PASS (`review-199.md`) |
| #201 | fbe074a | Past days in the week say rest or was due; Monday-first weeks | PASS (`review-201.md`) |
| #203 | 68cee3a | Themes 2a: the workout follows the look | PASS, W1 and W2 should-fix, closed by #207 (`review-203.md`) |
| #205 | aec9ccd | Live-workout set guard S701 to S706 | PASS on fixtures, Q1 and Q2 should-fix, closed by #210 (`review-205.md`) |
| #207 | df856c6 | Themes: workout keys visible with a light look pinned | GO on W1; W7 should-fix, closed by #215 (`review-207.md`) |
| #210 | e75f40f | Set guard: dictated and comma phrases | PASS (`review-210.md`) |
| #211 | 157f882 | Daily backup by his 4 AM day, clock, folder and restore fixes | PASS, lows only (`review-211.md`) |
| #215 | 862ed68 | Themes 2b: Tess, glows and Lock Screen follow the look | PASS (`review-215.md`) |
| #218 | 2892ac1 | Claude key store: Keychain, Test, the $10 ledger, the key-prefix guard | PASS, K11 should-fix, closed by #230 (`review-218.md`) |
| #219 | 15f2d86 | His day runs to 4 AM on Home; Review reads Core's past-day flags | PASS, D7 test gap (`review-219.md`) |
| #221 | 87bd157 | Looks in App Group storage, paint on workout pages, theme leftovers | PASS (`review-221.md`) |
| #225 | 3c9278a | v3: time zone recorded on every op (before the 26 Oct trip) | PASS, Z1 should-fix (`review-225.md`) |
| #227 | 8fc5bd3 | Settings: Claude key field, key safety in Ask and recipe paste | PASS, C1 and C2, closed by #234 (`review-227.md`) |
| #228 | 0dfe108 | ScrubFeel as a pure, tested function | PASS (`review-228-229.md`) |
| #229 | 3ccd3be | Workout ask field refuses Claude keys | PASS (`review-228-229.md`) |
| #230 | 419d6de | Claude key hardening: header, keep the key on a failed test, case-blind guard | PASS, H1 should-fix, closed by #234 (`review-230.md`) |
| #231 | f4ab565 | Looks tokens: restTint, dry motion, soul wash, glass blur | PASS, G1 flag for Design (`review-231.md`) |
| #234 | c76d735 | Home on theme tokens, 4 AM day stroke, Monday-first Review, Claude field fixes | PASS, M1 question for Product (`review-234.md`) |
| #236 | 9d4cb4f | Zone follows the device without a relaunch; test on a real v2 store | PASS, Z1 and Z2 closed (`review-225.md`, addendum) |
| #239 | fc31605 | Backups never copy an empty store; rewrite today's copy after a restore | PASS, no hotfix (`review-239.md`) |
| #241 | feb2ba7 | No dots, thinner ink, Receipts | PASS, N1 should-fix, closed by #246 (`review-241.md`) |
| #244 | 806b085 | Demo data and `-resetDemo` can never run on the phone | PASS, G1 should-fix, G2 note (`review-244.md`) |
| #248 | fdcaee4 | Set guard: the 2 × 10 ask, name-first receipts, set and errand | PASS, Q9 and Q10 should-fix (`review-248.md`) |
| #246 | c2fd7ad | Backups after a reinstall, the Next bloom plays | PASS, R3 should-fix (`review-246.md`) |
| #251 | 247150e | Tess asks "Bench 80 × 8 for Monday?" for a lift on a past day; × in lift lines (9 Core files) | PASS, lows D1 and D2 (`../qa/review-251.md`) |

| #254 | e7a5be4 | Set guard: RPE and kind still ask (Q9), no yes/no asks (Q10), "by" reads as ×, D1 and D2 for the dated ask (8 Core files) | PASS, lows P1 and P2 (`docs/qa/review-254.md`) |
| #258 | 67442a1 | Settings object, catalog v4: look, misses to Claude, backup folder, rest weekday (6 Core files, no app reader yet) | PASS, two lows (`../qa/review-258.md`; docs PR #265 still open) |

Note: #251 merged at 8:52 PM PT; QA passed it (`docs/qa/review-251.md`, now on master via #257). LOG makes one op,
so UNDO takes back the set and any workout it made; a day name always means a past day (or today), never a future
one. Its lows D1 and D2 are closed by #254.

**Since 92078ee** (to `5e91c56`, 9:06 PM PT): 10 merges, 2 of them app code (#254 at 9:00 PM PT, #258 at
9:05 PM PT, both Core only; no file in `App/`, `Features/`, `DesignSystem/`, `Shared/`, `Widgets/` or the app test
targets changed). The other 8 are docs (#253, #255, #256, #257, #259, #260, #261, #263).

**Since 5e91c56** (to `444e72b`, 9:19 PM PT): 7 merges, 4 of them app code. The other 3 are docs (#265 at 9:15,
#267 at 9:10, #268 at 9:16 PM PT).

| PR | Merge commit | What it changes | QA verdict (source) |
|---|---|---|---|
| #262 | 12f1c43 | Spoken numbers to digits (`TessSpoken`), run first in a live workout (`TessGrammar.swift:115-124`); "a hundred, five" is never groceries (K885); dated lift prefers the workout that has the exercise (P1) and is stamped at its end (P2) (7 Core files) | PASS, lows R1 to R3; closes K885, P1, P2 (`docs/qa/review-262.md`) |
| #266 | e79dda2 | One base across the app: the workout stands on Home's ground in every look (`Theme.swift:258-262`), light or dark scheme by the look (`WorkoutModeView.swift:140`); rest Lock Screen followed the look | PASS, lows B1 to B3 (`docs/qa/review-266.md`) |
| #264 | cc1da97 | Calmer capture; the 2 × 10 set-count ask answers on a tap (`BottomChrome.swift:138-158`, `AppModel.swift:172-184`); "Reinstalled?" counts every non-system op (`BackupView.swift:70`) | PASS, lows C1 to C5; closes R3 and L4 (`docs/qa/review-264.md`, on master via #270 after 444e72b) |
| #269 | 444e72b | Every demo and test launch flag simulator only (`LaunchFlags`); UI tests skip on a phone; `resetUserData` does nothing on a device; Lock Screen rest card stays Cobalt sky in every look (QA B3); names PleinGround's dark literal (B1) | **PASS**, "safe to install", one Mac check I1 (`docs/qa/review-269.md`, via #272 at 9:24 PM PT) |

**Since 444e72b** (to `410403c`, 9:24 PM PT): 3 merges, all docs (#271 Research, #270 `docs/qa/review-264.md`,
#272 `docs/qa/review-269.md`). No app file changed, so `444e72b` and `410403c` build the same app.

**Open app PRs at 9:30 PM PT** (both opened 9:27 PM PT, not merged, no QA review yet): **#273** "Speak: tap or hold
to talk; the voice ghost; LOG / NOT NOW on dated lifts" (Builder B) and **#274** "Grammar: a lift and an errand both
log; bodyweight N × M is sets; 'today' and 'at 7'" (Core; by its title, the set-loss work). Neither is in
`444e72b`.

## 2. Open fixes

Checked in code at `444e72b`. Open app PRs at 9:30 PM PT: #273 (Speak) and #274 (grammar, likely row 3).

| # | Fix | Must / should | Owner | State at 444e72b |
|---|---|---|---|---|
| 1 | **Launch-flags PR** (`debug-paths.md`, After #244): (a) `XCTSkip` on a device in TesseraUITests; (b) one simulator-only `LaunchFlags` helper for `-queueScript`, `-tessScript`, `-demoTime`, `-demoReview`, `-demoKitchen`, `-demoNotes`, `-theme`, `-backupFailure`; (c) `resetUserData()` refusing a store with real ops | **Must**, before any install (`ios-a.md` Now; QA G1 in `review-244.md`) | Builder A | **Merged as #269 at `444e72b`; QA review-269 PASS.** (a) and (b) done; (c) done differently (a device compile-out, not a refusal). Details and what stays open in 2a |
| 2 | R3: "Reinstalled?" line keys on `.user` ops in the last 50 | Should | Builder B | **Closed by #264** (`BackupView.swift:70` counts every non-system op over the last 2000; `review-264.md`). New low C4: settings ops will count once the look is saved as a `.user` op |
| 3 | **Set-loss PR**: the wrong-write rows A171, A183, A184, A162, A163, A167, A059, A181, A182 (`fixtures/grammar-regression.md`; for example "bench 80x8 dentist fri" in a workout, "buy milk and bench 80x8", "bench 80x8 at 7"). K885 was the tenth row; #262 closes it | Should; Product's fallback target once Research's rerun (item 108) and QA pass it | Core | Open, nine rows; no PR yet |
| 4 | G2: any non-SQLite error at launch counts as damage and moves the store aside | Note, worth closing (`review-244.md`) | Core | Open (`TesseraSchema.swift:76-77`) |
| 5 | P1: a dated lift joins the day's last workout even when an earlier one holds that exercise | Low (`review-254.md`) | Core | **Closed by #262** (`review-262.md`) |
| 6 | P2: a dated set joining an existing workout is stamped noon | Low (`review-254.md`) | Core | **Closed by #262** (stamped at the workout's end, `review-262.md`) |
| 7 | `restWeekday` not range-checked (0 or 8 would crash the first reader); a soft-deleted settings object silently stops saving | Lows (`review-258.md`) | Core | Open; nothing in the app reads settings yet |

Closed since the first draft: Q9, Q10 (`review-248.md`), D1 and D2 (`review-251.md`), all by #254 (`review-254.md`);
R3 and L4 by #264; P1, P2 and K885 by #262; #266's B1 (PleinGround's dark literal, now `PleinGround.nightGround`,
`Paint.swift:15`), B2 (the "82%" comment) and B3 (the light Lock Screen, now Cobalt sky in every look) by #269.

### 2a. What #269 guards on a device build, and what it leaves open

All `file:line` at `444e72b`.

**The gate.** `App/LaunchFlags.swift:8-14`: `LaunchFlags.allowed` is `true` under `#if targetEnvironment(simulator)`
and a compile-time `false` otherwise. `has(_:in:)` (`:17-21`) and `value(after:in:)` (`:24-30`) both return
nothing unless `allowed`. So on his phone every flag below reads as absent, in Debug and Release alike.

**Flags now read only through `LaunchFlags` (dead on a device):**

| Flag | Where (444e72b) | Was it writing on the phone before? |
|---|---|---|
| `-demo`, `-resetDemo` | `TesseraApp.swift:29`; `DemoData.swift:10-12, 18` (`guard allowed, LaunchFlags.allowed`, so a caller can't widen it) | Already gated by #244; now through the helper |
| `-demoTime` | `AppClock.swift:21` (still also inside `#if DEBUG`) | Yes (shifted clock on logs and backups) |
| `-theme` | `Theme.swift:281` | No (in memory); #266 had gated it with `DemoData.isAllowed` |
| `-queueScript` | `HomeQueue.swift:309` | Yes, edited his real tasks |
| `-demoReview` | `ReviewView.swift:327` | Yes, edited his real tasks |
| `-tessScript` | `BottomChrome.swift:86` | Yes |
| `-demoKitchen` | `GroceriesView.swift:746` | Yes |
| `-demoNotes` | `NotesView.swift:33` | Yes |
| `-backupFailure` | `BackupKeeper.swift:56` | Yes (a persisted fake failure line) |
| `-fakeClaudeKey` | `ClaudeSection.swift:43` | No (in-memory key) |
| `-homePage`, `-openLink` | `HomeSpatialView.swift:55, 112` | No |
| `-pasteDemo` | `PasteRecipe.swift:140` | No |
| Screen swaps `-soulGallery`, `-notes`, `-review`, `-groceries`, `-looks`, `-backup`, `-recipe`, `-pasteRecipe` | `TesseraApp.swift:45-62` | No |

`git grep 'ProcessInfo.processInfo.arguments' 444e72b -- '*.swift'` now finds only `LaunchFlags.swift:18, 25` and
three default parameters (`AppClock.swift:18`, `Theme.swift:279`, `DemoData.swift:14`) whose bodies read through
`LaunchFlags` or sit behind its guard. That ticks debug-paths.md's "no write-capable flag outside the helper" line.

**TesseraUITests on a device: they skip.** `TesseraUITests/SimulatorOnly.swift:5-11` adds `SimulatorOnlyTestCase`,
whose `setUpWithError` throws `XCTSkip("UI tests run on the simulator only, never on a phone with real data.")`
under `#if !targetEnvironment(simulator)`. All three UI test classes inherit it: `BackupReinstallUITests.swift:5`,
`ClaudeSettingsUITests.swift:5`, `HomeQueueUITests.swift:6`. Their own `setUp()` overrides don't replace
`setUpWithError`, so the skip still runs first.

**`resetUserData()`: not a refusal, a device compile-out.** `ObjectStore+Lifecycle.swift:54-56`: under
`#if os(iOS) && !targetEnvironment(simulator)` the body is just `return`, whoever calls it. So on his phone the
wipe cannot run at all, which is the Core second line of defence debug-paths.md asked for. It does **not** look at
the store's ops: on the simulator (and in `swift test` on the Mac) it still wipes any store, real ops or not.

**Not closed by #269** (from debug-paths.md "After #244", "Still open" and "slightly off"):

1. **`resetUserData()` refusing a store with real ops.** Still not built. The simulator restore drill (a restored copy
   of his real backup on the simulator) is still wiped by `-resetDemo`. Not a phone risk; matters for the drill.
2. **Launch note on a device saying the demo flags were ignored** (optional). Not built: nothing on the phone says a
   ticked argument was dropped. The flags simply read as absent.
3. **Simulator only, not `DEBUG &&` simulator.** `LaunchFlags.allowed` has no `#if DEBUG`. Most call sites also sit
   inside `#if DEBUG`, but `-demo`, `-resetDemo` (`TesseraApp.swift:29`) and `-theme` (`Theme.swift:281`) do not,
   so a Release build on the simulator still honours those three. Harmless for the phone; left as advised.
4. **UserDefaults argument domain (item 11).** Untouched by design: a `-look.day Plein` style argument still reaches
   `UserDefaults` on any build. Needs a deliberate odd argument; debug-paths.md advises leaving it.
5. **Hosted unit tests on the phone.** `LaunchFlagsTests.swift:7` (`#expect(LaunchFlags.allowed)`) and #244's
   `theTestsRunWhereDemoDataIsAllowed` would fail on a device. Not a data risk (in-memory stores); a useful signal.

Closed by #269 from the same list: `XCTSkip` on a device; the one `LaunchFlags` helper (all seven writing flags plus
`-theme`); `prepare`'s `allowed:` parameter can no longer widen the gate (`DemoData.swift:18`); the "no flag outside
the helper" grep; the Core second line of defence on a device.

Lows still open, not blocking: L5 (key-missing line after his
own REMOVE), W11 (`adoptRestored` has no caller), D7 (no Core test for a double-session day), G1 in `review-231.md`
(grey glass on the pure-black workout, Design's call). M1 in `review-234.md` is answered: Product kept "misses go
to Claude: yes" at 8:28 PM PT, and #258 stores it with that default.

## 3. Recommended install target

Product's call (9:06 PM PT Oct 15) sets the order below. Every candidate also needs `scripts/test.sh` to end
"All green" on that exact commit (engine package tests, then the app build and tests on the simulator).
review-269 mentions a green run (287 package tests, 111 app tests) without naming the commit; no "All green" record
for `444e72b` itself is in `docs/qa/` or `../qa/` (no toolchain here). Run it on the hash being installed, plus
QA's I1 (build TesseraUITests once).

1. **Primary: `444e72b`, the launch-flags PR's merge (#269).** QA's review-269 **passed** (9:24 PM PT). Still to
   do: `scripts/test.sh` ends "All green" on it, and I1. `410403c` (master now) builds the same app: the three
   merges since are docs only.
2. **Fallback: the merge of Core's set-loss PR** (the nine rows left in section 2, row 3), once Research's rerun
   (item 108) and QA pass it. It will sit on top of `444e72b`, so it carries #269's guards too.
3. **If neither is ready by Wed 21 Oct, 6:00 PM PT: the newest QA-passed master commit that includes #254**
   (`e7a5be4` or later). With review-269 passed, that is now `410403c`, the same app as `444e72b`, so tiers 1 and 3
   coincide. If #273 or #274 merges later, the newest QA-passed master moves only once its own review passes.

**Always, whichever commit is installed:** the scheme's Run arguments are empty (check Edit Scheme > Run >
Arguments before Cmd-R), no TesseraUITests run with his phone as the destination, `resign-day.md`'s safe order is
followed, and the app is never deleted. Rollback note from `resign-day.md`: after a v3 build runs, b19fb4a still
opens the database, but must not be used to restore a v3 backup. A rollback from a #258 build (catalog v4) to an
older one was not checked here. With #269 a ticked argument or a UI test run on the phone is now harmless, but the
"always" checks stay: they cost nothing and cover a QA miss.

### The candidates

| Candidate | Launch-flag guards | #254 (Q9, Q10, "by", D1, D2) | #262 spoken numbers, K885, P1, P2 | #266 workout on Home's base | #264 calm capture, tap answers, R3 | Set-loss rows | QA | Known gaps |
|---|---|---|---|---|---|---|---|---|
| **`444e72b`** (#269, primary) | Yes (section 2a) | Yes | Yes | Yes | Yes | No: nine rows open | All PASS, review-269 included | Nine set-loss rows. G2, #258 lows, C1 to C5, R1 to R3 (262). `resetUserData` refusal and device launch note not built. No Speak: #273 is **not on master** (open, 9:27 PM PT). `scripts/test.sh` "All green" and I1 to confirm on this hash |
| Set-loss merge (fallback) | Yes (based on 444e72b or later) | Yes | Yes | Yes | Yes | Yes | Needs item 108's rerun and its own QA | Likely #274 (open, not merged, not reviewed). Contains #273 Speak only if #273 merges first |
| `cc1da97` (#264, the newest QA-passed master before #269; reference) | **No**: seven flags still write on his phone, UI tests can drive it | Yes | Yes | Yes | Yes | No | All PASS | Everything in the first row, plus the open flags; the "always" conditions carry the safety |
| `5e91c56` (item 110's fallback, reference) | No | Yes | No | No | No | No (ten rows) | All PASS | Above, plus K885, P1, P2, R3, the plum-black workout |
| `92078ee` (reference only) | No | No: Q9 and Q10 open | No | No | No | No | All PASS | Everything above, plus Q9 ("2x10 @8" logs 2 kg) and Q10 |

The items in section 2, rows 3, 4 and 7, do not block the install.

## 4. install-day-script.md checked against 92078ee

The script was written against `8fc5bd3`. Line numbers have moved in several files; the table gives the ones that
matter. "Holds" means the expected screen and line are still right.

| Step | Result | What changed at 92078ee |
|---|---|---|
| Before you start | Holds | `-demo`/`-resetDemo` now run on the simulator only (`TesseraApp.swift:30`, `DemoData.swift:22`), which is what the script needs. Defaults Porcelain/Obsidian at `Looks.swift:207-208` hold |
| 1 | Holds | Porcelain ground `0xFFFFFF` at `Looks.swift:63-65` |
| 2 | Holds, new line number | The link word **The week** is now `HomeSpatialView.swift:214`. LOOK, then CLAUDE, then Backups at `ReviewView.swift:221-232`. Hint at `LookSentence.swift:64` |
| 3 | Holds | No change found |
| 4 | Holds | "always." and the hold-again hint at `LookSentence.swift:27-29` |
| 5 | Holds | Obsidian `0x000000` at `Looks.swift:73-78` |
| 6 | Holds | Workout ground `0x14111A` on Porcelain (`Looks.swift:68`). The 8:25 PM PT correction (workout on Home's base) is not built yet; when it lands this step changes |
| 7 | **Needs change** | #248 replaced "81 isn't loadable". Expect "Set N logged. 80 × 8, nearest load to 81." (`TessCaptureEngine.swift:262-273`). Placeholder now at `WorkoutParts.swift:323` |
| 8 | **Needs change** | Expect "Set N logged. 100 × 5, RPE 8." then "Set N logged, same again, RPE 9." (`TessCaptureEngine.swift:271-273`) |
| 9 | **Needs change** | Still no set and no task, but the lines are now Tess's own asks, not the model's: `81` gives "81 for how many reps?" (`TessGrammar+Live.swift:93-94`, with 100 kg as the last set); `+5` gives "+5 kg: on the next set?" (`:44`). Do not answer "yes" (that is QA's open Q10). `call mum at 7` holds. The model fallback line is now at `TessModel.swift:86` |
| 10 | Holds | `LookTable.swift:14, 16` |
| 11 | Holds | No change found |
| 12 | Holds | `-theme` still in memory only |
| 13 | Holds, new line number | `canStart` at `AppModel.swift:533`; refusal at `PlanActions.swift:121` |
| 14 | Holds | Headline now at `ReviewPage.swift:34-48`. Weeks count from Monday, so a Monday run reads "A quiet week so far" (QA L3, `review-234.md`) |
| 15 | Holds | No change found |
| 16 | Holds, with one new line to expect | Lines now at `BackupView.swift:51` (headline), `:341` (first copy) and `:348` (every day). New since #246: "Reinstalled? Restore brings back your copy from iCloud Drive." shows if none of the last 50 ops is by `.user` (`BackupView.swift:69`). Demo data is seeded as `.system`, so it can show here; that is QA's R3, not a step failure |
| 17 | Holds, new line number | Refusal line now `BottomChrome.swift:410`. Use the same made-up key prefix as the script, never a real key |
| 18 | Holds, new line numbers | `ClaudeSection.swift:126` ("Tess thinks on this phone only."), `:133` (Add a Claude key) |
| 19 | Holds, new line numbers | Line at `ClaudeSection.swift:285`; the 10-character paste rule at `:237` |
| 20 | Holds, new line numbers | `ClaudeSection.swift:150, 159, 188, 346, 360`. The keys are drawn from `Button("Test")`, `"Replace"`, `"Remove"` (`:194-199`), shown in caps by the button style (not checked on screen) |
| 21 | Holds | "On Now then." at `TessCaptureEngine.swift:233`. #251's day words apply only to a lift with a day name, not to these phrases |
| 22 | Holds | `TesseraDay.swift:10` |
| New | **Added as step 9a** | #251: in the workout, `bench 80x8 mon` asks "Bench 80 × 8 for Monday?"; `log it` gives "Bench 80 × 8 logged for Monday." (UNDO covers it); `not now` writes nothing. The LOG and NOT NOW words aren't drawn in the app yet, so the answers are typed |

**The script's "stale strings" list.** Item 1 is now closed in Core: `TessRouter.keyLine` (`TessModel.swift:60`)
says "That looks like a Claude key. It goes in Review, under Claude.", the same as the Ask bar, so only the review
guide still needs updating. Items 2 to 5 still stand.

**Summary of the check.** 18 steps hold (several with new line numbers), 3 need new expected lines (7, 8, 9), and 1
step should be added for #251. All of these, plus the moved line numbers, R3 beside step 16 and stale item 1 marked
closed, are now applied in `install-day-script.md` (step 9a is the #251 step).

### Re-check against 444e72b (#269)

`install-day-script.md` is now re-checked step by step against `444e72b` and updated in place (line numbers are
`444e72b`'s). The changes:

| Step | Change | Why |
|---|---|---|
| Before you start | Flags now read through `LaunchFlags` (`LaunchFlags.swift:8-14`), simulator only; Release on the simulator still honours `-demo`, `-resetDemo`, `-theme`. Defaults now `Looks.swift:186-187` | #269 |
| 6 | Workout on Home's base: white ground `#FFFFFF`, ink keys `#17141F`, light scheme on Porcelain by day. Was plum-black `#14111A` | #266 (`Theme.swift:258-262`, `WorkoutModeView.swift:140`) |
| 7, 8 | Same lines; new line numbers (`TessCaptureEngine.swift:263-274`) | moved by #262/#264 |
| **8a (new)** | Typed number words in the workout: `same at nine` logs "Set N logged, same again, RPE 9."; `a hundred, five` writes no set and nothing on Groceries | #262 (`TessGrammar.swift:115-124`, `SpokenNumbersTests.swift:85, 104-118`) |
| 9 | Same lines; `81` ask now at `TessGrammar+Live.swift:68-70`, `+5` at `:113-117` | moved by #254/#262 |
| 9a | Lines moved to `TessSetCountAsk.swift:102, 107`; still typed answers (no LOG / NOT NOW words, QA C5) | #264 drew only the 2 × 10 ask |
| 10 | Lock Screen rest card is Cobalt sky in every look (dark violet tint, cobalt wash top left, cream `#F6EFE4` countdown); Island stays Obsidian | #269 (`RestLiveActivity.swift:107`, `LookTable.swift:31-33`; Island `:51-52`) |
| 12 | `-theme porcelain` now gives the same white workout as step 6; the check is that nothing is saved | #266 |
| 16 | The "Reinstalled?" line now shows only when no op in the last 2000 is by anyone but `.system` (`BackupView.swift:70`); with demo data seeded as `.system` it still shows | #264 closed R3 |
| 17 | Field prompt "Write anything", question "What's on your mind?" (`BottomChrome.swift:227, 299`); key line `:406` | #264 |
| **23 (new)** | On the simulator, confirm the device-only guards can't be tested there; check by code read at the install hash instead | #269 |
| **S1 to S7 (new, phone)** | "Speak on the phone", about a minute after the install, with open checks 6b (relaunch after the mic switch) and 8c (en-IN exact or near match). Runs only if #273 is in the installed build; it is not in `444e72b` | #273 (open) |

All other steps hold with refreshed line numbers. No step depends on a flag behaving differently on the simulator:
`-demoTime`, `-theme`, `-openLink`, `-fakeClaudeKey` and `-resetDemo` all still work there through `LaunchFlags`.

### Steps that differ by candidate (before 444e72b)

Kept for reference: this table compared candidates when the script matched `92078ee`. With `444e72b` as the target
the script now matches it; on `cc1da97` (master just before #269) every step reads the same except 10 (the Lock
Screen card follows the look there: white on Porcelain, `LookTable.swift` `forState`) and 23 (no `LaunchFlags`).
Static read; #254's lines checked at `e7a5be4` and `5e91c56`:

| Step | 92078ee | With #254 (newest master, and any candidate based after e7a5be4) | Set-loss merge | Launch-flags merge |
|---|---|---|---|---|
| 7, 8 | As written | Same lines: "100 for 5 at 8" and "81 for 8" don't take the 2 × 10 ask | Re-check after the PR | Same as its base |
| 9, `81` | "81 for how many reps?" | Same | Re-check | Same as its base |
| 9, `+5` | "+5 kg: on the next set?" | A statement, not a question: "Say the set, like 105 × 5." (last set 100 × 5, `TessGrammar+Live.swift:115-117`). A bare "yes" now gets "Say the set, like 100 × 5." and never a task, so the script's "don't answer yes" can go | Re-check | Same as its base |
| 9, `call mum at 7` | "Call mum, today 7 pm." | Same | Re-check: A162 to A167 change how a set and a task in one phrase split | Same as its base |
| 9a | As written | `yes` also logs, like `log it`. LOG joins the named day's last workout, open or finished (D1) | Re-check | Same as its base |
| Skip (not a script step) | "Skip set N?" | "Skip is on the workout screen." | | |
| 1, 6, 12, 20, 21 | As written | Same | Same | Re-run: these use `-demoTime`, `-theme`, `-openLink`, `-fakeClaudeKey`, which the helper may change |
| 6, 10, 12 | Plum-black workout (`#14111A`) | Same | Same | Same, unless #266 merges first: then the workout stands on Home's ground in every look and these expected colours change |

#258 changes nothing on screen (no app reader yet), so no step differs for it.
