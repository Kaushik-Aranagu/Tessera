# Kitchen v2 backlog (not scheduled)

*Kitchen lead, 2026-10-15. Hold until Kaushik has cooked and shopped with v1 for a week; then pick by what he actually reached for. Each line is one slice, engine first.*

| Idea | Why it might earn its place | Notes |
|---|---|---|
| **Pantry area** (was Pantry light, inferred) | "Do I have it?" with no counting and no questions. Kaushik, Oct 16: a Pantry area that knows what he has, feeds Groceries and Recipes, and lets the ingredient peek show need against have; see the section below. `Ingredient` gets `state` (in / low / out / unknown) and `lastBoughtAt`. Shop clear → *in*; `FinishCooking` → used non-staples *low*, fresh produce *out*; "out of milk" in the ghost row → *out* and onto Groceries; "have rice" → *in* | Engine first, then its own area (the old "no pantry screen" default is reversed): state shows on the Ingredient page, as a dimmer weight on recipe lines you're out of, and in the Pantry area. Research: `tessera/research/kitchen-v2.md` §1 |
| **Running low by rhythm** | After 3 buys, past 1.5x the median gap an ingredient shows as a dim "usually by now" line at the bottom of Groceries, never auto-added | Needs purchase history; after pantry light |
| **What can I cook** | `RecipeMath.missing(recipe)`: rank by non-staples *out* or *unknown*, ties by "not cooked lately"; "0 missing", then "1 missing: lemons" | The shelf filter word, off by default; needs pantry light |
| **Week of dinners** | The dated "cook X thu" tasks shown as a week strip; one tap adds the week's recipes to groceries | Reuses Plans' week layout |
| **Recipe from a link** | Paste or share a recipe link and get the recipe on the paint-over screen | **Approved** (Kaushik 18:41, Product 19:06). Slices L1-L3 below |
| **Share sheet import** | Share a page from Safari straight into Tessera | Free-signing version is in L1 (App Intent and a Shortcut). A real Share Extension waits for a paid account |
| **Recipe edit in place** | Fix a line, reorder or split a step without re-pasting | Same paint-over surface as paste |
| **Recurring groceries** | "Milk every week" comes back after the shop ends | A list item flag, not a new class |
| **Leftovers and cooked twice** | "Cook double" scales up and makes a "leftovers, 2 portions" item on Later | Ties into tasks |
| **Cook notes into the recipe** | "Less salt next time" from a Cook note shows on the recipe page the next time | Notes with @recipe already link |
| **Parallel steps in one cook** | The roast runs while the sauce goes: several live steps and timers at once, the clock showing which overlap | Kaushik, Oct 16, kept as a note; the rule is in the section below. Ground: Core's step start-minutes for layout C |
| **Hands-free cook mode** | "Next", "back", "timer" by voice while cooking | On-device speech, grammar only |
| **Store-specific aisle order** | Walk order learned per shop from check-off order | Only if one shop's order feels wrong |
| **Nutrition** | Only if Kaushik asks | Data licensing first |

## Recipe from a link: slices L1-L3 (scheduled with kitchen v2)

*Design: `docs/design/kitchen/kitchen-v2.md` §L (Design branch, 1cb2fb6). There is no new screen: the paste paint-over reads the link, with a cadmium wash while reading and no spinner. Claude's reading streams in as a wet cobalt ghost that dries to ink on Save. Every failure keeps the link and opens a writing line, with Tess's line from the sheet's table and no modal. Product decided this on 2026-10-15 at 19:06; the brief is `docs/research/recipe-link-fetch.md`. Engine first, Core builds it, and the screens are the existing paste paint-over. The reading order is fixed: JSON-LD first, then the deterministic parser, then Claude Haiku last. Every result lands as a ghost recipe with Undo and keeps the link.*

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

## Pantry light, rhythm and what can I cook: slices P, R, W (designed, held for a week of use)

