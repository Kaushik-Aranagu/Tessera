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

## 6. Install
- [ ] **Standing approval removes asking him, not the gates. Only the named pin SHA installs: never master, never any other commit.** Install under his standing approval (12:36 PM PT Oct 16, Builder A's thread): Builder A installs whenever the phone is reachable over Wi-Fi, with no ask. Every safety step stays: Product names the SHA, the v9 gate, QA and the Design 66 walk pass, Step 0 SAVE A COPY runs, the install goes in place over Wi-Fi, the app is never deleted, and he gets one line after.

## 7. Rollback (decisions 12:16 PM PT Oct 16)

Before the pin is on his phone, the rollback is 444e72b (v5). Once the pin is installed, the rollback is 7b321d2. It is the only older build tested on the v9 store (gate V4). 444e72b is not used after the pin, because a v5 build on a v9 store was never tested.
