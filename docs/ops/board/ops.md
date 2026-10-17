# Ops board

Lead: Ops thread. Mission (Kaushik, Oct 16 5:43 PM PT): keep improving the infrastructure and the way the team works, and run a second lane that improves the work itself. Owns the usage governor ledger (usage-governor.md (in the project files under tessera/ops/, not mirrored in the repo)). Proposals that change another team's workflow go to the coordinator first.

**Lane 1 (infrastructure):** cheaper, safer merges. **Lane 2 (work quality):** stale boards, verdict lines, relay friction.

**Now:** pace-ledger row 4 (after the Sun Oct 18 5:00 AM PT reset), then the next Next item.

**Next (all junior tier unless noted):**
1. Pace ledger row 4: read the meter (coordinator rate_limit_event), cost per cloud team, burn per hour; report hot teams to the coordinator.
2. Per-team budget refit at the Sun Oct 18 5:00 AM PT weekly reset: update the shares in the staffing model from the first week of meter data, for the coordinator to approve.
3. Job timeout for runs that start before a screen lock: `run` could kill or flag a job that makes no progress for N minutes, since a stalled job still beats and holds the lock.
4. Subscription event cost note: PR events repeat 2 to 3 times at about 4k tokens each; write the "skip echoes, one status line" rule into the merge recipe.
5. Idle detector: a one-page rule for when a team is below its pace line (what it pulls, who it asks), so no lane sits empty.
6. Relay adoption: send lane-lock, verdict line, worker rotation and relay batch to the coordinator as one proposal for the Mac leads.
7. Remaining QA lines that mention a pin (qa.md lines 15, 23, 37): hand to QA or Product to mark merged items, since the PIN guard keeps Ops off them.

**Done:** #589 merge pre-checks and premerge workflow; #590 verdict line, verdicts.py, staleness.py; #592 staffing model; #593 pinned checkout; #596 test.sh audit, pr_digest.py, lane_lock.sh; #598, #600, #603 ledger and worker rotation; #675, #677 lane lock queue, heartbeat and locked-screen guard; #680 pace ledger check 3; #709, #712 zero-token CPU chores; #715 docs indexes (261 unindexed to 0); #718 merged items marked on the QA and Motion boards.
