# QA (Repo maintainer)

*No simulator or Swift toolchain in this thread, so QA here is code review on master, not running the app.*

**Now:** GO for install at b19fb4a (superset of d0154a9; review-183.md, U1 should-fix). Not in install: #179 PASS, #184 PASS with R1-R3 should-fix, #187 PASS (04:00 day), #190 PASS (U1 closed), #191 PASS, #193 Themes PASS, #199 closes T2 T3 T5 (T1 closed by Design; review-199.md), #195+#197 PASS, land clean (R4 closed in #219; review-195-197.md), #201 PASS (Tuesday isRest change justified, R5 closed; review-201.md), #203 Themes 2a PASS (review-203.md); #205 set guard PASS on fixtures, Q1 trailing period + Q2 comma still reach the task rule (should-fix, review-205.md); #207 GO on W1, W2-W5 closed, new W6 low + W7 should-fix (exercise page pushed in the workout latches night; review-207.md); #210 PASS, Q1-Q6 closed, no S701-S706 regression, H625 stays reps; lows Q7 ("bench 80 for 8, 81") + Q8 (2x10/5x5 on light kit; review-210.md); #211 backups by 4 AM day PASS, T1-T12 trace (lows B8 forget keeps failure, B10 forward clock; B9 phone check: deleted folder may resolve to Recently Deleted; review-211.md); #215 Themes 2b PASS, W6+W7 closed (W7 traced: nothing in the cover writes systemIsDark; one phone smoke step), LA palettes match; lows W8 W9 (review-215.md); #218 Claude key store PASS, key reaches no log/op/backup/export; K11 should-fix before T3/T4: cap not a hard stop under concurrent calls (reserve then settle); lows K12 K13 (review-218.md); #219 day boundary PASS, R4 closed, D7 test gap (double-session day, add Core row), D8 ring moved to the later day (Design FYI; review-219.md). Install needs scripts/test.sh "All green" + one TesseraUITests run + phone smoke. Next: docs PR indexing reviews 124-219.

**Next:**
1. Keep the docs index at `docs/README.md` current.
2. Review the remaining older merges: Tess engine and App Intents, processes and What's running, HealthKit.

**Done:** #46 to #58 reviewed (#64), grammar traced (#67), hotfix #70 checked and #40 to #45 reviewed (#77), the gym, kitchen and regression checks written for the Mac leads (#63), and the data-safety review (D1–D4, merged as #79).

**Later:**
- Performance budget checks (launch time, dial at 120 fps). These need a Mac lead to run them.
