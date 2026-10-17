# C2: Claude jobs, trigger, priority class and $40 step-aside

Sources: docs/ai/model-effort-cost-table.md and offline-retry-table.md (origin/master), plus claude-client.md,
architecture.md, side-jobs.md. Ruling (Product 8:16, 8:21, 8:24): in-app cap is $50, a hard stop. At 80% ($40) only
background word jobs (week story, living colour) and Home lines (.lines) step aside. Everything else runs to $50.
"Docs say" means the older docs differ from the ruling and need updating.

| Job | User trigger | Priority class | Steps aside at $40? |
|---|---|---|---|
| capture (Tess) | Tap (user sends a capture) | .capture | No, runs to $50 |
| Home done lines | Unclear, see flag 1 (finishing a workout, then generated in background) | .lines | Yes |
| Home lines (other Home words) | Background, when the pack changes | .lines | Yes |
| Plan my day wording | Tap (Plan my day) | .plan | No, runs to $50 |
| week story | Schedule (Monday after 04:00, once a week) | .lines (docs say) | Yes |
| recipe reader | Tap (user pastes a recipe link) | .recipe | No, runs to $50 |
| askSubject | Tap (opt-in question on a subject) | .asks | No, runs to $50 (docs say it steps aside after .lines, flag 3) |
| fillFacts | Background: opening a side with a gap, once per thing (ruled Product 8:24); off until the sides' opt-in and BD4 with his yes | Not stated, needs a TessJob | Yes (ruled 8:24) |
| linkItems (groceries link) | Tap (he taps it) | Not stated | No, runs to $50 |
| living colour | Background (pack change, at most 31 a month) | Not stated, spend-projection says it steps aside | Yes |
| keyCheck | Tap (Settings) | None (count_tokens, cost 0) | No switch; fallback stops at the cap only |
| answerQuery, shown as "Questions" (ask a log question, Haiku) | Tap (ruled Product 8:24) | Not stated | No, runs to $50 |

## Flags
1. Home done lines: part of Home lines (one call per finish, cached by workout id). Finishing a workout triggers it, but the call is background and shares .lines, so it steps aside at $40.
2. fillFacts: ruled background (opens a side with a gap), steps aside at $40, off until the sides' opt-in and BD4 with his yes. Still no timeout, priority, ledger name or retry in the docs; it needs a TessJob.
3. askSubject: claude-client and the retry table say .asks steps aside at $40 after .lines. The ruling says it keeps
   running. Update both docs. Cost impact is small (worst $2.77 a month at 20 a day).
4. answerQuery ("Questions"): ruled a tap that runs to $50. It is in spend-projection (Haiku, 5 a day) but in no job list yet; add it to the cost and retry tables.
5. living colour has no priority class in the docs. It should join .lines (or a new background class) so the $40 rule has something to key on. linkItems runs to $50 and never steps aside (Product 8:21); give it a named class that says so.
6. Where the docs differ from the ruling: claude-client says only .lines steps aside; architecture 5.5 adds week
   story; spend-projection adds living colour. The ruling matches the last two plus .lines, so claude-client needs
   the edit.
7. Step-aside is docs only today. Only the Settings warm line at 80% exists in code. At worst projected spend
   (about $6.90 a month) it never fires, so it guards loops only.
8. Stale text: ClaudeKey.swift comment, claude-first-uses.md and recipe-link-fetch.md still say a $10 month.
   Code `capNano` is $50.
9. Cap behavior for all jobs: at $50 every job shows "Claude paused until <date>." and writes no row.
