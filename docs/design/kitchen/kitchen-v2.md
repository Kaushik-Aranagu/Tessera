# Kitchen v2: recipe from a link, and pantry light (build sheet)

Just enough to build. Product steer: `docs/product/kitchen-v2-backlog.md` (slices L1-L3 and the top three backlog items); research brief `docs/research/recipe-link-fetch.md` §4 for every failure line. Drawn to `../no-buttons.md`. Light ground and kitchen colours as in `13-groceries.md`; Tess speaks beside her soul (right 78, bottom 43, width 262), as everywhere since #107.

Recordings:
- `../recordings/link-fetch.mp4` (source `../studies/link-fetch.html`): a JSON-LD read, a site that blocks, Claude reading a page with no recipe card, and a paywall.
- `../recordings/pantry-light.mp4` (source `../studies/pantry-light.html`): out-of lines on a recipe, the Ingredient page's state word, "Usually have" at the foot of Groceries (shown with its earlier label), and CAN COOK on the shelf.

## L · Recipe from a link (the paste screen, sheet 11)
No new screen. A link is read on the paste paint-over, and whatever comes back is painted by the same brush pass.

### Getting a link in
- **Empty paste screen:** a cobalt line at Title 34/400, "Paste a recipe / or a link." (two lines, set by hand), with **PASTE** under it as a label word (16/700, hairline on touch).
- **PASTE** is `PasteButton` for text and URLs. It's a system control and draws its own shape. Try `.buttonStyle(.plain)` with `.labelStyle(.titleOnly)` and an ink tint so it reads as the label word. If iOS won't draw it without a capsule, use the edit-menu paste on the page instead (long press, then Paste, which needs no prompt) and keep a plain label word that reads `UIPasteboard` on tap. Don't ship a capsule.
- **Share sheet:** the `ImportRecipeLink(url:)` Shortcut opens this screen with the link already landed, straight into Reading.
- **Ghost row:** a pasted link in Tess's Write opens this screen the same way.

### The link line
- y 150. The host at 21/600 ink ("hebbarskitchen.com"), then the path at 21/400 and 45%, truncated at the tail on one line.
- It lands from 10pt below with blur 3 to 0 over 300ms on the house curve.

### Reading (the living moment of L)
- **No spinner, no progress bar.** A soft cadmium wash, 140pt wide, sweeps left to right across the link line and loops (1.4s, `cubic-bezier(.45,0,.55,1)`, multiply blend, blur 5). It's the brush waiting on the page.
- Tess's dabs pulse in turn while she reads. Her line: "Reading hebbarskitchen.com…".
- **Reduce Motion:** no sweep; the link line breathes from 100% to 70% opacity.

### When it reads (L1 JSON-LD, L2 text)
1. The link line lifts and shrinks away (up 30, scale 0.8, 300ms). In its place at y 112 is the source, in labels: "FROM HEBBARSKITCHEN.COM".
2. The generated plain text lands as if pasted: ink at 85%, lines fading up 6pt, 30ms apart.
3. The brush pass reads it exactly as in sheet 11: amounts get a cadmium under-stroke, names a sage dab, durations a tick, steps their margin numerals, and the title is promoted to 34.
4. Tess counts what she found: "Six ingredients, three steps, two timers." When a page has several recipes, she adds "There were 3 on the page; I read the first."
5. **Save recipe** is a stroke word (Title 34/500 on a sage 19pt stroke) at y 690. Tap it to wet it. Then Tess says "Dal tadka saved." with **UNDO** in vermilion.
- The recipe keeps its link. On the Recipe page it sits one level down (tap the hero) as the first line: "From **hebbarskitchen.com**", with the host as a value word that opens Safari.

