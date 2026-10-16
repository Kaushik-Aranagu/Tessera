# Pin week one: three evening check-ins after the Catalog v9 pin

For: the coordinator, Core, Builder A, Builder B, QA. Owner: Research lab. Oct 16, 2026 (Pacific), read at master
e10b698. Day 1 = the day of the install (not fixed yet). Builds on `next-build-script-v9.md`, `review-refresh-3.md`,
`oct-22-list.md`, `pin-checklist.md`, `decisions.md`. Nothing run. Every value is made up.

**Quiet rule.** He already gets a 10-question morning message (`oct-22-list.md`). Each evening he gets exactly one
question, one word, sent 8 pm PT (5 pm PT while in New York, 8 pm there). Everything else is read without him. Never
ask about the Claude key beyond yes/no presence; never ask him to type, show or paste it.

## Where each thing is read (master)
- **Daily copy:** `Tessera-YYYY-MM-DD.tessera` in Documents/Backups and his picked folder, written on the first
  background after 4 am, replaced through the night until 4 am, 7 kept (`TesseraBackup.writeRolling`,
  `BackupKeeper.runDaily`). Copy the newest to `~/tessera-checkin`, run P0 as in `week-two-monday.md`: `inspect`
  passes (`backupInfo` present, `PRAGMA quick_check` = ok, schema no newer than the pin). A failed copy shows a quiet
  note on Review > Backups.
- **Claude receipts:** the usage ledger rides in the copy. Each call is time, use ("A capture", "A question", "Plan
  my day", "A paste", "Key check"), model and cost; no phrase text. Month total against $50 is Settings > Claude
  ("This month $... of $50."). The S1 count from Step 0 is the baseline.
- **Miss log:** `capture-misses.jsonl` beside the store, never in a copy or device backup, by design. It can't be
  read remotely; read it only with him at the Mac on day 3 (see below), or skip it.
- **Money-verb rows:** the op log in the copy (tasks and notes written, with UNDO marks), against suite rows H613
  `pay rent fri` (task), H612 `pay rent 650 fri` (task), A011 `paid rent fri` (dated note), only if Core's small
  pin fix is in the pin; otherwise these are still misses and not a flag.
- **Home lines:** only if #366 is in the pin (`git merge-base --is-ancestor`). Screens, so QA reads them from the
  one evening answer and his own messages, not from the copy.

## Day 1 (the day of the install)
- **Look at:** receipts count vs the S1 baseline, and spend (expect a few cents at most; typical month is about
  $3.23). Any "A capture" or "A question" receipt in the minutes after review items 4 to 6 or 10. That morning's
  v5 Step 0 copy is still in Backups and the first v9 copy appears tonight, or after 4 am.
- **Red flags:** a receipt at the time of a money, body or secret line (Core, stop candidate). The month line
  missing or not "of $50" with a key on the phone (Core). Any review item 1 to 14 a "no" (owner per its row; QA
  reproduces on the Simulator first).
- **Evening question:** `Did Tess mention Claude on anything you typed today? ★No / Yes`. Expected: No. A Yes goes
  to Core and QA the same evening with the time he gives, if he gives one.

## Day 2
- **Look at:** day 1's full copy passes P0 and holds the same workouts, sets and bests as before the install
  (Builder A). Receipts and spend since day 1 (expect under $1; over $2 in a day is a flag to Core). Money-verb rows
  if the fix is in. Home lines if #366 is in.
- **Red flags:** no day 1 copy, or a backup failure note (Builder A). P0 fails or a row count drops (Builder A,
  stop candidate). `pay rent fri` gives "Didn't catch that." on a pin that carries the fix (Core). Home hero cut,
  ends in "...", or shows " · " (Builder B, then QA).
- **Evening question:** with #366 in, `Did Home read right today? ★Yes / No`; expected Yes, a No goes to Builder B
  and QA. Without #366: `Did anything land wrong today? ★No / Yes`; expected No, a Yes goes to Core and QA.

## Day 3
- **Look at:** Builder A restores day 2's copy into the pin on the Simulator, timed; at or under 3.23 s and rows
  byte-identical to the copy. Receipts and spend running total; still far under $40 (the 80% step-aside). If he is
  at the Mac anyway, Builder A pulls the miss log from the app container: no secret-word line in it (#422 keeps them
  out), and no miss line whose time matches an "A capture" receipt for a money, body or health phrase.
- **Red flags:** restore over 3.23 s or any row differs (Builder A, stop candidate). A walled phrase matched to a
  receipt (Core, stop). Spend paused or stepped aside (Core). Two days without a copy (Builder A, stop candidate).
- **Evening question:** `Anything worse than the old build? ★No / Yes`. Expected: No. A Yes goes to QA to sort to an
  owner the next morning.

## The trip swap (Oct 26 to 28)
He leaves Mon Oct 26 for New York and lands at LAX Wed Oct 28, 9:20 pm PT. If day 2 or 3 is Oct 27 or 28 (or Oct 26
and he trained), that evening's look and question are replaced by the trip-zone check (T1, T2, X1 to X3):
- **Look at:** the copy has one session for the New York day, filed on its own day, and no second session started
  that day; one memory line for that day, never two. Known gap, not a flag: Review can count a late Monday task on
  Tuesday (R12).
- **Red flags:** a second session offered or started, or the set filed a day early (Core, then QA reruns X1 to X3).
- **Evening question:** `Did Home show today's workout as done? ★Yes / No`. Expected: Yes; a No goes to Core and QA.
  Back home, the next check reads the New York set as "Yesterday" in history from the copy, without asking him.

## What stops the pin
Any of: a money, body, health or secret line that reached Claude; a launch crash; workouts, sets or bests missing
from the app or a copy; P0 failing on two copies in a row; restore over 3.23 s or rows that differ. The coordinator
calls it, Product logs it. Roll back by installing **7b321d2** over the top, never deleting the app (decisions 12:16
PM PT: after the pin, the rollback build is 7b321d2; V4 showed it opens the v9 store). Never restore a copy made on
the pin onto 7b321d2; if data must come back, only the v5 Step 0 copy. After a rollback "Tess asks Claude" stays no
(decisions 10:18 AM PT), and the signing clock restarts from that install.
