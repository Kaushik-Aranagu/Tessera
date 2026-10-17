# Groceries FOR WHAT: sheet 77 acceptance, rows GS1 to GS16 (K17)

*Kitchen lead, 2026-10-17, extending `kitchen-sides-acceptance.md` sections 1 and 7 (rows 1.1 to 1.4 and 7.1 to 7.3, 7.11 stand; nothing below repeats them) and `lists-acceptance.md` 13.8 and 13.9. Sources: Design `sides-77.md` (Groceries row, Copy notes), `lists-recipes-87.md` ("A private item", ruled 8:35), `every-side.md` and `depth.md`. Product can overrule any line.*

| # | State | Pass when |
|---|---|---|
| GS1 | No planned recipes | Only JUST BECAUSE and USUALLY show, in that order, no cook group; the glance big fact is the just-because count; Tess says nothing (7.3 covers the line, this row covers the layout) |
| GS2 | One cook | One group, e.g. TACOS, SUNDAY, then JUST BECAUSE and USUALLY; Tess says "4 for 1 cook, 3 just because." with "cook" singular at 1 |
| GS3 | Two cooks, a shared ingredient | A row both cooks need (onions) sits under the sooner cook with "also chili" on it; the other group does not list it again |
| GS4 | Two cooks shown once | Counting the rows on the side gives the same number as the glance big fact and the front's "to buy" count; a shared row adds 1, never 2 |
| GS5 | Ordering | Groups run soonest cook first by cook date; two cooks on the same day order by plan order; JUST BECAUSE then USUALLY always last; a cook moved in the plan reorders the groups on the next open |
| GS6 | A private item | It reads only "Private item" at 66% ink, in its group like any row; it counts in the glance and in Tess's counts; its words appear in no group name, label, Tess line, receipt or VoiceOver string |
| GS7 | Private item, nothing behind it | Tapping it does nothing: no sheet, no link, no edit; the front's swipe keeps Check off and Remove; receipts read "Private item, on Groceries." / "Private item, removed." / "Private item, back on Groceries." (13.8) |
| GS8 | A checked row | It stays in its group, struck, until the shop clears it; it is not counted in the glance big fact or Tess's counts; its group header stays while it holds any row |
| GS9 | Empty list | No groups, no glance big fact; the side says "Nothing to buy." and has no ALL LINKS foot; Tess says nothing |
| GS10 | More than 4 groups | Four groups show in full, the rest fold into one quiet line "and 2 more" (digit, from the fifth); opening it is ALL LINKS, not a control on the side |
| GS11 | The glance | Stop 1 is a half-screen: the big fact "7" with *for 2 cooks* beneath, then "Tacos and chili", then "3 just because"; foot word ALL LINKS; the three lines add up to the front |
| GS12 | Tess's line | The same words at the glance and the full side: "7 for 2 cooks, 3 just because."; counts only, never an item name, a private item included |
| GS13 | No controls | The side has no button, switch or field; REMOVE stays the row swipe on the front; the only things to touch are the context-line word, the way back (GROCERIES) and the links |
| GS14 | Side word and Reduce Motion | The context-line word is FOR WHAT; with Reduce Motion on, front to side and back is a 150 ms crossfade, with no slide, turn or scale |
| GS15 | VoiceOver and Dynamic Type | Each group reads as a heading ("Tacos, Sunday, 4 things"); a row reads its name, "also chili" if it has it, and "checked" if struck; a private row reads "Private item"; at AX sizes one column, no clipped names, group names wrap |
| GS16 | Nothing sent to Claude | Opening the side, the glance and Tess's line make no Claude request; the line is built on the phone from counts; the wall holds for private items |

## Open, defaults taken

- A tie on cook date orders by plan order. Default taken.
- A checked row leaves the glance count and stays in its group. Default taken.
- The "and N more" line opens ALL LINKS and is not its own link. Default taken.
- Tess's wording at one cook is "1 cook" (singular). Default taken.
