# AI architecture team

*Started 2026-10-16 from Kaushik's first review (11:58 PM PT Oct 15): "a new AI team for architecture: data, harness, memory." Product edits the Next list; the team's lead runs it. Rules: Claude only through the one switch "Tess asks Claude" (sendsMissesToClaude); reserve before sending, a ledger row for every outcome, $50 a month cap (decided 9:27 AM PT Oct 16); Claude never writes the store; the key lives only in the phone's Keychain, never in any file or thread. Base: `research/tess-model-layer.md`.*

**Two lanes (Kaushik, 11:21 and 11:26 AM PT Oct 16):** this team's lead is its manager. It keeps two lanes going, pulls its next items from this board without waiting to be handed work, and splits work across subagents so it runs in parallel. When one lane waits on a review, build, gate or answer, it works the other in the same turn. The lanes below are suggestions; the lead replaces them with something better. If Next drops under 3, ask the Product lead directly. The coordinator handles cross-team blocks, merges and anything that needs Kaushik, with occasional spot checks.
- **Lane 1:** Next 1, the AI-5 eval rubric. (AI-3 vectors and the AI-2 note are in #430.)
- **Lane 2:** Next 2, the AI-7/AI-8 memory store interface note.

**Now:** the two lanes above. Done: the architecture map; the Home line writer (`home-lines.md`); Groceries with Tess (first features + the Kitchen lead's acceptance, AI-12 eval passed 10/10 on #420); living colour (architecture section 9); memory (shape A, decided, #411); AI-3 vectors + AI-2 ClaudeClient/TessJob note (#430); soul signals (#418).

*Product order for the ship list (Oct 16): AI-1 → AI-7 memory store → AI-8 "remember that…" → AI-9 What Tess knows → AI-2 → AI-3 → AI-5 eval → AI-4 → AI-10 → AI-6 → AI-11 → AI-12 → AI-14 living colour (Builder A, after Design 48) (memory moved up, 12:14 AM PT; $50 cap decided 9:27 AM PT Oct 16); AI-13 when already in the file. Core owns most rows, Builder B the screens, Research AI-5, the Kitchen lead AI-12.*

**Next:** (docs only, no spend unless Product says)
1. AI-5 eval rubric. Done when a scorer built on the AI-3 vectors grades Home lines (aware, plain, true, no clock digits in noticed lines, length caps), ready for Research's Haiku rerun with the tool forced.
2. AI-7/AI-8 memory store interface note for Core, the same shape as `claude-client.md`: shape A's profile block, told/noticed/recent, what Claude may see, forget and backup rules, "remember that…" (AI-8).
3. AI-9 What Tess knows: the data contract for Builder B's screen (what each row shows, where it came from, forget per row), from the memory note.
4. Spend projection. Done when a one-page table gives each Claude job's calls per day, model and monthly cost against the $50 cap after AI-2 (Home on Sonnet ~$1.05/month), with the 80% step-aside point, for Product.

