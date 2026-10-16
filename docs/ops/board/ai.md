# AI architecture team

*Started 2026-10-16 from Kaushik's first review (11:58 PM PT Oct 15): "a new AI team for architecture: data, harness, memory." Product edits the Next list; the team's lead runs it. Rules: Claude only through the one switch "Tess asks Claude" (missesGoToClaude); reserve before sending, a ledger row for every outcome, $10 a month cap; Claude never writes the store; the key lives only in the phone's Keychain, never in any file or thread. Base: `research/tess-model-layer.md`.*

**Now:** 2 (Home line writer, with Design 41). Done: 1 and 5 (architecture section 9, 7371b14), plus first three features and ship list (`docs/ai/` on master, PR #324 merged; copies in `ai/`).

*Product order for the ship list (Oct 16): AI-1 → AI-7 memory store → AI-8 "remember that…" → AI-9 What Tess knows → AI-2 → AI-3 → AI-5 eval → AI-4 → AI-10 → AI-6 → AI-11 → AI-12 → AI-14 living colour (Builder A, after Design 48) (memory moved up, 12:14 AM PT; $50 cap decided 9:27 AM PT Oct 16); AI-13 when already in the file. Core owns most rows, Builder B the screens, Research AI-5, the Kitchen lead AI-12.*

**Next:**
1. The architecture map. Done when `docs/ai/architecture.md` draws Tessera's data (store, ops, classes, records), Tess's memory (what she knows about him and how he sees and forgets it), and the harness (on-phone router, Claude calls, ledger, TessInbox, validators), with what each Claude call sends and costs, and the gaps ranked for Core.
2. The Tess line writer for Home. Done when a spec gives one plain line per Home item ("Workout done.", "Groceries: 4 left."), written on the phone by rules first and worded by Claude when the switch is on (cached per day, sent titles only), with the offline line, test cases and the Core and Builder B split. Pairs with Design 41.
3. Groceries with Tess. Done when a spec covers sorting a list into US aisles, connecting rows to recipes, suggesting what usually runs out, and one reminder rule (near a store or before a planned cook), with what stays on the phone, for Core and Design 47.
5. Tess's changing colours, the choosing side. Done when the architecture map covers what picks the soul's pigments: inputs (time, day, Tess's state), cadence, on-phone rules first, Claude only under the switch and cached (at most once a day), cost, the offline fallback, and delivery through the per-look soul pigments (TessSoul.swift palette). Tess only, never the app's base colours.
4. What Tess remembers. Done when a spec sets how facts about him are learned, shown and forgotten (from `tess-knows.mp4`), stored on the phone and in backups, and what Claude may see, for Core.
