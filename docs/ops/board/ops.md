# Ops board

Lead: Ops thread. Mission (Kaushik, Oct 16 5:43 PM PT): keep improving the infrastructure and the way the team works, and run a second lane that improves the work itself. Owns the usage governor ledger (usage-governor.md (in the project files under tessera/ops/, not mirrored in the repo)). Proposals that change another team's workflow go to the coordinator first.

**Lane 1 (infrastructure):** cheaper, safer merges. **Lane 2 (work quality):** stale boards, verdict lines, relay friction.

**Now:** pace-ledger row 2 (due 7:30 to 8 PM PT Oct 16), then refill and the 24/7 CPU lane below.

**Next (all junior tier unless noted):**
1. Pace ledger row 2: read the meter (coordinator rate_limit_event), cost per cloud team, burn per hour; report hot teams to the coordinator.
2. CPU lane follow-ups: schedule `scripts/ops/cpu_chores.sh` on the Mac (coordinator decides), and send Product the 269 unindexed docs and 46 stale board lines it found.
3. Per-team budget table: weekly percent and senior/middle/junior mix per team, added to the staffing model, for the coordinator to approve.
4. Relay adoption: send lane-lock, verdict line, worker rotation and relay batch to the coordinator as one proposal for the Mac leads.
5. Subscription event cost note: PR events repeat 2 to 3 times at about 4k tokens each; write the "skip echoes, one status line" rule into the merge recipe.
6. Idle detector: a one-page rule for when a team is below its pace line (what it pulls, who it asks), so no lane sits empty.
7. Job timeout for runs that start before a screen lock: `run` could kill or flag a job that makes no progress for N minutes, since a stalled job still beats and holds the lock.
8. Board staleness sweep: run staleness.py over every team board and send the stale list to Product.

**Done:** #589 merge pre-checks and premerge workflow; #590 verdict line, verdicts.py, staleness.py; #592 staffing model; #593 pinned checkout; #596 test.sh audit, pr_digest.py, lane_lock.sh; #598, #600, #603 ledger and worker rotation.