### When Claude reads it (L3)
- Only after L1 and L2 fail, and only with Claude on. Tess says "No recipe card there. Asking Claude.", and a **cloud mark** (a 22×14 cobalt outline, 1.6pt) appears just above her soul for as long as the request is out. This is the model layer's cloud mark.
- **The recipe streams in as a wet cobalt ghost.** Each line is painted left to right (clip from the left, 300ms) as it arrives, about 150ms apart, and breathes between 78% and 100%, like every ghost.
- Then the brush pass marks it as usual. Tess: "Claude read it. Check it, then save."
- **Save dries it to ink** top-down, 50ms per line, and the cloud mark fades. Then Tess: "Lemon pasta saved." with **UNDO**.
- The colour carries where it came from: ink means the page's own words, and wet cobalt means Tess's (Claude's) reading, until he saves.
- The 20s timeout falls through to the "no recipe found" line below.

### When it can't read it
In every case: no modal, no error code, and nothing written. The link stays where it is, and Tess speaks in cobalt beside the soul.

| Case | What stays on the page | Tess |
|---|---|---|
| Blocked (401/403/429, bot check) | The link line at full ink. A cobalt writing line opens under it at y 196 (0.5pt rule drawn left to right, 420ms) with a caret, ready for pasted text | "That site won't let me read it. Paste the recipe text instead." |
| Paywall, ingredients only | The ingredients, read and marked. A writing line opens under the "Method" line | "Got 12 ingredients. The steps are behind the site's paywall; paste them below." |
| Paywall, nothing | The link line, and a writing line | "That page is behind a paywall. Paste the recipe text instead." |
| No recipe found | The link line, and a writing line | "Couldn't find a recipe on that page. Paste the text instead." |
| Video with a written recipe in its description | The description is read and marked like a paste | "Read the video's description: 9 ingredients." |
| Video that links to a recipe site | The link line | "The video links to **hebbarskitchen.com**. Read that instead?" The host is a value word; tapping it starts Reading on that link |
| Video with nothing | The link line, and a writing line | "That's a video without a written recipe. Paste the ingredients if you have them." |
| Offline | The link line, at 45% | "You're offline. I'll read this link when you're back." He can leave; it waits in `TessInbox` and returns as a ghost recipe, never saved on its own |
| Claude paused (cap) | The link line, and a writing line | "Couldn't read that page, and Claude is paused until 1 Nov. Paste the text instead." |
| Too big or odd | The link line, and a writing line | "That page is too big or odd to read safely. Paste the text instead." |

## P · Pantry light (no pantry screen)

### On the Recipe page (sheet 10)
- **Out** lines: the amount drops from 600 to 400, the whole line goes to 55%, and a **faint ring** (11pt, 1.3pt stroke, ink 42%) sits in the left margin at x 6, centred on the row. It's the Review's language for a miss: a faint ring, never red.
- On arrival the out lines lighten over 420ms after the page settles, and each ring draws round from the top (520ms, house curve, 160ms apart). That is the one living moment.
- **Low** and **unknown** show nothing here. **Staples** stay as they are (45%, amounts at 400, no ring), so a staple never reads as missing.
- The amount column needs about 92pt for "1 bunch". Keep it fixed-width so out lines don't shift when their weight drops.
- **Swipe to Groceries** (sheet 10) sends out, low and unknown lines. Lines that are *in* stay put, like staples.

### On the Ingredient page
- Tap an ingredient name on a recipe; it travels up to be the hero (21 to 56, 460ms), and the rest of the page rises 14pt.
- y 58, the back word (`../back-word.md`): "‹ DAL TADKA".
- y 168, **the state sentence** (21/400 ink), opening with the state as a value word (600 on a cadmium wash):
  - "**Out** since you cooked dal on Tuesday."
  - "**Low**, after dal on Tuesday."
  - "**In** since Saturday's shop." or "**In**, as of now."
  - Unknown: no sentence.
- **Tap the value word** to cycle in → low → out → in. The sentence swaps through a blur (out 120ms, in 220ms), with a `.selection` haptic. It's undoable like any write.
- y 204, the rhythm in the context colour, only after 3 buys: "Bought 4 times, about every 12 days."
- y 276, USED IN in labels, then the recipe names on one line at 21/400; each name links to its recipe.

### Telling Tess
- "out of milk": "Milk's out. On the list." with **UNDO**.
- "have rice": "Rice, in." with **UNDO**.

## R · Usually have (foot of Groceries)
The first pantry step, ahead of pantry state: it reads existing Groceries history (3+ typed buys in 56 days), per the Kitchen lead.
- The last thing in the aisle window, after the last aisle, never pinned. One line at 21/400 and 55%: "Usually have: milk, eggs, rice", with "Usually have:" in the context colour and the names in ink. Three at most. (The recording still shows the earlier "USUALLY BY NOW" label above the names; the copy is now this one line, and the look and motion are unchanged.)
- **Tap a name** and it joins its aisle. The aisles below open by one row on the settle spring (420ms). The name flies to its new row on the y arc (`cubic-bezier(.3,0,.25,1)`, 520ms), inking from 55% to 100%. The rest of the line closes up behind it (360ms, house curve). The context count rolls up by one. Tess: "Milk, in Groceries." with **UNDO**.
- **Swipe a name left** to skip it until its next gap. Nothing is ever added on its own.
- When there's nothing due, the line takes no space.

## W · What can I cook (shelf filter word, sheet 14)
- **CAN COOK** replaces FROM THE BASKET as the third filter word when slice W lands (v1's shelf keeps FROM THE BASKET until pantry state exists): QUICK · NOT LATELY · CAN COOK. It's off by default and gets the vermilion carriage when on.
- **On:** names missing two or more drop (fade down 10pt, 180ms). The rest re-sort on the settle spring (460ms), keeping their sizes: nothing missing first (ties go to the one not cooked lately), then one missing. The context line swaps to "3 you can cook now".
- **One missing:** a line under the name unrolls left to right (360ms, 80ms apart) at 21/400 in the context colour, "1 missing: **lemons**", with the ingredient as a value word. Tap it to put it on the list: the line turns sage, "lemons is on the list", and Tess says "Lemons, in Groceries." with **UNDO**.
- **Unknown counts as missing**, as the research says, but the line says so honestly: "1 to check: **lemons**". Tapping it opens the Ingredient page instead of adding it.
- **Nothing cookable:** the context line reads "Nothing without a shop", and the one-missing names remain.

## Reduce Motion and Dynamic Type
- Reduce Motion: the reading sweep becomes a breath. Marks and rings fade in together over 200ms. Flights and re-sorts become crossfades in place.
- At accessibility sizes, the ring moves inline before the amount, and the missing line wraps under the name.

## Decided with the Kitchen lead (2026-10-15)
1. CAN COOK replaces FROM THE BASKET with slice W, and unknowns say "1 to check".
2. Swipe-to-Groceries skips *in* lines and staples; low lines go along with out and unknown.
3. Low stays unmarked on the recipe page. Anything that marks it must be quieter than the out ring, and nothing is needed yet.
