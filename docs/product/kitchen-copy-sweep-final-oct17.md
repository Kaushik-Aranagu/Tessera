# Kitchen copy final sweep, Oct 17 (K83)

*Docs only. Scope: the 52 Kitchen acceptance docs in `docs/product/` (kitchen-*.md, pantry-acceptance.md, lists-*.md, groceries-*.md, recipe-*.md, meal-plan-groceries-acceptance.md, cook-mode-acceptance.md, us-shop-acceptance.md, parallel-steps-acceptance.md, paste-hardening-acceptance.md). The three Oct 17 recheck files, `lists-copy-sweep-oct17.md` and `kitchen-gap-status-oct17.md` were read as sources, not swept. `kitchen-gap-status-oct17.md` was left as it was.*

## What the canon holds

- `kitchen-phrases.md` is a list of 50 input phrases with expected results (what Tess does). It holds no app-copy strings at all, so it cannot settle any wording question below.
- `decisions.md` on master holds the Oct 15 and Oct 16 rulings only: receipts "on" (10:06 PM Oct 15, 2:09 PM Oct 16), "Private item, on <list>." (8:13 PM), the failed-write line "Didn't save. Try again." (8:26 PM sheet 84, point 4), and the 5:58 PM Siri grocery receipt. It has no Oct 17 entries (no 3:00, 3:25, 3:40 or 3:55 text). The Oct 17 rulings reach the docs through the board lines the acceptance docs cite.

## Result table

| File | Row | Old | New / Open |
|---|---|---|---|
| `kitchen-misfire-rows.md` | C13 | the Bar line is "Private item, added to Errands" | **Edited.** "Private item, on Errands." (thing first, "on", 8:13 PM and 10:06 PM Oct 15; the only "added to" receipt left in scope) |
| `kitchen-gap-hunt-2.md` | G6 (Expected column) | Tess: "Groceries stays. Clear it instead." | **Edited.** "Groceries stays, clear it instead." (the G6 wording named in this task and in `kitchen-gap-status-oct17.md`; the row still carries its "Proposed, Product to rule" tag, left as is) |
| `kitchen-gap-hunt-2.md` | G11 (owner table, line 39) | "Already an ingredient. Pick another name." | **Open 1.** Master says "Didn't save that. Already an ingredient."; `kitchen-gap-status-oct17.md` cites the 3:40 follow-up as wanting that form. Neither `kitchen-phrases.md` nor `decisions.md` has the text, so the winner is not decided in the canon. Not edited. |
| `kitchen-gap-hunt-6.md` | G34 | Siri reads exactly "Private item, on Groceries." (proposed, Product to rule) | Consistent with the 8:13 PM and 5:58 PM rulings and with `kitchen-refill7-acceptance.md` K45.7. Left as is; the "proposed" tag is **Open 2**. |
| `kitchen-gap-hunt-6.md` | G39 | "Thu 16 Oct, 12 pm · Recipe link · ..." never "12:00 pm" or "noon" | Matches the 12 pm rule. No change. |
| `kitchen-refill7-acceptance.md` | K44.4 | "Milk, on Groceries." and "Milk, moved to Dairy and eggs." | Matches. No change. |
| `kitchen-refill10-acceptance.md` | K75.1 to K75.20 | "X, moved to <aisle>."; "Private item, moved to <aisle>." | Matches the aisle-change rule. No change. |
| `groceries-ai-acceptance.md` | line 67 | "Oat milk, on Groceries." | Matches. No change. |
| `kitchen-refill7-acceptance.md`, `kitchen-refill8-acceptance.md` | K47.14, K47.15, K54.10, K54.16 | "Recipe gone." with "Back to the list" | Matches. The "This recipe is gone. Undo brings it back." hits are labelled as master's old text. No change. |
| `kitchen-v2-acceptance.md` | G3 | "Recipe gone." centred, context colour | Matches. No change. |
| `kitchen-error-states-acceptance.md` | ER11, ER14, ER17, ER20, ER21, ER23, ER25, ER26 | "Didn't save. Try again." | Matches the 8:26 PM ruling. No change. |
| `kitchen-error-states-acceptance.md` | ER14, ER21; `kitchen-refill10-acceptance.md` K79.18 | "Private recipe didn't save. Try again." / "Private item didn't save. Try again." | **Open 3.** Private variants of the failed-write line; not in the canon. |
| `kitchen-refill7-acceptance.md`, `kitchen-refill8-acceptance.md`, `kitchen-refill9-lane1-acceptance.md`, `kitchen-week-of-use-script.md`, `kitchen-gap-hunt-6.md` | K45.17, K53.6, F5, house rules, G39 | "12 pm" | All already "12 pm". Remaining "noon" hits are scenario prose ("Dal at noon", "nearest noon", "before noon"), not app copy. No change. |
| `kitchen-refill5-acceptance.md`, `kitchen-widget-wash-acceptance.md`, `meal-plan-groceries-acceptance.md`, `kitchen-refill7-acceptance.md` K45.14 | K32.x, KW-W8, line 45 | "Private recipe, 7 pm."; no-time "Private recipe, today." / "tonight." | Matches. No change. |
| All 52 files | grep for bare "Private", "Saved." as expected copy, "in <list>" and "added to <list>" receipts, uppercase AM/PM clocks in app copy | | No other hit in expected app copy. "Saved." appears only as the quoted bad current behaviour (G34). |

