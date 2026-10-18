# Offline Mac playbook (Ops, Oct 17)

Use when the Mac is off, asleep, locked out, or the Mac leads (Core, Builder A, Builder B) are parked. Cloud teams keep working; nothing waits for the Mac that does not have to.

## What stops, what does not
- Stops: builds, test.sh, simulator runs and clips, installs on his phone, releases, anything that needs the lane lock, any Swift compile check.
- Keeps going (cloud only): planning and boards (Product), design sheets and studies (Design, Motion lab), research and evals (Research), docs and board mirrors (Ops), static reviews (QA reads diffs; it has no Swift toolchain), AI architecture docs, Kitchen rules.

## Rules for cloud teams while the Mac is out
1. Never report a Mac result you did not see. A PR that needs test.sh stays "waiting on the Mac" until the Mac lead sends the result; QA verdicts say "static review only, test.sh pending".
2. Frozen-PR rule holds: once a Mac lead sent a PR number, nobody pushes to it unless a fix was requested.
3. Prepare, do not merge: app-code PRs wait for their test.sh; docs-only PRs (premerge docs check CLEAN, QA PASS) merge as usual.
4. Put work for the Mac on the owning board as a ready-to-run item (exact command, file, expected result) so the lead starts without a question. Cross-team findings go on Product's boards.
5. Releases pause. The signing lapse is Fri Oct 23 2:12 PM PT; the coordinator tells Kaushik at the 6-day mark if nothing has installed.

## How relays queue
- Mac leads take relays from the coordinator, not direct sends. Cloud teams send the coordinator one batched note; the coordinator keeps the batch in relay-queue.md and delivers it with message_thread.
- A message_thread to a parked Mac session restarts it; if the Mac is off, delivery waits until the session returns, so write each relay to stand on its own (what, where, why, what to reply with).
- Do not resend the same relay; check relay-queue.md first. Order when the Mac returns: Builder A (release and signing), Core, Builder B.
- When the Mac returns, the coordinator posts one line and each lead reads its relay batch before taking new work.

## Ops checks during an outage (every 3 hours)
- Mirror boards and decisions to docs/ in one docs PR if Product refilled.
- Run the address check (team-addresses.md) and the stale-lines check.
- Keep a list of Mac-waiting PRs and what each needs; give it to the coordinator in the 3-hourly update.
