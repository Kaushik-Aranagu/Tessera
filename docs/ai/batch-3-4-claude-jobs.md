# Batch 3 and 4: the Claude jobs to build, their packs, budget and Review switches

For: Product (huddle plan batches 3 and 4), then Core (jobs, gate) and Builder B (the Review rows). From: AI architecture. Docs only: no Claude calls, no key use, no key content. Read against master 5af7cf5. **[code]** = read in Swift; **[docs]** = from a docs page; **[unbuilt]** = nothing on master yet; **[proposed]** = my call where no ruling or sheet exists. Prices and call counts come from `model-effort-cost-table.md` (M = measured, A = assumed).

## 1. The page in one table

| Job (huddle row) | Built? | Model, effort, max tokens | Pack: what leaves the phone | Typical / worst per month | Share of $50 | Review switch (under "Tess asks Claude") |
|---|---|---|---|---|---|---|
| **Plan my day wording** (batch 3 "Plan wording" and batch 4 "Plan my day at 8 AM" are **one job**, `PlanWording.swift`) | Yes [code] | Sonnet 5.5, low, 1,024 | `PlanPack`: compact JSON, short handles (t1, e2, w1, k1), block kinds, minutes of day, titles. A walled or secret-worded title goes as `task` / `busy` with its handle kept. Never ids, notes, health, history | $0.30 / $1.92 (2 a day typical, 5 a day cap, no cap in code) | 0.6% / 3.8% | **Plan my day wording** |
| **Recipe reading** (batch 3 "recipe reading"; batch 6 "Link fetch" is the phone's own fetch) | Yes [code `RecipeLinkReader.swift`] | Haiku 5.5, low, 4,096 | The fetched page text only: about 1,500 characters before the first "ingredient" and up to 22,000 after, cap 24,000. No image, no stored recipe, nothing from his objects | $0.01 / $0.08 (10 a month typical, 30 cap) | 0.02% / 0.2% | **Recipe reading** |
| **Capture fallback**, step 1: on the phone (batch 3 "Capture past the grammar") | Yes [code `TessModelCapture.swift`, Foundation Models] | Apple on-device model | Nothing leaves the phone | $0 / $0 | 0% | **On-phone fallback** (Product's name) |
| **Capture fallback**, step 2: Claude, after the grammar and the on-device model miss | Yes [code, #860, #884] | Haiku 5.5, no effort, 512 | The phrase whole (600 characters at most), the date line, the current exercise name, the last set, 11 tool definitions. Key and key-shaped text never; Siri and Shortcuts never; a phrase with "timer", or any phrase while a Cook runs, never | $0.09 / $0.35 (5 a day typical, 20 worst, no count cap in code) | 0.2% / 0.7% | **Misses go to Claude** (the stored name today, `missesGoToClaude`) |
| **Visible memory** (batch 3 "Visible memory") | Page: partly [code `TessMemory.swift`]; Claude touch: **[unbuilt]** (`remember` tool, AI-8) | Same call as capture; no job of its own | Nothing extra. Claude writes no memory (AI-0). The only Claude touch is the `remember` tool inside a capture miss, which proposes a ghost row; only KEEP writes. Recent memory lines also ride in the Home lines pack (`architecture.md` Home row) | $0 / $0 beyond capture (the tool definition is already in the 11) | 0% | Page: **Memory** (Product's name, a page, not a Claude switch). Claude side: **Tess suggests what to keep** [proposed] |
| **Total of the five** | | | | **$0.40 / $2.35** | **0.8% / 4.7%** | |

Whole app, all jobs: about $0.79 typical, $6.90 to $7.05 worst (14% of $50), so the cap holds with 7x room. The $40 step-aside never touches these five: capture, plan and recipe all run to $50 (`job-trigger-table.md`).

## 2. Where the switches live (this is the part that needs a ruling)

- **Sheet 93 page 1 cannot hold them.** "Tess asks Claude" opens in place with three lines (Key, This month, Receipts); the page is already at the 6-row limit (`settings-claude-page-spec.md` section 1). Four more rows would break SP02.
- **They belong in the Review section (batch 0)**, which is "one row per open choice, each with a plain before/after line". My recommendation: a group heading **Tess asks Claude** there, with these rows in this order: **Plan my day wording**, **Recipe reading**, **Misses go to Claude**, **Tess suggests what to keep**. **On-phone fallback** is not a Claude switch (no request, no spend), so it sits in its own row above the group under the heading Tess on this phone. The Memory page needs no switch.
- **Rule:** a job runs only if the master switch is On (a key saved and the stored value, `settings-claude-page-spec.md` section 2) **and** its own row is On. Off on any row stops that job only; master Off stops every job whatever the rows say. Rows keep their values through master Off and through Remove key, so re-adding a key restores the choices. Default for every row: On, because that is today's behavior (one stored switch, `ClaudeSection.swift:72, 157`).
- **Before/after lines** (one plain line each, proposed): Plan my day wording - "Off: you get the plan Tess makes herself." Recipe reading - "Off: paste the text and she reads it on the phone." Misses go to Claude - "Off: what she can't read stays in the box." Tess suggests what to keep - "Off: she only keeps what you say outright."
- **Cost per row:** each row may show its month spend ("$0.03 this month") from the ledger by job word (the Receipts words). No bar, no colour; the master line already shows the $50 meter.

## 3. What each job must prove before it counts as built for the batch

| Job | Core builds or fixes | Tests (none needs a key or a live call) |
|---|---|---|
| Plan my day wording | The per-day cap of 5 (written in the doc, not in code); the job switch read in `AppModel.asksClaude`'s gate | `planWordingStopsAtFiveCallsADay`; `planOffMakesNoRequestAndKeepsTheRulesPlan`; `planPackHoldsNoIdNoteNoHealthNoHistory` |
| Recipe reading | The job switch; "Claude is off. Paste the text instead." when its row is Off | `recipeOffMakesNoRequestAndShowsThePasteLine`; `recipePackHoldsNoImageAndNoStoredRecipe` |
| Capture fallback | Order stays grammar, on-phone model, Claude; the new row stops only step 2; the 8 s cap and the inbox drain (`offline-inbox-drain-and-eight-second-cap.md`) | `onPhoneFallbackOffSkipsOnlyTheOnDeviceModel`; `missesToClaudeOffStopsOnlyClaude`; `walledPhraseStillMaskedWhenSent` |
| Visible memory | `remember` tool (AI-8): proposes a ghost, never keeps on its own, never a forget tool; screen first (`TessMemoryScreen.refusal`) | `rememberToolOnlyProposesAGhost`; `suggestOffRemovesTheRememberTool`; `claudeNeverWritesMemoryWithoutKeep` |
| All rows | One gate | `masterOffStopsEveryJobWhateverTheRowsSay`; `rowsKeepTheirValuesThroughRemoveKey`; `reviewRowsReadTheValueTheGateReads` |

## 4. Risks and rulings I need

1. **Names.** "Plan wording" and "Plan my day wording" are one job; the huddle plan lists it twice (batch 3 and batch 4). Merge the rows, or the Review section will show two switches for one thing.
2. **"Misses go to Claude" is the existing stored name** and the plainest. Product's batch 3 row calls the whole group "Tess asks Claude"; keep that as the group heading and the master switch, and use the job words for the rows.
3. **No daily count cap for capture in code.** Money alone bounds it ($0.0015 a call worst). Worst month if it ran away at 200 a day: about $9, still under the cap, so I do not propose a count cap.
4. **Memory lines in Home packs** are a second path for told facts to reach Claude. They follow the Home lines switch and its walls (a private line is never packed). If Product wants one switch for "memory in what Tess sends", it needs its own row; I have not added one.
5. **Foundation Models availability.** On a phone without the on-device model the first step is skipped and Claude is next; the row must read "Not on this phone" and stay Off, not error.
