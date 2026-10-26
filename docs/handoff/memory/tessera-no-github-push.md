---
name: tessera-no-github-push
description: "Tessera repo — never push, open PRs or write anything to GitHub; work in the local clone only"
metadata:
  node_type: memory
  type: feedback
  originSessionId: c3cd5f8e-7f6d-44a4-a7b7-dd28cfe8ffb3
  modified: 2026-10-25T00:06:12.982Z
---

Never push, open PRs, comment or otherwise write to GitHub for Kaushik-Aranagu/Tessera. Work only in the local clone (this session: `/tmp/claude-49350/-workspace-karanagu-agents-claude/c3cd5f8e-7f6d-44a4-a7b7-dd28cfe8ffb3/scratchpad/Tessera`; working dir is not writable) and report results to the user.

**Why:** The user said (Oct 25, 2026) this setup is not allowed to push to GitHub.
**How to apply:** Local commits/branches are fine; skip every `git push`, `gh pr`, and the repo handoff docs' "open a PR" steps. No Swift toolchain here, so code is written without building the app (user OK'd that). See [[tessera-routines-woodland]].
