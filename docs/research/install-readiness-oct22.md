# Oct 22 install readiness (board item 103)

*Research, draft for Product. Date 2026-10-16 (UTC); first checked at 8:55 PM PT on Thu 15 Oct against
`92078ee` (#252, 8:52 PM PT), updated for item 110 against `origin/master` at `5e91c56` (#263, 9:06 PM PT). All
times Pacific (PDT). Static read only: no Swift toolchain, no simulator run, no install made. Sources:
`git log --first-parent b19fb4a..5e91c56`, GitHub open PRs, QA reviews in `docs/qa/` on master and
`../qa/review-*.md`, `debug-paths.md` (After #244), `install-day-script.md`, `resign-day.md`, `oct-22-list.md`,
`fixtures/grammar-regression.md` (on master, #260), `../ops/board/ios-a.md` and `../ops/board/qa.md`. Product's
call on the targets: 9:06 PM PT Oct 15.*

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

| #254 | e7a5be4 | Set guard: RPE and kind still ask (Q9), no yes/no asks (Q10), "by" reads as ×, D1 and D2 for the dated ask (8 Core files) | PASS, lows P1 and P2 (`docs/qa/review-254.md`) |
| #258 | 67442a1 | Settings object, catalog v4: look, misses to Claude, backup folder, rest weekday (6 Core files, no app reader yet) | PASS, two lows (`../qa/review-258.md`; docs PR #265 still open) |

Note: #251 merged at 8:52 PM PT; QA passed it (`docs/qa/review-251.md`, now on master via #257). LOG makes one op,
so UNDO takes back the set and any workout it made; a day name always means a past day (or today), never a future
one. Its lows D1 and D2 are closed by #254.

**Since 92078ee** (to `5e91c56`, 9:06 PM PT): 10 merges, 2 of them app code (#254 at 9:00 PM PT, #258 at
9:05 PM PT, both Core only; no file in `App/`, `Features/`, `DesignSystem/`, `Shared/`, `Widgets/` or the app test
targets changed). The other 8 are docs (#253, #255, #256, #257, #259, #260, #261, #263).

**Open app PRs at 9:10 PM PT** (not merged, not in any candidate yet): #266 "One base across the app: the workout
stands on Home's ground in every look" (Builder A), #264 "A calmer capture; the set-count ask answers on a tap"
(Builder B), #262 "Spoken numbers to digits; 'a hundred, five' is never groceries" (Core). Neither the launch-flags
PR nor the set-loss PR is open yet.

## 2. Open fixes, not merged

None of the items below has an open PR at 9:10 PM PT, so each is unbuilt. Checked in code at 5e91c56.

| # | Fix | Must / should | Owner | Still open in code at 5e91c56 |
|---|---|---|---|---|
| 1 | **Launch-flags PR** (`debug-paths.md`, After #244): (a) `XCTSkip` on a device in TesseraUITests; (b) one simulator-only `LaunchFlags` helper for `-queueScript`, `-tessScript`, `-demoTime`, `-demoReview`, `-demoKitchen`, `-demoNotes`, `-theme`, `-backupFailure`; (c) `resetUserData()` refusing a store with real ops | **Must**, before any install (`ios-a.md` Now; QA G1 in `review-244.md`) | Builder A | Yes. No `XCTSkip` in TesseraUITests, no helper in the app, `resetUserData` unguarded (`ObjectStore+Lifecycle.swift`). `-queueScript` and `-demoReview` still edit his real tasks on a device Debug build |
| 2 | R3: "Reinstalled?" line keys on `.user` ops in the last 50, so it can show on his own phone after Tess-logged workouts | Should | Builder B | Yes (`BackupView.swift:69`) |
| 3 | **Set-loss PR**: the ten wrong-write rows A171, A183, A184, A162, A163, A167, A059, A181, A182, K885 (`fixtures/grammar-regression.md`; for example "bench 80x8 dentist fri" in a workout, "buy milk and bench 80x8", "bench 80x8 at 7") | Should; Product's fallback target once Research's rerun (item 108) and QA pass it | Core | Yes, all ten fail on master per #260's rerun |
| 4 | G2: any non-SQLite error at launch counts as damage and moves the store aside | Note, worth closing (`review-244.md`) | Core | Yes (`TesseraSchema.swift:76-77`) |
| 5 | P1: a dated lift joins the day's last workout even when an earlier one holds that exercise | Low (`review-254.md`) | Core | Yes |
| 6 | P2: a dated set joining an existing workout is stamped noon, which can sit before that workout's start | Low (`review-254.md`) | Core | Yes |
| 7 | `restWeekday` not range-checked (0 or 8 would crash the first reader); a soft-deleted settings object silently stops saving | Lows (`review-258.md`) | Core | Yes; nothing in the app reads settings yet |

Closed since the first draft: Q9, Q10 (`review-248.md`), D1 and D2 (`review-251.md`), all by #254 (`review-254.md`).

Lows still open, not blocking: B8/L4 (`BackupKeeper.forget()` keeps a folder failure), L5 (key-missing line after his
own REMOVE), W11 (`adoptRestored` has no caller), D7 (no Core test for a double-session day), G1 in `review-231.md`
(grey glass on the pure-black workout, Design's call). M1 in `review-234.md` is answered: Product kept "misses go
to Claude: yes" at 8:28 PM PT, and #258 stores it with that default.

## 3. Recommended install target

Product's call (9:06 PM PT Oct 15) sets the order below. Every candidate also needs `scripts/test.sh` to end
"All green" on that exact commit.

1. **Primary: the launch-flags PR's merge commit**, once QA passes it. Product names the hash when it lands.
2. **Fallback: the merge of Core's set-loss PR** (the ten rows in section 2, row 3), once Research's rerun (item
   108) and QA pass it.
3. **If neither is ready by Wed 21 Oct, 6:00 PM PT: the newest QA-passed master commit that includes #254**
   (`e7a5be4` or later). Today that is `5e91c56`: both app PRs since 92078ee (#254, #258) have a QA PASS.

**Always, whichever commit is installed:** the scheme's Run arguments are empty (check Edit Scheme > Run >
Arguments before Cmd-R), no TesseraUITests run with his phone as the destination, `resign-day.md`'s safe order is
followed, and the app is never deleted. Rollback note from `resign-day.md`: after a v3 build runs, b19fb4a still
opens the database, but must not be used to restore a v3 backup. A rollback from a #258 build (catalog v4) to an
older one was not checked here.

### The candidates

| Candidate | Launch-flag guards | #251 dated ask | #254 (Q9, Q10, typed "by", D1, D2) | Set-loss fixes (10 rows) | Settings v4 (#258) | Known gaps |
|---|---|---|---|---|---|---|
| Launch-flags merge (primary) | Yes | Yes, if based on master after 247150e | Yes, if based on master after e7a5be4 | Only if the set-loss PR merged first | Yes, if based after 67442a1 | Not built or reviewed yet. Set-loss rows stay open unless merged first. R3, G2, P1, P2, #258 lows |
| Set-loss merge (fallback) | Only if the launch-flags PR merged first | Yes | Yes | Yes | Yes | Not built; needs item 108's rerun and QA. Without the launch-flags PR, seven flags still write on his phone and UI tests can drive it, so the "always" conditions carry the safety |
| Newest QA-passed master with #254 (now `5e91c56`) | No | Yes | Yes | No: the ten rows still write wrong or lose sets | Yes | Flags as above. Ten wrong-write rows. R3, G2, P1, P2, #258 lows |
| `92078ee` (reference only) | No | Yes, with lows D1 and D2 | No: Q9 and Q10 open | No | No | Everything above, plus Q9 ("2x10 @8" logs 2 kg) and Q10 (yes/no asks with no answer) |

Open PRs #266 (workout on Home's base), #264 (calm capture, the set-count ask answers on a tap) and #262 (spoken
numbers, which touches K885) are in a candidate only if they merge before it is cut; each would need its own QA
PASS first.

The items in section 2, rows 2 and 4 to 7, do not block the install.

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

### Steps that differ by candidate

`install-day-script.md` as it stands matches `92078ee`. Differences on the other candidates (static read; #254's
lines checked at `e7a5be4` and `5e91c56`):

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
