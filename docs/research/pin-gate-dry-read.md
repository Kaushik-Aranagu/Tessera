# Pin gate dry read: the v9 script and the checklist against master

For: Product, Builder A, QA. Owner: Research lab. Fri Oct 16, 2026 (Pacific), read at `origin/master` 70f37da. Nothing
built, run or installed. Read together: `next-build-script-v9.md` (script), `../product/pin-checklist.md` (checklist),
`pin-week-one.md`, `oct-22-list.md`, `resign-day.md`, `new-on-your-phone-v9.md`, `docs/qa/`, the boards. Facts held: phone
on 7b321d2 (Oct 16, 9:57 am PT); rollback 444e72b before the pin, 7b321d2 after; Catalog v9; #407 (v10) and #403 out;
signing lapses about Fri Oct 23, 9:57 am PT. Master: Catalog v9 (`SystemCatalog.swift:350`), nothing at v10; #366, #403,
#407, P14 and M1 not merged; #446, #451, #454, #457, #471, #475 merged. Count: 34 rows, 11 ok, 13 stale, 8 missing, 2 conflict.

| id | doc:line | Says | Master shows | State | Fix (one line) | Owner |
|---|---|---|---|---|---|---|
| G1 | script:3-15 | Read at 7334c8b; MU2, A2 "no PR yet"; paste wall "no PR yet" | #451 bf2a4bb (MU2 + A2), #454 234080a merged; #366 still open | stale | Refresh the table to 70f37da | Research |
| G2 | script:25; oct-22-list:30,67; pin-week-one:18 | Receipts and key in "Settings > Claude" | `ClaudeSection()` sits on Review (`ReviewView.swift:224`, "until Settings exists"); no Settings screen | stale | Say "Review, under Claude" | Research |
| G3 | script:110 | R2 "Settings, the Rest day row" | No Settings screen; rest-day reader not merged | stale | Skip stays; reword to where the row lands | Research |
| G4 | script:34; checklist:33 | V2 stops on any count but 366 v5 rows | Same number in decisions 10:18 am PT and pin-week-one | ok | None | Builder A |
| G5 | checklist:34; qa.md:15 | Builder A runs `next-build-script.md` M0 to M4, restore "against the +0.7 s before number" | checklist:33, script:35, pin-week-one:49, oct-22-list:23 all say v9 script, fail above 3.23 s | conflict | Point both lines at `next-build-script-v9.md` V1-V6, 3.23 s | Product |
| G6 | script:38 | V6: newer backup onto older build stays forbidden, untested | #475 refuses it: "That copy is from a newer Tessera. Update first." (`BackupView.swift:257`) | missing | Add a Sim row: a #407-head (v10) copy restored into the pin is refused with that line | Research |
| G7 | script:56-58 | W7-W9 expect "Kept, on this phone only." (proposed) | Body facts go `parseBodyFact` to a private note, "Private note, kept." (`TessGrammar.swift:153`, `TessCaptureEngine.swift:300`); the proposed line is the memory refusal (`TessMemory.swift:264`) | stale | Expect "Private note, kept." | Research |
| G8 | script:119 | P1 expects "I left out 1 line that looked private." | No such string; #454 marks the line "ignored" and never saves it (`PasteRecipe.swift:205`, `:421`; clip 50) | stale | Expect the wifi line marked ignored, no tacocat saved | Research |
| G9 | script:50,59,69,72,78 | "Didn't catch that.", "I don't keep sums of money.", "No connection. Saved it for Claude.", "Private note, kept.", "Mic is off for Tessera." | All present (`ClaudeTessModel.swift:116,204`, `TessGrammar.swift:148`, `SpeechListener.swift:24`) | ok | None | Research |
| G10 | script:42,69,99 | `-fakeClaudeKey`, `-demoTime`, `SIMCTL_CHILD_TZ` on the Simulator | Every flag reads through `LaunchFlags`, simulator-only (`LaunchFlags.swift:8-14`, `AppClock.swift:21`) | ok | None | Builder A |
| G11 | script:71; checklist:11 | I3: no retry caller, add a test-only check | `readWaiting` has no caller outside `TessInbox.swift:58`; #451 refuses at add | ok | None | Builder A |
| G12 | script (none) | No row for the notes key refusal (B1) | #471 merged 68c9a19: a key-shaped note is refused | missing | Add a Notes row with a made-up `<key-shaped placeholder>` from Builder A's fixture, never typed from memory | Research |
| G13 | script (none) | No row for Siri Add a Task (#457, QA I3) | Merged cf50bb0: key refused, secret with value becomes a private note (`Intents.swift:134-142`) | missing | Add a Shortcuts row: "door code 4417" gives "Private note, kept." | Research |
| G14 | script (none); checklist:16-17 | M1 and P14 are riders | Neither on master: Siri checks key and secret words only; `runDaily` runs on background with no fallback check (`TesseraApp.swift:83`) | missing | Add skip-if-not-in rows for both | Research |
| G15 | checklist:5-7 | "Blockers (all merged)"; #366 day label at `HomeLineHero.swift:101` before merge | File not on master; #366 head d2bbc44 (ios/home-lines) has the 4 am `DayLabel`; QA's last pass is 46dfd4d, before it | **resolved 12:47 pm PT**: #366 merged as 6047078 with the day-label fix (`HomeLineHero.swift:102` uses `TesseraDay` on master) | Note "pushed at d2bbc44, QA re-check and Design clip due on that head" | Product |
| G16 | checklist:14 | B1 unticked | #471 merged; Core 0k follow-ups (RenameObject key guard, `TrainingActions.swift:487`) not merged | stale | Tick B1; list 0k as its own line, in or out | Product |
| G17 | checklist:18,20,22 | Paste wall, Siri I3, MU2 follow-up unticked | #454, #457, #471 merged | stale | Tick all three with SHAs | Product |
| G18 | checklist:21 | Grammar recount open | #471 "a bare verb is a task again"; pull-ups known (`TessGrammar+Lift.swift:27`); Groceries pins not checked | stale | Tick what #471 closed; Core confirms the rest | Product |
| G19 | checklist:17 | P14: "pay rent 2100 friday" stays a task | Not on master | ok | Open rider as written | Product |
| G20 | checklist:24 | #403 and #407 never in this pin | Neither merged; §3 checks Catalog v9 (catches #407) but nothing catches #403 (no catalog change) | missing | Add to §3: `git log 7b321d2..<pin>` lists no #403 or #407 merge | Product |
| G21 | checklist:36 | Coordinator merges #403 and #407 in §4 | Pin is a SHA, so safe only if named first | ok | Keep after "Pin named" is logged | Product |
| G22 | checklist:30 | "CI green on the pin commit" | No CI (CLAUDE.md); `scripts/test.sh` must end "All green" | stale | Builder A runs `scripts/test.sh` at the pin | Builder A |
| G23 | checklist:34-35; oct-22-list:24 | Design 66's 3-minute Porcelain walk | No spec on master (design.md:6, ios-a.md:9 name it only) | missing | Design writes the walk's beats before the gate | Product |
| G24 | checklist:16 | Cites "QA review-475"; #471 PASS | No `docs/qa/review-471.md` or `review-475.md` on master | missing | QA's next docs PR lands them | Product |
| G25 | checklist:48; pin-week-one:71; oct-22-list:42; script:36 | After the pin roll back to 7b321d2 (V4 tests it) | Consistent | ok | None | Research |
| G26 | oct-22-list:16 | "Rollback build is 444e72b (v5)" under rules that hold either way | Holds only before the pin (checklist §7) | conflict | "444e72b before the pin, 7b321d2 after" | Research |
| G27 | resign-day:72-78 | Rollback to b19fb4a or d0154a9; read at c5d7193 | Superseded by checklist §7 | stale | Point the section at checklist §7 | Research |
| G28 | oct-22-list:11-13 | At 234080a riders merged: #454, #457 | #471 and #475 merged since | stale | Add them | Research |
| G29 | pin-week-one:23-24 | Money-verb rows only if Core's fix is in | #471 merged, so any pin carries it | stale | Drop the "only if" | Research |
| G30 | new-on-your-phone-v9.md | Phone notes for the pin | Not on master; only on claude/project-thread-uf4bjb (6f57c2b). Content matches: "Review, under Claude", "Update first", rollback 7b321d2, #366 and P14 marked "if it lands" | missing | Merge it before §5's review-session entry | Research |
| G31 | script:27; checklist:29 | Catalog v9, nothing at v10 | `version: 9`; no v10 | ok | None | Builder A |
| G32 | script:95; checklist:28 | 0bff60b, 70112f9 ancestors; #380 #381 #377 #391 #397 #399 #402 #422 in | All ancestors of master; 7b321d2, 444e72b, ff548605 too | ok | None | Builder A |
| G33 | oct-22-list:9; resign-day:70 | Lapse about Fri Oct 23, 9:57 am PT; next reminder Wed Oct 28 | Matches the 7b321d2 install | ok | None | Research |
| G34 | script:20-25; oct-22-list:26-30; checklist:44 | Step 0 SAVE A COPY on the phone first, install on his word, never delete | Same order in all three | ok | None | Builder A |

## Fixed by Research, 12:55 pm PT (at master 01b30a2, working tree only, not committed)
- **G1:** script header and dependency table refreshed to 01b30a2 (#451, #454, #457, #471, #475, #366 merged; M1, P14 not).
- **G2:** "Settings > Claude" is now "Review, under Claude" in the script (S1), `oct-22-list.md` (Step 0, check 5) and
  `pin-week-one.md` (month total). Backups were already "Review > Backups".
- **G3:** script R2 points at wherever the rest-day reader's PR puts the row; master has no Settings screen.
- **G6:** script rows B5 and B6 (Simulator, #407-head v10 store and copy), expecting master's launch note and "That copy
  is from a newer Tessera. Update first." (`BackupView.swift:257`). V6 now points at B6.
- **G7:** W7 to W9 expect "Private note, kept." (`TessCaptureEngine.swift:300`); the wall intro no longer says "proposed".
- **G8:** P1 expects the wifi line shown pale and marked "ignored" before saving, no Tess line, and no tacocat in the
  saved text (`PasteRecipe.swift:421`, `Recipes.swift:174`, recording 50).
- **G12:** script row B1: paste a key-shaped test string from the test kit (never his real key) into Notes; nothing saved,
  "That looks like a Claude key. It goes in Review, under Claude." (`ClaudeKeyGuard.swift:6`).
- **G13:** script rows SI1 (`door code 4417` through Add a Task gives "Private note, kept.") and SI2 (Simulator key refusal).
- **G14:** skip-if-not-in rows P14 (`took advil 400mg` kept as a private note, not read back; `pay rent 2100 friday`
  stays a task) and M1 (no backup copy from the in-memory fallback after B5).
- **G20 (script side):** V0, before the install: `git log --oneline 7b321d2..<pin SHA>` has no #403 or #407 merge and
  `SystemCatalog` is version 9. Checklist §3 still needs Product's line.
- **G15:** resolved (above). `oct-22-list.md` and `pin-week-one.md` no longer say #366 is open.
- **G26:** `oct-22-list.md`: rollback is 444e72b before the pin, 7b321d2 after it.
- **G27:** `resign-day.md` rollback section: b19fb4a and d0154a9 gone; current rule (444e72b before, 7b321d2 after,
  re-sign builds the exact installed SHA).
- **G28:** `oct-22-list.md` riders now list #471 and #475.
- **G29:** `pin-week-one.md` drops the "only if Core's fix is in" (#471 is on master).
- **G30:** resolved without an edit: `new-on-your-phone-v9.md` reached master in #485 (6f57c2b is an ancestor of 01b30a2).

## Blocking before the pin is named
1. ~~#366 merges at d2bbc44 or later with the 4 am day label (G15).~~ Merged 6047078, 12:47 pm PT.
2. Checklist §4 sends Builder A to the old M0-M4 script and the +0.7 s number; fix to V1-V6 and 3.23 s (G5).
3. §3 gains a check that no #403 or #407 merge is in `7b321d2..<pin>` (G20); "CI green" becomes `scripts/test.sh` (G22).
4. Script expectations that would fail a good build: W7-W9 (G7), P1 (G8), "Settings > Claude" (G2).
5. Design 66's walk has written beats, or QA can't read it as a pass (G23).

## Questions for Product
1. Name the pin on #366's merge, or hold for P14 and M1? If M1 misses, #407 waits (checklist:16).
2. Core 0k (key guard on rename and title edit): rider, or after the pin?
3. Add script rows for B1, #457 and the B5/B6 refusal (G6, G12, G13)? Research can draft them today.
4. CLAUDE.md still says `-demoTime` is DEBUG; master makes every flag simulator-only. Update it?
