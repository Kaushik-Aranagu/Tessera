# Ops board

Lead: Ops thread. Mission (Kaushik, Oct 16 5:43 PM PT): keep improving the infrastructure and the way the team works, and run a second lane that improves the work itself. Owns the usage governor ledger ([usage-governor.md](../usage-governor.md)). Proposals that change another team's workflow go to the coordinator first.

**Lane 1 (infrastructure):** cheaper, safer merges. **Lane 2 (work quality):** stale boards, verdict lines, relay friction.

**Now:** PR 1 = scripts/ops/premerge_check.py + tree_check.sh + .github/workflows/premerge.yml (the merge recipe's mechanical checks as code).

**Next:**
1. Verdict-line template for QA and Design (one parseable line: `PR #n PASS|FIX FIRST sha: findings`) plus a script that lists latest verdict per PR from docs/qa.
2. PR-status digest: one table of open PRs, head SHA, QA/Design verdict, mergeable state, so merge workers read one file instead of many.
3. test.sh speed audit: time each stage, find what can run in parallel or be skipped when only docs change.
4. Board and memory staleness check: script that flags board entries naming merged PRs and memory files over 3000 bytes.
5. Fresh-worker rotation rule for merge workers (restart past about 250k tokens) written into the merge recipe.
6. Mac lane-lock convention: a lock file naming who owns a simulator or a pkill pattern, so one lane never kills another's run.
7. Relay batching: a single relay-queue format the coordinator can send in one message to each Mac lead.
8. Docs index check: docs/README.md lists every new docs file.

**Done:** none yet.
