# Lists 9 to 12: copy audit for Builder B

Board item 62. Research, 2026-10-16. Checked every user-facing line in Design's `design/kitchen/lists-9-12.md` and the Kitchen lead's `product/lists-screens-acceptance.md` (rows 9.1 to 12.5, G1 to G13). Rules from `research/tess-voice.md` (principles 1 to 8, M34, M35), `research/undo-lines.md`, `research/empty-states.md` (rules 1 to 5) and the type rules (no italics, Label 16/700 uppercase, no button shapes: ink words). Master read at `origin/master` 71c9dac (Merge #190).

For: Builder B (screens 9 to 12), Design (copy), Kitchen lead.

## What master already ships

There is no Lists screen on master. The engine is there (`TesseraCore/Sources/TesseraCore/Lists/Lists.swift`), and its `summary(in:)` lines are what Tess, Siri and the model-route fallback show (`undo-lines.md` path 19). They are all verb first, so they break principle 1 today. They are rows S1 to S7 below; fixing them is a Core change, but Builder B's screens will surface them.

## The table

Ids: D = Design's sheet, A = acceptance file, S = shipped on master, N = a line the screens need and neither file gives.

| id | where | current line | rule broken | proposed after line |
|---|---|---|---|---|
| D1 | lists-9-12 §9 table y 124; A 9.1 | "6 lists, packing running" | Names keep their own case; "packing" reads as a verb | "6 lists, Packing running" |
| D2 | lists-9-12 §9 paste | context counts up to "7 lists, packing running" | Same as D1 | "7 lists, Packing running" |
| D3 | lists-9-12 §9 paste; A 9.5; ship-list-lists §9 | Tess: "Twelve things, two sections." | Numbers as digits (voice Do/Don't); principle 1: name the thing first | "{name}, 12 things, 2 sections." With no heading to name it: "New list, 12 things, 2 sections." |
| D4 | lists-9-12 §9 paste | ghost state word "12 THINGS · 2 SECTIONS" | Fine. Missing forms: no sections, and "[x]" lines that come in done | "12 THINGS" / "12 THINGS · 3 DONE" |
| D5 | lists-9-12 §9 state words; A 9.3 | "3 OF 7" on every list | Empty rule 5: a zero-item list must not read "0 OF 0" | "EMPTY" as the state word when a list has no items |
| D6 | lists-9-12 §9 state words | "RUNNING · 9 LEFT", "3 OF 7", "REUSABLE", "PICK ONE" | No rule for a list that is several at once (reusable and pick one and 3 of 7); two words could stack | One labels line, most live first: "RUNNING · 9 LEFT", else "3 OF 7 · REUSABLE". At most two words |
| D7 | lists-9-12 §9 last row; A 9.6 | "Archived" always at the foot | Silence rule 7 and empty rule 5: with nothing archived it zooms into an empty page | Hide "Archived" until something is archived |
| D8 | lists-9-12 §10 trip list; A G9 | Tess: "Packing, Lisbon put away." with UNDO | Passes principle 1. Missing: the undo line and the window. Putting away is a finish, so destructive (M35) | Keep it. UNDO stays 10 s. Undo says "Packing, Lisbon taken back." |
| D9 | lists-9-12 §10 bare words | Tess: "Added to Packing." | Principle 1 (verb first, names no item); master's grocery capture says "Milk, on the list." | 1 item: "Passport, on Packing." 2: "Passport and adapter, on Packing." 3+: "3 things on Packing." Undo: "Passport taken back." / "3 things taken back." |
| D10 | lists-9-12 §10 bare words; A G7 | "buy milk" goes to Groceries "and Tess names it" (no line given) | Needs a line; "on the list" is ambiguous on a list page | "Milk, on Groceries." (lists-daily G7 had "Plasters are on Groceries."; this matches the master capture shape) |
| D11 | lists-9-12 §10 the fold; A 10.4 | "**4** done" (tap restores, hold 0.7 s clears) | No line and no Undo for clearing, which deletes checked items: a destructive write (rule 8) | On clear: "4 done cleared." UNDO 10 s: "4 done taken back." |
| D12 | lists-9-12 §10 the fold; A 10.4 | "**4** done · hold to reset" | Fine as a hint. Reset loses every `checkedAt`, so it is destructive and has no line or Undo | On reset: "Packing reset, 9 open." UNDO 10 s: "Packing reset taken back." |
| D13 | lists-9-12 §10 running | context line "Packing, running"; Now "Packing, 9 left" | Pass. Matches master's "Shopping, 9 left." | Keep |
| D14 | lists-9-12 §10 bare words; A G6 | "done" finishes the run (no line) | Needs a done line (principle 1, counts) | "Packing, done. 9 of 9." Reusable list: "Packing, done. Reset for next time." Undo: "Packing taken back." |
| D15 | lists-9-12 §10 two runs; A G11 | the first run waits in the ledger with RESUME | No line when the new run takes Now; silence is fine (rule 7) | Keep silent. The ledger word is enough |
| D16 | lists-9-12 §10 option words; A 10.5 | "Sections · Reusable · Run it · Pick one · Archive" | Words pass. "Archive" has no line or Undo, and its foot word is "Archived" while Tess says "put away" (D8) | On Archive: "Packing archived." Undo: "Packing taken back." See disagreement 5 for the word |
| D17 | lists-9-12 §10 x between lists | rail of list names | Pass (names only) | Keep |
| D18 | lists-9-12 §10 On Now; A G3 | "GYM BAG" ink label word 60 min before | Pass: ink word, no shape, uppercase label | Keep |
| D19 | lists-9-12 §11; A 11.2 | "Add a note" at 40% | Words pass (empty rule 1). 40% is an extra grey (skill: secondary is 60% ink only) | "Add a note" at 60% ink |
| D20 | lists-9-12 §11; A 11.3 | date "Thursday"; else "Add a day" at 40% | "Thursday" is ambiguous past 6 days; 40% as D19 | Within 6 days: "Thursday". Further: "Thu 23 Oct". Today and tomorrow: "Today", "Tomorrow". "Add a day" at 60% |
| D21 | lists-9-12 §11 day lane | "Today · Fri · Sat · Sun · Mon …" | Pass. Keep "Tomorrow" out of the lane: one form per day | Keep |
| D22 | lists-9-12 §11; A 11.4 | "LINKED FROM" | Pass (master ObjectPage uses the same label). Empty case not given | Hide the label when there are no backlinks |
| D23 | lists-9-12 §11 swipe right | strikes the item (no line) | Silent is right (checking is silent in Groceries) | Keep silent; the row's strike in the list is the receipt |
| D24 | lists-9-12 §12; A 12.4, G13 | "That's all of them." | Passes (state line, no count, no nudge, as G13 decides) | Keep. Optional: "That's all of Films." if Kaushik wants the name |
| D25 | lists-9-12 §12 | picks and skips (no line) | Silence rule 7: pass | Keep silent |
| D26 | lists-9-12 §10 empty list | not given in either file | Empty rules 1 and 5: a list with no items needs one line and a fast path | Context line: "Nothing on it yet". Window: "Type a few, or paste a block." |
| D27 | lists-9-12 §10 context line | only "Packing, running" given; ship-list §10 gives "3 of 7" | Missing idle form | Idle: "3 of 7". All done, not running: "All 7 done" |
| N1 | screens 10 and 11 | no gesture or line to delete one item (engine slice 1 has it) | Undo rule: destructive write, 10 s | "Passport deleted." UNDO 10 s: "Passport taken back." |
| N2 | screen 11 | editing an item's text in place | Edits are silent (like Notes autosave) | No line |
| S1 | Lists.swift:93; TessCaptureEngine.swift:171 | "New list: Packing" / "New list: Packing." | Principle 1, verb or label first | "Packing, new list." |
| S2 | Lists.swift:143 | "Added {text}" | Principle 1, verb first, no list named | "{text}, on {list}." |
| S3 | Lists.swift:177 | "Got {title}" | Principle 1; slang | "{title}, done." |
| S4 | Lists.swift:177 | "Back on the list: {title}" | Principle 1 | "{title}, back on {list}." |
| S5 | Lists.swift:219 | "Moved {title}" | Principle 1 | "{title} moved to {section}." |
| S6 | Lists.swift:251 | "Renamed {from} to {to}" | Principle 1 | "{from} renamed {to}." |
| S7 | Lists.swift:280 | "Cleared {list}" | Principle 1; names no count | "{list}, {n} done cleared." (D11 on the page) |
| S8 | TessCaptureEngine.swift:152-153 | "Milk, on the list." / "3 things on the list." | Pass for Groceries; ambiguous once other lists exist | "Milk, on Groceries." when the shelf has more than Groceries |

Type rules: neither file uses italics on screen (the one `*out*` in the design file is markdown emphasis in prose). Every label line (LISTS, state words, LINKED FROM, GYM BAG, "PACKING · 9 LEFT", "REUSABLE · PICK ONE") is uppercase at Label 16; Builder B should set them at 16/700. UNDO, RESUME, the option words and "‹ KITCHEN" are ink words with no shapes: pass. Note for Design: the sheet's Hero 56/500 and Title 34/500 differ from the skill's Hero 64/700 and Title 34/600; not copy, flagged only.

## Where the acceptance file and the design file disagree

| # | Acceptance says | Design says | Proposed default |
|---|---|---|---|
| 1 | 9.3: state word "RUNNING" | "RUNNING · 9 LEFT" | Design's: the count is what he checks. Also matches the door's "PACKING · 9 LEFT" |
| 2 | 9.3 lists no Groceries word | "14 TO BUY" for Groceries | Design's; it matches master's "12 to buy, in Groceries" |
| 3 | 9.5 has no context count-up | "7 lists, packing running" counts up | Design's, cased per D2 |
| 4 | 10.8: adds to this list, no Tess line | "Added to Packing." | Neither: D9's "Passport, on Packing." |
| 5 | G9: "put away" | foot word "Archived", option word "Archive" | Both files hold both words. Default: one word. Keep G9's "put away" for Tess, and make the foot "Put away" and the option word "Put away" too. If Kaushik prefers "Archive", Tess says "Packing, Lisbon archived." Product call |
| 6 | 10.7: no context line or Now line | "Packing, running" and Now "Packing, 9 left" | Design's (G2 already names "X, N left") |
| 7 | 10.4: on a reusable list it "reads hold to reset" | "4 done · hold to reset" | Same intent; Design's exact string |

Both files agree on the rest. One non-copy mismatch worth knowing: `ship-list-lists.md` §12 says the others dim to 20% with a soft haptic; both the acceptance (12.2) and Design say 14% and a medium haptic. Build to 14% and medium.

## Open for Product

1. D5 "EMPTY" or a fast-path word ("ADD ONE")? Empty rule 5 prefers what to add; a label has no tap.
2. D12 "Packing reset taken back." reads long. The alternative is "Packing taken back.", which can read as if the list went away (same worry as X11 in tess-voice).
3. D14: should "done" on a reusable list reset it automatically? ship-list slice 5 says finish is "reset if reusable"; the line assumes yes.
