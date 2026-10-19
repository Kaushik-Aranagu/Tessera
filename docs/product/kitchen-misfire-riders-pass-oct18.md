# Kitchen misfire rows vs the Oct 22 rider list

*Kitchen lead, 2026-10-18. Board item (8) on `ops/board/kitchen.md:8`. Scope: does `docs/product/kitchen-misfire-rows.md` (cited "MR line N") have a row that would catch a misfire when each Kitchen-touching rider lands on his phone, and is that row still right after the rulings through Oct 18 12:23 AM. That file is not edited here; proposed edits are in the last section.*

**Sources.** Rider list: memory `team/silo/riders.md` lines 10 and 13 and `riders-detail.md` lines 9 and 12; boards `ops/board/core.md:200` (0an) and `ops/board/ios-b.md:70` (0z), both under `/mnt/project-files/tessera/`. Rulings: `/mnt/project-files/tessera/product/decisions.md` (DEC), lines quoted. DEC 1069 (Oct 18 12:23 AM) is not yet in the repo copy `docs/product/decisions.md` (1063 lines); every other DEC cite below has the same line in both copies.

**What the file is.** A phrase fixture for the Bar grammar. It has no row for another door (Groceries Add line, Siri, Paste), a "?" ending, a timer notification, a hold key or Low Power. Those last three are not phrase misfires and are covered by `cook-mode-acceptance.md:33`, `kitchen-first-week-script.md:85` (FW34) and DEC 1011, 1027; none of them is on the rider list.

## Rider table

Kitchen-touching riders only. Not Kitchen, skipped: R1/R2 Review and routines band, 0r, 0t, 0u, 0n, 0o, 0aa N15, 0ae, 0ag, HW11, HW13, 0l-2 beyond its grocery read-back, PN-MENTION 0ad (notes only).

