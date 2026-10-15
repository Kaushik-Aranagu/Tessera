# Kitchen v2 backlog (not scheduled)

*Kitchen lead, 2026-10-15. Hold until Kaushik has cooked and shopped with v1 for a week; then pick by what he actually reached for. Each line is one slice, engine first.*

| Idea | Why it might earn its place | Notes |
|---|---|---|
| **Pantry light (inferred)** | "Do I have it?" with no counting and no questions. `Ingredient` gets `state` (in / low / out / unknown) and `lastBoughtAt`. Shop clear → *in*; `FinishCooking` → used non-staples *low*, fresh produce *out*; "out of milk" in the ghost row → *out* and onto Groceries; "have rice" → *in* | One engine slice, no pantry screen: state shows on the Ingredient page and as a dimmer weight on recipe lines you're out of. Research: `tessera/research/kitchen-v2.md` §1 |
| **Running low by rhythm** | After 3 buys, past 1.5x the median gap an ingredient shows as a dim "usually by now" line at the bottom of Groceries, never auto-added | Needs purchase history; after pantry light |
| **What can I cook** | `RecipeMath.missing(recipe)`: rank by non-staples *out* or *unknown*, ties by "not cooked lately"; "0 missing", then "1 missing: lemons" | The shelf filter word, off by default; needs pantry light |
| **Week of dinners** | The dated "cook X thu" tasks shown as a week strip; one tap adds the week's recipes to groceries | Reuses Plans' week layout |
| **Recipe from a link** | Paste a URL; fetch once, read the schema.org Recipe JSON-LD (handles `@graph`, array `@type`, `HowToSection`, ISO 8601 times), write it out as plain text into the existing paste parser and paint-over. Keep `sourceURL`; store only recipe fields, no photos or headnote; on failure "Couldn't read that page, paste the text instead." | **Waits on Kaushik's yes to fetching** (on the coordinator's list). Research §2 |
| **Share sheet import** | Share a page from Safari straight into Tessera | Needs an App Group entitlement, so a paid developer account; until then Copy Link and paste |
| **Recipe edit in place** | Fix a line, reorder or split a step without re-pasting | Same paint-over surface as paste |
| **Recurring groceries** | "Milk every week" comes back after the shop ends | A list item flag, not a new class |
| **Leftovers and cooked twice** | "Cook double" scales up and makes a "leftovers, 2 portions" item on Later | Ties into tasks |
| **Cook notes into the recipe** | "Less salt next time" from a Cook note shows on the recipe page the next time | Notes with @recipe already link |
| **Hands-free cook mode** | "Next", "back", "timer" by voice while cooking | On-device speech, grammar only |
| **Store-specific aisle order** | Walk order learned per shop from check-off order | Only if one shop's order feels wrong |
| **Nutrition** | Only if Kaushik asks | Data licensing first |
