# Money: the month page and the spend page (M5 screens 7 and 6, steer)

For Builder B, after Core's `SpendLedger` (screen 7) and `Spend` with its actions (screen 6). It is drawn to `no-buttons.md` and pairs with `money-dial.md`. Recording: `recordings/money-pages.mp4` (source `studies/money-pages.html`).

Shared: amounts are tabular and shown as typed ("€20" stays "€20"). Vermilion is only for UNDO and cobalt only for Tess. **An amount is never red.** There are no budgets, charts or "left to spend".

## 7 · The month page
- **Label:** MONEY. **Hero:** the month line, "October, logged" at Title 44.
- **Under it, one sentence in Body 21:** "**41** spends. Most went to groceries, **312.40**, and lunch, **86.10**." The count and the top two categories by total come from `monthLine(for:)`.
- **Each other currency gets one short line:** "Also **€60.00** in 3 spends."
- **The ledger is one gesture away.** The first ledger line peeks faintly at the foot of the page (28%).
  - **Swipe up:** the month line lifts away (−40pt, fade, 340ms) and becomes the label "OCTOBER · 41 SPENDS".
  - The ledger rises line by line from below (26pt, 440ms, 30ms stagger, house curve).
- **Pinch out** zooms back to the previous month: the same page for September, with a 460ms zoom. **Pinch in** returns.
- **Empty month:** the hero says "October: nothing logged yet", and Tess says one cobalt line by her soul: "Tell me what you spent. Try: spent 4.50 coffee."

## The ledger (typographic, no rows)
- **Days:** the day numeral at 34 Light in the left margin, in the subdued colour, at x 22.
- **Spends:** amount at 24/600 tabular, right-aligned in a 104pt column so the decimals line up, then the word at 24/400 in the context colour, 14pt after. Lines are 36pt apart, and day blocks are 22pt apart.
- **Newest first.** There are no separators, hairlines, cards or rows.
- **Other currencies** follow under their own label ("IN EUROS") as a short ledger in the same form.

## 6 · The spend page (tap a spend)
- **The amount grows in place into the hero.** It moves from its ledger spot to the hero spot (x 20, y 140) as 24/600 becomes 80 Light over 520ms (ease-out cubic). The ledger steps back (fade, 3pt blur, scale 0.985).
- **The breadcrumb label** is "OCTOBER". Tapping it, or swiping down, goes back.
- **The context line in Body:** "**lunch** · Thu 15 Oct, 13:10". The word is a value word.
- **Retag in place:** tap the word, and up to four recent words slide in on the line below (300ms, 40ms stagger). Tap one, and it flies up into the slot as the old word blurs out (`EditSpend`, `.selection`). Typing a new word works the same way: the slot becomes a field. One lowercased word.
- **One level deeper:** swipe up, and the rest of the spend arrives as sentences (380ms, 60ms stagger), never a form:
  - "Typed as **spent 12.40 lunch**."
  - "In **no currency**." The currency is a value word that cycles, as on the dial.
  - "Logged at **13:10** on **Thu 15 Oct**." The time and date are value words that open the time drum in place.
  - "A note? **Add one**."
  - A shop total adds "From the **5:40 shop**, on **Groceries**." Both are links (z).

## Delete is a swipe
- **Drag the hero amount left.** It follows the finger, dims, then blurs out, and the page folds back into the ledger (320ms).
- **The ledger closes up:** the lines under the gap move up 36pt on the settle spring `cubic-bezier(.3,1.3,.5,1)`, and the label count drops by one.
- **Tess says** "Deleted 12.40, food." with UNDO (`DeleteObject` through the op log).

## Accessibility and Reduce Motion
- The month line reads as one sentence. Each ledger line reads "15 October, 12.40, lunch", with a delete action.
- The hero has the delete action as an accessibility custom action. The tag is a button with recent words as its options.
- **Reduce Motion:** the ledger and sentences fade in place, the hero cross-fades instead of growing, and the delete is a fade.