| Rider | Rows covering | Status | Gap and proposed row |
|---|---|---|---|
| 0v + 0ah: "?" phrases pass the walls (DEC 223) | None. No phrase in the file ends in "?" | MISSING | D1, D2 |
| 0ai: one engine wall for AddGroceries and list items, widened at DEC 219 and riders.md:13 (13 `lastWeightKg` sites, body words, a set in focus) | C1-C16 (MR 83-98); A39, A40 (MR 47-48) for the set in focus | OK | Optional D8 for the body-word list |
| 0ac medicine and health words on lists and Groceries (DEC 105, 241) | C13 (MR 95) Errands only | MISSING for Groceries | D3 |
| HW9 10% weight rule (DEC 223 item 4; riders-detail.md:9) | A15 "coffee beans 1 kg" (MR 23), A5 (MR 13), C4 (MR 86) | OK | None. A15 is the row that fails if "1 kg" reads as body weight |
| 0an + 0w: Groceries Add line, Name it, pasted recipe saves (core.md:200) | C15 (MR 97) is the Bar door only | MISSING | D4, D5, D6 |
| 0z recipe-link money strip (ios-b.md:70; rider only if merged and QA'd by Oct 22) | None | MISSING | D6 |
| 0ad / G105: a private recipe name reads "Private recipe" in a task title and receipt (DEC 935) | A31-A33 (MR 39-41) use plain recipe names | MISSING | D7 |
| P14 + 0l-2 Siri `privateLine` (DEC 205, 131) | C1 wording (MR 83); Bar only | MISSING for Siri | D9 |
| UNDO slot (F1-F4) | None needed: UNDO is not phrase-dependent | OK | Receipts are checked in `kitchen-v2-acceptance.md:31` (P13) |
| Task receipt for a walled amount (0ai, DEC 109 at 8:09 PM Oct 16, after DEC 201 at 2:22 PM) | C9 (MR 91) says "Pay rent, Friday." | STALE | Amend C9 |
| Receipt wording line (Product Oct 17 8:40 AM, DEC 889) | MR 79 says 8:40 AM ruled "<Thing>, on <List>." | STALE | Amend MR 79 note |
| Timer notification title "Timer" (DEC 1069; FW34 line 85) | A23-A27 (MR 31-35) | MISSING (not a rider) | D10 |

OK 3, STALE 2, MISSING 7 (12 rows). Rows checked and still right with no change: A35, A37 (MR 43, 45; match `kitchen-v2-acceptance.md:31`), A20 and B7-B8 (dated buy stays a task), C1-C8, C10-C14, C16. No row mentions tap-to-reveal, a hold key or Low Power, so DEC 935 (no reveal), 1027 (hold keys) and 1069 (Low Power) make nothing stale. C13 and C14 (MR 95-96) say "Private item" with no reveal, which matches DEC 935 and `lists-acceptance.md:110` (13.8).

## Why the two STALE rows are stale

1. **C9.** DEC 109 (8:09 PM Oct 16) rules the stored title is "Pay rent fri" once the amount is dropped, and the receipt is "Pay rent, Fri." DEC 201 (2:22 PM Oct 16, earlier) said "Pay rent, Friday." Later wins. A title that still trips the wall keeps "Private task, Fri."
2. **MR 79.** DEC 889 item 1 gives the example "Rice, added on Trip." and says the old "added to" changes to "on". `lists-acceptance.md:110` (13.8) and the Oct 17 4:00 PM and 4:21 AM rulings (DEC 927, 43) use "<Thing>, on <List>." with no "added". The file follows the second form. Product should confirm that "Rice, on Trip." is the ruled form, because DEC 889 as written contradicts it.

## Proposed row edits (for Product to accept; MR not edited)

Part D is new: "Other doors, riders and the Oct 22 gate". Expected cells that need a Product call are marked ASK.

**Amend C9 (MR 91).** Expected: `task "Pay rent", Friday; amount stripped; the stored title is "Pay rent fri"; receipt "Pay rent, Fri."` (DEC 109). If the title still trips the wall: `"Private task, Fri."`.

**Amend MR 79 note.** Replace the 8:40 AM clause with: `list receipt is "<Thing>, on <List>." (lists-acceptance.md 13.8; DEC 889 item 1 example "added on" is superseded by the thing-first rule, ASK Product to confirm)`.

**Amend C15 (MR 97).** Expected: `Bar: private note, receipt "Private note, kept."; no grocery row, nothing sent to Claude. Add line (D4) behaves differently.`

| # | Phrase | Expected |
|---|---|---|
| D1 | door code 4417? | private note, receipt "Private note, kept."; never a plain task (DEC 223 item 1); no Groceries row |
| D2 | out of milk? | ASK: not a grocery write and not walled; whatever it becomes (task or answer) carries no "Private ..." mask. Fails if the "?" route makes it a Private note |
| D3 | buy ibuprofen | groceries ["ibuprofen"]; receipt "Private item, on Groceries."; the row reads "Private item" on his screen, no reveal (DEC 105, 935); never sent to Claude |
| D4 | Add line: milk, door code 4417 | nothing written; the draft stays; one line "That one stays out of Groceries."; no UNDO (DEC 889 item 4). A sum-only line ("$40 at costco") says "That stays on this phone." |
| D5 | Add line: milk $4 | groceries ["milk"], price stripped, same as C1; receipt "Milk, on Groceries." |
| D6 | Paste a recipe whose text has "milk 3.49 gallon" or "$4.50" | the ingredient keeps "milk", the price is dropped and stored nowhere; a pasted page with a walled line saves without it and the miss log keeps no walled phrase (DEC 223 item 2, 889 item 7; 0z for the link path) |
| D7 | cook dentist cake (recipe "Dentist cake") | starts cooking; the recipe reads "Private recipe" on screens and receipts (DEC 935 G105) |
| D7b | dentist cake thursday | dated task whose title is walled: "Private task"; the link to the recipe stays |
| D8 | buy bathroom scales | groceries ["bathroom scales"]; not a body weight, no Private mask (body-word list under 0ai) |
| D9 | Siri: add oat milk 4.50 to groceries | item "Oat milk", price dropped, read-back "Oat milk, on Groceries."; a private item reads "Private item, on Groceries." (DEC 131, 43) |
| D10 | timer dentist 10 | timer starts; the notification title is "Timer" and the body is "Timer is done." because the label is private (FW34, `kitchen-first-week-script.md:85`; DEC 1069 keeps the title "Timer"). Plain label "Rice" gives body "Rice is done." |

## Notes for the Oct 22 gate

- D1 to D7 depend on 0ah, 0ai, 0an and 0w landing. Run Part C and D against the first release carrying each, not the last.
- D2 and D8 are the over-wall traps (DEC 241: when unsure the rule leans toward walling). A fail there is annoying, not a leak; a pass on D1, D3, D4 and D7 is the leak check.
- Timer notification, hold keys and Low Power have no phrase row by design. Their checks live in `cook-mode-acceptance.md:33`, the FW34 row, and DEC 1011 and 1027 (hold keys finish or clear: cook Done, Finish workout, Groceries Done, Lists Reset; "Clear the basket" is a tap key).


## Rulings in (Product)

C9 reads "Pay rent, Fri."; line 79 receipt wording follows decisions line 889 ("Rice, added on Trip."); D2 uses the default in this doc.
