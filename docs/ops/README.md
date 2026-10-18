# Ops docs

How the team works, and the tools that keep it cheap. Scripts are in `scripts/ops/`.

- [board.md](board.md): how the boards work; per-team boards are in [board/](board/ops.md).
- [staffing-model.md](staffing-model.md): senior, middle and junior tiers and per-team budgets.
- [pace-ledger.md](pace-ledger.md): weekly meter checks and burn per hour.
- [worker-rotation.md](worker-rotation.md): when to restart a long-lived thread.
- [lane-lock.md](lane-lock.md): the Mac simulator lock (`wait`, `run`, heartbeat, locked screen).
- [cpu-chores.md](cpu-chores.md): zero-token checks in `scripts/ops/cpu_chores.sh`.
- [verdict-line.md](verdict-line.md): the QA and Design verdict line.
- [relay-batch.md](relay-batch.md): one relay message per Mac lead.
- [test-sh-audit.md](test-sh-audit.md): where `scripts/test.sh` spends its time.
- [discovery-gaps.md](discovery-gaps.md): gaps found by the discovery lane.
- [idle-detector.md](idle-detector.md): when a team is below its pace line, what it pulls and who it asks.
- [handoff-block.md](handoff-block.md): the block every fresh thread's brief carries, plus breadcrumbs for the leads that moved on Oct 17.
- [team-addresses.md](team-addresses.md): current thread and session ids for every team, the retired ids, and the two-minute address check.
- [offline-mac-playbook.md](offline-mac-playbook.md): what cloud teams do while the Mac leads are paused and how relays queue.
- [release-14-checklist.md](release-14-checklist.md): fill-in checklist for naming and installing release 14 when the Mac unlocks.
- [kitchen-rotation-note.md](kitchen-rotation-note.md): what a Kitchen lead rotation hands off.

## More docs (index added by Ops, Oct 17)

- [board/ai.md](board/ai.md): AI architecture team
- [board/core.md](board/core.md): Core engine (Mac)
- [board/design.md](board/design.md): Design studio
- [board/ios-a.md](board/ios-a.md): iOS Builder A (Mac, current iOS build thread)
- [board/ios-b.md](board/ios-b.md): iOS Builder B (Mac, starts once ios/ship-2 merges)
- [board/product.md](board/product.md): Planning lead (Product lead thread)
- [board/qa.md](board/qa.md): QA (Repo maintainer)
- [board/research.md](board/research.md): Research lab
