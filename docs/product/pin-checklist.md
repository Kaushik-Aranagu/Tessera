# Pin checklist (next build)

*Product lead, 11:28 AM PT Oct 16. Run top to bottom the minute the last blocker merges. The pin is a master merge commit, never a PR head.*

## 1. Blockers (all merged on master)
- [x] #366 AI-1 Home lines (Builder B): merged 60470780 at 12:47 PM PT, QA and Design PASS at d2bbc44.
  - Day label fix done: #366 frozen at d2bbc44 with the 4 am day-label fix and tests (138 green). The set-1 stale line is cut from the clip. Waiting on QA's diff review and Design's clip re-pass (12:40 PM PT).
- [x] The stuck-listening fix (Builder B): #446, 0eca9bbe.
- [x] #422 secret-word wall + $50 cap (5af8f2c2, Catalog v9).
- [x] MU2 (Core, #451 merged bf2a4bb5): money, body and health phrases never reach Claude, incl. CA6 answerQuery allow-list and CA7 screens before the offline inbox add. (decisions.md 11:35 AM PT; QA A1, Research MW1)
- [x] A2 (Core, in #451, merged bf2a4bb5): the inbox retry goes through the router walls, inside MU2 or a tiny PR beside it, with a test that the inbox refuses a queued secret word and a queued money phrase (master has no readWaiting caller, so the gate's I2 alone would pass trivially).

## 2. Riders (in only if merged before the last blocker)
- [x] B1 (#471, 68c9a19f) (QA backups, 12:12 PM PT): Notes refuses a key-shaped note (Core 0e). First rider.
- [x] B5/B6 (#475, merged 76be1c07 12:36 PM PT; QA backups, 12:12 PM PT): the v9 build refuses a newer-catalog store or backup (Core 0e). Second rider; if it misses, #407 waits for a build that has it.
- [x] (#498, a36b161b) M1 (QA review-475; not a blocker. The fix is one line: skip runDaily when lastOpenOutcome == .inMemoryFallback, TesseraApp.swift:83, 12:29 PM PT; Core rider 2b): BackupKeeper.runDaily never runs in the in-memory fallback, so a v10 → pin rollback can't roll his 7 good copies away with empty-store backups. Goes with B5/B6. If it misses the pin, #407 waits.
- [ ] ", best" not ", PR" in DayStory.swift:225 (Core 0w, Research week story, 1:00 PM PT). Rider if it lands before M1.
- [ ] P14 (Research privacy trace, 12:26 PM PT): Siri's Add a Task routes like the Ask bar. Body facts, and past-tense money with an amount, become a private note ("Private note, kept.", no echo). "pay rent 2100 friday" stays a task (decisions 12:11). Core 0j/0l or a tiny PR. Third rider, after B5/B6.
- [x] Paste/link SecretWords wall (Core, #454, 234080a3).
- [ ] One-time mark-private pass for pre-#422 notes (Core, Research 139).
- [x] Siri Add a Task secret-word wall, I3 (Core, QA; #457, cf50bb0a).
- [x] (on master per the docs worker, 12:49 PM PT; #471) Grammar recount fixes: "pay rent fri" makes a task again (regression on his phone), pins/combination on Groceries, pull-ups alias (Core, Research).
- [x] (on master per the docs worker, 12:49 PM PT; #471) MU2 follow-up: health facts with no number and "paid N for M" stay on the phone (QA L1, L3 on #451).
- [~] (#494 QA PASS c0b8dcb, Design pass running) P1 UNDO revives a hidden workout, T1 zone-less times as UTC (Core, QA); P2 stale session after UNDO (Builder B).
- Never in this pin: #403 eyes, #407 tessEyes (v10). They merge right after the pin is named.

## 3. Name the SHA
**PIN: a36b161b7294596848a319c0cc0fc50a3b25f2ee** (named 1:08 PM PT Oct 16; master after #498 M1). Catalog v9; trip commits and 7b321d2 are ancestors; no #403/#407. Riders not in: P14, ", best", pre-#422 note pass.
- [x] Name the pin once M1 merges, if that's today. If M1 doesn't land today, name master as it stands and hold #407 until a build with M1 is on his phone (12:51 PM PT). Core 0k, the rename key guard, is after the pin, not a rider. Fetch master; the pin = master HEAD after the last blocker (or rider) merged. Record the full SHA.
- [ ] `git log --oneline <installed 7b321d2>..<pin>` lists what he gets; confirm #380, #381, #377 + #391 (T1-T4 trip: 0bff60b and 70112f9 must be ancestors; Research 141 says the trip is a go on master, so this pin must be on his phone by Oct 25), #397, #399, #402, #422 and the blockers are all in.
- [x] Catalog version at the pin is v9; nothing at v10.
- [x] `git log 7b321d2..<pin> --merges` shows no #403 or #407 merge (the v9 check alone can't catch #403).
- [ ] `scripts/test.sh` on the pin ends "All green" (there's no CI).

## 4. Tell everyone (one message each, through the coordinator)
- Link his page `docs/research/new-on-your-phone-v9.md` (8 lines) in the one line after install. Research drops whatever didn't make the pin once the SHA is named.
- Script: `../research/next-build-script-v9.md` (Research 44 steps, run in order). Gate numbers (12:02 PM PT Oct 16): the v5 copy has 366 rows (the 8:56 AM gate read); any other count stops the gate until Builder A explains it. The timed v5 restore fails above 3.23 s (the 2.23 s before-restore time + 1 s).
- [ ] Builder A: run the v9 gate on the pin (`../research/next-build-script-v9.md`, V1 to V6): upgrade over the v5 backup copy, 366 v5 rows byte-identical, the timed v5 restore fails above 3.23 s, 7b321d2 opens the v9 store. Then record Design's 9-beat walk in one 3-minute Porcelain take on the pin (`docs/design/next-build-walk.md`, on master via #493; -demoTime 18:10 -resetDemo -theme porcelain) into docs/recordings/next-build-walk-v9.mp4. A beat passes when it matches its sheet. Known board rows never fail it.
- [ ] QA: read the gate run. Design: pass the 66 walk.
- [ ] Coordinator: merge #403 and #407 (re-check heads), Builder B's post-#366 batch goes out.

## 5. Write it down
- [x] decisions.md: "Pin named" entry (1:08 PM PT) with the SHA and what it carries.
- [ ] board.md install line; review-session.md "Next build" section for the pin (Home lines, glass tabs, live workout, Kitchen week, soul router, private notes, money wall if in), with install-day Step 0 (SAVE A COPY in Review > Backups).
- [ ] Mirror to master in a small docs PR.

## Next build first (decisions 1:15 PM PT)
- N13 private note rows (Builder B 0p), N15 pre-#422 pass (Core 0aa), P14 (with HW13 "Body weight logged."), ", best", HW19 sick words in PrivateFacts, HW9/P16 Face ID on Siri writes (Core 0ac). PN-MENTION: an "@Private note" mention can't open a private note's body (Core 0ad resolve skips private, Builder B 0r ObjectPage; QA review-508). #508 (private-note rows, N13) merged.

## 6. Install

**Gate result on a36b161 (Builder A, 1:45 PM PT Oct 16):** V0-V4 PASS. On V2, 365 of 366 rows are byte-identical; the one difference is tidyProcesses pausing a 5-hour-old running demo process at launch, which is expected and not a migration change. V5's UI step was NOT run, because Builder A's safety check blocks typing even made-up secret phrases, and we don't work around it. The coordinator's call: V5 is covered by the pin's tests (SecretWordsTests:70-91, TessTests, PrivacyFollowupTests), so it does not block the install. Walk beats 7 and 8 are skipped and marked for the same reason. Kaushik gets an optional hand check after the install. Future gates: V5 and walk beats 7-8 (the wifi half) become Research's `fixtures/walls-ui-phrases.json` + `walls-ui-test-spec.md` (WallsUITests, WallsSiriTests). His optional check after install: in Notes, type "wifi password is tacocat4417" and see Private note. Originally: V5 runs as a SimulatorOnly UI test that reads its phrases from a fixture file, so no session types a secret-shaped phrase (Research AU, Builder B owns the test).

- [ ] **Standing approval removes asking him, not the gates. Only the named pin SHA installs: never master, never any other commit.** Install under his standing approval (12:36 PM PT Oct 16, Builder A's thread): Builder A installs whenever the phone is reachable over Wi-Fi, with no ask. Every safety step stays: Product names the SHA, the v9 gate, QA and the Design 66 walk pass, Step 0 SAVE A COPY runs, the install goes in place over Wi-Fi, the app is never deleted, and he gets one line after.
- [ ] **Step 0 copy name and place (decisions 1:41 PM PT Oct 16, Research AN):** save the Step 0 copy OUTSIDE the Backups folder, for example in Files > On My iPhone > Tessera Step 0, and rename it "Before a36b161" (for later installs, "Before <SHA>"). A copy left in Backups with the suggested "Tessera-<day>.tessera" name (BackupKeeper.swift:170) can be replaced or pruned by the new build. Check the copy is there BEFORE installing.

**Next pins (decisions 1:43 PM PT Oct 16):** the next pin is a v9 rider build (PN-MENTION, N15, P14, HW sick words with CR1, UNDO slot, 0ae trip bands, Step 0 name), with no catalog change, so a36b161 and it read each other's store. Catalog v10 (#407 and the eyes setting) ships after that, alone, as its own pin, under the after-v10 rules in §7. The riders pin is named at the Thu Oct 22 9:30 AM branch call with whatever has merged and passed QA, and it waits for no single rider (decisions 1:51). **Signing deadline (Builder A, 2:11 PM PT Oct 16):** a36b161's profile expires Thu Oct 22 at 7:53 PM PT (HealthKit is entitled on the free team). The riders build has to pass the gate and be installed before then. If it isn't installed by 4:00 PM PT Thu, Builder A re-signs a36b161 with a fresh profile and installs that instead (decisions 2:13), and the riders build goes on afterwards. Gate: research/next-build-v9r.md; his page: research/new-on-your-phone-v9r.md. Once it's named, swap a36b161 for the riders SHA in the after-v10 rule below.

## 7. Rollback (decisions 12:16 PM PT Oct 16)

Before the pin is on his phone, the rollback is 444e72b (v5). Once the pin (a36b161) is installed, there is NO older-build rollback (decisions 1:50 PM PT Oct 16, superseding 12:16). 7b321d2 opens the v9 store (gate V4), but it predates #422, ignores isPrivate and would show private notes' text, so it is never installed again. The way back is rolling forward with a fix, or restoring the Step 0 copy ("Before a36b161") on a36b161 itself. 444e72b is not used after the pin, because a v5 build on a v9 store was never tested.

**After v10 (decisions 1:27 PM PT Oct 16):** once the v10 build is installed, the rollback is a36b161, and only if a36b161 was on his phone first. It refuses the v10 store and runs in memory with the launch note (U3), so it does not show his data. Getting his data back means rolling forward or restoring the Step 0 copy. Restoring Step 0 on a36b161 first keeps the v10 store as a Before-restore copy (up to 3 kept), so a later v10 can restore it; only work done during an in-memory rollback is lost (Research v10-rollback-drill.md R5). 7b321d2 also predates #422 and would show private notes in plain text. U1-U4 run on the named v10 SHA, never on core/tess-eyes (based on 5af8f2c, without #475 or M1); the drill adds five real actions so the M1 check means something. 7b321d2 has no newer-store check and would write to the v10 store, so 7b321d2 and 444e72b are never installed after v10. Step 0 SAVE A COPY runs on a36b161 before the v10 install. The next-build gate is `research/next-build-v10.md`: V0 becomes catalog 10 plus #403 and #407 merged, upgrade rows start from the a36b161 v9 store, V4 is retired, M1 and P14 become hard rows, and the new rows are U1-U4, E1-E4, DB1, NP1-2, HP1-3 and UW1.
