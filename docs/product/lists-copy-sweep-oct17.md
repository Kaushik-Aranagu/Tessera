# K23 Lists copy sweep

Docs are nearly clean: no "at <time>", no "Archive/Archived" on screen, no ", added to" receipts, private items read "Private item" in docs 13.8. starter-lists.md, kitchen-phrases.md 41-48, lists-fixtures.md and lists-slice-8-phrases.md: no stale on-screen copy found. docs/research/lists-copy.md D3/D7/D9/D16 and disagreements 4/5 quote the old strings as audit history ("Current" column), not live copy; leave.

## Docs
| file:line | stale text | rule | replacement |
|---|---|---|---|
| docs/product/ship-list-lists.md:32 | `Tess saying "Twelve things, two sections."` | digits for counts; thing first (copy D3, accepted in lists-screens-acceptance 9.5) | `Tess saying "12 things, 2 sections."` |
| docs/product/ship-list-lists.md:13 | `archive it (and bring it back)` (slice 1 row) | no "archive" on screen; engine op ok | `put it away (the engine's `archive`) and bring it back` |
| docs/product/lists-acceptance.md:8b (line 64-67 block) | `receipt "Private note, kept."` | fine as is, no change | none |

(Only the first row is a clear on-screen miss; the second is wording in a spec, minor.)

## For Builder B / Core (code)
Conflict first: docs everywhere (lists-acceptance 13.8, lists-screens G6/10.8, copy D9, slice-8 phrases) say receipts are thing first with "on": "Rice, on Packing." / "Private item, on Groceries." Lists.swift mixes both forms. Check which wins: the docs' ruling (Product 12:27 PM Oct 16, sheet 87) is "on". If #638 really keeps "added to" for lists, then the docs (about 15 places) are the stale side; the task text suggests "added to" is current, so confirm with Kitchen lead before editing either.

| file:line | stale text | rule | replacement |
|---|---|---|---|
| TesseraCore/Sources/TesseraCore/Lists/Lists.swift:185 | `"\(kept...), added to \(listTitle)"` (receipt) | receipt form is inconsistent with line 182 `"Private item, on <list>"` in the same function | pick one form for both branches: `"\(Kept), on \(listTitle)"` (docs) or change line 182 to `"Private item, added to \(listTitle)"` (#638) |
| Lists.swift:170-174 | comment and `summary` `"\(thing), added to \(listTitle)"` | same as above; summary and receipt must match | same choice as above |
| Lists.swift:182 | `"\(Self.privateItemLabel), on \(listTitle)"` | consistent with docs 13.8, inconsistent with 185 | keep if docs win |
| TesseraCore/Sources/TesseraCore/Kitchen/Groceries.swift:431 | `"Added \(lines[0])"` / `"Added \(lines.count) things"` | receipt names the thing first | `"\(Line), on Groceries"` / `"\(n) things on Groceries"` (confirm it is shown on screen, it may be an op summary only) |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:369 | `"\(name), on the list."` / `"\(n) things on the list."` | copy S8: name the list once other lists exist | `"\(name), on Groceries."` / `"\(n) things on Groceries."` when the shelf has other lists |
| TessCaptureEngine.swift:311 | `"\(SecretWords.title), kept."` vs Lists.swift:180 `..., kept` (no period) | receipts end with a period on Tess lines | add the period in Lists.swift:180 if shown as a Tess line |

Not found in code: any "Archive"/"Archived" string on a Lists screen, any " at <time>" in Lists copy. Starter list definitions are docs-only (docs/product/starter-lists.md); no "Packing" seed exists in TesseraCore/Sources.