*Design: `docs/design/kitchen/kitchen-v2.md` §P, §R, §W, with the recording `pantry-light.mp4`. These are the top three rows of the table above, made into slices. Core builds the engine, and the screens are changes to existing sheets (10, the Ingredient page, 13, 14). They are still held until Kaushik has cooked and shopped with v1 for a week.*

**P. Pantry light.** (After R, and only if R's evidence and week one show he wants a state.)
- Engine: `Ingredient.state` (in, low, out or unknown) and `lastBoughtAt`, set by clearing the shop, by `FinishCooking`, and by "out of milk" or "have rice".
- Recipe page: an out line drops to 400 weight at 55%, with a faint ring in the margin, never red. Low, unknown and staples show nothing.
- Ingredient page: a state sentence ("**Out** since you cooked dal on Tuesday"). Tapping the value word cycles in, low, out, and the change can be undone.
- **Swipe-to-Groceries sends out, low and unknown lines, and skips in lines and staples** (decided, see below).

**R. Usually have (Research's U0, `docs/research/pantry-light.md` §9).** This no longer waits on P: it reads the Groceries history that already exists (checked items keep `checkedAt` after clearing). If week one's question 1 comes back "yes", it is the first v2 pantry step. Decided 2026-10-15:
- The rule is Research's rules 1-9. An item qualifies after 3 or more typed buys within 56 days at a steady interval U. It is due from **0.85 × U to 2 × U** days after the last buy; the backlog's 1.5× would show weekly milk a week late. Recipe-only items like lemons never qualify.
- At most **4 names** (Design 47 on 2026-10-16; was 3), the most overdue first. Each is offered for **one shop run**: if it's shown and not bought when the shop clears, it goes quiet until the next buy resets it. Swiping left does the same (`SkipUsual`).
- **The surface is Design 47's USUALLY label and a line of ink words** (2026-10-16; this replaced "Usually have: milk, eggs", which had replaced USUALLY BY NOW). It states a fact about him with no deadline feel. It keeps Design's §R look: the label at 55% and the names at 21/400 at 55%, as the last thing in the aisle window and in at-the-shop mode, never pinned, taking no space when empty.
- Tapping a name adds it to its aisle, and Tess says "Milk, in Groceries." with Undo. Long-pressing gives the reason: "Bought 6 times in 8 weeks, about weekly." On the Ingredient page it reads "Usually every 7 days. Last bought 9 days ago."
- It never notifies, never shows a badge, never makes a Home offer, never adds anything on its own, and never uses red.
- *Accept against* Research's 20-week fixture (§7), every row.

**W. What can I cook.** After P.
- **CAN COOK** replaces FROM THE BASKET as the shelf's third filter word (decided, see below). It is off by default.
- Names missing two or more ingredients drop away. Names missing nothing come first, then names missing one, which show "1 missing: **lemons**". Tapping the value word adds it to Groceries.
- **An unknown counts as missing but reads "1 to check: lemons"**, and tapping it opens the Ingredient page.

**Kitchen lead decisions on Design's two questions (2026-10-15):**
1. **Yes**, rename FROM THE BASKET to CAN COOK, and say "1 to check" for unknowns. The rename lands with W; until pantry state exists, v1's shelf keeps FROM THE BASKET.
2. **Yes**, swipe-to-Groceries skips in lines. Low lines go along with out and unknown, since "low" means "might not be enough for this recipe". Staples stay skipped as today.

## Parallel steps in one cook (Kaushik, Oct 16; a note, not scheduled)

*The ask: several live steps and timers at once, like the roast while the sauce goes, with the model working out which steps overlap. The ground is Core's step start-minutes for layout C (`recipe-layouts.md` §C): each step starts where the running sum of the earlier steps' active time puts it, and a step's `RecipeParser.durations` is its wait.*

**Which steps can run in parallel.** A step can host others only when it has a wait of 5 minutes or more (roast, simmer, bake, rest, chill, marinate, rise, boil the pasta). A step can run during a host when it needs no hands on the host's pan: chopping, a sauce, a dressing, a salad, setting the table, toasting nuts. A step that names the host's subject ("stir the sauce", "flip the chicken", "drain the pasta") belongs to the host's track and ends it or sits inside it. At most two tracks are live at once on the clock and in cook mode; a third waits.

**The parser's overlap rule, no model.** Deterministic, first slice:
1. A step opens a parallel track when it begins with a cue: "meanwhile", "while the", "while that", "as the", "in the meantime", "at the same time", "during this time". The step starts at the host's start minute, not its end, and its own wait runs beside the host's.
2. A step with no cue starts at the latest end of every live track (the join). "Drain", "remove from the oven", "when the timer goes" and a step naming the host's subject close that track.
3. An untimed step is 2 minutes of active time on the clock (one constant, shown as a short stroke); a step with a range uses its lower bound, as today.
4. The clock's length is the join of the last tracks, never the sum of every step; it must land within 10% of the recipe's own total time line when there is one, else the parser shows the sum and marks nothing parallel.

**The model's part, after that.** For a recipe with no cue words Claude may propose which steps overlap, only when he lets Tess ask and never in a live cook: the pack is the step texts with their waits (no ingredients, no notes), the reply is pairs `(step, runsDuring)`, at most 3. The phone checks each pair: the host has a wait of 5 minutes or more, the guest does not come before the host, the guest does not name the host's subject, no step is a guest twice. A proposal shows on layout C as a faint bracket beside the clock; one tap keeps it for that recipe, and it never moves a step in cook mode on its own.

**Cook mode.** Two live lines: the current step set apart by the accent, the other track's line dimmer with its own timer under it; one timer per track; the one he last touched is current; the step card's NEXT moves within the current track. Finishing a host's timer brings its track forward with one haptic, the same moment as today's timer end.

**Done when** (for whoever builds it): the seed recipes with "meanwhile" steps show two tracks on the clock; the clock's length is within 10% of the written total time for those with one; cook mode runs the pasta timer and the sauce step at once with both timers alive; a recipe with no cues renders exactly as today.

## Pantry area (Kaushik, Oct 16; after a week of real Kitchen v1 use, not in the next builds)

*This reverses the old "no pantry screen" default. Product places the Pantry area as the home for the held R (usually have) and P (pantry light) slices; W (CAN COOK) follows it.*

- **What it is:** an area that knows what he has, built on P's engine (`Ingredient.state` in, low, out or unknown, and `lastBoughtAt`, set by clearing the shop, by `FinishCooking` and by "out of milk" or "have rice"), never by counting and never by asking. It is a view on the Ingredient objects that already exist, not a new class.
- **It feeds Groceries:** out lines are offered, never auto-added; USUALLY (R) is the rhythm line and lives here as well as at the foot of Groceries; the week's planned cooks' needs read against state.
- **It feeds Recipes:** the ingredient peek on layout C reads need against have when state is known ("6 eggs, have", "feta, out", "1 bag spinach, low"), with state words only, never a count he didn't type; with no state the peek shows the plain line as today. An out line is what the swipe sends to Groceries (decided above).
- **What stays from P:** engine first, the state sentence on the Ingredient page, the dim out line on the recipe page, undoable state cycling, nothing red, no notification.
- **What changes:** a screen exists. Design sheet needed, in Groceries' frame (‹ KITCHEN at 58, title, a line of counts "4 out, 2 low", the aisle window of ingredients grouped by state then aisle, USUALLY at the foot, Tess's band); ink words, no pills. Oct 22's question 1 ("did you want to know whether you had something") now sets how soon, not whether.
- **Done when:** P's engine rows pass; the area opens from KITCHEN and from "pantry" to Tess; the peek on three seed recipes reads need against have; a shop clear and a finished cook change the counts line; nothing on Groceries or the recipe page changes when state is unknown.
