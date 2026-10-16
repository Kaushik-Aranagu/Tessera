# AI architecture team

*Started 2026-10-16 from Kaushik's first review (11:58 PM PT Oct 15): "a new AI team for architecture: data, harness, memory." Product edits the Next list; the team's lead runs it. Rules: Claude only through the one switch "Tess asks Claude" (sendsMissesToClaude); reserve before sending, a ledger row for every outcome, $50 a month cap (decided 9:27 AM PT Oct 16); Claude never writes the store; the key lives only in the phone's Keychain, never in any file or thread. Base: `research/tess-model-layer.md`.*

**Two lanes (Kaushik, 11:21 and 11:26 AM PT Oct 16):** this team's lead is its manager. It keeps two lanes going, pulls its next items from this board without waiting to be handed work, and splits work across subagents so it runs in parallel. When one lane waits on a review, build, gate or answer, it works the other in the same turn. The lanes below are suggestions; the lead replaces them with something better. If Next drops under 3, ask the Product lead directly. The coordinator handles cross-team blocks, merges and anything that needs Kaushik, with occasional spot checks.
- **Lane 1:** the consistency pass: fold decisions.md 11:45 AM PT into architecture.md and ship-list.md (section 6 Sonnet, AI-11 Monday, AI-14 clamp), one copy of each rule.
- **Lane 2:** the AI-13 migration map: each old Claude caller (capture, plan, recipe link, key check) onto ClaudeClient, no behavior or ledger change.

**Now:** the two lanes above. Done: the architecture map; the Home line writer (`home-lines.md`); Groceries with Tess (first features + the Kitchen lead's acceptance, AI-12 eval passed 10/10 on #420); living colour (architecture section 9); memory (shape A, decided, #411); AI-3 vectors, AI-2 ClaudeClient/TessJob note, AI-5 eval rubric and AI-7/AI-8 memory-store note (#430, 3c003a2); soul signals (#418); AI-9 contract, spend projection, AI-4/AI-10 home-lines-job and AI-11/AI-6/AI-14 week-story-job (#436). Every AI ship-list row is now written.

*Product order for the ship list (Oct 16): AI-1 → AI-7 memory store → AI-8 "remember that…" → AI-9 What Tess knows → AI-2 → AI-3 → AI-5 eval → AI-4 → AI-10 → AI-6 → AI-11 → AI-12 → AI-14 living colour (Builder A, after Design 48) (memory moved up, 12:14 AM PT; $50 cap decided 9:27 AM PT Oct 16); AI-13 when already in the file. Core owns most rows, Builder B the screens, Research AI-5, the Kitchen lead AI-12.*

**Next:** (reviews against your notes, as Core's PRs land; docs only)
0b. (Research `plan-rerun-plan.md`, 12:58 PM PT Oct 16) Build the runner `scripts/ai/plan_my_day_eval.py` for the Plan my day rerun. It follows the script rules: env-only key, api.anthropic.com only, redirects refused, bounded calls, a $1 stop, writes only under docs/. The rerun is 26 packs, 72 Sonnet calls, about $0.33. It runs only after Core G1, G4 and G9 land and he says yes in your thread.
0a. (AI-5 verdict #488, 12:50 PM PT Oct 16) Narrow the Home-wording prompt with Research's rule: Claude only words done moments that add a best, a gap or a count change. Plan a Sonnet-only rerun with its count and cost; it runs only on his yes in your thread. The switch stays off until it passes.
0. (Research cap-math-check.md, 12:40 PM PT Oct 16) Fix spend-projection.md: lines 44-45 should read $31.41 and $41.41, and line 69 should say $6.48 a day reaches $50 in 7.7 days. Recheck the Sonnet cache-read price on the models page; code has 200 n$/token, claude-first-uses.md has $0.10/M. Tell Core the right figure.
1. Review Core's AI-3 small PR (TessLineCheck + SW3 wording) against `line-check-vectors.md`.
2. Review MU2 + A2 against the money/body/health wall and the router rule (a pin blocker, so first when it opens).
3. Review Core's AI-2 PR (ClaudeClient + TessJob, the 40-a-day cap, A6) against `claude-client.md` and `spend-projection.md`.
4. Plan the AI-5 Haiku rerun with Research (tool forced, scored by `eval-rubric.md`): call count and cost first; the run waits on his word in its thread, as before.

