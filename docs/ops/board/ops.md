# Ops board

Lead: Ops thread. Mission (Kaushik, Oct 16 5:43 PM PT): keep improving the infrastructure and the way the team works, and run a second lane that improves the work itself. Owns the usage governor ledger (usage-governor.md (in the project files under tessera/ops/, not mirrored in the repo)). Proposals that change another team's workflow go to the coordinator first.

**Lane 1 (infrastructure):** cheaper, safer merges. **Lane 2 (work quality):** stale boards, verdict lines, relay friction.

**Now:** staffing model proposal ([../staffing-model.md](../staffing-model.md)), then PR digest and test.sh timing.

**Next:**
1. Adopt the verdict line with QA and Design (template in ../verdict-line.md).
2. PR-status digest: one table of open PRs, head SHA, QA/Design verdict, mergeable state, so merge workers read one file instead of many.
3. test.sh speed audit: time each stage, find what can run in parallel or be skipped when only docs change.
4. Board and memory staleness check: script that flags board entries naming merged PRs and memory files over 3000 bytes.
5. Fresh-worker rotation rule for merge workers (restart past about 250k tokens) written into the merge recipe.
6. Mac lane-lock convention: a lock file naming who owns a simulator or a pkill pattern, so one lane never kills another's run.
7. Relay batching: a single relay-queue format the coordinator can send in one message to each Mac lead.
8. Docs index check: docs/README.md lists every new docs file.

**Done:** #589 merge pre-checks as code + premerge workflow; #590 verdict line, verdicts.py, staleness.py.
