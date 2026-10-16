# Pin checklist (next build)

*Product lead, 11:28 AM PT Oct 16. Run top to bottom the minute the last blocker merges. The pin is a master merge commit, never a PR head.*

## 1. Blockers (all merged on master)
- [ ] #366 AI-1 Home lines (Builder B): Design clip pass + QA confirm.
- [x] The stuck-listening fix (Builder B): #446, 0eca9bbe.
- [x] #422 secret-word wall + $50 cap (5af8f2c2, Catalog v9).
- [ ] MU2 (Core): money, body and health phrases never reach Claude, incl. CA6 answerQuery allow-list and CA7 screens before the offline inbox add. (decisions.md 11:35 AM PT; QA A1, Research MW1)
- [ ] A2 (Core): the inbox retry goes through the router walls, inside MU2 or a tiny PR beside it.

## 2. Riders (in only if merged before the last blocker)
- [ ] Paste/link SecretWords wall (Core).
- [ ] One-time mark-private pass for pre-#422 notes (Core, Research 139).
- [ ] Siri Add a Task secret-word wall, I3 (Core, QA).
- [ ] P1 UNDO revives a hidden workout, T1 zone-less times as UTC (Core, QA); P2 stale session after UNDO (Builder B).
- Never in this pin: #403 eyes, #407 tessEyes (v10). They merge right after the pin is named.

## 3. Name the SHA
- [ ] Fetch master; the pin = master HEAD after the last blocker (or rider) merged. Record the full SHA.
- [ ] `git log --oneline <installed 7b321d2>..<pin>` lists what he gets; confirm #380, #381, #377 + #391 (T1-T4 trip: 0bff60b and 70112f9 must be ancestors; Research 141 says the trip is a go on master, so this pin must be on his phone by Oct 25), #397, #399, #402, #422 and the blockers are all in.
- [ ] Catalog version at the pin is v9; nothing at v10.
- [ ] CI green on the pin commit.

## 4. Tell everyone (one message each, through the coordinator)
- [ ] Builder A: run the gate on the pin (`../research/next-build-script.md`, M0 to M4): upgrade over the v5 backup copy, 366 v5 rows byte-identical, timed v5 restore against the +0.7 s before number (slow = gate failure), an older build opening the v9 store. Then record Design 66's 3-minute Porcelain walk.
- [ ] QA: read the gate run. Design: pass the 66 walk.
- [ ] Coordinator: merge #403 and #407 (re-check heads), Builder B's post-#366 batch goes out.

## 5. Write it down
- [ ] decisions.md: "Pin named" entry with the SHA and what it carries.
- [ ] board.md install line; review-session.md "Next build" section for the pin (Home lines, glass tabs, live workout, Kitchen week, soul router, private notes, money wall if in), with install-day Step 0 (SAVE A COPY in Review > Backups).
- [ ] Mirror to master in a small docs PR.

## 6. Install
- [ ] Only after gate PASS + QA + Design 66 pass, and only on his own "install it" in the iOS build thread.
