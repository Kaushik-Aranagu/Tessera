# Kitchen v2 backlog (not scheduled)

*Kitchen lead, 2026-10-15. Hold until Kaushik has cooked and shopped with v1 for a week; then pick by what he actually reached for. Each line is one slice, engine first.*

| Idea | Why it might earn its place | Notes |
|---|---|---|
| **Pantry light (inferred)** | "Do I have it?" with no counting and no questions. `Ingredient` gets `state` (in / low / out / unknown) and `lastBoughtAt`. Shop clear → *in*; `FinishCooking` → used non-staples *low*, fresh produce *out*; "out of milk" in the ghost row → *out* and onto Groceries; "have rice" → *in* | One engine slice, no pantry screen: state shows on the Ingredient page and as a dimmer weight on recipe lines you're out of. Research: `tessera/research/kitchen-v2.md` §1 |
| **Running low by rhythm** | After 3 buys, past 1.5x the median gap an ingredient shows as a dim "usually by now" line at the bottom of Groceries, never auto-added | Needs purchase history; after pantry light |
| **What can I cook** | `RecipeMath.missing(recipe)`: rank by non-staples *out* or *unknown*, ties by "not cooked lately"; "0 missing", then "1 missing: lemons" | The shelf filter word, off by default; needs pantry light |
| **Week of dinners** | The dated "cook X thu" tasks shown as a week strip; one tap adds the week's recipes to groceries | Reuses Plans' week layout |
| **Recipe from a link** | Paste or share a recipe link and get the recipe on the paint-over screen | **Approved** (Kaushik 18:41, Product 19:06). Slices L1-L3 below |
| **Share sheet import** | Share a page from Safari straight into Tessera | Free-signing version is in L1 (App Intent and a Shortcut). A real Share Extension waits for a paid account |
| **Recipe edit in place** | Fix a line, reorder or split a step without re-pasting | Same paint-over surface as paste |
| **Recurring groceries** | "Milk every week" comes back after the shop ends | A list item flag, not a new class |
| **Leftovers and cooked twice** | "Cook double" scales up and makes a "leftovers, 2 portions" item on Later | Ties into tasks |
| **Cook notes into the recipe** | "Less salt next time" from a Cook note shows on the recipe page the next time | Notes with @recipe already link |
| **Hands-free cook mode** | "Next", "back", "timer" by voice while cooking | On-device speech, grammar only |
| **Store-specific aisle order** | Walk order learned per shop from check-off order | Only if one shop's order feels wrong |
| **Nutrition** | Only if Kaushik asks | Data licensing first |

## Recipe from a link: slices L1-L3 (scheduled with kitchen v2)

*Product decided this on 2026-10-15 at 19:06; the brief is `docs/research/recipe-link-fetch.md`. Engine first, Core builds it, and the screens are the existing paste paint-over. The reading order is fixed: JSON-LD first, then the deterministic parser, then Claude Haiku last. Every result lands as a ghost recipe with Undo and keeps the link.*

**L1. Fetch, JSON-LD and the share sheet.**
- `Recipe` gets `sourceURL` (`.text`), and `CreateRecipe` takes a URL input, `CreateRecipe(parsed:sourceURL:)`, alongside `CreateRecipe(text:)`.
- The fetch follows brief §1: an ephemeral `URLSession`, one GET only when he pastes or shares a link, https only, at most 5 redirects (all https), and the final URL kept as `sourceURL`.
- Before fetching it refuses private IPs, `localhost`, `.local` and any port other than 443. Limits are 8 s per request, 15 s in total and 3 MB, and the content type must be HTML. It checks offline status first.
- **The user agent is honest:** `Tessera/<version> (iPhone; personal recipe reader)`. It never imitates Safari, never rotates and never retries with tricks.
- When a site blocks the fetch (401/403/429, or a bot-check page), Tess says in cobalt: "That site won't let me read it. Paste the recipe text instead." The link stays in the box.
- `RecipeJSONLD` handles `@graph`, arrays, `mainEntity`, array `@type`, `HowToStep` and `HowToSection`, ISO 8601 times, and `recipeYield`. It builds the `ParsedRecipe` directly and never re-guesses serialized text.
- When a page has several recipes, it reads the first and says so.
- **Share sheet:** an `ImportRecipeLink(url:)` App Intent in `TesseraIntents` opens the paste screen with the link. Kaushik adds a one-step Shortcut, "Receive URLs from Share Sheet, then Import recipe link". This needs no entitlement. The ghost row and the paste screen also accept a pasted link through `PasteButton`.
- *Accept when:* the ten URLs in brief §3 are re-checked on the Mac with curl, and their JSON-LD blocks are saved as fixtures and pass `swift test`. Every site that blocks gives the paste line, never an error code or a modal. The Shortcut is checked on the phone once; if iOS 27 won't run it from the share sheet, paste is the path and this goes in the acceptance note.

**L2. Pages without JSON-LD.** This comes after the Paste hardening slice, because it relies on gaps 3 and 6 being fixed.
- SwiftSoup, pinned exactly, in a new `TesseraImport` target, so the engine stays on GRDB only.
- It reads visible text, preferring the WPRM or Tasty recipe card, then `article`/`main`. It drops navigation, comments, share and ad blocks, then runs `RecipeParser`.
- New text cases: WPRM's "10 minutes mins" and Archana's "Prep: 10 M".
- A result is accepted only with at least 2 ingredients, at least 1 step and no more than 80 ingredients.
- Failure lines from brief §4: paywall ("Got 12 ingredients. The steps are behind the site's paywall; paste them below."), video-only (read the description, or offer the linked recipe site), and no recipe found.
- Offline: the link waits as one `TessInbox` item and becomes a ghost recipe the next time he is online. It never commits on its own.
- *Accept when:* piperhaywood (#9) and the Substack page read through text, and the paywall and video lines show for #4 and #10.

**L3. Claude Haiku as the last resort.** This comes after the Tess model layer's structured `createRecipe` tool (T2/T3).
- It runs only when L1 and L2 both fail and Claude is on, keyed, online and under the cost cap.
- Input is trimmed visible text (at most 24,000 characters) inside a data-only block, with one `createRecipe` tool. The call is streamed so the ghost fills in, with a 20 s timeout.
- The app sets `sourceURL` and `sourceText`, never the model. The arguments go through `ActionRegistry.decode` as a pending ghost (`actor = tess`, `route = claude`).
- It costs about $0.0013 per link.
- *Accept when:* a page that L1 and L2 reject (or a fixture made to fail them) arrives as a ghost recipe with Undo, and with Claude off it ends at the paste line.