**Rulings applied Oct 17 (4:35):** Open 1 (G11 copy "Didn't save that. Already an ingredient."), Open 2 (G34 "proposed" tag dropped), Open 3 (private "Didn't save" variants keep the form, kind only), and the two carried items in Open 5 (merge lines are ink, cobalt is Tess's band only; backup file names use a 4-digit year) are closed. Open 4 (log G6 and G11 in `decisions.md`) is Product's. The 10 missing groups are now in `kitchen-phrases-2.md`.

## Open

1. **G11 wording.** "Already an ingredient. Pick another name." (`kitchen-gap-hunt-2.md` line 39) against "Didn't save that. Already an ingredient." (master, and the 3:40 follow-up as cited in `kitchen-gap-status-oct17.md`). Product to write the winner into `decisions.md`; then edit line 39 only.
2. **G34 Siri line for a private grocery.** "Private item, on Groceries." is marked proposed in G34 but is stated as ruled in K45.7. Product to confirm G34 can drop its "proposed" tag.
3. **Private variants of the failed-write line** (ER14, ER21, K79.18). Not in the canon.
4. **G6 and G11 3:40 rulings have no text in `decisions.md`** on master. The G6 edit above follows the wording given for this task and the gap-status cite; Product to log it.
5. Carried from `kitchen-copy-recheck-oct17.md`: item 2 (cobalt on a merge, `us-shop-acceptance.md` K7.9) and item 3 (4-digit year in a backup file name, `kitchen-gap-hunt-5.md` G26 note) are still unruled.

## Phrases the acceptance docs depend on that `kitchen-phrases.md` lacks

`kitchen-phrases.md` has none of the following; they are listed, not invented. Each is used word for word in the docs named.

- Receipts: "Milk, on Groceries.", "Private item, on Groceries.", "Rice, on Packing." (many files).
- Aisle change: "Chicken, moved to Dairy and eggs." and "Private item, moved to <aisle>." (`kitchen-refill10-acceptance.md` K75).
- Private forms: "Private note, kept.", "Private recipe, 7 pm.", "Private recipe, today.", "Private recipe, tonight." (`kitchen-refill5-acceptance.md` K32, `kitchen-widget-wash-acceptance.md` KW-W8).
- Errors: "Didn't save. Try again." and its private variants (`kitchen-error-states-acceptance.md`).
- Recipe gone page: "Recipe gone." with "Back to the list" (`kitchen-refill7-acceptance.md` K47, `kitchen-refill8-acceptance.md` K54).
- Refusals: "Groceries stays, clear it instead." (G6), the G11 line (Open 1).
- Siri: the private-grocery read-back (G34), "Nothing planned." (K45, K53).
- Claude receipt clock in house form, "Thu 16 Oct, 12 pm · Recipe link · Haiku · 0.3¢" (G39).
- Timer limit: "Timers run up to 24 h." (`kitchen-refill9-lane1-acceptance.md` K65).
- Tess lines for paste and link reads: "N ingredients, M steps." is in `kitchen-phrases.md` row 36 only; "Claude read it. Check it, then save." and "I couldn't find ingredients. Tap a line to mark one." are not.

## Counts

Files swept 52; edits 2 (one line each); rows checked and clean 11 groups; Open items 5; phrases missing from `kitchen-phrases.md` 10 groups.
