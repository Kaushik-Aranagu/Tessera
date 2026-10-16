# Oct 22 install readiness (board item 103)

*Research, draft for Product. Date 2026-10-16 (UTC); checked at 8:55 PM PT on Thu 15 Oct. All times Pacific (PDT).
Checked against `origin/master` at `92078ee` (#252, 8:52 PM PT). Static read only: no Swift toolchain, no
simulator run, no install made. Sources: `git log --first-parent b19fb4a..92078ee`, GitHub open PRs (none open at
8:55 PM PT), QA reviews in `../qa/review-*.md`, `debug-paths.md` (After #244), `install-day-script.md`,
`resign-day.md`, `oct-22-list.md`, `../ops/board/ios-a.md` and `../ops/board/qa.md`.*

**Context.** The phone runs b19fb4a (fallback d0154a9). Free signing runs out Thu 22 Oct. His phone gets Debug
builds, so `#if DEBUG` does not protect it. #244 (`806b085`) put `-demo` and `-resetDemo` behind
`targetEnvironment(simulator)`; the rest of the launch-flag work is still open (below).

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

Note: #251 merged at 8:52 PM PT and QA has since passed it (`../qa/review-251.md`, in project files, not yet on
master). LOG makes one op, so UNDO takes back the set and any workout it made; a day name always means a past day
(or today), never a future one. Two lows, D1 and D2 (section 2).

## 2. Open fixes, not merged

No PR is open on GitHub at 8:55 PM PT, so every item below is unbuilt. Checked in code at 92078ee.

| # | Fix | Must / should | Owner | Still open in code at 92078ee |
|---|---|---|---|---|
| 1 | **Launch-flags PR** (`debug-paths.md`, After #244): (a) `XCTSkip` on a device in TesseraUITests; (b) one simulator-only `LaunchFlags` helper for `-queueScript`, `-tessScript`, `-demoTime`, `-demoReview`, `-demoKitchen`, `-demoNotes`, `-theme`, `-backupFailure`; (c) `resetUserData()` refusing a store with real ops | **Must**, before any install (`ios-a.md` Now; QA G1 in `review-244.md`) | Builder A | Yes. No `XCTSkip` in TesseraUITests, no helper in the app, `resetUserData` unguarded (`ObjectStore+Lifecycle.swift`). `-queueScript` and `-demoReview` still edit his real tasks on a device Debug build |
| 2 | R3: "Reinstalled?" line keys on `.user` ops in the last 50, so it can show on his own phone after Tess-logged workouts | Should | Builder B | Yes (`BackupView.swift:69`) |
| 3 | Q9: an RPE or kind word skips the 2 × 10 ask ("2x10 @8" logs 2 kg) | Should | Core | Yes (`TessGrammar+Live.swift:99`, `rpe == nil, kind == nil`) |
| 4 | Q10: the new "Skip set N?" and "+5 kg: on the next set?" asks have no "yes" answer | Should | Core | Yes (`TessGrammar+Live.swift:44, 47`) |
| 5 | G2: any non-SQLite error at launch counts as damage and moves the store aside | Note, worth closing (`review-244.md`) | Core | Yes (`TesseraSchema.swift:76-77`) |
| 6 | D1: an unfinished workout on the named day isn't matched, so LOG makes a second "Workout" for that day | Should (low), folds into the Q9/Q10 PR | Core | Yes (`review-251.md`) |
| 7 | D2: sets logged for a past day carry today's `loggedAt`, so anything sorting by `loggedAt` puts them on today | Should (low), folds into the Q9/Q10 PR | Core | Yes (`review-251.md`) |

Lows still open, not blocking: B8/L4 (`BackupKeeper.forget()` keeps a folder failure), L5 (key-missing line after his
own REMOVE), W11 (`adoptRestored` has no caller), D7 (no Core test for a double-session day), G1 in `review-231.md`
(grey glass on the pure-black workout, Design's call), M1 in `review-234.md` (Product to confirm the "misses go to
Claude: yes" default before that path is built).

## 3. Recommended install target

**Install the launch-flags PR's merge commit, on top of `92078ee`.** Product names it when it lands; it must
carry a QA PASS, and `scripts/test.sh` must end "All green" on that commit.

Why not `92078ee` as it stands: it has everything QA passed since b19fb4a, but seven launch flags still write on a
device Debug build, and the UI tests can still drive his real app. Builder A's board says the launch-flags PR comes
before any install.

**Fallback if the launch-flags PR has not merged by Wed 21 Oct, 6:00 PM PT:** install `92078ee`, with three conditions: the scheme's Run arguments are empty (check Edit Scheme > Run >
Arguments before Cmd-R), no TesseraUITests run with his phone as the destination, and `resign-day.md`'s safe order
is followed (never delete the app). Rollback note from `resign-day.md`: after a v3 build runs, b19fb4a still opens
the database, but must not be used to restore a v3 backup.

The items in section 2, rows 2 to 7, do not block the install.

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
closed, are now applied in `install-day-script.md` (step 9a is the #251 step). If the launch-flags PR changes how `-demoTime`, `-theme`, `-openLink` or
`-fakeClaudeKey` are read, steps 1, 6, 12, 20 and 21 must be re-run on the simulator against that commit, since they
depend on those flags still working there.
